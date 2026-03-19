// ── Payment Domain Entities ───────────────────────────────────────────────────
// Provider-agnostic payment abstractions supporting:
// Stripe, Checkout.com, PayPal, Tap, MyFatoorah, ZainCash, SuperKi,
// Apple Pay, Google Pay — and any future gateway.

enum PaymentProviderType {
  mock,         // Dev / testing
  zainCash,
  superKi,
  stripe,
  checkoutCom,
  payPal,
  tap,
  myFatoorah,
  applePay,
  googlePay,
  bankTransfer,
  cash,
}

enum VerificationType {
  none,
  otp,                // SMS / app OTP (ZainCash, SuperKi)
  threeDSecure,       // 3DS redirect (Visa, MasterCard)
  redirect,           // External gateway redirect (PayPal, Tap)
  biometric,          // Apple/Google Pay
}

enum PaymentFlowState {
  idle,
  collectingDetails,
  initiating,         // API call in flight
  awaitingVerification,
  verifying,
  processing,
  succeeded,
  failed,
  cancelled,
}

// ── Payment Request ───────────────────────────────────────────────────────────

class PaymentRequest {
  final double amount;
  final String donorName;
  final String currency;                // 'IQD' default
  final PaymentProviderType provider;
  final String? cardNumber;             // Tokenised or masked — never raw PAN in prod
  final String? cardHolderName;
  final String? cardExpiry;            // MM/YY
  final String? cvv;                   // Only held in memory; never logged/stored
  final String? phoneNumber;            // For wallet providers
  final String? notes;
  final Map<String, String> metadata;  // Extensible per-provider extras

  const PaymentRequest({
    required this.amount,
    required this.donorName,
    required this.provider,
    this.currency = 'IQD',
    this.cardNumber,
    this.cardHolderName,
    this.cardExpiry,
    this.cvv,
    this.phoneNumber,
    this.notes,
    this.metadata = const {},
  });

  /// Returns a safe, loggable copy with sensitive fields redacted.
  PaymentRequest redacted() => PaymentRequest(
        amount: amount,
        donorName: donorName,
        provider: provider,
        currency: currency,
        cardNumber: cardNumber != null ? '****' : null,
        cardHolderName: cardHolderName,
        cardExpiry: cardExpiry,
        cvv: cvv != null ? '***' : null,
        phoneNumber: phoneNumber != null
            ? '${phoneNumber!.substring(0, 4)}****${phoneNumber!.substring(phoneNumber!.length - 2)}'
            : null,
        notes: notes,
        metadata: metadata,
      );

  @override
  String toString() => 'PaymentRequest(provider: $provider, amount: $amount $currency)';
}

// ── Payment Session ───────────────────────────────────────────────────────────
// Returned by the gateway after initiating a payment.

class PaymentSession {
  final String sessionId;
  final PaymentProviderType provider;
  final double amount;
  final String currency;
  final VerificationType verificationType;
  final String? redirectUrl;      // For redirect-based flows
  final String? transactionId;    // Gateway transaction ID
  final DateTime createdAt;
  final DateTime expiresAt;
  final Map<String, dynamic> providerData; // Raw gateway response (sanitised)

  const PaymentSession({
    required this.sessionId,
    required this.provider,
    required this.amount,
    required this.currency,
    required this.verificationType,
    this.redirectUrl,
    this.transactionId,
    required this.createdAt,
    required this.expiresAt,
    this.providerData = const {},
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get requiresVerification => verificationType != VerificationType.none;
}

// ── Payment Verification Step ─────────────────────────────────────────────────

class PaymentVerificationStep {
  final String sessionId;
  final VerificationType type;
  final String? otpCode;          // Entered by user (never logged)
  final String? redirectResultUrl; // Return URL from 3DS / external redirect
  final Map<String, dynamic> extras;

  const PaymentVerificationStep({
    required this.sessionId,
    required this.type,
    this.otpCode,
    this.redirectResultUrl,
    this.extras = const {},
  });
}

// ── Payment Result ────────────────────────────────────────────────────────────

class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? referenceNumber;
  final String? errorCode;
  final String? errorMessageAr;
  final String? errorMessageEn;
  final PaymentProviderType provider;
  final double amount;
  final String currency;
  final DateTime timestamp;
  final Map<String, dynamic> providerResponse; // Sanitised gateway response

  const PaymentResult({
    required this.success,
    required this.provider,
    required this.amount,
    required this.currency,
    required this.timestamp,
    this.transactionId,
    this.referenceNumber,
    this.errorCode,
    this.errorMessageAr,
    this.errorMessageEn,
    this.providerResponse = const {},
  });

  factory PaymentResult.failure({
    required PaymentProviderType provider,
    required double amount,
    required String currency,
    required String errorCode,
    required String errorMessageAr,
    String? errorMessageEn,
    Map<String, dynamic> providerResponse = const {},
  }) =>
      PaymentResult(
        success: false,
        provider: provider,
        amount: amount,
        currency: currency,
        timestamp: DateTime.now(),
        errorCode: errorCode,
        errorMessageAr: errorMessageAr,
        errorMessageEn: errorMessageEn,
        providerResponse: providerResponse,
      );

  factory PaymentResult.success({
    required PaymentProviderType provider,
    required double amount,
    required String currency,
    required String transactionId,
    required String referenceNumber,
    Map<String, dynamic> providerResponse = const {},
  }) =>
      PaymentResult(
        success: true,
        provider: provider,
        amount: amount,
        currency: currency,
        timestamp: DateTime.now(),
        transactionId: transactionId,
        referenceNumber: referenceNumber,
        providerResponse: providerResponse,
      );

  String get displayErrorAr =>
      errorMessageAr ?? 'حدث خطأ غير متوقع. يرجى المحاولة مجدداً';
}

// ── Immutable Payment Flow State ──────────────────────────────────────────────

class PaymentFlowData {
  final PaymentFlowState state;
  final PaymentSession? session;
  final PaymentResult? result;
  final String? errorAr;
  final int otpResendCountdown; // seconds remaining

  const PaymentFlowData({
    this.state = PaymentFlowState.idle,
    this.session,
    this.result,
    this.errorAr,
    this.otpResendCountdown = 0,
  });

  PaymentFlowData copyWith({
    PaymentFlowState? state,
    PaymentSession? session,
    PaymentResult? result,
    String? errorAr,
    int? otpResendCountdown,
    bool clearSession = false,
    bool clearResult = false,
    bool clearError = false,
  }) =>
      PaymentFlowData(
        state: state ?? this.state,
        session: clearSession ? null : (session ?? this.session),
        result: clearResult ? null : (result ?? this.result),
        errorAr: clearError ? null : (errorAr ?? this.errorAr),
        otpResendCountdown: otpResendCountdown ?? this.otpResendCountdown,
      );

  bool get isLoading =>
      state == PaymentFlowState.initiating ||
      state == PaymentFlowState.verifying ||
      state == PaymentFlowState.processing;
}
