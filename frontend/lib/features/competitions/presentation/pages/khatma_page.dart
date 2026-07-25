import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/shared/providers/app_providers.dart';
import 'package:charity_app/features/competitions/domain/khatma_models.dart';
import 'package:charity_app/features/competitions/presentation/providers/khatma_provider.dart';
import 'package:charity_app/features/quran/domain/quran_models.dart';
import 'package:charity_app/features/quran/presentation/pages/quran_reader_page.dart';

class KhatmaPage extends ConsumerWidget {
  const KhatmaPage({super.key});

  String _currentUser(WidgetRef ref) =>
      ref.read(authProvider).user?.name ?? 'مستخدم';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final khatma = ref.watch(khatmaProvider);
    final active = khatma.active;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('الختمة القرآنية',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _ProgressHeader(khatma: active, completedKhatmas: khatma.totalCompletedKhatmas),
          const SizedBox(height: 16),
          if (active.isComplete) _CompletedBanner(index: active.index),
          const _Legend(),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 30,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (_, i) {
              final juz = active.juz[i];
              return _JuzCell(
                juz: juz,
                isMine: juz.reservedBy == _currentUser(ref),
                onTap: () => _onJuzTap(context, ref, juz),
              );
            },
          ),
          const SizedBox(height: 18),
          _HelpNote(isDark: isDark),
        ],
      ),
    );
  }

  void _onJuzTap(BuildContext context, WidgetRef ref, JuzModel juz) {
    final me = _currentUser(ref);
    final isMine = juz.reservedBy == me;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _JuzSheet(
        juz: juz,
        isMine: isMine,
        onRead: () async {
          Navigator.pop(context); // إغلاق الورقة
          final start = juzStartFor(juz.number);
          await Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
            builder: (_) => QuranReaderPage(surahNumber: start.surah, initialAyah: start.ayah),
          ));
          // عند الرجوع من القراءة: إن كان الجزء محجوزاً باسمي ولم يُكمَل، اسأل عن الإتمام.
          if (!context.mounted) return;
          final current = ref.read(khatmaProvider).active.juz[juz.number - 1];
          if (current.isReserved && current.reservedBy == me) {
            _confirmCompletion(context, ref, juz.number);
          }
        },
        onReserve: () {
          ref.read(khatmaProvider.notifier).reserve(juz.number, me);
          Navigator.pop(context);
          _toast(context, 'تم حجز الجزء ${juz.number} باسمك');
          // أعد فتح الورقة لتظهر خيارات «اقرأ هذا الجزء» و«تأكيد الإتمام».
          final updated = ref.read(khatmaProvider).active.juz[juz.number - 1];
          _onJuzTap(context, ref, updated);
        },
        onComplete: () {
          ref.read(khatmaProvider.notifier).markCompleted(juz.number);
          Navigator.pop(context);
          _toast(context, 'بارك الله فيك — تم تسجيل إتمام الجزء ${juz.number}');
        },
        onCancel: () {
          ref.read(khatmaProvider.notifier).cancelReservation(juz.number);
          Navigator.pop(context);
          _toast(context, 'تم إلغاء حجز الجزء ${juz.number}');
        },
      ),
    );
  }

  void _confirmCompletion(BuildContext context, WidgetRef ref, int juzNumber) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.menu_book_rounded, color: Color(0xFF0E7A5B)),
            const SizedBox(width: 8),
            Expanded(
              child: Text('هل أكملت قراءة الجزء $juzNumber؟',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ],
        ),
        content: Text('إن أتممت قراءة الجزء، أكّد لتسجيله ضمن الختمة.',
            style: GoogleFonts.cairo(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ليس بعد',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700, color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(khatmaProvider.notifier).markCompleted(juzNumber);
              Navigator.pop(ctx);
              _toast(context, 'بارك الله فيك — تم تسجيل إتمام الجزء $juzNumber');
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: Text('نعم، أكملته',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF059669),
      ),
    );
  }
}

// ── Progress Header ─────────────────────────────────────────────────────────────
class _ProgressHeader extends StatelessWidget {
  final KhatmaModel khatma;
  final int completedKhatmas;
  const _ProgressHeader({required this.khatma, required this.completedKhatmas});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: khatma.gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: khatma.gradient.colors.first.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text('${khatma.index}',
                      style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الختمة رقم ${khatma.index}',
                        style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                    Text('أكملنا $completedKhatmas ختمة بفضل الله',
                        style: GoogleFonts.cairo(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.85))),
                  ],
                ),
              ),
              Text('${khatma.completedCount}/30',
                  style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: khatma.progress,
              minHeight: 9,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _HeaderStat(value: '${khatma.completedCount}', label: 'تمت قراءته'),
              _HeaderStat(value: '${khatma.reservedCount}', label: 'محجوز'),
              _HeaderStat(value: '${khatma.availableCount}', label: 'متاح'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String value, label;
  const _HeaderStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
        Text(label, style: GoogleFonts.cairo(fontSize: 9.5, color: Colors.white.withValues(alpha: 0.85))),
      ],
    );
  }
}

