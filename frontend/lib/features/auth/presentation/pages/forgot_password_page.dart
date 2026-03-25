import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/core/router/app_router.dart';
import 'package:charity_app/shared/providers/app_providers.dart';

enum _ResetMethod { email, phone }

enum _ResetStep { input, otp, newPassword, done }

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  _ResetMethod _method = _ResetMethod.email;
  _ResetStep _step = _ResetStep.input;

  final _inputCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());

  String get _collectedOtp =>
      _otpControllers.map((c) => c.text).join();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_inputCtrl.text.trim().isEmpty) return;
    final error = await ref
        .read(authProvider.notifier)
        .sendPasswordResetOtp(_inputCtrl.text.trim());
    if (!mounted) return;
    if (error != null) {
      _showError('تعذّر إرسال الرمز. تحقق من البيانات وحاول مجدداً.');
    } else {
      setState(() => _step = _ResetStep.otp);
    }
  }

  Future<void> _verifyAndReset() async {
    if (_newPassCtrl.text != _confirmCtrl.text) {
      _showError('كلمتا المرور غير متطابقتين');
      return;
    }
    if (_newPassCtrl.text.length < 8) {
      _showError('كلمة المرور يجب أن تكون 8 أحرف على الأقل');
      return;
    }
    final error = await ref.read(authProvider.notifier).resetPassword(
          emailOrPhone: _inputCtrl.text.trim(),
          otp: _collectedOtp,
          newPassword: _newPassCtrl.text,
        );
    if (!mounted) return;
    if (error != null) {
      _showError('رمز التحقق غير صحيح أو منتهي الصلاحية');
    } else {
      setState(() => _step = _ResetStep.done);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.cairo()),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _goBack() {
    if (_step == _ResetStep.input) {
      context.pop();
    } else {
      setState(() => _step = _ResetStep.values[_step.index - 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
            size: 20,
          ),
          onPressed: _goBack,
        ),
        title: Text(
          'استعادة كلمة المرور',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, 20 + MediaQuery.of(context).padding.bottom),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) {
              final slide = Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic));
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: switch (_step) {
              _ResetStep.input =>
                _InputStep(
                  key: const ValueKey('input'),
                  method: _method,
                  controller: _inputCtrl,
                  isDark: isDark,
                  isLoading: isLoading,
                  onMethodChanged: (m) => setState(() => _method = m),
                  onSubmit: _sendOtp,
                ),
              _ResetStep.otp =>
                _OtpStep(
                  key: const ValueKey('otp'),
                  target: _inputCtrl.text.trim(),
                  controllers: _otpControllers,
                  focusNodes: _otpFocusNodes,
                  isDark: isDark,
                  isLoading: isLoading,
                  onSubmit: () => setState(() => _step = _ResetStep.newPassword),
                  onResend: _sendOtp,
                  debugOtp: ref.watch(authProvider.select((s) => s.debugVerificationCode)),
                ),
              _ResetStep.newPassword =>
                _NewPasswordStep(
                  key: const ValueKey('newpass'),
                  newPassCtrl: _newPassCtrl,
                  confirmCtrl: _confirmCtrl,
                  isDark: isDark,
                  isLoading: isLoading,
                  onSubmit: _verifyAndReset,
                ),
              _ResetStep.done =>
                _DoneStep(
                  key: const ValueKey('done'),
                  isDark: isDark,
                  onGoLogin: () => context.go(AppRoutes.login),
                ),
            },
          ),
        ),
      ),
    );
  }
}

// ── Step 1: Input ─────────────────────────────────────────────────────────────
class _InputStep extends StatelessWidget {
  final _ResetMethod method;
  final TextEditingController controller;
  final bool isDark;
  final bool isLoading;
  final ValueChanged<_ResetMethod> onMethodChanged;
  final VoidCallback onSubmit;

  const _InputStep({
    super.key,
    required this.method,
    required this.controller,
    required this.isDark,
    required this.isLoading,
    required this.onMethodChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StepHeader(
          icon: Icons.lock_reset_rounded,
          title: 'نسيت كلمة المرور؟',
          subtitle: 'اختر طريقة استلام رمز التحقق',
          isDark: isDark,
        ),
        const SizedBox(height: 28),
        SegmentedButton<_ResetMethod>(
          segments: [
            ButtonSegment(
              value: _ResetMethod.email,
              label: Text('بريد إلكتروني',
                  style: GoogleFonts.cairo(fontSize: 13)),
              icon: const Icon(Icons.email_outlined, size: 16),
            ),
            ButtonSegment(
              value: _ResetMethod.phone,
              label:
                  Text('رقم الهاتف', style: GoogleFonts.cairo(fontSize: 13)),
              icon: const Icon(Icons.phone_outlined, size: 16),
            ),
          ],
          selected: {method},
          onSelectionChanged: (s) => onMethodChanged(s.first),
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
                  ? Colors.white
                  : AppColors.primary,
            ),
            backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
                  ? AppColors.primary
                  : Colors.transparent,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _FpField(
          controller: controller,
          label: method == _ResetMethod.email
              ? 'البريد الإلكتروني'
              : 'رقم الهاتف',
          icon: method == _ResetMethod.email
              ? Icons.email_outlined
              : Icons.phone_outlined,
          keyboardType: method == _ResetMethod.email
              ? TextInputType.emailAddress
              : TextInputType.phone,
          isDark: isDark,
        ),
        const SizedBox(height: 24),
        _FpButton(
            label: 'إرسال رمز التحقق',
            isLoading: isLoading,
            onTap: onSubmit),
      ],
    );
  }
}

// ── Step 2: OTP ───────────────────────────────────────────────────────────────
class _OtpStep extends StatefulWidget {
  final String target;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool isDark;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onResend;
  final String? debugOtp;

