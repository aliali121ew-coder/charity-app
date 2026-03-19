// ─────────────────────────────────────────────────────────────────────────────
// ZainCashPaymentProvider — Real API Integration Contract
//
// Implements the official ZainCash Merchant API flow:
//
//   1. Backend creates a JWT-signed transaction (POST /api/transaction/create)
//   2. ZainCash sends an OTP SMS to the wallet-owner's phone
//   3. User enters OTP in app
//   4. Backend verifies OTP (POST /api/transaction/verify)
//   5. ZainCash confirms via webhook; backend polls /api/transaction/status
//
// 📌 Production credentials must be injected at runtime via environment
//    variables — never hard-coded.
//
// Add to pubspec.yaml:
//   http: ^1.2.0
// ─────────────────────────────────────────────────────────────────────────────

// import 'dart:convert';                      // ← uncomment with http
// import 'package:http/http.dart' as http;   // ← uncomment when http is added
import 'package:uuid/uuid.dart';
import '../../domain/models/payment_models.dart';
import '../../domain/interfaces/payment_provider_interface.dart';

// ── Configuration ─────────────────────────────────────────────────────────────

class ZainCashConfig {
  /// Your ZainCash merchant ID (from the merchant portal).
  final String merchantId;

  /// Your ZainCash secret key — used to sign the JWT.
  /// NEVER expose this to the client.  Must live on your backend.
  final String secretKey;

  /// MSISDN of the merchant's ZainCash wallet (e.g. '9647801234567').
  final String msisdn;

  /// Service type identifier issued by ZainCash.
  final String serviceType;

  /// Whether to hit the sandbox (test) environment.
  final bool isSandbox;

  /// Your backend URL that proxies requests to ZainCash.
  /// All ZainCash API calls MUST be made server-side to protect secretKey.
  final String backendBaseUrl;

  const ZainCashConfig({
    required this.merchantId,
    required this.secretKey,
    required this.msisdn,
    required this.serviceType,
    required this.backendBaseUrl,
    this.isSandbox = false,
  });

  // ZainCash endpoints (for documentation; actual calls go through backend)
  String get _zcBase => isSandbox
      ? 'https://test.zaincash.iq'
      : 'https://api.zaincash.iq';

  String get createTransactionUrl => '$_zcBase/transaction/create';
  String get payUrl => '$_zcBase/transaction/pay';

  // Your backend endpoints that wrap ZainCash API calls
  String get backendCreateUrl => '$backendBaseUrl/api/payments/zaincash/create';
  String get backendVerifyUrl => '$backendBaseUrl/api/payments/zaincash/verify';
  String get backendStatusUrl => '$backendBaseUrl/api/payments/zaincash/status';
  String get backendCancelUrl => '$backendBaseUrl/api/payments/zaincash/cancel';
}

// ── Provider ──────────────────────────────────────────────────────────────────

class ZainCashPaymentProvider implements PaymentProviderInterface {
  ZainCashPaymentProvider({required this.config});

  final ZainCashConfig config;
  // Used when the real HTTP implementation is uncommented
  // ignore: unused_field
  static const _uuid = Uuid();

  @override
  String get providerId => 'zaincash';

  @override
  String get providerName => 'ZainCash';

  @override
  bool get isAvailable => true;

  @override
  List<PaymentMethodType> get supportedMethods =>
      const [PaymentMethodType.zaincash];

  // ── Create Session ─────────────────────────────────────────────────────────
  // Calls your backend, which:
  //   1. Generates a JWT: { amount, orderId, serviceType, msisdn, redirectUrl }
  //      signed with the secretKey using HS256
  //   2. POSTs { token, merchantId, lang } to ZainCash /transaction/create
  //   3. ZainCash returns { token } — the transaction reference token
  //   4. Your backend returns the session to the client

