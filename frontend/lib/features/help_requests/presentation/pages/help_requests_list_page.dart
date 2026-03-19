import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/help_requests/domain/entities/help_request.dart';
import 'package:charity_app/features/help_requests/domain/entities/request_status.dart';
import 'package:charity_app/features/help_requests/domain/entities/request_type.dart';
import 'package:charity_app/features/help_requests/providers/help_requests_provider.dart';
import 'package:charity_app/features/help_requests/providers/location_provider.dart';
import 'package:charity_app/features/help_requests/widgets/help_request_card.dart';
import 'package:charity_app/features/help_requests/widgets/request_status_badge.dart';
import 'package:charity_app/features/help_requests/widgets/edit_window_indicator.dart';
import 'package:charity_app/shared/widgets/section_header.dart';
import 'package:charity_app/shared/widgets/app_search_bar.dart';
import 'package:charity_app/shared/widgets/empty_state_widget.dart';

class HelpRequestsListPage extends ConsumerWidget {
  const HelpRequestsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(helpRequestsProvider);

    final pendingCount =
        state.all.where((r) => r.status == RequestStatus.pending).length;
    final underReviewCount =
        state.all.where((r) => r.status == RequestStatus.underReview).length;
    final approvedCount =
        state.all.where((r) => r.status == RequestStatus.approved).length;
    final completedCount =
        state.all.where((r) => r.status == RequestStatus.completed).length;
    final rejectedCount =
        state.all.where((r) => r.status == RequestStatus.rejected).length;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          // ── Header section ────────────────────────────────────────────────
          Container(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  title: 'طلبات المساعدة',
                  subtitle: 'إدارة ومتابعة طلبات الدعم',
                ),
                const SizedBox(height: 14),

