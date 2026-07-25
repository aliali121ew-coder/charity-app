import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/devotions/data/devotional_repository.dart';
import 'package:charity_app/features/devotions/presentation/pages/devotional_categories_page.dart';

/// يحمّل قسماً دينياً من JSON ثم يعرض شاشة التصنيفات العامة عند الجاهزية.
/// هذا الغلاف يفصل تحميل البيانات عن واجهة العرض القابلة لإعادة الاستخدام.
class DevotionalSectionLoaderPage extends ConsumerWidget {
  final String namespace;
  final String fallbackTitle;
  final Color fallbackColor;

  const DevotionalSectionLoaderPage({
    super.key,
    required this.namespace,
    required this.fallbackTitle,
    required this.fallbackColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final async = ref.watch(devotionalSectionProvider(namespace));

    return async.when(
      data: (section) => DevotionalCategoriesPage(section: section),
      loading: () => Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(
          title: Text(fallbackTitle, style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
          centerTitle: true,
        ),
        body: Center(child: CircularProgressIndicator(color: fallbackColor)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(
          title: Text(fallbackTitle, style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 54, color: fallbackColor),
                const SizedBox(height: 14),
                Text('تعذّر تحميل المحتوى',
                    style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                const SizedBox(height: 6),
                Text('تأكّد من وجود ملف البيانات الصحيح.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
