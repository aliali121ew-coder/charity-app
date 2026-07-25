import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_flip/page_flip.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/istikhara/domain/istikhara_models.dart';
import 'package:charity_app/features/istikhara/presentation/providers/istikhara_providers.dart';
import 'package:charity_app/features/istikhara/presentation/widgets/istikhara_shared.dart';

const Color _mushafGreen = Color(0xFF0E7A5B);
const Color _mushafPaper = Color(0xFFFBF7EC);

/// تعرض حركة قلب صفحات مصحف حقيقية لمدّة ٤ ثوانٍ ثم تكشف نتيجة الخيرة.
class QuranIstikharaResultPage extends ConsumerStatefulWidget {
  const QuranIstikharaResultPage({super.key});

  @override
  ConsumerState<QuranIstikharaResultPage> createState() => _QuranIstikharaResultPageState();
}

class _QuranIstikharaResultPageState extends ConsumerState<QuranIstikharaResultPage> {
  QuranIstikharaEntry? _entry;
  bool _revealed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final loadFuture = ref.read(quranIstikharaDataProvider.future);
    await Future.delayed(const Duration(seconds: 4));
    try {
      final data = await loadFuture;
      if (!mounted) return;
      setState(() {
        _entry = pickRandomEntry(data);
        _revealed = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'تعذّر تحميل قاعدة بيانات الخيرة.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('استخارة بالقرآن', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: _error != null
          ? Center(
              child: Text(_error!,
                  style: GoogleFonts.cairo(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)))
          : !_revealed
              ? _MushafFlipAnimation(isDark: isDark)
              : _ResultView(entry: _entry!, isDark: isDark),
    );
  }
}

// ── حركة قلب صفحات المصحف ───────────────────────────────────────────────────────
class _MushafFlipAnimation extends StatefulWidget {
  final bool isDark;
  const _MushafFlipAnimation({required this.isDark});

  @override
  State<_MushafFlipAnimation> createState() => _MushafFlipAnimationState();
}

class _MushafFlipAnimationState extends State<_MushafFlipAnimation> {
  final _controller = GlobalKey<PageFlipWidgetState>();
  Timer? _timer;
  int _page = 0;
  static const _pageCount = 8;

  @override
  void initState() {
    super.initState();
    // قلب صفحة كل ٦٥٠ مللي ثانية (أطول من زمن حركة القلب نفسها).
    _timer = Timer.periodic(const Duration(milliseconds: 650), (_) {
      if (!mounted || _page >= _pageCount - 1) return;
      _page++;
      _controller.currentState?.nextPage();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: AspectRatio(
                aspectRatio: 0.72,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: PageFlipWidget(
                    key: _controller,
                    backgroundColor: _mushafPaper,
                    isRightSwipe: true,
                    children: List.generate(_pageCount, (i) => const _MushafPage()),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
          child: Column(
            children: [
              Text('نستخير الله...',
                  style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: widget.isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              const SizedBox(height: 8),
              Text('يُفتح المصحف لاستخراج الخيرة',
                  style: GoogleFonts.cairo(
                      fontSize: 12.5,
                      color: widget.isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              const SizedBox(height: 18),
              SizedBox(
                width: 160,
                child: LinearProgressIndicator(
                  backgroundColor: widget.isDark ? AppColors.borderDark : AppColors.borderLight,
                  color: _mushafGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// صفحة مصحف زخرفية (إطار + سطور خافتة) لإضفاء واقعية على حركة القلب.
class _MushafPage extends StatelessWidget {
  const _MushafPage();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _mushafPaper,
      padding: const EdgeInsets.all(14),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: _mushafGreen.withValues(alpha: 0.55), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: _mushafGreen.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Icon(Icons.brightness_7_rounded, color: _mushafGreen.withValues(alpha: 0.5), size: 22),
                  ),
                  const SizedBox(height: 16),
                  // سطور خافتة تحاكي الكتابة.
                  for (int i = 0; i < 11; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Container(
                        height: 3.5,
                        margin: EdgeInsets.only(
                          left: (i % 3) * 14.0,
                          right: (i % 2) * 10.0,
                        ),
                        decoration: BoxDecoration(
                          color: _mushafGreen.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultView extends ConsumerWidget {
  final QuranIstikharaEntry entry;
  final bool isDark;
  const _ResultView({required this.entry, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = 'سورة ${entry.surahName} • آية ${entry.verseNumber}';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        IstikharaResultView(result: entry.result, detail: detail, commentary: entry.commentary),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: istikharaAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.close_rounded, color: istikharaAccent),
                label: Text('إنهاء', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: istikharaAccent)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => showSaveIstikharaDialog(
                  context,
                  ref,
                  method: IstikharaMethod.quran,
                  result: entry.result,
                  detail: detail,
                  commentary: entry.commentary,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: istikharaAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.bookmark_add_rounded),
                label: Text('حفظ', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
