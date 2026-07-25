import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/competitions/domain/competition_models.dart';
import 'package:charity_app/features/competitions/presentation/providers/competitions_provider.dart';
import 'package:charity_app/features/competitions/presentation/providers/points_provider.dart';
import 'package:charity_app/features/competitions/presentation/providers/store_provider.dart';
import 'package:charity_app/features/competitions/presentation/pages/create_store_prize_page.dart';
import 'package:charity_app/features/competitions/presentation/pages/store_claim_page.dart';

class PrizesPage extends ConsumerStatefulWidget {
  const PrizesPage({super.key});

  @override
  ConsumerState<PrizesPage> createState() => _PrizesPageState();
}

class _PrizesPageState extends ConsumerState<PrizesPage> {
  int _tab = 0; // 0 = المتجر، 1 = سجل استبدالي

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF059669),
    ));
  }

  void _redeem(Prize p) {
    final err = ref.read(storeRedemptionsProvider.notifier).redeem(p);
    if (err != null) {
      _snack(err, isError: true);
      return;
    }
    if (p.type == PrizeType.digital) {
      _snack('تم استبدال "${p.title}" بنجاح 🎉');
    } else {
      _snack('تم حجز "${p.title}" — راجع سجل الاستبدال لكود الاستلام 🎁');
      setState(() => _tab = 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final points = ref.watch(userPointsProvider);
    final prizes = ref.watch(storePrizesProvider);
    final canManage = ref.watch(canManageCompetitionsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('الجوائز', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      floatingActionButton: (canManage && _tab == 0)
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateStorePrizePage())),
              backgroundColor: AppColors.pink,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text('إضافة جائزة',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: Colors.white)),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _PointsBanner(points: points),
          ),
          _Tabs(selected: _tab, onSelect: (i) => setState(() => _tab = i)),
          Expanded(
            child: _tab == 0
                ? _StoreGrid(prizes: prizes, points: points, isDark: isDark, canManage: canManage, onRedeem: _redeem)
                : const _RedemptionsTab(),
          ),
        ],
      ),
    );
  }
}

// ── التبويبات ─────────────────────────────────────────────────────────────────
class _Tabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _Tabs({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const labels = ['متجر النقاط', 'سجل استبدالي'];
    return Container(
      height: 44,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.pink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(2, (i) {
          final sel = selected == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sel ? AppColors.pink : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(labels[i],
                    style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w800,
                        color: sel ? Colors.white : AppColors.textSecondaryLight)),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── شبكة المتجر ──────────────────────────────────────────────────────────────
class _StoreGrid extends StatelessWidget {
  final List<Prize> prizes;
  final int points;
  final bool isDark;
  final bool canManage;
  final void Function(Prize) onRedeem;
  const _StoreGrid({
    required this.prizes,
    required this.points,
    required this.isDark,
    required this.canManage,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    if (prizes.isEmpty) {
      return Center(
        child: Text('لا توجد جوائز في المتجر بعد',
            style: GoogleFonts.cairo(color: AppColors.textSecondaryLight)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
      itemCount: prizes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.66,
      ),
      itemBuilder: (_, i) {
        final p = prizes[i];
        return _PrizeCard(
          prize: p,
          canAfford: points >= p.pointsCost,
          isDark: isDark,
          canManage: canManage,
          onRedeem: () => onRedeem(p),
        );
      },
    );
  }
}

// ── تبويب سجل الاستبدال ────────────────────────────────────────────────────────
class _RedemptionsTab extends ConsumerWidget {
  const _RedemptionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = ref.watch(storeRedemptionsProvider);
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_rounded, size: 56, color: AppColors.textTertiaryLight),
            const SizedBox(height: 12),
            Text('لم تستبدل أي جائزة بعد',
                style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
          ],
        ),
      );
    }
    final df = DateFormat('yyyy/MM/dd', 'ar');
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final r = items[i];
        final statusColor = r.isExpired ? ClaimStatus.expired.color : r.status.color;
        final statusLabel = r.isExpired ? 'انتهت المهلة' : r.status.label;
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
              onTap: r.isPhysical
                  ? () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => StoreClaimPage(redemptionId: r.id)))
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [r.color, r.color.withValues(alpha: 0.7)]),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(r.icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.prizeTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(color: r.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                                child: Text(r.type.label,
                                    style: GoogleFonts.cairo(fontSize: 8.5, fontWeight: FontWeight.w800, color: r.color)),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                                child: Text(statusLabel,
                                    style: GoogleFonts.cairo(fontSize: 8.5, fontWeight: FontWeight.w800, color: statusColor)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('${r.pointsCost} نقطة • ${df.format(r.redeemedAt)}',
                              style: GoogleFonts.cairo(fontSize: 9.5, color: AppColors.textTertiaryLight)),
                        ],
                      ),
                    ),
                    if (r.isPhysical) const Icon(Icons.qr_code_2_rounded, color: AppColors.textTertiaryLight),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── بانر النقاط ───────────────────────────────────────────────────────────────
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

// ── بطاقة الجائزة ─────────────────────────────────────────────────────────────
class _PrizeCard extends ConsumerWidget {
  final Prize prize;
  final bool canAfford;
  final bool isDark;
  final bool canManage;
  final VoidCallback onRedeem;
  const _PrizeCard({
    required this.prize,
    required this.canAfford,
    required this.isDark,
    required this.canManage,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outOfStock = prize.stock <= 0;
    final disabled = outOfStock || !canAfford;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 78,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [prize.color, prize.color.withValues(alpha: 0.7)]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Stack(
              children: [
                Center(child: Icon(prize.icon, color: Colors.white, size: 36)),
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: outOfStock ? const Color(0xFFEF4444) : Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(outOfStock ? 'نفدت' : 'متبقٍ ${prize.stock}',
                        style: GoogleFonts.cairo(fontSize: 8.5, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(prize.type.icon, color: Colors.white, size: 11),
                        const SizedBox(width: 3),
                        Text(prize.type == PrizeType.digital ? 'رقمية' : 'مادية',
                            style: GoogleFonts.cairo(fontSize: 7.5, fontWeight: FontWeight.w800, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                if (canManage)
                  Positioned(
                    bottom: 4, left: 4,
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => CreateStorePrizePage(existing: prize))),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(prize.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Text(prize.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(fontSize: 10,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded, size: 14, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 3),
                      Text('${prize.pointsCost}',
                          style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFFD97706))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: disabled ? Colors.grey.withValues(alpha: 0.3) : prize.color,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: disabled ? null : onRedeem,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            outOfStock ? 'نفدت الكمية' : (canAfford ? 'استبدال' : 'نقاط غير كافية'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w800,
                                color: disabled ? Colors.grey.shade600 : Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
