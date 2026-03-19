import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/core/localization/app_localizations.dart';
import 'package:charity_app/shared/models/log_model.dart';
import 'package:charity_app/shared/widgets/app_search_bar.dart';
import 'package:charity_app/shared/widgets/section_header.dart';
import 'package:charity_app/shared/widgets/activity_log_item.dart';
import 'package:charity_app/shared/widgets/empty_state_widget.dart';
import 'package:charity_app/features/logs/presentation/providers/logs_provider.dart';
class LogsPage extends ConsumerWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(logsProvider);
    final notifier = ref.read(logsProvider.notifier);

    final todayCount = notifier.todayCount;
    final addCount = state.all.where((l) => l.actionType == LogActionType.add).length;
    final editCount = state.all.where((l) => l.actionType == LogActionType.edit).length;
    final approveCount = state.all.where((l) => l.actionType == LogActionType.approve || l.actionType == LogActionType.distribute).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : AppColors.surfaceLight,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: l10n.tr('operations_log'),
                subtitle: 'سجل حميع عمليات النظام',
                actions: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.file_download_outlined, size: 16),
                    label: Text(l10n.tr('export'), style: GoogleFonts.cairo(fontSize: 13)),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Summary cards
              SizedBox(
                height: 74,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _LogSummaryCard(label: l10n.tr('total_operations'), value: '${state.all.length}', color: AppColors.kpiBlue.first, icon: Icons.receipt_long_rounded),
                    const SizedBox(width: 8),
                    _LogSummaryCard(label: l10n.tr('operations_today'), value: '$todayCount', color: AppColors.kpiGreen.first, icon: Icons.today_rounded),
                    const SizedBox(width: 8),
                    _LogSummaryCard(label: 'إضافات', value: '$addCount', color: AppColors.logAdd, icon: Icons.add_circle_outline_rounded),
                    const SizedBox(width: 8),
                    _LogSummaryCard(label: 'تعديلات', value: '$editCount', color: AppColors.logEdit, icon: Icons.edit_outlined),
                    const SizedBox(width: 8),
                    _LogSummaryCard(label: 'اعتمادات', value: '$approveCount', color: AppColors.logApprove, icon: Icons.check_circle_outline_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Search + filter
              Row(
                children: [
                  Expanded(
                    child: AppSearchBar(
                      hint: l10n.tr('search_logs'),
                      onChanged: (q) => ref.read(logsProvider.notifier).search(q),
                      showFilterButton: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ActionTypeFilter(
                    value: state.actionTypeFilter,
                    onChanged: (t) => ref.read(logsProvider.notifier).filterByAction(t),
                    l10n: l10n,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),

        // Timeline list
        Expanded(
          child: state.filtered.isEmpty
              ? const EmptyStateWidget(icon: Icons.receipt_long_outlined, title: 'لا توجد سجلات', subtitle: 'لم يتم العثور على نتائج')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.filtered.length,
                  itemBuilder: (ctx, i) => ActivityLogItem(
                    log: state.filtered[i],
                    isLast: i == state.filtered.length - 1,
                  ),
                ),
        ),
      ],
    );
  }
}

class _LogSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _LogSummaryCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Expanded(child: Text(label, style: GoogleFonts.cairo(fontSize: 10, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _ActionTypeFilter extends StatelessWidget {
  final LogActionType? value;
  final ValueChanged<LogActionType?> onChanged;
  final AppLocalizations l10n;
  const _ActionTypeFilter({required this.value, required this.onChanged, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visibleTypes = [LogActionType.add, LogActionType.edit, LogActionType.delete, LogActionType.approve, LogActionType.reject, LogActionType.distribute];
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: DropdownButton<LogActionType?>(
        value: value,
        underline: const SizedBox(),
        isDense: true,
        hint: Text(l10n.tr('all'), style: GoogleFonts.cairo(fontSize: 13)),
        items: [
          DropdownMenuItem(value: null, child: Text(l10n.tr('all'), style: GoogleFonts.cairo(fontSize: 13))),
          ...visibleTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.labelAr, style: GoogleFonts.cairo(fontSize: 13)))),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
