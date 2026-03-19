import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/core/localization/app_localizations.dart';
import 'package:charity_app/core/permissions/role.dart';
import 'package:charity_app/shared/models/aid_model.dart';
import 'package:charity_app/shared/widgets/app_search_bar.dart';
import 'package:charity_app/shared/widgets/section_header.dart';
import 'package:charity_app/shared/widgets/status_chip.dart';
import 'package:charity_app/shared/widgets/empty_state_widget.dart';
import 'package:charity_app/features/aid/presentation/providers/aid_provider.dart';
import 'package:charity_app/shared/providers/app_providers.dart';
import 'package:intl/intl.dart';

class AidPage extends ConsumerWidget {
  const AidPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(aidProvider);
    final user = ref.watch(authProvider).user;
    final canAdd = user?.hasPermission(Permission.addAid) ?? false;
    final canApprove = user?.hasPermission(Permission.approveAid) ?? false;
    final canDistribute = user?.hasPermission(Permission.distributeAid) ?? false;

    final pendingCount = state.all.where((a) => a.status == AidStatus.pending).length;
    final approvedCount = state.all.where((a) => a.status == AidStatus.approved).length;
    final distributedCount = state.all.where((a) => a.status == AidStatus.distributed).length;
    final totalAmount = state.all.fold(0.0, (sum, a) => sum + a.amount);

