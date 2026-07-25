import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:page_flip/page_flip.dart';
import 'package:charity_app/features/quran/domain/quran_models.dart';
import 'package:charity_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:charity_app/features/reading/domain/reading_preferences.dart';
import 'package:charity_app/features/reading/presentation/providers/reading_preferences_provider.dart';
import 'package:charity_app/features/reading/presentation/widgets/reading_settings_sheet.dart';

const _bismillah = 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ';

String _toArabicDigits(int n) =>
    n.toString().split('').map((c) => '٠١٢٣٤٥٦٧٨٩'[int.parse(c)]).join();

class QuranReaderPage extends ConsumerStatefulWidget {
  final int surahNumber;
  final int initialAyah;
  const QuranReaderPage({super.key, required this.surahNumber, this.initialAyah = 1});

  @override
  ConsumerState<QuranReaderPage> createState() => _QuranReaderPageState();
}

class _QuranReaderPageState extends ConsumerState<QuranReaderPage> {
  late int _surahNumber = widget.surahNumber;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(quranSettingsProvider);
    final reading = ref.watch(readingPreferencesProvider);
    final bg = reading.background;
    final dataAsync = ref.watch(quranDataProvider);

    return Scaffold(
      backgroundColor: bg.pageColor,
      appBar: AppBar(
        backgroundColor: bg.pageColor,
        foregroundColor: bg.textColor,
        elevation: 0,
        iconTheme: IconThemeData(color: bg.textColor),
        title: dataAsync.maybeWhen(
          data: (surahs) {
            final s = surahs[_surahNumber - 1];
            return Column(
              children: [
                Text('سورة ${s.name}',
                    style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800, color: bg.textColor)),
                Text('${s.isMeccan ? 'مكية' : 'مدنية'} • ${s.ayahCount} آية',
                    style: GoogleFonts.cairo(
                        fontSize: 10, fontWeight: FontWeight.w500, color: bg.secondaryTextColor)),
              ],
            );
          },
          orElse: () => Text('المصحف', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: bg.textColor)),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'إعدادات القراءة',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => ReadingSettingsSheet.show(context, accent: const Color(0xFF0E7A5B)),
          ),
        ],
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('تعذّر تحميل المصحف', style: GoogleFonts.cairo(color: bg.textColor))),
        data: (surahs) {
          final surah = surahs[_surahNumber - 1];
          final showBismillah = _surahNumber != 1 && _surahNumber != 9;
          final isInitialSurah = _surahNumber == widget.surahNumber;
          final startIndex =
              (isInitialSurah && widget.initialAyah > 1) ? widget.initialAyah : 0;

          return Column(
            children: [
              Expanded(
                child: reading.mode == ReadingMode.flip
                    ? _QuranFlipView(
                        key: ValueKey('flip_${_surahNumber}_${reading.font.key}_${reading.fontSize}_${bg.key}'),
                        surah: surah,
                        showBismillah: showBismillah,
                        reading: reading,
                        bg: bg,
                        bookmarks: settings.bookmarks,
                        surahNumber: _surahNumber,
                        initialAyah: isInitialSurah ? widget.initialAyah : 1,
                      )
                    : ScrollablePositionedList.builder(
                        key: ValueKey(_surahNumber),
                        initialScrollIndex: startIndex,
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                        itemCount: surah.ayahCount + 1, // +1 للترويسة
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _SurahHeader(surah: surah, showBismillah: showBismillah, bg: bg, font: reading.font);
                          }
                          final ayahNumber = index;
                          final isTarget =
                              ayahNumber == widget.initialAyah && widget.initialAyah > 1 && isInitialSurah;
                          return _AyahTile(
                            text: surah.ayahs[ayahNumber - 1],
                            ayahNumber: ayahNumber,
                            fontSize: reading.fontSize,
                            font: reading.font,
                            bg: bg,
                            isBookmarked: settings.bookmarks.contains('$_surahNumber:$ayahNumber'),
                            highlight: isTarget,
                            onTap: () {
                              ref.read(quranSettingsProvider.notifier).setLastRead(_surahNumber, ayahNumber);
                            },
                            onBookmark: () =>
                                ref.read(quranSettingsProvider.notifier).toggleBookmark(_surahNumber, ayahNumber),
                          );
                        },
                      ),
              ),
              _SurahNavBar(
                surahNumber: _surahNumber,
                bg: bg,
                onPrev: _surahNumber > 1 ? () => setState(() => _surahNumber--) : null,
                onNext: _surahNumber < 114 ? () => setState(() => _surahNumber++) : null,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Surah Header ────────────────────────────────────────────────────────────────
class _SurahHeader extends StatelessWidget {
  final Surah surah;
  final bool showBismillah;
  final ReadingBackground bg;
  final ReadingFont font;
  const _SurahHeader({required this.surah, required this.showBismillah, required this.bg, required this.font});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0E7A5B), Color(0xFF0A5C44)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: const Color(0xFF0A5C44).withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text('سورة ${surah.name}',
                  style: GoogleFonts.amiriQuran(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
        ),
        if (showBismillah)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(_bismillah,
                textAlign: TextAlign.center,
                style: font.style(fontSize: 24, height: 1.8, color: bg.textColor)),
          ),
      ],
    );
  }
}

