// ─────────────────────────────────────────────────────────────────────────────
// PaymentFlowProvider — Riverpod State Machine
//
// States:  idle → sessionCreating → formReady → initiating →
//          verifying → processing → success | failure
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/payment_models.dart';
import '../../domain/interfaces/payment_provider_interface.dart';
import '../../data/providers/mock_payment_provider.dart';
import '../../data/providers/backend_payments_provider.dart';

// ── State ─────────────────────────────────────────────────────────────────────

enum PaymentFlowStep {
  idle,
  sessionCreating, // Contacting backend to create payment intent
  formReady,       // Session ready; user filling in form
  initiating,      // Submitting input to provider
  verifying,       // Awaiting OTP / 3DS input from user
  processing,      // Code submitted; awaiting final provider confirmation
  success,
  failure,
}

class PaymentFlowState {
  final PaymentFlowStep step;
  final PaymentMethodType selectedMethod;
  final int selectedCardIndex;
  final PaymentSession? session;
  final PaymentInitiationResult? initiationResult;
  final PaymentResult? result;
  final String? errorAr;
  final bool canRetry;

  const PaymentFlowState({
    this.step = PaymentFlowStep.idle,
    this.selectedMethod = PaymentMethodType.zaincash,
    this.selectedCardIndex = 0,
    this.session,
    this.initiationResult,
    this.result,
    this.errorAr,
    this.canRetry = false,
  });

  bool get isLoading =>
      step == PaymentFlowStep.sessionCreating ||
      step == PaymentFlowStep.initiating ||
      step == PaymentFlowStep.processing;

  bool get showVerification => step == PaymentFlowStep.verifying;
  bool get showSuccess => step == PaymentFlowStep.success;
  bool get showFailure => step == PaymentFlowStep.failure;
  bool get showForm =>
      step == PaymentFlowStep.formReady ||
      step == PaymentFlowStep.initiating;

  // Sentinel used to distinguish "not provided" from explicit null in copyWith.
  static const _absent = Object();