    return Column(
      children: [
        Container(
          color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : AppColors.surfaceLight,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              PageHeader(
                title: l10n.tr('aid'),
                subtitle: 'إدارة سجلات المساعدات',
                actions: [
                  if (canAdd)
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(l10n.tr('add_aid'), style: GoogleFonts.cairo(fontSize: 13)),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Summary cards (horizontal scroll)
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _SummaryCard(label: 'الإجمالي', value: '${state.all.length}', gradient: AppColors.gradientBlue, glowColor: const Color(0xFF3B82F6), icon: Icons.list_alt_rounded),
                    const SizedBox(width: 10),
                    _SummaryCard(label: 'قيد الانتظار', value: '$pendingCount', gradient: AppColors.gradientOrange, glowColor: const Color(0xFFF59E0B), icon: Icons.hourglass_top_rounded),
                    const SizedBox(width: 10),
                    _SummaryCard(label: 'معتمد', value: '$approvedCount', gradient: AppColors.gradientGreen, glowColor: const Color(0xFF10B981), icon: Icons.check_circle_rounded),
                    const SizedBox(width: 10),
                    _SummaryCard(label: 'تم الصرف', value: '$distributedCount', gradient: AppColors.gradientTeal, glowColor: const Color(0xFF00C9A7), icon: Icons.done_all_rounded),
                    const SizedBox(width: 10),
                    _SummaryCard(label: 'المبلغ الكلي', value: '${(totalAmount / 1000000).toStringAsFixed(1)}M', gradient: AppColors.gradientPurple, glowColor: const Color(0xFF7C3AED), icon: Icons.account_balance_wallet_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Search + Type filter
              Row(
                children: [
                  Expanded(
                    child: AppSearchBar(
                      hint: l10n.tr('search_aid'),
                      onChanged: (q) => ref.read(aidProvider.notifier).search(q),
                      showFilterButton: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _AidTypeFilter(
                    value: state.typeFilter,
                    onChanged: (t) => ref.read(aidProvider.notifier).filterByType(t),
                    l10n: l10n,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),

        // List
        Expanded(
          child: state.filtered.isEmpty
              ? const EmptyStateWidget(icon: Icons.volunteer_activism_outlined, title: 'لا توجد مساعدات', subtitle: 'لم يتم العثور على نتائج')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.filtered.length,
                  itemBuilder: (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AidRecordCard(
                      aid: state.filtered[i],
                      canApprove: canApprove,
                      canDistribute: canDistribute,
                      onApprove: () => ref.read(aidProvider.notifier).approveAid(state.filtered[i].id),
                      onDistribute: () => ref.read(aidProvider.notifier).distributeAid(state.filtered[i].id),
                      l10n: l10n,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Aid Record Card ───────────────────────────────────────────────────────────
class AidRecordCard extends StatelessWidget {
  final AidModel aid;
  final bool canApprove;
  final bool canDistribute;
  final VoidCallback onApprove;
  final VoidCallback onDistribute;
  final AppLocalizations l10n;

  const AidRecordCard({
    super.key,
    required this.aid,
    required this.canApprove,
    required this.canDistribute,
    required this.onApprove,
    required this.onDistribute,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeColor = _typeColor(aid.type);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: typeColor.withValues(alpha: isDark ? 0.2 : 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: typeColor.withValues(alpha: isDark ? 0.18 : 0.1),
            blurRadius: 14,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            // Gradient accent header strip
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [typeColor, typeColor.withValues(alpha: 0.4)],
                ),
              ),
            ),
            Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_typeIcon(aid.type), size: 20, color: typeColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              aid.beneficiaryName,
                              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                            ),
                          ),
                          StatusChip.aid(aid.status),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(aid.type.labelAr, style: GoogleFonts.cairo(fontSize: 11, color: typeColor, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            aid.referenceNumber,
                            style: GoogleFonts.cairo(fontSize: 11, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                // Amount
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('القيمة', style: GoogleFonts.cairo(fontSize: 10, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight)),
                      Text(
                        '${NumberFormat('#,###').format(aid.amount)} ${l10n.tr('iqd')}',
                        style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      ),
                    ],
                  ),
                ),
                // Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('التاريخ', style: GoogleFonts.cairo(fontSize: 10, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight)),
                    Text(DateFormat('dd/MM/yyyy').format(aid.date), style: GoogleFonts.cairo(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                  ],
                ),
                const SizedBox(width: 12),
                // Employee
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('المسؤول', style: GoogleFonts.cairo(fontSize: 10, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight)),
                    Text(aid.responsibleEmployee, style: GoogleFonts.cairo(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                  ],
                ),
              ],
            ),

            // Action buttons for pending/approved
            if (aid.status == AidStatus.pending && canApprove || aid.status == AidStatus.approved && canDistribute) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (aid.status == AidStatus.pending && canApprove)
                    _ActionBtn(
                      label: l10n.tr('approve_aid'),
                      color: AppColors.kpiGreen.first,
                      icon: Icons.check_circle_outline_rounded,
                      onTap: onApprove,
                    ),
                  if (aid.status == AidStatus.approved && canDistribute) ...[
                    const SizedBox(width: 8),
                    _ActionBtn(
                      label: l10n.tr('distribute_aid'),
                      color: AppColors.kpiBlue.first,
                      icon: Icons.volunteer_activism_rounded,
                      onTap: onDistribute,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
          ],
        ),
      ),
    );
  }

  Color _typeColor(AidType type) {
    switch (type) {
      case AidType.financial: return AppColors.kpiBlue.first;
      case AidType.food: return AppColors.kpiGreen.first;
      case AidType.medical: return AppColors.kpiRose.first;
      case AidType.seasonal: return AppColors.kpiOrange.first;
      case AidType.education: return AppColors.kpiPurple.first;
      case AidType.other: return AppColors.kpiTeal.first;
    }
  }

  IconData _typeIcon(AidType type) {
    switch (type) {
      case AidType.financial: return Icons.attach_money_rounded;
      case AidType.food: return Icons.restaurant_rounded;
      case AidType.medical: return Icons.medical_services_rounded;
      case AidType.seasonal: return Icons.calendar_month_rounded;
      case AidType.education: return Icons.school_rounded;
      case AidType.other: return Icons.category_rounded;
    }
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: color),
      label: Text(label, style: GoogleFonts.cairo(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      style: TextButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final LinearGradient gradient;
  final Color glowColor;
  final IconData icon;
  const _SummaryCard({required this.label, required this.value, required this.gradient, required this.glowColor, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.38),
            blurRadius: 14,
            spreadRadius: -3,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle accent
          Positioned(
            right: -14,
            top: -14,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AidTypeFilter extends StatelessWidget {
  final AidType? value;
  final ValueChanged<AidType?> onChanged;
  final AppLocalizations l10n;
  const _AidTypeFilter({required this.value, required this.onChanged, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: DropdownButton<AidType?>(
        value: value,
        underline: const SizedBox(),
        isDense: true,
        hint: Text(l10n.tr('all'), style: GoogleFonts.cairo(fontSize: 13)),
        items: [
          DropdownMenuItem(value: null, child: Text(l10n.tr('all'), style: GoogleFonts.cairo(fontSize: 13))),
          ...AidType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.labelAr, style: GoogleFonts.cairo(fontSize: 13)))),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
