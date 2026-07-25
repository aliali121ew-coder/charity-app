import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/quran/domain/quran_models.dart';
import 'package:charity_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:charity_app/features/quran/presentation/pages/quran_reader_page.dart';

class QuranSurahsPage extends ConsumerStatefulWidget {
  const QuranSurahsPage({super.key});

  @override
  ConsumerState<QuranSurahsPage> createState() => _QuranSurahsPageState();
}

class _QuranSurahsPageState extends ConsumerState<QuranSurahsPage> {
  String _query = '';

  void _openReader(int surah, [int ayah = 1]) {
    // قراءة بملء الشاشة فوق الـ shell (دون الشريط العلوي/السفلي للتطبيق).
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
      builder: (_) => QuranReaderPage(surahNumber: surah, initialAyah: ayah),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(quranSettingsProvider);
    final dataAsync = ref.watch(quranDataProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('القرآن الكريم', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('تعذّر تحميل المصحف', style: GoogleFonts.cairo())),
      data: (surahs) {
        final q = _query.trim();
        final filtered = q.isEmpty
            ? surahs
            : surahs.where((s) =>
                s.name.contains(q) ||
                s.englishName.toLowerCase().contains(q.toLowerCase()) ||
                s.number.toString() == q).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
          children: [
            if (settings.lastRead != null && q.isEmpty)
              _ContinueCard(
                surah: surahs[settings.lastReadSurah! - 1],
                ayah: settings.lastReadAyah!,
                onTap: () => _openReader(settings.lastReadSurah!, settings.lastReadAyah!),
              ),
            _SearchField(onChanged: (v) => setState(() => _query = v), isDark: isDark),
            const SizedBox(height: 10),
            ...filtered.map((s) => _SurahTile(
                  surah: s,
                  isDark: isDark,
                  onTap: () => _openReader(s.number),
                )),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(child: Text('لا توجد نتائج',
                    style: GoogleFonts.cairo(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
              ),
          ],
        );
      },
      ),
    );
  }
}

// ── Continue Reading ────────────────────────────────────────────────────────────
class _ContinueCard extends StatelessWidget {
  final Surah surah;
  final int ayah;
  final VoidCallback onTap;
  const _ContinueCard({required this.surah, required this.ayah, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0E7A5B), Color(0xFF0A5C44)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: const Color(0xFF0A5C44).withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('متابعة القراءة',
                          style: GoogleFonts.cairo(fontSize: 11, color: Colors.white.withValues(alpha: 0.85))),
                      Text('سورة ${surah.name} • الآية $ayah',
                          style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Search Field ────────────────────────────────────────────────────────────────
class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final bool isDark;
  const _SearchField({required this.onChanged, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: GoogleFonts.cairo(fontSize: 13),
      decoration: InputDecoration(
        hintText: 'ابحث عن سورة...',
        hintStyle: GoogleFonts.cairo(fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
      ),
    );
  }
}

// ── Surah Tile ──────────────────────────────────────────────────────────────────
class _SurahTile extends StatelessWidget {
  final Surah surah;
  final bool isDark;
  final VoidCallback onTap;
  const _SurahTile({required this.surah, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // رقم السورة داخل نجمة/معيّن
                SizedBox(
                  width: 42, height: 42,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.rotate(
                        angle: 0.785398,
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                        ),
                      ),
                      Text('${surah.number}',
                          style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(surah.englishName,
                          style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                      Text('${surah.isMeccan ? 'مكية' : 'مدنية'} • ${surah.ayahCount} آية',
                          style: GoogleFonts.cairo(fontSize: 10.5,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                    ],
                  ),
                ),
                Text(surah.name,
                    style: GoogleFonts.amiriQuran(fontSize: 22, fontWeight: FontWeight.w700,
                        color: const Color(0xFF0E7A5B))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
