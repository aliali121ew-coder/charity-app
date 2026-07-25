import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_flip/page_flip.dart';
import 'package:charity_app/features/devotions/domain/devotional_models.dart';
import 'package:charity_app/features/devotions/presentation/providers/devotional_favorites_provider.dart';
import 'package:charity_app/features/devotions/presentation/providers/devotional_progress_provider.dart';
import 'package:charity_app/features/reading/domain/reading_preferences.dart';
import 'package:charity_app/features/reading/presentation/providers/reading_preferences_provider.dart';
import 'package:charity_app/features/reading/presentation/widgets/reading_settings_sheet.dart';

/// شاشة عامة لعرض نص ديني كامل، مع تخصيص كامل لتجربة القراءة:
/// تكبير/تصغير الخط، اختيار نوع الخط، تغيير الخلفية، والتبديل بين
/// التمرير وقلب الصفحات كورقة حقيقية، إضافةً للنسخ والتفضيل.
class DevotionalReaderPage extends ConsumerWidget {
  final DevotionalSection section;
  final DevotionalItem item;
  const DevotionalReaderPage({super.key, required this.section, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(readingPreferencesProvider);
    final bg = prefs.background;
    final color = section.color;
    final isFavorite =
        ref.watch(devotionalFavoritesProvider)[section.namespace]?.contains(item.id) ?? false;

    return Scaffold(
      backgroundColor: bg.pageColor,
      appBar: AppBar(
        backgroundColor: bg.pageColor,
        foregroundColor: bg.textColor,
        elevation: 0,
        iconTheme: IconThemeData(color: bg.textColor),
        title: Text(item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 15, color: bg.textColor)),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'إعدادات القراءة',
            onPressed: () => ReadingSettingsSheet.show(context, accent: color),
            icon: const Icon(Icons.tune_rounded),
          ),
          IconButton(
            tooltip: 'نسخ النص',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: item.body));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('تم نسخ النص', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                behavior: SnackBarBehavior.floating,
                backgroundColor: color,
              ));
            },
            icon: const Icon(Icons.copy_rounded),
          ),
          IconButton(
            onPressed: () =>
                ref.read(devotionalFavoritesProvider.notifier).toggle(section.namespace, item.id),
            icon: Icon(isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                color: isFavorite ? const Color(0xFFF59E0B) : bg.textColor),
          ),
        ],
      ),
      body: prefs.mode == ReadingMode.flip
          ? _FlipReader(section: section, item: item, prefs: prefs)
          : _ScrollReader(section: section, item: item, prefs: prefs),
    );
  }
}

/// عنوان المناسبة فوق النص (يُستخدم في الوضعين).
class _OccasionBanner extends StatelessWidget {
  final String occasion;
  final Color accent;
  final ReadingBackground bg;
  const _OccasionBanner({required this.occasion, required this.accent, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: bg.isDark ? 0.22 : 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: bg.isDark ? bg.textColor : accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(occasion,
                style: GoogleFonts.cairo(
                    fontSize: 12, fontWeight: FontWeight.w700, color: bg.isDark ? bg.textColor : accent)),
          ),
        ],
      ),
    );
  }
}

String _cleanBody(String body) {
  return body
      .replaceAll('\r\n', '\n')
      .split('\n\n')
      .map((paragraph) => paragraph.replaceAll('\n', ' ').trim().replaceAll(RegExp(r'\s+'), ' '))
      .join('\n\n');
}

// ── وضع التمرير ──────────────────────────────────────────────────────────────
class _ScrollReader extends StatelessWidget {
  final DevotionalSection section;
  final DevotionalItem item;
  final ReadingPreferences prefs;
  const _ScrollReader({required this.section, required this.item, required this.prefs});

  @override
  Widget build(BuildContext context) {
    final bg = prefs.background;
    final cleanedBody = _cleanBody(item.body);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      children: [
        if (item.occasion != null)
          _OccasionBanner(occasion: item.occasion!, accent: section.color, bg: bg),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bg.isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: bg.borderColor),
          ),
          child: Text(
            cleanedBody,
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
            style: prefs.bodyStyle(),
          ),
        ),
        if (item.isExcerpt) ...[
          const SizedBox(height: 12),
          Text('* هذا مقتطف من النص؛ سيُستكمل النص الكامل لاحقاً.',
              style: GoogleFonts.cairo(fontSize: 11, color: bg.secondaryTextColor)),
        ],
      ],
    );
  }
}

// ── وضع قلب الصفحات ───────────────────────────────────────────────────────────
/// يقسّم النص إلى صفحات عند حدود الأسطر (دون قطع سطر)، وكل صفحة تعرض نصّها فقط —
/// تخطيط واحد ثم تقطيع حرفي، فالأداء جيّد حتى للنصوص الطويلة جداً (كالجوشن).
class _FlipReader extends ConsumerStatefulWidget {
  final DevotionalSection section;
  final DevotionalItem item;
  final ReadingPreferences prefs;
  const _FlipReader({required this.section, required this.item, required this.prefs});

