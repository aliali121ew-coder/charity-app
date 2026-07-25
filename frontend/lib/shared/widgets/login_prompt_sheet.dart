import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/core/router/app_router.dart';

/// Show this sheet when a guest user tries a protected action.
/// Usage:
///   LoginPromptSheet.show(context, reason: 'للتبرع يجب تسجيل الدخول');
class LoginPromptSheet extends StatelessWidget {
  final String? reason;

  const LoginPromptSheet({super.key, this.reason});

  static Future<void> show(
    BuildContext context, {
    String? reason,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LoginPromptSheet(reason: reason),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        color: isDark ? AppColors.cardDark : Colors.white,
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, 20 + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3D33A8), Color(0xFF5B4FCF)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.lock_person_rounded,
                  color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),

            Text(
              'تسجيل الدخول مطلوب',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color:
                    isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              reason ??
                  'هذه الميزة متاحة للمستخدمين المسجلين فقط.\nسجّل الدخول أو أنشئ حساباً مجاناً.',
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: Colors.grey,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Login button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3D33A8), Color(0xFF5B4FCF)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.authEmail);
                  },
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'تسجيل الدخول',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Register button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('${AppRoutes.authEmail}?tab=register');
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'إنشاء حساب جديد',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Dismiss
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'متابعة كزائر',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
