import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/shared/providers/app_providers.dart';
import 'package:charity_app/core/router/app_router.dart';

class VerifyEmailPage extends ConsumerStatefulWidget {
  final String email;
  const VerifyEmailPage({super.key, required this.email});

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage>
    with WidgetsBindingObserver {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  String? _errorMsg;
  int _resendCountdown = 60;
  Timer? _timer;
  DateTime? _endTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCountdown();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _endTime != null) {
      final remaining = _endTime!.difference(DateTime.now()).inSeconds;
      if (!mounted) return;
      setState(() => _resendCountdown = remaining.clamp(0, 60));
      if (_resendCountdown <= 0) _timer?.cancel();
    }
  }

  void _startCountdown() {
    _endTime = DateTime.now().add(const Duration(seconds: 60));
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      final remaining = _endTime!.difference(DateTime.now()).inSeconds;
      setState(() {
        _resendCountdown = remaining.clamp(0, 60);
        if (_resendCountdown <= 0) t.cancel();
      });
    });
  }

  String get _code =>
      _controllers.map((c) => c.text).join();

  Future<void> _submit() async {
    final code = _code;
    if (code.length < 6) {
      setState(() => _errorMsg = 'أدخل الرمز المكون من 6 أرقام');
      return;
    }
    setState(() { _isLoading = true; _errorMsg = null; });

    final error = await ref.read(authProvider.notifier).verifyEmail(
          email: widget.email,
          code: code,
        );

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _isLoading = false;
        _errorMsg = error == 'invalid_code'
            ? 'الرمز غير صحيح أو انتهت صلاحيته'
            : 'حدث خطأ، حاول مرة أخرى';
        // Clear inputs on wrong code
        for (final c in _controllers) c.clear();
      });
      _focusNodes[0].requestFocus();
    }
    // On success the router redirect handles navigation
  }

  Future<void> _resend() async {
    if (_resendCountdown > 0) return;
    final error = await ref.read(authProvider.notifier).resendVerification(widget.email);
    if (!mounted) return;
    if (error == null) {
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال رمز جديد')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white70 : Colors.black54),
          onPressed: () {
            // Go back to login
            ref.read(authProvider.notifier).logout();
            context.go(AppRoutes.login);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF3D2B8E)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: const Icon(Icons.mark_email_read_rounded,
                    color: Colors.white, size: 38),
              ),
              const SizedBox(height: 28),
              Text(
                'تحقق من بريدك الإلكتروني',
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'أرسلنا رمز تحقق مكون من 6 أرقام إلى\n${widget.email}',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black54,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Debug: show OTP code if server returned it (dev mode only)
              Builder(builder: (ctx) {
                final debugCode = ref.watch(
                    authProvider.select((s) => s.debugVerificationCode));
                if (debugCode == null) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bug_report_rounded,
                          color: Colors.amber, size: 18),
                      const SizedBox(width: 8),
                      Text('رمز التجربة: ',
                          style: GoogleFonts.cairo(
                              fontSize: 13, color: Colors.amber)),
                      Text(debugCode,
                          style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.amber,
                              letterSpacing: 4)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              // OTP inputs
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (i) => _OtpBox(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    isDark: isDark,
                    onChanged: (val) {
                      if (val.isNotEmpty && i < 5) {
                        _focusNodes[i + 1].requestFocus();
                      }
                      if (val.isEmpty && i > 0) {
                        _focusNodes[i - 1].requestFocus();
                      }
                      if (_code.length == 6) _submit();
                    },
                  )),
                ),
              ),
              const SizedBox(height: 16),
              if (_errorMsg != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMsg!,
                            style: GoogleFonts.cairo(
                                fontSize: 13, color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 28),
              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Text('تحقق',
                          style: GoogleFonts.cairo(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 24),
              // Resend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('لم تستلم الرمز؟ ',
                      style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.black54)),
                  GestureDetector(
                    onTap: _resendCountdown == 0 ? _resend : null,
                    child: Text(
                      _resendCountdown > 0
                          ? 'إعادة الإرسال ($_resendCountdown ث)'
                          : 'إعادة الإرسال',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _resendCountdown == 0
                            ? const Color(0xFF6C63FF)
                            : (isDark ? Colors.white38 : Colors.black38),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.cairo(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: Color(0xFF6C63FF), width: 2),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
