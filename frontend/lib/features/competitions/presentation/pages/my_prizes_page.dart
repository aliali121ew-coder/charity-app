import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/competitions/domain/competition_models.dart';
import 'package:charity_app/features/competitions/presentation/providers/points_provider.dart';
import 'package:charity_app/features/competitions/presentation/pages/claim_card_page.dart';

class MyPrizesPage extends ConsumerWidget {
  const MyPrizesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final claims = ref.watch(claimsProvider);
    final points = ref.watch(userPointsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('جوائزي', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _PointsBanner(points: points),
          const SizedBox(height: 16),
          if (claims.isEmpty)
            _empty(isDark)
          else
            ...claims.map((c) => _ClaimTile(card: c, isDark: isDark)),
        ],
      ),
    );
  }

  Widget _empty(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          const Icon(Icons.card_giftcard_rounded, size: 64, color: AppColors.textTertiaryLight),
          const SizedBox(height: 14),
          Text('لا توجد جوائز بعد',
              style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
          const SizedBox(height: 6),
          Text('شارك في المسابقات واربح لتظهر بطاقات جوائزك هنا',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondaryLight)),
        ],
      ),
    );
  }
}

class _PointsBanner extends StatelessWidget {
  final int points;
  const _PointsBanner({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.gradientOrange,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.stars_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('رصيد نقاطك',
                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.white.withValues(alpha: 0.85))),
              Text('$points نقطة',
                  style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClaimTile extends StatelessWidget {
  final ClaimCard card;
  final bool isDark;
  const _ClaimTile({required this.card, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy/MM/dd', 'ar');
    final statusColor = card.isExpired ? ClaimStatus.expired.color : card.status.color;
    final statusLabel = card.isExpired ? 'انتهت المهلة' : card.status.label;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ClaimCardPage(claimId: card.id))),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [card.color, card.color.withValues(alpha: 0.7)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(card.prizeType.icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.prizeTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                      const SizedBox(height: 2),
                      Text(card.competitionTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(fontSize: 10.5, color: AppColors.textSecondaryLight)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(statusLabel,
                                style: GoogleFonts.cairo(fontSize: 9, fontWeight: FontWeight.w800, color: statusColor)),
                          ),
                          const SizedBox(width: 8),
                          Text('حتى ${df.format(card.deadline)}',
                              style: GoogleFonts.cairo(fontSize: 9.5, color: AppColors.textTertiaryLight)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.qr_code_2_rounded, color: AppColors.textTertiaryLight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