// ── Completed Banner ────────────────────────────────────────────────────────────
class _CompletedBanner extends StatelessWidget {
  final int index;
  const _CompletedBanner({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.celebration_rounded, color: Color(0xFF059669)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'تمّت الختمة رقم $index بفضل الله 🎉 وفُتحت ختمة جديدة — تابع الحجز فيها.',
              style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF047857)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Legend ──────────────────────────────────────────────────────────────────────
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        _LegendItem(color: Color(0xFF94A3B8), label: 'متاح للحجز'),
        _LegendItem(color: Color(0xFFF59E0B), label: 'تم حجزه'),
        _LegendItem(color: Color(0xFF10B981), label: 'تمت القراءة'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.cairo(fontSize: 10.5, fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
      ],
    );
  }
}

// ── Juz Cell ────────────────────────────────────────────────────────────────────
class _JuzCell extends StatelessWidget {
  final JuzModel juz;
  final bool isMine;
  final VoidCallback onTap;
  const _JuzCell({required this.juz, required this.isMine, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = juz.color;
    final filled = !juz.isAvailable;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            gradient: filled
                ? LinearGradient(colors: [color, color.withValues(alpha: 0.75)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight)
                : null,
            color: filled ? null : color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: filled ? 0.0 : 0.4), width: 1.2),
            boxShadow: filled
                ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))]
                : null,
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('الجزء',
                        style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700,
                            color: filled ? Colors.white.withValues(alpha: 0.9) : color)),
                    Text('${juz.number}',
                        style: GoogleFonts.cairo(fontSize: 23, fontWeight: FontWeight.w900, height: 1.05,
                            color: filled ? Colors.white : color)),
                    if (juz.isReserved) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isMine ? 'حجزك' : (juz.reservedBy ?? '').split(' ').first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (juz.isCompleted)
                const Positioned(top: 6, right: 6, child: Icon(Icons.check_circle_rounded, size: 15, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Juz Action Sheet ────────────────────────────────────────────────────────────
class _JuzSheet extends StatelessWidget {
  final JuzModel juz;
  final bool isMine;
  final VoidCallback onRead;
  final VoidCallback onReserve;
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  const _JuzSheet({
    required this.juz,
    required this.isMine,
    required this.onRead,
    required this.onReserve,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 14, 20, 18 + MediaQuery.of(context).viewPadding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))),
          Row(
            children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(color: juz.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text('${juz.number}',
                    style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.w900, color: juz.color))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الجزء ${juz.number}',
                        style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.w900,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                    Text(juz.statusLabel,
                        style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700, color: juz.color)),
                    if (juz.reservedBy != null)
                      Text('بواسطة: ${juz.reservedBy}',
                          style: GoogleFonts.cairo(fontSize: 11,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                  ],
                ),
              ),
            ],
          ),
            const SizedBox(height: 20),
            // الجزء المتاح: حجز فقط
            if (juz.isAvailable)
              _SheetButton(label: 'احجز هذا الجزء', icon: Icons.bookmark_add_rounded,
                  color: const Color(0xFF059669), onTap: onReserve),
            // محجوز باسمي: اقرأ + تأكيد الإتمام + إلغاء الحجز
            if (juz.isReserved && isMine) ...[
              _SheetButton(label: 'اقرأ هذا الجزء', icon: Icons.menu_book_rounded,
                  color: const Color(0xFF0E7A5B), onTap: onRead),
              const SizedBox(height: 10),
              _SheetButton(label: 'تأكيد إتمام القراءة', icon: Icons.check_circle_rounded,
                  color: const Color(0xFF10B981), onTap: onComplete),
              const SizedBox(height: 10),
              _SheetButton(label: 'إلغاء الحجز', icon: Icons.close_rounded,
                  color: const Color(0xFFEF4444), outlined: true, onTap: onCancel),
            ],
            // محجوز من قبل غيري: اقرأ + ملاحظة
            if (juz.isReserved && !isMine) ...[
              _SheetButton(label: 'اقرأ هذا الجزء', icon: Icons.menu_book_rounded,
                  color: const Color(0xFF0E7A5B), onTap: onRead),
              const SizedBox(height: 10),
              _InfoBox(text: 'هذا الجزء محجوز من قبل ${juz.reservedBy}. اختر جزءاً آخر متاحاً للحجز.', isDark: isDark),
            ],
            // مكتمل: اقرأ + ملاحظة
            if (juz.isCompleted) ...[
              _SheetButton(label: 'اقرأ هذا الجزء', icon: Icons.menu_book_rounded,
                  color: const Color(0xFF0E7A5B), onTap: onRead),
              const SizedBox(height: 10),
              _InfoBox(text: 'تمت قراءة هذا الجزء بحمد الله ✅', isDark: isDark),
            ],
          ],
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;
  const _SheetButton({
    required this.label, required this.icon, required this.color,
    this.outlined = false, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: outlined ? Colors.transparent : color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: outlined ? Border.all(color: color, width: 1.5) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: outlined ? color : Colors.white),
              const SizedBox(width: 8),
              Text(label, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800,
                  color: outlined ? color : Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  final bool isDark;
  const _InfoBox({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, textAlign: TextAlign.center,
          style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
    );
  }
}

// ── Help Note ───────────────────────────────────────────────────────────────────
class _HelpNote extends StatelessWidget {
  final bool isDark;
  const _HelpNote({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'احجز جزءاً متاحاً ثم أكّد إتمام قراءته. لا تُفتح الختمة التالية إلا بعد إتمام قراءة جميع الأجزاء الثلاثين.',
              style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
          ),
        ],
      ),
    );
  }
}