  @override
  Future<PaymentSession> createSession({
    required double amount,
    required PaymentCurrency currency,
    required PaymentMethodType method,
    required String donorName,
    required String donationId,
    Map<String, dynamic>? metadata,
  }) async {
    // orderId and now are used in the real HTTP body below (currently stubbed)
    // final orderId = 'ORD-${_uuid.v4().substring(0, 8).toUpperCase()}';
    // final now = DateTime.now();

    // ── Real implementation (requires http package) ──
    //
    // final response = await http.post(
    //   Uri.parse(config.backendCreateUrl),
    //   headers: {
    //     'Content-Type': 'application/json',
    //     'Authorization': 'Bearer $yourAppAuthToken',
    //   },
    //   body: jsonEncode({
    //     'amount': amount,
    //     'currency': currency.code,
    //     'order_id': orderId,
    //     'donor_name': donorName,
    //     'donation_id': donationId,
    //     'service_type': config.serviceType,
    //     'merchant_id': config.merchantId,
    //     'is_sandbox': config.isSandbox,
    //     ...?metadata,
    //   }),
    // );
    //
    // if (response.statusCode != 200) {
    //   final body = jsonDecode(response.body) as Map<String, dynamic>;
    //   throw PaymentException(
    //     code: body['error_code'] as String? ?? 'CREATE_FAILED',
    //     message: body['message'] as String? ?? 'Failed to create ZainCash session',
    //     messageAr: body['message_ar'] as String?,
    //   );
    // }
    //
    // final data = jsonDecode(response.body) as Map<String, dynamic>;
    // return PaymentSession.fromJson(data);
    // ── End real implementation ──

    // Stub: replace this block with the real HTTP call above
    throw UnimplementedError(
      'ZainCashPaymentProvider.createSession: '
      'Add http package and uncomment the real implementation. '
      'Configure ZainCashConfig with your merchant credentials.',
    );
  }

  // ── Initiate Payment ───────────────────────────────────────────────────────
  // After the session is created, the backend uses the ZainCash transaction
  // token to trigger an OTP to the donor's registered ZainCash phone number.

  @override
  Future<PaymentInitiationResult> initiatePayment({
    required PaymentSession session,
    required PaymentInput input,
  }) async {
    if (input is! WalletPaymentInput) {
      throw const PaymentException(
        code: 'INVALID_INPUT',
        message: 'ZainCash requires WalletPaymentInput',
        messageAr: 'يتطلب زين كاش رقم هاتف المحفظة.',
      );
    }

    if (session.isExpired) throw const PaymentSessionExpiredException();

    // ── Real implementation ──
    //
    // final response = await http.post(
    //   Uri.parse(config.backendInitiateUrl),
    //   headers: {
    //     'Content-Type': 'application/json',
    //     'Authorization': 'Bearer $yourAppAuthToken',
    //   },
    //   body: jsonEncode({
    //     'session_id': session.sessionId,
    //     'phone': input.phoneNumber,
    //     'wallet_owner': input.walletOwnerName,
    //   }),
    // );
    //
    // if (response.statusCode != 200) { ... throw ... }
    //
    // final data = jsonDecode(response.body) as Map<String, dynamic>;
    // final updatedSession = PaymentSession.fromJson(data['session']);
    // return PaymentInitiationResult(
    //   requiresVerification: true,
    //   verificationType: VerificationType.otp,
    //   session: updatedSession,
    //   messageAr: 'تم إرسال رمز التحقق إلى رقم '
    //       '${_maskPhone(input.phoneNumber)}. '
    //       'يُرجى إدخاله خلال 3 دقائق.',
    // );
    // ── End real implementation ──

    throw UnimplementedError(
      'ZainCashPaymentProvider.initiatePayment: '
      'Add http package and configure backend URL.',
    );
  }

  // ── Verify OTP ─────────────────────────────────────────────────────────────
  // The OTP entered by the user is forwarded to the backend, which calls:
  //   POST ZainCash /api/transaction/verify  (or the equivalent endpoint)
  // The result is determined ENTIRELY by ZainCash's response — never locally.

