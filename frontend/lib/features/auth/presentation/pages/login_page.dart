import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/core/router/app_router.dart';
import 'package:charity_app/shared/providers/app_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

// Google Sign-In instance — serverClientId is the Web OAuth 2.0 Client ID
// from Google Cloud Console → APIs & Services → Credentials
final _googleSignIn = GoogleSignIn(
  serverClientId: const String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '', // Set via --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com
  ),
  scopes: ['email', 'profile'],
);

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin {
  late AnimationController _orbCtrl;
  late AnimationController _entryCtrl;
  late Animation<double> _orbAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _googleLoading = false;

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _orbAnim = CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut);
    _fadeAnim =
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleGuestAccess() async {
    await ref.read(authProvider.notifier).loginAsGuest();
  }

  Future<void> _handleGoogleSignIn() async {
    if (_googleLoading) return;

    // Detect unconfigured Google Sign-In (GOOGLE_WEB_CLIENT_ID not set)
    const clientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');
    if (clientId.isEmpty) {
      _showError('تسجيل الدخول عبر Google غير مُفعَّل بعد — استخدم البريد الإلكتروني');
      return;
    }

    setState(() => _googleLoading = true);
    try {
      // Sign out first so account picker always shows
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      if (account == null || !mounted) {
        setState(() => _googleLoading = false);
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        if (mounted) _showError('تعذّر الحصول على رمز Google — تأكد من ضبط GOOGLE_WEB_CLIENT_ID');
        setState(() => _googleLoading = false);
        return;
      }

      final success =
          await ref.read(authProvider.notifier).loginWithGoogle(idToken);

      if (!success && mounted) {
        _showError('فشل تسجيل الدخول عبر Google');
      }
    } on Exception catch (e) {
      if (mounted) {
        final msg = e.toString();
        if (msg.contains('network_error')) {
          _showError('خطأ في الشبكة — تحقق من اتصالك بالإنترنت');
        } else if (msg.contains('sign_in_cancelled')) {
          // User cancelled — no error needed
        } else {
          _showError('فشل تسجيل الدخول عبر Google: $msg');
        }
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient background ───────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A0F3C),
                  Color(0xFF3D33A8),
                  Color(0xFF5B4FCF),
                ],
              ),
            ),
          ),

          // ── Floating orbs (3D illusion) ───────────────────────────────────
          AnimatedBuilder(
            animation: _orbAnim,
            builder: (_, __) => Stack(
              children: [
                _Orb(
                  x: -70 + (_orbAnim.value * 25),
                  y: size.height * 0.08 + (_orbAnim.value * 40),
                  size: 260,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                _Orb(
                  x: size.width - 80 + (_orbAnim.value * -20),
                  y: size.height * 0.38 + (_orbAnim.value * 30),
                  size: 180,
                  color: const Color(0xFF7C6FE0).withValues(alpha: 0.25),
                ),
                _Orb(
                  x: size.width * 0.25 + (_orbAnim.value * 15),
                  y: size.height * 0.70 + (_orbAnim.value * -30),
                  size: 140,
                  color: Colors.blue.withValues(alpha: 0.12),
                ),
                _Orb(
                  x: size.width * 0.55,
                  y: size.height * 0.15 + (_orbAnim.value * -20),
                  size: 90,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ],
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        children: [
                          SizedBox(height: size.height * 0.08),

                          // Logo
                          Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 30,
                                  offset: const Offset(0, 12),
                                ),
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  blurRadius: 1,
                                  offset: const Offset(0, -1),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.volunteer_activism_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            'أهلاً بك',
                            style: GoogleFonts.cairo(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'معاً نصنع الفرق — انضم إلى مجتمعنا الخيري',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.72),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: size.height * 0.07),

                          // ── Google button ─────────────────────────────────
                          _SocialButton(
                            onTap: _googleLoading ? null : _handleGoogleSignIn,
                            icon: Icons.g_mobiledata_rounded,
                            label: _googleLoading
                                ? 'جارٍ التحقق...'
                                : 'المتابعة عبر Google',
                            backgroundColor: Colors.white,
                            textColor: const Color(0xFF1F2937),
                            iconColor: const Color(0xFFEA4335),
                            isLoading: _googleLoading,
                          ),
                          const SizedBox(height: 12),

                          // ── Email button ──────────────────────────────────
                          _GradientButton(
                            onTap: () =>
                                context.push(AppRoutes.authEmail),
                            icon: Icons.email_rounded,
                            label: 'الدخول بالبريد الإلكتروني',
                          ),

                          const SizedBox(height: 28),

                          // Divider
                          Row(children: [
                            Expanded(
                              child: Divider(
                                color:
                                    Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                'أو',
                                style: GoogleFonts.cairo(
                                  color:
                                      Colors.white.withValues(alpha: 0.45),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color:
                                    Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                          ]),

                          const SizedBox(height: 20),

                          // ── Guest button ──────────────────────────────────
                          TextButton.icon(
                            onPressed: _handleGuestAccess,
                            icon: Icon(
                              Icons.visibility_outlined,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                            label: Text(
                              'متابعة كزائر (عرض محدود)',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color:
                                    Colors.white.withValues(alpha: 0.6),
                                decoration: TextDecoration.underline,
                                decorationColor:
                                    Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                          ),

                          // Register shortcut
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: () => context.push(
                                '${AppRoutes.authEmail}?tab=register'),
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  color:
                                      Colors.white.withValues(alpha: 0.55),
                                ),
                                children: [
                                  const TextSpan(text: 'ليس لديك حساب؟ '),
                                  TextSpan(
                                    text: 'أنشئ حساباً مجاناً',
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.white
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: size.height * 0.05),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Floating Orb ──────────────────────────────────────────────────────────────
class _Orb extends StatelessWidget {
  final double x;
  final double y;
  final double size;
  final Color color;

  const _Orb({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}

// ── Social Button (Google) ────────────────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final bool isLoading;

  const _SocialButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          shadowColor: Colors.black.withValues(alpha: 0.15),
        ).copyWith(
          elevation: const WidgetStatePropertyAll(4),
        ),
        icon: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor.withValues(alpha: 0.7),
                ),
              )
            : Icon(icon, color: iconColor, size: 24),
        label: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

// ── Gradient Button (Email) ───────────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;

  const _GradientButton({
    required this.onTap,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C6FE0), Color(0xFF5B4FCF)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: TextButton.icon(
          onPressed: onTap,
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          icon: Icon(icon, color: Colors.white, size: 18),
          label: Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