  PaymentFlowState copyWith({
    PaymentFlowStep? step,
    PaymentMethodType? selectedMethod,
    int? selectedCardIndex,
    Object? session = _absent,
    Object? initiationResult = _absent,
    Object? result = _absent,
    Object? errorAr = _absent,
    bool? canRetry,
  }) {
    return PaymentFlowState(
      step: step ?? this.step,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      selectedCardIndex: selectedCardIndex ?? this.selectedCardIndex,
      session: session == _absent ? this.session : session as PaymentSession?,
      initiationResult: initiationResult == _absent
          ? this.initiationResult
          : initiationResult as PaymentInitiationResult?,
      result: result == _absent ? this.result : result as PaymentResult?,
      errorAr: errorAr == _absent ? this.errorAr : errorAr as String?,
      canRetry: canRetry ?? this.canRetry,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class PaymentFlowNotifier extends Notifier<PaymentFlowState> {
  PaymentProviderRegistry get _registry =>
      ref.read(paymentProviderRegistryProvider);

  @override
  PaymentFlowState build() => const PaymentFlowState();

  // ── Card selection ─────────────────────────────────────────────────────────

  void selectCard(int index, PaymentMethodType method) {
    state = PaymentFlowState(
      step: PaymentFlowStep.idle,
      selectedMethod: method,
      selectedCardIndex: index,
    );
  }

  // ── Start checkout ─────────────────────────────────────────────────────────

  Future<void> startCheckout({
    required double amount,
    required PaymentCurrency currency,
    required String donorName,
    required String donationId,
  }) async {
    final provider = _registry.forMethod(state.selectedMethod);
    if (provider == null) {
      state = state.copyWith(
        step: PaymentFlowStep.failure,
        errorAr: 'وسيلة الدفع المختارة غير متاحة حالياً.',
        canRetry: false,
      );
      return;
    }

    state = state.copyWith(step: PaymentFlowStep.sessionCreating);

    try {
      final session = await provider.createSession(
        amount: amount,
        currency: currency,
        method: state.selectedMethod,
        donorName: donorName,
        donationId: donationId,
      );
      state = state.copyWith(
        step: PaymentFlowStep.formReady,
        session: session,
      );
    } on PaymentException catch (e) {
      state = state.copyWith(
        step: PaymentFlowStep.failure,
        errorAr: e.messageAr ?? 'حدث خطأ أثناء إنشاء جلسة الدفع.',
        canRetry: true,
      );
    } catch (_) {
      state = state.copyWith(
        step: PaymentFlowStep.failure,
        errorAr: 'تعذر الاتصال بخادم الدفع. يرجى التحقق من اتصالك.',
        canRetry: true,
      );
    }
  }

  // ── Submit payment ─────────────────────────────────────────────────────────

  Future<void> submitPayment(PaymentInput input) async {
    final session = state.session;
    if (session == null) return;

    final provider = _registry.forMethod(state.selectedMethod);
    if (provider == null) return;

    state = state.copyWith(step: PaymentFlowStep.initiating);

    try {
      final result = await provider.initiatePayment(
        session: session,
        input: input,
      );

      if (result.requiresVerification) {
        state = state.copyWith(
          step: PaymentFlowStep.verifying,
          session: result.session,
          initiationResult: result,
          errorAr: null,
        );
      } else {
        state = state.copyWith(
          step: PaymentFlowStep.success,
          session: result.session,
          result: PaymentResult(
            success: true,
            session: result.session,
          ),
          errorAr: null,
        );
      }
    } on PaymentException catch (e) {
      state = state.copyWith(
        step: PaymentFlowStep.failure,
        errorAr: e.messageAr ?? 'فشل تقديم طلب الدفع.',
        canRetry: true,
      );
    } catch (_) {
      state = state.copyWith(
        step: PaymentFlowStep.failure,
        errorAr: 'حدث خطأ غير متوقع. يرجى المحاولة مجدداً.',
        canRetry: true,
      );
    }
  }

  // ── Verify OTP / 3DS ───────────────────────────────────────────────────────

  Future<void> submitVerification(String code) async {
    final session = state.session;
    if (session == null) return;

    final provider = _registry.forMethod(state.selectedMethod);
    if (provider == null) return;

    state = state.copyWith(step: PaymentFlowStep.processing);

    try {
      final result = await provider.verifyPayment(
        session: session,
        verificationCode: code,
      );

      if (result.success) {
        state = state.copyWith(
          step: PaymentFlowStep.success,
          session: result.session,
          result: result,
          errorAr: null,
        );
      } else {
        final isRetryable = result.errorCode != 'SESSION_EXPIRED';
        state = state.copyWith(
          step: isRetryable
              ? PaymentFlowStep.verifying
              : PaymentFlowStep.failure,
          session: result.session,
          result: result,
          errorAr: result.errorMessageAr ?? 'فشل التحقق.',
          canRetry: isRetryable,
        );
      }
    } on PaymentException catch (e) {
      state = state.copyWith(
        step: PaymentFlowStep.failure,
        errorAr: e.messageAr ?? 'فشل التحقق.',
        canRetry: false,
      );
    } catch (_) {
      state = state.copyWith(
        step: PaymentFlowStep.failure,
        errorAr: 'تعذر التحقق. يرجى المحاولة مجدداً.',
        canRetry: true,
      );
    }
  }

  // ── Cancel / Reset ─────────────────────────────────────────────────────────

  Future<void> cancel() async {
    final sessionId = state.session?.sessionId;
    if (sessionId != null) {
      final provider = _registry.forMethod(state.selectedMethod);
      try {
        await provider?.cancelSession(sessionId);
      } catch (_) {
        // best-effort
      }
    }
    state = const PaymentFlowState();
  }

  void reset() {
    state = PaymentFlowState(
      selectedMethod: state.selectedMethod,
      selectedCardIndex: state.selectedCardIndex,
    );
  }

  void retryFromForm() {
    state = state.copyWith(
      step: PaymentFlowStep.formReady,
      errorAr: null,
      canRetry: false,
    );
  }

  Future<void> resendOtp(String sessionId) async {
    final provider = _registry.forMethod(state.selectedMethod);
    if (provider == null) return;
    try {
      await provider.resendOtp(sessionId);
    } catch (_) {
      // best-effort — resend failure is non-fatal
    }
  }
}

// ── Riverpod Providers ────────────────────────────────────────────────────────

final paymentProviderRegistryProvider = Provider<PaymentProviderRegistry>((ref) {
  final registry = PaymentProviderRegistry.instance;

  // Backend Hosted Payments (Visa/Master + ZainCash via redirect + webhooks)
  registry.register(BackendPaymentsProvider(ref));

  // Development: MockPaymentProvider (simulates full flow with delays).
  registry.register(MockPaymentProvider());

  // Production ZainCash — uncomment and inject real config via env vars:
  // registry.register(ZainCashPaymentProvider(config: ZainCashConfig(
  //   merchantId:   const String.fromEnvironment('ZAINCASH_MERCHANT_ID'),
  //   secretKey:    const String.fromEnvironment('ZAINCASH_SECRET'),
  //   msisdn:       const String.fromEnvironment('ZAINCASH_MSISDN'),
  //   serviceType:  const String.fromEnvironment('ZAINCASH_SERVICE_TYPE'),
  //   backendBaseUrl: const String.fromEnvironment('BACKEND_URL'),
  // )));

  return registry;
});

final paymentFlowProvider =
    NotifierProvider<PaymentFlowNotifier, PaymentFlowState>(
  PaymentFlowNotifier.new,
);
