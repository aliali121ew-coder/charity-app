import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/core/router/app_router.dart';
import 'package:charity_app/shared/providers/app_providers.dart';

class EmailAuthPage extends ConsumerStatefulWidget {
  final String initialTab;
  const EmailAuthPage({super.key, this.initialTab = 'login'});

  @override
  ConsumerState<EmailAuthPage> createState() => _EmailAuthPageState();
}

class _EmailAuthPageState extends ConsumerState<EmailAuthPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Login
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  final _loginFormKey = GlobalKey<FormState>();
  bool _obscureLogin = true;

  // Register
  final _regEmailCtrl = TextEditingController();
  final _regPhoneCtrl = TextEditingController();
  final _regUsernameCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regConfirmCtrl = TextEditingController();
  final _regFormKey = GlobalKey<FormState>();
  bool _obscureReg = true;
  bool _obscureConfirm = true;
  double _passStrength = 0;

  @override
  void initState() {
    super.initState();
    final startIndex = widget.initialTab == 'register' ? 1 : 0;
    _tabCtrl = TabController(length: 2, vsync: this, initialIndex: startIndex);
    _regPassCtrl.addListener(_updateStrength);
  }

  void _updateStrength() {
    final p = _regPassCtrl.text;
    double s = 0;
    if (p.length >= 8) s += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(p)) s += 0.25;
    if (RegExp(r'[0-9]').hasMatch(p)) s += 0.25;
    if (RegExp(r'[!@#\$%^&*()_+\-=]').hasMatch(p)) s += 0.25;
    setState(() => _passStrength = s);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPhoneCtrl.dispose();
    _regUsernameCtrl.dispose();
    _regPassCtrl.dispose();
    _regConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).login(
          _loginEmailCtrl.text.trim(),
          _loginPassCtrl.text,
        );
    if (!success && mounted) {
      _showError('بيانات الدخول غير صحيحة');
    }
  }

  Future<void> _handleRegister() async {
    if (!_regFormKey.currentState!.validate()) return;
    final error = await ref.read(authProvider.notifier).register(
          email: _regEmailCtrl.text.trim(),
          phone: _regPhoneCtrl.text.trim(),
          username: _regUsernameCtrl.text.trim(),
          password: _regPassCtrl.text,
        );
    if (error != null && mounted) {
      _showError(error == 'server_error'
          ? 'حدث خطأ في الخادم، حاول مجدداً'
          : error);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF1F5F9),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 170,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3D33A8), Color(0xFF5B4FCF)],
                    ),
                  ),
                ),
                Positioned(
                  right: -40,
                  top: -40,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Positioned(
                  left: -20,
                  bottom: 50,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 52,
                  left: 20,
                  right: 20,
                  child: Row(children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.volunteer_activism_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'الدخول بالبريد الإلكتروني',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(46),
              child: Container(
                color:
                    isDark ? const Color(0xFF111827) : Colors.white,
                child: TabBar(
                  controller: _tabCtrl,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: GoogleFonts.cairo(
                      fontSize: 14, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.cairo(fontSize: 14),
                  tabs: const [
                    Tab(text: 'تسجيل الدخول'),
                    Tab(text: 'حساب جديد'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _LoginTab(
              formKey: _loginFormKey,
              emailCtrl: _loginEmailCtrl,
              passCtrl: _loginPassCtrl,
              obscure: _obscureLogin,
              onToggleObscure: () =>
                  setState(() => _obscureLogin = !_obscureLogin),
              onSubmit: _handleLogin,
              isLoading: authState.isLoading,
              isDark: isDark,
            ),
            _RegisterTab(
              formKey: _regFormKey,
              emailCtrl: _regEmailCtrl,
              phoneCtrl: _regPhoneCtrl,
              usernameCtrl: _regUsernameCtrl,
              passCtrl: _regPassCtrl,
              confirmCtrl: _regConfirmCtrl,
              obscurePass: _obscureReg,
              obscureConfirm: _obscureConfirm,
              onTogglePass: () => setState(() => _obscureReg = !_obscureReg),
              onToggleConfirm: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              passStrength: _passStrength,
              onSubmit: _handleRegister,
              isLoading: authState.isLoading,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Login Tab ─────────────────────────────────────────────────────────────────
class _LoginTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final bool isLoading;
  final bool isDark;

  const _LoginTab({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.isLoading,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 24, 20, 20 + MediaQuery.of(context).padding.bottom),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AuthField(
              controller: emailCtrl,
              label: 'البريد الإلكتروني أو اسم المستخدم',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              isDark: isDark,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'هذا الحقل مطلوب' : null,
            ),
            const SizedBox(height: 14),
            _AuthField(
              controller: passCtrl,
              label: 'كلمة المرور',
              icon: Icons.lock_outline_rounded,
              isDark: isDark,
              obscure: obscure,
              suffix: IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: Colors.grey,
                ),
                onPressed: onToggleObscure,
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'هذا الحقل مطلوب' : null,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => context.push(AppRoutes.authForgot),
                child: Text(
                  'نسيت كلمة المرور؟',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _SubmitButton(
              label: 'تسجيل الدخول',
              isLoading: isLoading,
              onTap: onSubmit,
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () => context.push(
                    '${AppRoutes.authEmail}?tab=register'),
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: isDark
                            ? Colors.grey[400]
                            : Colors.grey[600]),
                    children: [
                      const TextSpan(text: 'ليس لديك حساب؟ '),
                      TextSpan(
                        text: 'أنشئ حساباً الآن',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Register Tab ──────────────────────────────────────────────────────────────
class _RegisterTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController usernameCtrl;
  final TextEditingController passCtrl;
  final TextEditingController confirmCtrl;
  final bool obscurePass;
  final bool obscureConfirm;
  final VoidCallback onTogglePass;
  final VoidCallback onToggleConfirm;
  final double passStrength;
  final VoidCallback onSubmit;
  final bool isLoading;
  final bool isDark;

  const _RegisterTab({
    required this.formKey,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.usernameCtrl,
    required this.passCtrl,
    required this.confirmCtrl,
    required this.obscurePass,
    required this.obscureConfirm,
    required this.onTogglePass,
    required this.onToggleConfirm,
    required this.passStrength,
    required this.onSubmit,
    required this.isLoading,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 24, 20, 20 + MediaQuery.of(context).padding.bottom),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            _AuthField(
              controller: emailCtrl,
              label: 'البريد الإلكتروني',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              isDark: isDark,
              validator: (v) {
                if (v == null || v.isEmpty) return 'هذا الحقل مطلوب';
                if (!v.contains('@')) return 'بريد إلكتروني غير صحيح';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _AuthField(
              controller: phoneCtrl,
              label: 'رقم الهاتف',
              hint: 'للاسترداد في حالة نسيان كلمة المرور',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              isDark: isDark,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'هذا الحقل مطلوب' : null,
            ),
            const SizedBox(height: 14),
            _AuthField(
              controller: usernameCtrl,
              label: 'اسم المستخدم',
              hint: 'فريد — سيظهر للآخرين',
              icon: Icons.person_outline_rounded,
              isDark: isDark,
              validator: (v) {
                if (v == null || v.isEmpty) return 'هذا الحقل مطلوب';
                if (v.length < 3) return 'على الأقل 3 أحرف';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _AuthField(
              controller: passCtrl,
              label: 'كلمة المرور',
              icon: Icons.lock_outline_rounded,
              isDark: isDark,
              obscure: obscurePass,
              suffix: IconButton(
                icon: Icon(
                  obscurePass
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: Colors.grey,
                ),
                onPressed: onTogglePass,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'هذا الحقل مطلوب';
                if (v.length < 8) return 'على الأقل 8 أحرف';
                return null;
              },
            ),
            const SizedBox(height: 8),
            _PasswordStrengthBar(strength: passStrength),
            const SizedBox(height: 14),
            _AuthField(
              controller: confirmCtrl,
              label: 'تأكيد كلمة المرور',
              icon: Icons.lock_outline_rounded,
              isDark: isDark,
              obscure: obscureConfirm,
              suffix: IconButton(
                icon: Icon(
                  obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: Colors.grey,
                ),
                onPressed: onToggleConfirm,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'هذا الحقل مطلوب';
                if (v != passCtrl.text) return 'كلمتا المرور غير متطابقتين';
                return null;
              },
            ),
            const SizedBox(height: 24),
            _SubmitButton(
              label: 'إنشاء الحساب',
              isLoading: isLoading,
              onTap: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final bool isDark;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDark,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textDirection: TextDirection.rtl,
      validator: validator,
      style: GoogleFonts.cairo(
        fontSize: 14,
        color: isDark ? Colors.white : const Color(0xFF1F2937),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
        suffixIcon: suffix,
        labelStyle: GoogleFonts.cairo(
          fontSize: 13,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        hintStyle: GoogleFonts.cairo(
          fontSize: 12,
          color: isDark ? Colors.grey[600] : Colors.grey[400],
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
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
          borderSide:
              BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  final double strength;
  const _PasswordStrengthBar({required this.strength});

  @override
  Widget build(BuildContext context) {
    final Color color = switch (strength) {
      <= 0.25 => const Color(0xFFEF4444),
      <= 0.50 => const Color(0xFFF59E0B),
      <= 0.75 => const Color(0xFF3B82F6),
      _ => const Color(0xFF10B981),
    };
    final String label = switch (strength) {
      <= 0.0 => '',
      <= 0.25 => 'ضعيفة جداً',
      <= 0.50 => 'ضعيفة',
      <= 0.75 => 'متوسطة',
      _ => 'قوية ✓',
    };

    if (strength == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: strength,
            minHeight: 5,
            backgroundColor: Colors.grey.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'قوة كلمة المرور: $label',
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const _SubmitButton({
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
            colors: [Color(0xFF3D33A8), Color(0xFF5B4FCF)],
          ),
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
