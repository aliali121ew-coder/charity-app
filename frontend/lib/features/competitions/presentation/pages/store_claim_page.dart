import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/competitions/domain/competition_models.dart';
import 'package:charity_app/features/competitions/presentation/providers/competitions_provider.dart';
import 'package:charity_app/features/competitions/presentation/providers/store_provider.dart';
import 'package:charity_app/features/competitions/presentation/widgets/qr_view.dart';

class StoreClaimPage extends ConsumerWidget {
  final String redemptionId;
  const StoreClaimPage({super.key, required this.redemptionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = ref.watch(storeRedemptionsProvider);
    final canManage = ref.watch(canManageCompetitionsProvider);
    StoreRedemption? r;
    for (final x in items) {
      if (x.id == redemptionId) {
        r = x;
        break;
      }
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('كود الاستلام', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: r == null
          ? Center(child: Text('السجل غير متاح', style: GoogleFonts.cairo(color: AppColors.textSecondaryLight)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                _Visual(r: r),
                const SizedBox(height: 18),
                _Actions(r: r, canManage: canManage, ref: ref),
              ],
            ),
    );
  }
}

class _Visual extends StatelessWidget {
  final StoreRedemption r;
  const _Visual({required this.r});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy/MM/dd', 'ar');
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [r.color, r.color.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: r.color.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
            child: Column(
              children: [
                Icon(r.icon, color: Colors.white, size: 42),
                const SizedBox(height: 8),
                Text('استبدال جائزة',
                    style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.9))),
                Text(r.prizeTitle, textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Column(
              children: [
                QrView(data: r.qrData, size: 170, foreground: r.color.computeLuminance() < 0.5 ? r.color : const Color(0xFF0F172A)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: r.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: r.color.withValues(alpha: 0.3)),
                  ),
                  child: Text(r.claimCode,
                      style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800, color: r.color, letterSpacing: 2)),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _stat('الحالة', r.isExpired ? 'انتهت المهلة' : r.status.label, r.isExpired ? ClaimStatus.expired.color : r.status.color)),
                    const SizedBox(width: 10),
                    Expanded(child: _stat('مهلة الاستلام', r.status == ClaimStatus.received ? 'مكتمل' : df.format(r.deadline), AppColors.textSecondaryLight)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(r.instructions,
                    style: GoogleFonts.cairo(fontSize: 11.5, height: 1.5, color: Colors.white.withValues(alpha: 0.92)))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.cairo(fontSize: 9.5, color: AppColors.textSecondaryLight)),
            const SizedBox(height: 3),
            Text(value, textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      );
}

class _Actions extends StatelessWidget {
  final StoreRedemption r;
  final bool canManage;
  final WidgetRef ref;
  const _Actions({required this.r, required this.canManage, required this.ref});

  void _share(BuildContext context) {
    Clipboard.setData(ClipboardData(text: 'استبدال جائزة: ${r.prizeTitle}\nكود الاستلام: ${r.claimCode}'));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('تم نسخ كود الاستلام', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF059669),
    ));
  }

  void _confirm(BuildContext context) {
    final err = ref.read(storeRedemptionsProvider.notifier).confirmReceipt(r.id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err ?? 'تم تأكيد الاستلام وخصم ${r.pointsCost} نقطة ✓', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: err == null ? const Color(0xFF059669) : const Color(0xFFEF4444),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final received = r.status == ClaimStatus.received;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _share(context),
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: Text('نسخ الكود', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
            style: OutlinedButton.styleFrom(
              foregroundColor: r.color,
              side: BorderSide(color: r.color),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        if (canManage && !received) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _confirm(context),
              icon: const Icon(Icons.verified_rounded, size: 18),
              label: Text('تأكيد الاستلام (مشرف) — يخصم ${r.pointsCost} نقطة',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
        if (received)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                const SizedBox(width: 6),
                Text('تم استلام الجائزة بنجاح',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: const Color(0xFF059669))),
              ],
            ),
          ),
      ],
    );
  }
}