  @override
  Future<PaymentResult> verifyPayment({
    required PaymentSession session,
    required String verificationCode,
  }) async {
    if (session.isExpired) {
      return PaymentResult.failure(
        errorCode: 'SESSION_EXPIRED',
        errorMessage: 'Session expired',
        errorMessageAr: 'انتهت صلاحية الجلسة. يرجى المحاولة مجدداً.',
        session: session.copyWith(status: PaymentSessionStatus.expired),
      );
    }

    // ── Real implementation ──
    //
    // final response = await http.post(
    //   Uri.parse(config.backendVerifyUrl),
    //   headers: {
    //     'Content-Type': 'application/json',
    //     'Authorization': 'Bearer $yourAppAuthToken',
    //   },
    //   body: jsonEncode({
    //     'session_id': session.sessionId,
    //     'verification_reference': session.verificationReference,
    //     'otp': verificationCode,
    //   }),
    // );
    //
    // final data = jsonDecode(response.body) as Map<String, dynamic>;
    //
    // if (response.statusCode == 200 && data['success'] == true) {
    //   return PaymentResult.success(
    //     transactionId: data['transaction_id'] as String,
    //     providerReference: data['zaincash_ref'] as String,
    //     session: PaymentSession.fromJson(data['session']),
    //     metadata: data['metadata'] as Map<String, dynamic>?,
    //   );
    // }
    //
    // return PaymentResult.failure(
    //   errorCode: data['error_code'] as String? ?? 'VERIFY_FAILED',
    //   errorMessage: data['message'] as String? ?? 'Verification failed',
    //   errorMessageAr: data['message_ar'] as String?
    //       ?? 'فشل التحقق. يرجى التأكد من الرمز.',
    //   session: PaymentSession.fromJson(data['session']),
    // );
    // ── End real implementation ──

    throw UnimplementedError(
      'ZainCashPaymentProvider.verifyPayment: '
      'Add http package and configure backend URL.',
    );
  }

  // ── Status check ───────────────────────────────────────────────────────────

  @override
  Future<PaymentSession> checkStatus(String sessionId) async {
    // ── Real implementation ──
    //
    // final response = await http.get(
    //   Uri.parse('${config.backendStatusUrl}/$sessionId'),
    //   headers: { 'Authorization': 'Bearer $yourAppAuthToken' },
    // );
    // return PaymentSession.fromJson(
    //     jsonDecode(response.body) as Map<String, dynamic>);
    // ── End ──

    throw UnimplementedError('ZainCashPaymentProvider.checkStatus: configure backend.');
  }

  // ── Cancel ─────────────────────────────────────────────────────────────────

  @override
  Future<bool> cancelSession(String sessionId) async {
    // ── Real implementation ──
    //
    // final response = await http.post(
    //   Uri.parse(config.backendCancelUrl),
    //   headers: { 'Content-Type': 'application/json',
    //               'Authorization': 'Bearer $yourAppAuthToken' },
    //   body: jsonEncode({ 'session_id': sessionId }),
    // );
    // return response.statusCode == 200;
    // ── End ──

    throw UnimplementedError('ZainCashPaymentProvider.cancelSession: configure backend.');
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  @override
  Future<void> resendOtp(String sessionId) async {
    // Real: POST config.backendResendUrl with { session_id: sessionId }
    // Stub: no-op
  }

  String _maskPhone(String phone) {
    final c = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (c.length < 4) return phone;
    return '${c.substring(0, 4)}****${c.substring(c.length - 2)}';
  }
}

// ── ZainCash JWT payload reference ────────────────────────────────────────────
// Your backend must build and sign this JWT with HS256 using the secret key.
//
// Payload:
// {
//   "amount":       number,        // IQD amount
//   "serviceType":  string,        // issued by ZainCash
//   "msisdn":       string,        // merchant wallet MSISDN e.g. "9647801234567"
//   "orderId":      string,        // unique per transaction
//   "redirectUrl":  string,        // URL ZainCash POSTs result to
//   "iat":          timestamp,
//   "exp":          timestamp      // iat + 4 hours
// }
//
// POST body to ZainCash /transaction/create:
// {
//   "token":      "<signed JWT>",
//   "merchantId": "<your merchant ID>",
//   "lang":       "ar"             // or "en"
// }
//
// ZainCash response:
// { "token": "<zcTransaction token>" }  ← this goes into session.verificationReference

// ── Stripe integration stub ────────────────────────────────────────────────────
// To add Stripe: implement PaymentProviderInterface for Stripe.
// Use flutter_stripe package for PCI-DSS compliant card tokenization.
// createSession → POST /create-payment-intent on your backend (Stripe SDK)
// initiatePayment → Stripe.instance.confirmPayment(clientSecret, ...)
// No OTP needed; Stripe handles 3DS natively inside confirmPayment.

// ── MyFatoorah integration stub ────────────────────────────────────────────────
// MyFatoorah uses a similar JWT flow for GCC markets.
// POST /v2/InitiatePayment → get payment method list
// POST /v2/ExecutePayment  → get payment URL
// Redirect flow or in-app WebView for card entry.