// ── Ayah Tile ───────────────────────────────────────────────────────────────────
class _AyahTile extends StatelessWidget {
  final String text;
  final int ayahNumber;
  final double fontSize;
  final ReadingFont font;
  final ReadingBackground bg;
  final bool isBookmarked;
  final bool highlight;
  final VoidCallback onTap;
  final VoidCallback onBookmark;
  const _AyahTile({
    required this.text,
    required this.ayahNumber,
    required this.fontSize,
    required this.font,
    required this.bg,
    required this.isBookmarked,
    required this.highlight,
    required this.onTap,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onBookmark,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: highlight
              ? const Color(0xFF10B981).withValues(alpha: 0.12)
              : (isBookmarked ? const Color(0xFFF59E0B).withValues(alpha: 0.08) : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
          border: highlight ? Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)) : null,
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$text ',
                style: font.style(fontSize: fontSize, height: 2.0, color: bg.textColor),
              ),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: _AyahBadge(number: ayahNumber, bookmarked: isBookmarked),
              ),
            ],
          ),
          textAlign: TextAlign.justify,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}

class _AyahBadge extends StatelessWidget {
  final int number;
  final bool bookmarked;
  const _AyahBadge({required this.number, required this.bookmarked});

  @override
  Widget build(BuildContext context) {
    final color = bookmarked ? const Color(0xFFF59E0B) : const Color(0xFF0E7A5B);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Center(
        child: Text(_toArabicDigits(number),
            style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ),
    );
  }
}

