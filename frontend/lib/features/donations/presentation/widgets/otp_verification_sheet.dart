import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/payment_flow_provider.dart';
import '../../domain/models/payment_models.dart';

// ── OTP Verification Bottom Sheet ─────────────────────────────────────────────
// Shown when a wallet payment (ZainCash / SuperKi) requires OTP confirmation.

class OtpVerificationSheet extends ConsumerStatefulWidget {
  final PaymentSession session;
  final bool isDark;

  const OtpVerificationSheet({
    super.key,
    required this.session,
    required this.isDark,
  });

  static Future<void> show(
    BuildContext context, {
    required PaymentSession session,
    required bool isDark,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => OtpVerificationSheet(session: session, isDark: isDark),
    );
  }

  @override
  ConsumerState<OtpVerificationSheet> createState() =>
      _OtpVerificationSheetState();
}

class _OtpVerificationSheetState extends ConsumerState<OtpVerificationSheet>
    with SingleTickerProviderStateMixin {
  final _otpCtrls = List.generate(6, (_) => TextEditingController());
  final _focuses = List.generate(6, (_) => FocusNode());
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 8)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeCtrl);

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focuses[0].requestFocus());
  }

  @override
  void dispose() {
    for (final c in _otpCtrls) c.dispose();
    for (final f in _focuses) f.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  String get _otp => _otpCtrls.map((c) => c.text).join();

  void _onFieldChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      FocusScope.of(context).requestFocus(_focuses[index + 1]);
    }
    if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focuses[index - 1]);
    }
    if (_otp.length == 6) _submit();
  }

  void _submit() {
    if (_otp.length != 6) {
      _shakeCtrl.forward(from: 0);
      return;
    }
    ref.read(paymentFlowProvider.notifier).submitVerification(_otp);
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(paymentFlowProvider);

    ref.listen<PaymentFlowState>(paymentFlowProvider, (prev, next) {
      // Close sheet when done
      if (next.step == PaymentFlowStep.success ||
          next.step == PaymentFlowStep.failure ||
          next.step == PaymentFlowStep.idle) {
        Navigator.of(context).pop();
      }
      // Wrong OTP — shake + clear
      if (next.step == PaymentFlowStep.verifying &&
          next.errorAr != null &&
          prev?.errorAr != next.errorAr) {
        _shakeCtrl.forward(from: 0).then((_) {
          for (final c in _otpCtrls) c.clear();
          FocusScope.of(context).requestFocus(_focuses[0]);
        });
      }
    });

    final isDark = widget.isDark;
    final bg = isDark ? const Color(0xFF1A1A2E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 16,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F52BA), Color(0xFF003D7A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F52BA).withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.phone_android_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'أدخل رمز التحقق',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تم إرسال رمز OTP إلى رقم المحفظة المسجل',
            style: TextStyle(
              color:
                  isDark ? Colors.white.withOpacity(0.55) : Colors.grey.shade600,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          // OTP boxes
          AnimatedBuilder(
            animation: _shakeAnim,
            builder: (context, child) => Transform.translate(
              offset: Offset(
                _shakeAnim.value *
                    ((_shakeCtrl.value * 10).floor().isEven ? 1 : -1),
                0,
              ),
              child: child,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                return Container(
                  width: 44,
                  height: 52,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: TextFormField(
                    controller: _otpCtrls[i],
                    focusNode: _focuses[i],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) => _onFieldChanged(i, v),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF252540)
                          : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color:
                                const Color(0xFF0F52BA).withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white24
                              : Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF0F52BA), width: 2),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                );
              }),
            ),
          ),
          if (flow.errorAr != null) ...[
            const SizedBox(height: 12),
            Text(
              flow.errorAr!,
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          // Confirm
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: flow.isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F52BA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: flow.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('تأكيد',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),
          _ResendRow(isDark: isDark, session: widget.session),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () =>
                ref.read(paymentFlowProvider.notifier).cancel(),
            child: Text(
              'إلغاء',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.45)
                    : Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Resend row with countdown ─────────────────────────────────────────────────

class _ResendRow extends ConsumerStatefulWidget {
  final bool isDark;
  final PaymentSession session;

  const _ResendRow({required this.isDark, required this.session});

  @override
  ConsumerState<_ResendRow> createState() => _ResendRowState();
}

class _ResendRowState extends ConsumerState<_ResendRow> {
  static const _cooldownSeconds = 60;

  Timer? _timer;
  int _secondsLeft = _cooldownSeconds;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _cooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        if (mounted) setState(() => _secondsLeft = 0);
      } else {
        if (mounted) setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0 || _isSending) return;
    setState(() => _isSending = true);
    try {
      final provider = ref.read(paymentFlowProvider.notifier);
      await provider.resendOtp(widget.session.sessionId);
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _startCountdown();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isDark
        ? const Color(0xFF4DA6FF)
        : const Color(0xFF0F52BA);

    if (_isSending) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      );
    }

    if (_secondsLeft > 0) {
      return Text(
        'إعادة الإرسال بعد ${_secondsLeft}ث',
        style: TextStyle(
          color: color.withValues(alpha: 0.5),
          fontSize: 12,
        ),
      );
    }

    return TextButton(
      onPressed: _resend,
      child: Text(
        'إعادة إرسال الرمز',
        style: TextStyle(color: color, fontSize: 13),
      ),
    );
  }
}
