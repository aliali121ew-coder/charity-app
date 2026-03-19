// ─────────────────────────────────────────────────────────────────────────────
// MockPaymentProvider
//
// Development-only provider.  Simulates realistic delays and flows so the UI
// and state machine can be tested without a live gateway.
//
// ⚠️  NEVER ship this as the active provider in production.
//     Replace with the real ZainCash / Stripe provider via registry.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../domain/models/payment_models.dart';
import '../../domain/interfaces/payment_provider_interface.dart';

class MockPaymentProvider implements PaymentProviderInterface {
  MockPaymentProvider({this.simulateFailure = false});

  /// Set to true to simulate a failed payment (useful for testing error states).
  final bool simulateFailure;

  static const _uuid = Uuid();

  @override
  String get providerId => 'mock';

  @override
  String get providerName => 'Mock Provider (Dev)';

  @override
  bool get isAvailable => true;

  @override
  List<PaymentMethodType> get supportedMethods =>
      PaymentMethodType.values.toList();

  // ── Session creation ───────────────────────────────────────────────────────

  @override
  Future<PaymentSession> createSession({
    required double amount,
    required PaymentCurrency currency,
    required PaymentMethodType method,
    required String donorName,
    required String donationId,
    Map<String, dynamic>? metadata,
  }) async {
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 800));

    final sessionId = 'mock_sess_${_uuid.v4().substring(0, 8)}';
    final now = DateTime.now();

    // Determine what verification the mock requires
    final verType = _verificationFor(method);

    return PaymentSession(
      sessionId: sessionId,
      providerId: providerId,
      amount: amount,
      currency: currency,
      method: method,
      status: PaymentSessionStatus.pending,
      verificationRequired: verType,
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: 15)),
      clientToken: 'mock_client_token_${_uuid.v4().substring(0, 12)}',
      providerData: {
        'mock': true,
        'donor': donorName,
        'donation_id': donationId,
        ...?metadata,
      },
    );
  }

  // ── Payment initiation ─────────────────────────────────────────────────────

  @override
  Future<PaymentInitiationResult> initiatePayment({
    required PaymentSession session,
    required PaymentInput input,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1200));

    if (session.isExpired) throw const PaymentSessionExpiredException();

    final verType = _verificationFor(session.method);
    final needsVerification = verType != VerificationType.none;

    // Mock: wallet methods get an OTP reference
    final updatedSession = session.copyWith(
      status: needsVerification
          ? PaymentSessionStatus.verificationRequired
          : PaymentSessionStatus.processing,
      verificationReference:
          needsVerification ? 'mock_otp_ref_${_uuid.v4().substring(0, 6)}' : null,
    );

    String? msgAr;
    if (verType == VerificationType.otp) {
      msgAr = 'تم إرسال رمز التحقق إلى هاتفك المرتبط بالمحفظة.';
    } else if (verType == VerificationType.threeDSecure) {
      msgAr = 'يتطلب هذا الدفع التحقق الأمني ثلاثي الأبعاد (3D Secure).';
    }

    return PaymentInitiationResult(
      requiresVerification: needsVerification,
      verificationType: verType,
      session: updatedSession,
      messageAr: msgAr,
    );
  }

  // ── Verification ───────────────────────────────────────────────────────────

  @override
  Future<PaymentResult> verifyPayment({
    required PaymentSession session,
    required String verificationCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    if (session.isExpired) {
      return PaymentResult.failure(
        errorCode: 'SESSION_EXPIRED',
        errorMessage: 'Session expired',
        errorMessageAr: 'انتهت صلاحية الجلسة.',
        session: session.copyWith(status: PaymentSessionStatus.expired),
      );
    }

    if (simulateFailure) {
      return PaymentResult.failure(
        errorCode: 'OTP_MISMATCH',
        errorMessage: 'OTP verification failed',
        errorMessageAr: 'رمز التحقق غير صحيح.',
        session: session.copyWith(status: PaymentSessionStatus.failed),
      );
    }

    // In mock: accept any 4–6 digit code (real providers verify server-side)
    final cleaned = verificationCode.trim();
    if (cleaned.length < 4) {
      return PaymentResult.failure(
        errorCode: 'INVALID_CODE',
        errorMessage: 'Verification code too short',
        errorMessageAr: 'رمز التحقق قصير جداً.',
        session: session,
      );
    }

    final completedSession =
        session.copyWith(status: PaymentSessionStatus.completed);

    return PaymentResult.success(
      transactionId: 'TXN-${_uuid.v4().substring(0, 8).toUpperCase()}',
      providerReference: 'MOCK-REF-${Random().nextInt(999999).toString().padLeft(6, '0')}',
      session: completedSession,
      metadata: {'mock': true, 'code_used': cleaned},
    );
  }

  // ── Status check ───────────────────────────────────────────────────────────

  @override
  Future<PaymentSession> checkStatus(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Mock always reports 'processing'; real provider returns actual state
    throw UnimplementedError(
        'checkStatus not meaningful for mock; use real provider in production');
  }

  // ── Cancel ─────────────────────────────────────────────────────────────────

  @override
  Future<bool> cancelSession(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return true;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  @override
  Future<void> resendOtp(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Mock: silently succeeds — OTP "resent"
  }

  VerificationType _verificationFor(PaymentMethodType method) {
    if (method == PaymentMethodType.zaincash ||
        method == PaymentMethodType.superki) {
      return VerificationType.otp;
    }
    if (method == PaymentMethodType.visa ||
        method == PaymentMethodType.mastercard) {
      return VerificationType.threeDSecure;
    }
    return VerificationType.none;
  }
}