// ── Surah Nav Bar ───────────────────────────────────────────────────────────────
class _SurahNavBar extends StatelessWidget {
  final int surahNumber;
  final ReadingBackground bg;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  const _SurahNavBar({required this.surahNumber, required this.bg, this.onPrev, this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14, 8, 14, 8 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: bg.pageColor,
        border: Border(top: BorderSide(color: bg.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(child: _NavBtn(label: 'السابقة', icon: Icons.arrow_forward_rounded, onTap: onPrev)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0E7A5B).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$surahNumber / 114',
                style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF0E7A5B))),
          ),
          const SizedBox(width: 10),
          Expanded(child: _NavBtn(label: 'التالية', icon: Icons.arrow_back_rounded, onTap: onNext)),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  const _NavBtn({required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? const Color(0xFF0E7A5B) : Colors.grey.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: enabled ? Colors.white : Colors.grey),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700,
                        color: enabled ? Colors.white : Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quran Flip View (وضع قلب الصفحات للمصحف) ─────────────────────────────────────
/// يعرض سورة كاملة في وضع قلب الصفحات. يُخطّط نصّ السورة (مع أرقام الآيات)
/// مرّة واحدة، ثم يقسّمه إلى صفحات عند حدود الأسطر — فلا يُقطع أي سطر، ويُحافظ
/// على ترتيب الآيات وأرقامها، وبأداء جيّد حتى للسور الطويلة.
class _QuranFlipView extends StatelessWidget {
  final Surah surah;
  final bool showBismillah;
  final ReadingPreferences reading;
  final ReadingBackground bg;
  final Set<String> bookmarks;
  final int surahNumber;
  final int initialAyah;

  const _QuranFlipView({
    super.key,
    required this.surah,
    required this.showBismillah,
    required this.reading,
    required this.bg,
    required this.bookmarks,
    required this.surahNumber,
    required this.initialAyah,
  });

  static const double _badgeWidth = 32;
  static const double _badgeHeight = 28;

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final ayahStyle = reading.font.style(fontSize: reading.fontSize, height: 2.0, color: bg.textColor);

    return LayoutBuilder(
      builder: (context, constraints) {
        const pad = 20.0;
        const footer = 22.0;
        const gap = 8.0;
        final pageWidth = constraints.maxWidth - pad * 2;
        final pageHeight = constraints.maxHeight - pad * 2 - footer - gap;
        if (pageWidth <= 0 || pageHeight <= 0) return const SizedBox.shrink();

        // بناء سلسلة الفقرات الكاملة مع تتبّع موضع بداية كل آية ومقاسات الشارات.
        final spans = <InlineSpan>[];
        final placeholders = <PlaceholderDimensions>[];
        final ayahStartOffset = <int>[]; // ayahStartOffset[i] = موضع الآية (i+1)
        final plain = StringBuffer();

        if (showBismillah) {
          const b = '$_bismillah\n\n';
          spans.add(TextSpan(text: b, style: ayahStyle));
          plain.write(b);
        }

        for (var n = 1; n <= surah.ayahCount; n++) {
          ayahStartOffset.add(plain.length);
          final t = '${surah.ayahs[n - 1]} ';
          spans.add(TextSpan(text: t, style: ayahStyle));
          plain.write(t);
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _AyahBadge(number: n, bookmarked: bookmarks.contains('$surahNumber:$n')),
          ));
          plain.write('￼'); // WidgetSpan يُحتسب كحرف واحد عند التخطيط
          placeholders.add(const PlaceholderDimensions(
            size: Size(_badgeWidth, _badgeHeight),
            alignment: PlaceholderAlignment.middle,
          ));
          spans.add(const TextSpan(text: '  '));
          plain.write('  ');
        }

        final rootSpan = TextSpan(children: spans);

        // تخطيط النصّ مرّة واحدة لاستخراج مقاييس الأسطر.
        final painter = TextPainter(
          text: rootSpan,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.justify,
          textScaler: textScaler,
        )..setPlaceholderDimensions(placeholders);
        painter.layout(maxWidth: pageWidth);

        // تحديد قمم الصفحات عند حدود الأسطر (دون قطع أي سطر). نترك هامش أمان
        // صغيراً كي لا تُقصّ ذيول الحروف في السطر الأخير بسبب فروق التقريب.
        final usableHeight = pageHeight - 12;
        final metrics = painter.computeLineMetrics();
        final pageTopY = <double>[];
        double pageTop = 0;
        double y = 0;
        for (final m in metrics) {
          final lineBottom = y + m.height;
          if (lineBottom - pageTop > usableHeight && y > pageTop) {
            pageTopY.add(pageTop);
            pageTop = y;
          }
          y = lineBottom;
        }
        pageTopY.add(pageTop);

        // تحويل قمم الصفحات إلى مواضع حرفية، فيُعرض في كل صفحة نصّها فقط
        // (يبدأ عند بداية سطر تماماً) — لا قصّ ولا نصّ مُتسرّب من صفحة أخرى.
        final totalLen = plain.length;
        final pageStart = <int>[0];
        for (var i = 1; i < pageTopY.length; i++) {
          // أقصى يمين السطر هو بدايته في النصّ العربي.
          final pos = painter.getPositionForOffset(Offset(pageWidth, pageTopY[i] + 1));
          final off = pos.offset.clamp(pageStart.last, totalLen);
          pageStart.add(off > pageStart.last ? off : pageStart.last);
        }

        // تحديد صفحة البداية حسب الآية المطلوبة.
        int initialIndex = 0;
        if (initialAyah > 1 && initialAyah <= ayahStartOffset.length) {
          final target = ayahStartOffset[initialAyah - 1];
          for (var i = pageStart.length - 1; i >= 0; i--) {
            if (target >= pageStart[i]) {
              initialIndex = i;
              break;
            }
          }
        }
        initialIndex = initialIndex.clamp(0, pageStart.length - 1);

        final pages = <Widget>[
          for (var i = 0; i < pageStart.length; i++)
            _QuranFlipPage(
              spans: _sliceSpans(
                spans,
                pageStart[i],
                i + 1 < pageStart.length ? pageStart[i + 1] : totalLen,
              ),
              textScaler: textScaler,
              bg: bg,
              pad: pad,
              footer: footer,
              gap: gap,
              pageNumber: i + 1,
              totalPages: pageStart.length,
            ),
        ];

        return PageFlipWidget(
          backgroundColor: bg.pageColor,
          isRightSwipe: true,
          initialIndex: initialIndex,
          children: pages,
        );
      },
    );
  }

  /// يستخرج المقاطع الواقعة ضمن المدى الحرفي [start, end) من قائمة [source]،
  /// مع تقطيع المقاطع النصّية جزئياً عند الحاجة. كل WidgetSpan يُحتسب حرفاً واحداً.
  static List<InlineSpan> _sliceSpans(List<InlineSpan> source, int start, int end) {
    final out = <InlineSpan>[];
    var pos = 0;
    for (final span in source) {
      if (span is TextSpan) {
        final text = span.text ?? '';
        final len = text.length;
        final s0 = pos, s1 = pos + len;
        final a = start > s0 ? start : s0;
        final b = end < s1 ? end : s1;
        if (a < b) out.add(TextSpan(text: text.substring(a - s0, b - s0), style: span.style));
        pos += len;
      } else {
        // WidgetSpan (شارة الآية) = حرف واحد.
        if (pos >= start && pos < end) out.add(span);
        pos += 1;
      }
    }
    return out;
  }
}

class _QuranFlipPage extends StatelessWidget {
  final List<InlineSpan> spans;
  final TextScaler textScaler;
  final ReadingBackground bg;
  final double pad;
  final double footer;
  final double gap;
  final int pageNumber;
  final int totalPages;

  const _QuranFlipPage({
    required this.spans,
    required this.textScaler,
    required this.bg,
    required this.pad,
    required this.footer,
    required this.gap,
    required this.pageNumber,
    required this.totalPages,
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
                child: Text.rich(
                  TextSpan(children: spans),
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                  textScaler: textScaler,
                ),
              ),
            ),
          ),
          SizedBox(height: gap),
          SizedBox(
            height: footer,
            child: Center(
              child: Text('$pageNumber / $totalPages',
                  style: GoogleFonts.cairo(
                      fontSize: 11, fontWeight: FontWeight.w700, color: bg.secondaryTextColor)),
            ),
          ),
        ],
      ),
    );
  }
}