  const _OtpStep({
    super.key,
    required this.target,
    required this.controllers,
    required this.focusNodes,
    required this.isDark,
    required this.isLoading,
    required this.onSubmit,
    required this.onResend,
    this.debugOtp,
  });

  @override
  State<_OtpStep> createState() => _OtpStepState();
}

class _OtpStepState extends State<_OtpStep> {
  int _seconds = 60;
  late final Stream<int> _ticker;

  String get _otp => widget.controllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _ticker = Stream.periodic(
      const Duration(seconds: 1),
      (i) => 59 - i,
    ).take(60);
    _ticker.listen((s) {
      if (mounted) setState(() => _seconds = s);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StepHeader(
          icon: Icons.sms_rounded,
          title: 'أدخل رمز التحقق',
          subtitle: 'تم إرسال رمز مكوّن من 6 أرقام إلى\n${widget.target}',
          isDark: widget.isDark,
        ),
        const SizedBox(height: 16),
        // Debug OTP display (shown when email fails or in dev mode)
        if (widget.debugOtp != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bug_report_rounded, color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                Text('رمز التجربة: ',
                    style: GoogleFonts.cairo(fontSize: 13, color: Colors.amber)),
                Text(widget.debugOtp!,
                    style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.amber,
                        letterSpacing: 4)),
              ],
            ),
          ),
        const SizedBox(height: 16),
        // 6 OTP boxes
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              return Container(
                width: 46,
                height: 56,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: TextFormField(
                  controller: widget.controllers[i],
                  focusNode: widget.focusNodes[i],
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color:
                        widget.isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: widget.isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: widget.isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty && i < 5) {
                      widget.focusNodes[i + 1].requestFocus();
                    } else if (v.isEmpty && i > 0) {
                      widget.focusNodes[i - 1].requestFocus();
                    }
                    // Auto-confirm on last digit
                    if (i == 5 && v.isNotEmpty) {
                      final allFilled = widget.controllers
                          .every((c) => c.text.isNotEmpty);
                      if (allFilled) widget.onSubmit();
                    }
                  },
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 24),
        if (_seconds > 0)
          Text(
            'إعادة الإرسال بعد $_seconds ثانية',
            style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
          )
        else
          TextButton(
            onPressed: widget.onResend,
            child: Text(
              'إعادة إرسال الرمز',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        const SizedBox(height: 20),
        _FpButton(
            label: 'تأكيد الرمز',
            isLoading: widget.isLoading,
            onTap: () {
              if (_otp.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('أدخل الرمز المكون من 6 أرقام',
                      style: GoogleFonts.cairo()),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
                return;
              }
              widget.onSubmit();
            }),
      ],
    );
  }
}

// ── Step 3: New Password ──────────────────────────────────────────────────────
class _NewPasswordStep extends StatefulWidget {
  final TextEditingController newPassCtrl;
  final TextEditingController confirmCtrl;
  final bool isDark;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _NewPasswordStep({
    super.key,
    required this.newPassCtrl,
    required this.confirmCtrl,
    required this.isDark,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  State<_NewPasswordStep> createState() => _NewPasswordStepState();
}

class _NewPasswordStepState extends State<_NewPasswordStep> {
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          icon: Icons.lock_open_rounded,
          title: 'كلمة مرور جديدة',
          subtitle: 'اختر كلمة مرور قوية لحماية حسابك',
          isDark: widget.isDark,
        ),
        const SizedBox(height: 28),
        _FpField(
          controller: widget.newPassCtrl,
          label: 'كلمة المرور الجديدة',
          icon: Icons.lock_outline_rounded,
          isDark: widget.isDark,
          obscure: _obscureNew,
          suffix: IconButton(
            icon: Icon(
              _obscureNew
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 18,
              color: Colors.grey,
            ),
            onPressed: () => setState(() => _obscureNew = !_obscureNew),
          ),
        ),
        const SizedBox(height: 14),
        _FpField(
          controller: widget.confirmCtrl,
          label: 'تأكيد كلمة المرور',
          icon: Icons.lock_outline_rounded,
          isDark: widget.isDark,
          obscure: _obscureConfirm,
          suffix: IconButton(
            icon: Icon(
              _obscureConfirm
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 18,
              color: Colors.grey,
            ),
            onPressed: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
        const SizedBox(height: 24),
        _FpButton(
            label: 'تعيين كلمة المرور',
            isLoading: widget.isLoading,
            onTap: widget.onSubmit),
      ],
    );
  }
}

// ── Step 4: Done ──────────────────────────────────────────────────────────────
class _DoneStep extends StatelessWidget {
  final bool isDark;
  final VoidCallback onGoLogin;

  const _DoneStep({super.key, required this.isDark, required this.onGoLogin});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 50),
        ),
        const SizedBox(height: 20),
        Text(
          'تم بنجاح!',
          style: GoogleFonts.cairo(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'تم تعيين كلمة مرورك الجديدة\nيمكنك الآن تسجيل الدخول',
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: Colors.grey,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
        _FpButton(label: 'تسجيل الدخول', onTap: onGoLogin),
      ],
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const _StepHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3D33A8), Color(0xFF5B4FCF)],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 34),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: Colors.grey,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _FpField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _FpField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDark,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textDirection: TextDirection.rtl,
      style: GoogleFonts.cairo(
        fontSize: 14,
        color: isDark ? Colors.white : const Color(0xFF1F2937),
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
        suffixIcon: suffix,
        labelStyle: GoogleFonts.cairo(
          fontSize: 13,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _FpButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const _FpButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF3D33A8), Color(0xFF5B4FCF)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: TextButton(
          onPressed: isLoading ? null : onTap,
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