  @override
  ConsumerState<_FlipReader> createState() => _FlipReaderState();
}

class _FlipReaderState extends ConsumerState<_FlipReader> {
  bool _announced = false;

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final item = widget.item;
    final prefs = widget.prefs;
    final bg = prefs.background;
    final textScaler = MediaQuery.textScalerOf(context);
    final style = prefs.bodyStyle();
    final cleanedBody = _cleanBody(item.body);

    return Column(
      children: [
        if (item.occasion != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: _OccasionBanner(occasion: item.occasion!, accent: section.color, bg: bg),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const pad = 22.0;
              const footer = 22.0;
              const gap = 6.0;
              final pageWidth = constraints.maxWidth - pad * 2;
              final pageHeight = constraints.maxHeight - pad * 2 - footer - gap;
              if (pageWidth <= 0 || pageHeight <= 0) return const SizedBox.shrink();

              final painter = TextPainter(
                text: TextSpan(text: cleanedBody, style: style),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.justify,
                textScaler: textScaler,
              )..layout(maxWidth: pageWidth);

              // قمم الصفحات عند حدود الأسطر مع هامش أمان كي لا تُقصّ ذيول الحروف.
              final metrics = painter.computeLineMetrics();
              final pageStartLines = <int>[0];
              double pageTop = 0;
              double y = 0;
              final usableHeight = pageHeight - 4.0;

              for (int i = 0; i < metrics.length; i++) {
                final m = metrics[i];
                final lineBottom = y + m.height;
                if (lineBottom - pageTop > usableHeight && i > pageStartLines.last) {
                  pageStartLines.add(i);
                  pageTop = y;
                }
                y = lineBottom;
              }

              final total = cleanedBody.length;
              final pageStart = <int>[0];
              for (int i = 1; i < pageStartLines.length; i++) {
                final lineIndex = pageStartLines[i];
                double lineY = 0;
                for (int j = 0; j < lineIndex; j++) {
                  lineY += metrics[j].height;
                }
                final lineCenterY = lineY + metrics[lineIndex].height / 2;

                final pos = painter.getPositionForOffset(Offset(pageWidth / 2, lineCenterY));
                final range = painter.getLineBoundary(pos);
                final startOffset = range.start.clamp(pageStart.last, total);
                pageStart.add(startOffset > pageStart.last ? startOffset : pageStart.last);
              }

              final pages = <Widget>[
                for (var i = 0; i < pageStart.length; i++)
                  _FlipPage(
                    text: cleanedBody.substring(
                      pageStart[i],
                      i + 1 < pageStart.length ? pageStart[i + 1] : total,
                    ),
                    style: style,
                    textScaler: textScaler,
                    bg: bg,
                    pageNumber: i + 1,
                    totalPages: pageStart.length,
                    pad: pad,
                    footer: footer,
                    gap: gap,
                  ),
              ];

              // استئناف من آخر صفحة محفوظة (مع تنبيه القارئ) وحفظ التقدّم.
              final savedPage = ref.read(devotionalProgressProvider)[item.id] ?? 0;
              final initialPage = savedPage.clamp(0, pages.length - 1);
              if (!_announced && initialPage > 0) {
                _announced = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('تابعتَ القراءة من صفحة ${initialPage + 1}',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: section.color,
                    duration: const Duration(seconds: 2),
                  ));
                });
              }

              return PageFlipWidget(
                key: ValueKey('${item.id}_${prefs.font.key}_${prefs.fontSize}_${bg.key}'),
                backgroundColor: bg.pageColor,
                isRightSwipe: true, // اتجاه عربي: السحب من اليمين
                initialIndex: initialPage,
                onPageFlipped: (p) =>
                    ref.read(devotionalProgressProvider.notifier).setPage(item.id, p),
                children: pages,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FlipPage extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextScaler textScaler;
  final ReadingBackground bg;
  final int pageNumber;
  final int totalPages;
  final double pad;
  final double footer;
  final double gap;
  const _FlipPage({
    required this.text,
    required this.style,
    required this.textScaler,
    required this.bg,
    required this.pageNumber,
    required this.totalPages,
    required this.pad,
    required this.footer,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg.pageColor,
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  text,
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                  textScaler: textScaler,
                  style: style,
                ),
              ),
            ),
          ),
          SizedBox(height: gap),
          SizedBox(
            height: footer,
            child: Center(
              child: Text(
                '$pageNumber / $totalPages',
                style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: bg.secondaryTextColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
