import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/quran/presentation/pages/quran_surahs_page.dart';
import 'package:charity_app/features/devotions/presentation/pages/devotional_section_loader_page.dart';
import 'package:charity_app/features/qibla/presentation/pages/qibla_page.dart';
import 'package:charity_app/features/istikhara/presentation/pages/istikhara_home_page.dart';

class IbadatPage extends StatelessWidget {
  const IbadatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = <_IbadahItem>[
      _IbadahItem('القرآن الكريم', 'تلاوة وحفظ', Icons.menu_book_rounded, const Color(0xFF0E7A5B),
          (_) => const QuranSurahsPage()),
      _IbadahItem('الأدعية', 'أدعية مأثورة', Icons.front_hand_rounded, const Color(0xFF7C3AED),
          (_) => const DevotionalSectionLoaderPage(
              namespace: 'duas', fallbackTitle: 'الأدعية', fallbackColor: Color(0xFF7C3AED))),
      _IbadahItem('الزيارات', 'زيارات مأثورة', Icons.mosque_rounded, const Color(0xFF06B6D4),
          (_) => const DevotionalSectionLoaderPage(
              namespace: 'ziyarat', fallbackTitle: 'الزيارات', fallbackColor: Color(0xFF06B6D4))),
      _IbadahItem('الأعمال', 'أعمال الأيام', Icons.auto_awesome_rounded, const Color(0xFFF59E0B),
          (_) => const DevotionalSectionLoaderPage(
              namespace: 'amal', fallbackTitle: 'الأعمال', fallbackColor: Color(0xFFF59E0B))),
      _IbadahItem('اتجاه القبلة', 'بوصلة القبلة', Icons.explore_rounded, const Color(0xFFEF4444),
          (_) => const QiblaPage()),
      _IbadahItem('الاستخارة', 'بالقرآن والسبحة', Icons.auto_awesome_rounded, const Color(0xFF6366F1),
          (_) => const IstikharaHomePage()),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _Header(isDark: isDark),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.80,
          children: items
              .map((it) => _IbadahCard(
                    item: it,
                    isDark: isDark,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: it.builder),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _IbadahItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
  const _IbadahItem(this.title, this.subtitle, this.icon, this.color, this.builder);
}

// ── Header ─────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final bool isDark;
  const _Header({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E7A5B), Color(0xFF065F46)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF0E7A5B).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.mosque_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('العبادات',
                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 3),
                Text('زادك الروحي في مكان واحد',
                    style: GoogleFonts.cairo(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ibadah Card ─────────────────────────────────────────────────────────────────
class _IbadahCard extends StatelessWidget {
  final _IbadahItem item;
  final bool isDark;
  final VoidCallback onTap;
  const _IbadahCard({required this.item, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 58, height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [item.color, item.color.withValues(alpha: 0.72)]),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: item.color.withValues(alpha: 0.32), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Icon(item.icon, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Text(
                  item.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  item.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 10.5,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
