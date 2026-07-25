import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/competitions/domain/competition_models.dart';
import 'package:charity_app/features/competitions/presentation/providers/competitions_provider.dart';
import 'package:charity_app/features/competitions/presentation/providers/points_provider.dart';
import 'package:charity_app/features/competitions/presentation/widgets/qr_view.dart';

class ClaimCardPage extends ConsumerWidget {
  final String claimId;
  const ClaimCardPage({super.key, required this.claimId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final claims = ref.watch(claimsProvider);
    final canManage = ref.watch(canManageCompetitionsProvider);
    ClaimCard? card;
    for (final c in claims) {
      if (c.id == claimId) {
        card = c;
        break;
      }
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('بطاقة الجائزة', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: card == null
          ? Center(
              child: Text('البطاقة غير متاحة',
                  style: GoogleFonts.cairo(color: AppColors.textSecondaryLight)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                _ClaimCardVisual(card: card),
                const SizedBox(height: 18),
                _Actions(card: card, canManage: canManage, ref: ref),
              ],
            ),
    );
  }
}

// ── البطاقة الأنيقة القابلة للحفظ ──────────────────────────────────────────────
class _ClaimCardVisual extends StatelessWidget {
  final ClaimCard card;
  const _ClaimCardVisual({required this.card});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy/MM/dd', 'ar');
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [card.color, card.color.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: card.color.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
            child: Column(
              children: [
                const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 46),
                const SizedBox(height: 8),
                Text('🎉 مبروك الفوز!',
                    style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 2),
                Text(card.winnerName,
                    style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
          // القسم الأبيض: QR + الكود
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                _row('الجائزة', card.prizeTitle, icon: card.prizeType.icon),
                const Divider(height: 20),
                _row('المسابقة', card.competitionTitle, icon: Icons.workspace_premium_rounded),
                const SizedBox(height: 16),
                QrView(data: card.qrData, size: 170, foreground: card.color.computeLuminance() < 0.5 ? card.color : const Color(0xFF0F172A)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: card.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: card.color.withValues(alpha: 0.3)),
                  ),
                  child: Text(card.claimCode,
                      style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800, color: card.color, letterSpacing: 2)),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _miniStat(
                        label: 'الحالة',
                        value: card.isExpired ? 'انتهت المهلة' : card.status.label,
                        color: card.isExpired ? ClaimStatus.expired.color : card.status.color,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _miniStat(
                        label: 'مهلة الاستلام',
                        value: card.status == ClaimStatus.received
                            ? 'مكتمل'
                            : df.format(card.deadline),
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // تعليمات الاستلام
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(card.instructions,
                      style: GoogleFonts.cairo(fontSize: 11.5, height: 1.5, color: Colors.white.withValues(alpha: 0.92))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: card.color),
        const SizedBox(width: 8),
        Text('$label: ',
            style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight)),
        Expanded(
          child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimaryLight)),
        ),
      ],
    );
  }

  Widget _miniStat({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
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
}

// ── أزرار: مشاركة + (للمشرف) تأكيد الاستلام ────────────────────────────────────
class _Actions extends StatelessWidget {
  final ClaimCard card;
  final bool canManage;
  final WidgetRef ref;
  const _Actions({required this.card, required this.canManage, required this.ref});

  void _share(BuildContext context) {
    final msg =
        '🎉 الحمد لله، فزت في "${card.competitionTitle}"!\nالجائزة: ${card.prizeTitle}\nكود المطالبة: ${card.claimCode}';
    Clipboard.setData(ClipboardData(text: msg));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('تم نسخ بطاقة الفوز — يمكنك لصقها ومشاركتها 🎁',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF059669),
    ));
  }

  void _confirm(BuildContext context) {
    final err = ref.read(claimsProvider.notifier).confirmReceipt(card.id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err ?? 'تم تأكيد الاستلام وخصم ${card.pointsCost} نقطة ✓',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: err == null ? const Color(0xFF059669) : const Color(0xFFEF4444),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final received = card.status == ClaimStatus.received;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _share(context),
            icon: const Icon(Icons.share_rounded, size: 18),
            label: Text('شارك كفوزي', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
            style: OutlinedButton.styleFrom(
              foregroundColor: card.color,
              side: BorderSide(color: card.color),
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
              label: Text('تأكيد الاستلام (مشرف) — يخصم ${card.pointsCost} نقطة',
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
