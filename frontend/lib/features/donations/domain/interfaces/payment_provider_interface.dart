// ─────────────────────────────────────────────────────────────────────────────
// Payment Provider Interface — Strategy Pattern
//
// Every payment gateway (ZainCash, Stripe, PayPal, Tap, MyFatoorah …) must
// implement this contract.  The rest of the app only talks to this interface;
// swapping a provider never touches UI or business logic.
// ─────────────────────────────────────────────────────────────────────────────

import '../models/payment_models.dart';

// ── Core interface ─────────────────────────────────────────────────────────────

abstract class PaymentProviderInterface {
  /// Unique identifier for this provider (e.g. 'zaincash', 'stripe').
  String get providerId;

  /// Human-readable provider name.
  String get providerName;

  /// Payment methods this provider supports.
  List<PaymentMethodType> get supportedMethods;

  /// Whether this provider is currently available (feature flag / env-based).
  bool get isAvailable;

  // ── Session lifecycle ──────────────────────────────────────────────────────

  /// Step 1 — Create a payment session server-side.
  ///
  /// The backend generates an intent / order and returns a [PaymentSession]
  /// with a [clientToken] (or [redirectUrl]) that the client uses.
  /// Raw card data or wallet credentials are NEVER sent here.
  Future<PaymentSession> createSession({
    required double amount,
    required PaymentCurrency currency,
    required PaymentMethodType method,
    required String donorName,
    required String donationId,
    Map<String, dynamic>? metadata,
  });

  /// Step 2 — Initiate the payment with the collected input.
  ///
  /// For cards: the provider's client-side SDK tokenises the raw data before
  /// it ever leaves the device; only the resulting token is sent to the backend.
  /// For wallets (ZainCash): the backend triggers an OTP via the provider's API.
  ///
  /// Returns a [PaymentInitiationResult] that says whether further
  /// verification (OTP / 3DS / redirect) is required.
  Future<PaymentInitiationResult> initiatePayment({
    required PaymentSession session,
    required PaymentInput input,
  });

  /// Step 3 (conditional) — Submit the verification code.
  ///
  /// Called only when [PaymentInitiationResult.requiresVerification] is true.
  /// The code (OTP, 3DS PIN, …) is forwarded to the provider's verification
  /// endpoint; the result comes from the provider — never evaluated locally.
  Future<PaymentResult> verifyPayment({
    required PaymentSession session,
    required String verificationCode,
  });

  /// Poll the current status of a session (used after redirect flows / webhooks).
  Future<PaymentSession> checkStatus(String sessionId);

  /// Cancel / void a pending session.
  Future<bool> cancelSession(String sessionId);

  /// Resend OTP to the wallet-owner's phone (wallet providers only).
  /// No-op for card/redirect providers.
  Future<void> resendOtp(String sessionId) async {}
}

// ── Provider Registry ──────────────────────────────────────────────────────────
// Central registry — register providers at app startup; the rest of the app
// resolves the correct provider by method type.

class PaymentProviderRegistry {
  PaymentProviderRegistry._();

  static final PaymentProviderRegistry instance =
      PaymentProviderRegistry._();

  final Map<String, PaymentProviderInterface> _providers = {};

  void register(PaymentProviderInterface provider) {
    _providers[provider.providerId] = provider;
  }

  PaymentProviderInterface? byId(String providerId) =>
      _providers[providerId];

  /// Returns the first available provider that supports [method].
  PaymentProviderInterface? forMethod(PaymentMethodType method) {
    for (final p in _providers.values) {
      if (p.isAvailable && p.supportedMethods.contains(method)) {
        return p;
      }
    }
    return null;
  }

  List<PaymentProviderInterface> get allAvailable =>
      _providers.values.where((p) => p.isAvailable).toList();
}

// ── Exceptions ────────────────────────────────────────────────────────────────

class PaymentException implements Exception {
  final String code;
  final String message;
  final String? messageAr;

  const PaymentException({
    required this.code,
    required this.message,
    this.messageAr,
  });

  @override
  String toString() => 'PaymentException[$code]: $message';
}

class PaymentSessionExpiredException extends PaymentException {
  const PaymentSessionExpiredException()
      : super(
          code: 'SESSION_EXPIRED',
          message: 'Payment session has expired',
          messageAr: 'انتهت صلاحية جلسة الدفع. يرجى المحاولة مجدداً.',
        );
}

class PaymentVerificationFailedException extends PaymentException {
  const PaymentVerificationFailedException({String? messageAr})
      : super(
          code: 'VERIFICATION_FAILED',
          message: 'Payment verification failed',
          messageAr: messageAr ?? 'فشل التحقق. يرجى التأكد من الرمز وإعادة المحاولة.',
        );
}

class PaymentProviderUnavailableException extends PaymentException {
  const PaymentProviderUnavailableException(String provider)
      : super(
          code: 'PROVIDER_UNAVAILABLE',
          message: 'Payment provider $provider is not available',
          messageAr: 'بوابة الدفع غير متاحة حالياً. يرجى المحاولة لاحقاً.',
        );
}