                // ── Summary cards ─────────────────────────────────────────
                SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _SummaryCard(
                        label: 'الإجمالي',
                        value: '${state.all.length}',
                        gradient: AppColors.gradientBlue,
                        glowColor: const Color(0xFF3B82F6),
                        icon: Icons.list_alt_rounded,
                      ),
                      const SizedBox(width: 10),
                      _SummaryCard(
                        label: 'قيد الانتظار',
                        value: '$pendingCount',
                        gradient: AppColors.gradientOrange,
                        glowColor: const Color(0xFFF59E0B),
                        icon: Icons.hourglass_top_rounded,
                      ),
                      const SizedBox(width: 10),
                      _SummaryCard(
                        label: 'قيد المراجعة',
                        value: '$underReviewCount',
                        gradient: AppColors.gradientIndigo,
                        glowColor: const Color(0xFF6366F1),
                        icon: Icons.manage_search_rounded,
                      ),
                      const SizedBox(width: 10),
                      _SummaryCard(
                        label: 'تمت الموافقة',
                        value: '$approvedCount',
                        gradient: AppColors.gradientGreen,
                        glowColor: const Color(0xFF10B981),
                        icon: Icons.check_circle_rounded,
                      ),
                      const SizedBox(width: 10),
                      _SummaryCard(
                        label: 'مكتمل',
                        value: '$completedCount',
                        gradient: AppColors.gradientTeal,
                        glowColor: const Color(0xFF00C9A7),
                        icon: Icons.verified_rounded,
                      ),
                      const SizedBox(width: 10),
                      _SummaryCard(
                        label: 'مرفوض',
                        value: '$rejectedCount',
                        gradient: AppColors.gradientRed,
                        glowColor: const Color(0xFFEF4444),
                        icon: Icons.cancel_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Search bar ────────────────────────────────────────────
                AppSearchBar(
                  hint: 'بحث في الطلبات...',
                  onChanged: (q) =>
                      ref.read(helpRequestsProvider.notifier).search(q),
                  showFilterButton: false,
                ),
                const SizedBox(height: 10),

                // ── Status filter chips ───────────────────────────────────
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: 'الكل',
                        isSelected:
                            state.statusFilter == null && state.typeFilter == null,
                        isDark: isDark,
                        onTap: () => ref
                            .read(helpRequestsProvider.notifier)
                            .clearAllFilters(),
                      ),
                      const SizedBox(width: 6),
                      ...RequestStatus.values.map((s) => Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _FilterChip(
                              label: s.labelAr,
                              isSelected: state.statusFilter == s,
                              isDark: isDark,
                              onTap: () => ref
                                  .read(helpRequestsProvider.notifier)
                                  .filterByStatus(
                                      state.statusFilter == s ? null : s),
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // ── Count + type filter bar ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${state.filtered.length} طلب',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const Spacer(),
                _TypeFilterButton(
                  selected: state.typeFilter,
                  isDark: isDark,
                  onChanged: (t) =>
                      ref.read(helpRequestsProvider.notifier).filterByType(t),
                ),
              ],
            ),
          ),

          // ── List ──────────────────────────────────────────────────────────
          Expanded(
            child: state.filtered.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.inbox_outlined,
                    title: 'لا توجد طلبات',
                    subtitle: 'اضغط على "طلب جديد" لتقديم طلب مساعدة',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80, top: 4),
                    itemCount: state.filtered.length,
                    itemBuilder: (context, index) {
                      final request = state.filtered[index];
                      return HelpRequestCard(
                        request: request,
                        onTap: () =>
                            _showRequestBottomSheet(context, request, isDark),
                        onEditTap: request.isEditable
                            ? () => context
                                .push('/help-requests/${request.id}/edit')
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(locationProvider.notifier).clearLocation();
          context.push('/help-requests/location');
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'طلب جديد',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Summary card (same style as other pages) ──────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final LinearGradient gradient;
  final Color glowColor;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.gradient,
    required this.glowColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.35),
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
                    fontSize: 22,
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

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariantLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Type filter button ────────────────────────────────────────────────────────

class _TypeFilterButton extends StatelessWidget {
  final RequestType? selected;
  final bool isDark;
  final void Function(RequestType?) onChanged;

  const _TypeFilterButton({
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<RequestType?>(
      initialValue: selected,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: null,
          child: Text('كل الأنواع', style: GoogleFonts.cairo(fontSize: 13)),
        ),
        ...RequestType.values.map(
          (t) => PopupMenuItem(
            value: t,
            child: Text(t.labelAr, style: GoogleFonts.cairo(fontSize: 13)),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected != null
              ? AppColors.primary.withValues(alpha: 0.1)
              : isDark
                  ? AppColors.surfaceVariantDark
                  : AppColors.surfaceVariantLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected != null
                ? AppColors.primary
                : isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_rounded,
              size: 14,
              color: selected != null
                  ? AppColors.primary
                  : isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
            ),
            const SizedBox(width: 4),
            Text(
              selected?.labelAr ?? 'النوع',
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: selected != null
                    ? AppColors.primary
                    : isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Sheet ──────────────────────────────────────────────────────────────

void _showRequestBottomSheet(
    BuildContext context, HelpRequest request, bool isDark) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RequestBottomSheet(request: request, isDark: isDark),
  );
}

class _RequestBottomSheet extends StatelessWidget {
  final HelpRequest request;
  final bool isDark;

  const _RequestBottomSheet({required this.request, required this.isDark});

  static (LinearGradient, IconData) _typeConfig(RequestType t) {
    switch (t) {
      case RequestType.generalHelp:
        return (AppColors.gradientPurple, Icons.volunteer_activism_rounded);
      case RequestType.doctorBooking:
        return (AppColors.gradientTeal, Icons.medical_services_rounded);
      case RequestType.treatment:
        return (AppColors.gradientBlue, Icons.medication_rounded);
      case RequestType.foodBasket:
        return (AppColors.gradientGreen, Icons.shopping_basket_rounded);
      case RequestType.financial:
        return (AppColors.gradientOrange, Icons.account_balance_wallet_rounded);
      case RequestType.householdMaterials:
        return (AppColors.gradientIndigo, Icons.chair_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (gradient, icon) = _typeConfig(request.type);
    final dateStr =
        intl.DateFormat('dd/MM/yyyy  HH:mm').format(request.submittedAt);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Gradient header strip
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gradient.colors.first.withValues(alpha: 0.12),
                  gradient.colors.last.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: gradient.colors.first.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.type.labelAr,
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: gradient.colors.first,
                        ),
                      ),
                      Text(
                        request.title,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                RequestStatusBadge(status: request.status),
              ],
            ),
          ),

          // Info rows
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  label: request.fullName,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: '${request.governorate} — ${request.area}',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.access_time_rounded,
                  label: dateStr,
                  isDark: isDark,
                ),
                if (request.attachments.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.attach_file_rounded,
                    label: '${request.attachments.length} مرفقات',
                    isDark: isDark,
                    color: AppColors.primary,
                  ),
                ],
              ],
            ),
          ),

          // Edit window
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: EditWindowIndicator(
              request: request,
              onEditTap: request.isEditable
                  ? () {
                      Navigator.pop(context);
                      context.push('/help-requests/${request.id}/edit');
                    }
                  : null,
            ),
          ),

          // Action buttons
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 14, 16, 16 + MediaQuery.of(context).padding.bottom),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'إغلاق',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.colors.first.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/help-requests/${request.id}');
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'عرض التفاصيل',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 12, color: Colors.white),
                        ],
                      ),
                    ),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Color? color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.isDark,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ??
        (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);
    return Row(
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.cairo(fontSize: 12, color: c),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
