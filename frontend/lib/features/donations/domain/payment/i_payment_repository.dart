import 'payment_entities.dart';

/// Abstract contract every payment provider must fulfill.
/// Swap implementations at the DI layer — no page code changes needed.
abstract class IPaymentRepository {
  PaymentProviderType get providerType;

  /// Step 1 — Initiate: send request to gateway, get back a session.
  /// May return a session with [VerificationType.none] if no extra step needed.
  Future<PaymentSession> initiatePayment(PaymentRequest request);

  /// Step 2 (conditional) — Verify: submit OTP / 3DS result / redirect result.
  /// Only called when [session.requiresVerification] is true.
  Future<PaymentResult> verifyPayment(PaymentVerificationStep step);

  /// Direct flow (no verification): initiate + confirm in one shot.
  /// Providers that don't need a verification step should implement this.
  Future<PaymentResult> processPayment(PaymentRequest request);

  /// Cancel / void a pending session (best-effort; not all gateways support it).
  Future<void> cancelPayment(String sessionId);

  /// Resend OTP for wallet providers.
  Future<void> resendOtp(String sessionId);

  /// Whether this provider supports a given feature flag.
  bool supportsFeature(String featureKey) => false;
}
