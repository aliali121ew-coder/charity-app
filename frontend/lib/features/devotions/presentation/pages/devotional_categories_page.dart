import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/devotions/domain/devotional_models.dart';
import 'package:charity_app/features/devotions/presentation/pages/devotional_items_page.dart';

/// شاشة عامة تعرض تصنيفات قسم ديني كامل (الأدعية / الزيارات / الأعمال).
/// يُغذّى المحتوى بالكامل من [DevotionalSection] فلا حاجة لتكرار هذا الكود
/// لكل قسم — أي تعديل تصميمي هنا ينعكس على الأقسام الثلاثة دفعة واحدة.
class DevotionalCategoriesPage extends StatelessWidget {
  final DevotionalSection section;
  const DevotionalCategoriesPage({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(section.title, style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _SectionHero(section: section),
          const SizedBox(height: 18),
          ...section.categories.map((c) => _CategoryTile(
                category: c,
                color: section.color,
                isDark: isDark,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => DevotionalItemsPage(section: section, category: c),
                )),
              )),
        ],
      ),
    );
  }
}

class _SectionHero extends StatelessWidget {
  final DevotionalSection section;
  const _SectionHero({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [section.color, section.color.withValues(alpha: 0.72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: section.color.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Icon(section.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(section.title,
                    style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 3),
                Text(section.tagline,
                    style: GoogleFonts.cairo(fontSize: 11, color: Colors.white.withValues(alpha: 0.85))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Text('${section.totalItems}',
                    style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                Text('نص', style: GoogleFonts.cairo(fontSize: 8.5, color: Colors.white.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final DevotionalCategory category;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  const _CategoryTile({required this.category, required this.color, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
                  child: Icon(category.icon, color: color, size: 24),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.title,
                          style: GoogleFonts.cairo(fontSize: 14.5, fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                      const SizedBox(height: 2),
                      Text(category.subtitle,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(fontSize: 11,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text('${category.items.length}',
                      style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w800, color: color)),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_left_rounded, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
