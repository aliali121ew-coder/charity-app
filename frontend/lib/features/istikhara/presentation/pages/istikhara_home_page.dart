import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/istikhara/domain/istikhara_models.dart';
import 'package:charity_app/features/istikhara/presentation/pages/istikhara_adab_page.dart';
import 'package:charity_app/features/istikhara/presentation/pages/istikhara_history_page.dart';
import 'package:charity_app/features/istikhara/presentation/widgets/istikhara_shared.dart';

/// شاشة الاستخارة: يختار المستخدم نوع الاستخارة (بالقرآن أو السبحة)،
/// أو يفتح سجلّ استخاراته المحفوظة.
class IstikharaHomePage extends StatelessWidget {
  const IstikharaHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('الاستخارة', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'سجلّ الاستخارات',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const IstikharaHistoryPage()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const _Hero(),
          const SizedBox(height: 18),
          Text('اختر نوع الاستخارة',
              style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
          const SizedBox(height: 12),
          _MethodCard(
            isDark: isDark,
            icon: Icons.menu_book_rounded,
            color: const Color(0xFF0E7A5B),
            title: 'استخارة بالقرآن',
            subtitle: 'فتح المصحف واستخراج آية مع تقييمها وشرحها',
            onTap: () => _open(context, IstikharaMethod.quran),
          ),
          const SizedBox(height: 12),
          _MethodCard(
            isDark: isDark,
            icon: Icons.blur_circular_rounded,
            color: const Color(0xFFB45309),
            title: 'استخارة السبحة',
            subtitle: 'على طريقة الإمام المهدي (عج) — قبض الخرز والعدّ',
            onTap: () => _open(context, IstikharaMethod.tasbih),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, IstikharaMethod method) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => IstikharaAdabPage(method: method)),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [istikharaAccent, Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: istikharaAccent.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('استخارة أهل البيت عليهم السلام',
                    style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 4),
                Text('عند التحيّر، فوّض أمرك لله واطلب خيرته بأدبٍ وطمأنينة',
                    style: GoogleFonts.cairo(
                        fontSize: 11.5, height: 1.5, color: Colors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _MethodCard({
    required this.isDark,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.72)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 9, offset: const Offset(0, 4))],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.cairo(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            height: 1.4,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                  ],
                ),
              ),
              Icon(Icons.chevron_left_rounded, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
            ],
          ),
        ),
      ),
    );
  }
}
