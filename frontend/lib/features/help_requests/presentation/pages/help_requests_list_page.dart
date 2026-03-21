import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/help_requests/domain/entities/help_request.dart';
import 'package:charity_app/features/help_requests/domain/entities/request_status.dart';
import 'package:charity_app/features/help_requests/domain/entities/request_type.dart';
import 'package:charity_app/features/help_requests/domain/entities/urgency_level.dart';
import 'package:charity_app/features/help_requests/providers/help_requests_provider.dart';
import 'package:charity_app/features/help_requests/providers/location_provider.dart';
import 'package:charity_app/features/help_requests/widgets/help_request_card.dart';
import 'package:charity_app/features/help_requests/widgets/request_status_badge.dart';
import 'package:charity_app/features/help_requests/widgets/edit_window_indicator.dart';
import 'package:charity_app/shared/widgets/app_search_bar.dart';
import 'package:charity_app/shared/widgets/empty_state_widget.dart';

class HelpRequestsListPage extends ConsumerWidget {
  const HelpRequestsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(helpRequestsProvider);

    // ── Count helpers (scoped to active date if set) ──────────────────────────
    final scope =
        state.dateFilter != null ? state.filtered : state.all;
    final pendingCount =
        scope.where((r) => r.status == RequestStatus.pending).length;
    final underReviewCount =
        scope.where((r) => r.status == RequestStatus.underReview).length;
    final approvedCount =
        scope.where((r) => r.status == RequestStatus.approved).length;
    final completedCount =
        scope.where((r) => r.status == RequestStatus.completed).length;
    final rejectedCount =
        scope.where((r) => r.status == RequestStatus.rejected).length;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : const Color(0xFFF5F7FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Date banner (when date filter is active) ──────────────────────
          if (state.dateFilter != null)
            SliverToBoxAdapter(
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.12),
                      AppColors.primary.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(Icons.calendar_today_rounded,
                          size: 14, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'عرض طلبات يوم',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            intl.DateFormat('EEEE، dd MMMM yyyy', 'ar')
                                .format(state.dateFilter!),
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${state.filtered.length} طلب',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Stats cards ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 0, 0),
              child: SizedBox(
                height: 96,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.only(right: 16),
                  children: [
                    _StatCard(
                      label: 'الإجمالي',
                      value: '${scope.length}',
                      gradient: AppColors.gradientBlue,
                      glowColor: const Color(0xFF3B82F6),
                      icon: Icons.list_alt_rounded,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      label: 'قيد الانتظار',
                      value: '$pendingCount',
                      gradient: AppColors.gradientOrange,
                      glowColor: const Color(0xFFF59E0B),
                      icon: Icons.hourglass_top_rounded,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      label: 'قيد المراجعة',
                      value: '$underReviewCount',
                      gradient: AppColors.gradientIndigo,
                      glowColor: const Color(0xFF6366F1),
                      icon: Icons.manage_search_rounded,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      label: 'تمت الموافقة',
                      value: '$approvedCount',
                      gradient: AppColors.gradientGreen,
                      glowColor: const Color(0xFF10B981),
                      icon: Icons.check_circle_rounded,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      label: 'مكتمل',
                      value: '$completedCount',
                      gradient: AppColors.gradientTeal,
                      glowColor: const Color(0xFF00C9A7),
                      icon: Icons.verified_rounded,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      label: 'مرفوض',
                      value: '$rejectedCount',
                      gradient: AppColors.gradientRed,
                      glowColor: const Color(0xFFEF4444),
                      icon: Icons.cancel_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Search + Filters ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                children: [
                  // Search
                  AppSearchBar(
                    hint: 'بحث في الطلبات...',
                    onChanged: (q) =>
                        ref.read(helpRequestsProvider.notifier).search(q),
                    showFilterButton: false,
                  ),
                  const SizedBox(height: 10),

                  // Status chips row
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterChip(
                          label: 'الكل',
                          isSelected: state.statusFilter == null &&
                              state.typeFilter == null,
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
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // ── Count + Type + Date filters bar ──────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _FiltersBarDelegate(
              isDark: isDark,
              child: _FiltersBar(isDark: isDark, state: state, ref: ref),
            ),
          ),

          // ── List ──────────────────────────────────────────────────────────
          state.filtered.isEmpty
              ? const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateWidget(
                    icon: Icons.inbox_outlined,
                    title: 'لا توجد طلبات',
                    subtitle: 'اضغط على "طلب جديد" لتقديم طلب مساعدة',
                  ),
                )
              : SliverList.builder(
                  itemCount: state.filtered.length + 1,
                  itemBuilder: (context, index) {
                    if (index == state.filtered.length) {
                      return const SizedBox(height: 100);
                    }
                    final request = state.filtered[index];
                    return HelpRequestCard(
                      request: request,
                      onTap: () =>
                          _showRequestBottomSheet(context, request, isDark),
                      onEditTap: request.isEditable
                          ? () =>
                              context.push('/help-requests/${request.id}/edit')
                          : null,
                    );
                  },
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(locationProvider.notifier).clearLocation();
          context.push('/help-requests/location');
        },
        backgroundColor: AppColors.primary,
        elevation: 4,
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

// ── Pinned filters bar delegate ───────────────────────────────────────────────

class _FiltersBarDelegate extends SliverPersistentHeaderDelegate {
  final bool isDark;
  final Widget child;

  _FiltersBarDelegate({required this.isDark, required this.child});

  @override
  double get minExtent => 50;
  @override
  double get maxExtent => 50;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? AppColors.backgroundDark : const Color(0xFFF5F7FA),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_FiltersBarDelegate old) =>
      old.isDark != isDark || old.child != child;
}

// ── Filters bar ───────────────────────────────────────────────────────────────

class _FiltersBar extends ConsumerWidget {
  final bool isDark;
  final HelpRequestsState state;
  final WidgetRef ref;

  const _FiltersBar(
      {required this.isDark, required this.state, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef _) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Result count
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceVariantDark
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
              ),
            ),
            child: Text(
              '${state.filtered.length} طلب',
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
          const Spacer(),

          // Clear filters button (visible when any filter is active)
          if (state.statusFilter != null ||
              state.typeFilter != null ||
              state.dateFilter != null) ...[
            GestureDetector(
              onTap: () =>
                  ref.read(helpRequestsProvider.notifier).clearAllFilters(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.filter_alt_off_rounded,
                        size: 12, color: Color(0xFFEF4444)),
                    const SizedBox(width: 4),
                    Text(
                      'مسح',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Date filter button
          _DateFilterButton(
            selectedDate: state.dateFilter,
            isDark: isDark,
            onDateSelected: (d) =>
                ref.read(helpRequestsProvider.notifier).filterByDate(d),
          ),
          const SizedBox(width: 8),

          // Type filter button
          _TypeFilterButton(
            selected: state.typeFilter,
            isDark: isDark,
            onChanged: (t) =>
                ref.read(helpRequestsProvider.notifier).filterByType(t),
          ),
        ],
      ),
    );
  }
}

// ── Date filter button ────────────────────────────────────────────────────────

class _DateFilterButton extends StatelessWidget {
  final DateTime? selectedDate;
  final bool isDark;
  final void Function(DateTime?) onDateSelected;

  const _DateFilterButton({
    required this.selectedDate,
    required this.isDark,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = selectedDate != null;
    final label = hasDate
        ? intl.DateFormat('dd/MM/yyyy').format(selectedDate!)
        : 'التاريخ';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: AppColors.primary,
                    brightness: Theme.of(context).brightness,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) onDateSelected(picked);
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: hasDate
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : isDark
                      ? AppColors.surfaceVariantDark
                      : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(10),
                bottomLeft: const Radius.circular(10),
                topRight:
                    Radius.circular(hasDate ? 0 : 10),
                bottomRight:
                    Radius.circular(hasDate ? 0 : 10),
              ),
              border: Border.all(
                color: hasDate
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
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: hasDate
                      ? AppColors.primary
                      : isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: hasDate
                        ? AppColors.primary
                        : isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasDate)
          GestureDetector(
            onTap: () => onDateSelected(null),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 7, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                border: Border(
                  top: BorderSide(color: AppColors.primary),
                  bottom: BorderSide(color: AppColors.primary),
                  right: BorderSide(color: AppColors.primary),
                ),
              ),
              child: Icon(Icons.close_rounded,
                  size: 13, color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final LinearGradient gradient;
  final Color glowColor;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.gradient,
    required this.glowColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: -3,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
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
                  child: Icon(icon, size: 15, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontSize: 24,
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
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : isDark
                    ? AppColors.surfaceVariantDark
                    : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
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
      color: isDark ? AppColors.cardDark : Colors.white,
      elevation: 4,
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
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected != null
              ? AppColors.primary.withValues(alpha: 0.1)
              : isDark
                  ? AppColors.surfaceVariantDark
                  : Colors.white,
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
                fontWeight: FontWeight.w600,
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
    // Pass only the ID so the sheet always reads fresh state from provider
    builder: (_) =>
        _RequestBottomSheet(requestId: request.id, isDark: isDark),
  );
}

class _RequestBottomSheet extends ConsumerWidget {
  final String requestId;
  final bool isDark;

  const _RequestBottomSheet(
      {required this.requestId, required this.isDark});

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

  static Color _urgencyColor(UrgencyLevel u) => switch (u) {
        UrgencyLevel.critical => const Color(0xFFEF4444),
        UrgencyLevel.high => const Color(0xFFF59E0B),
        UrgencyLevel.medium => const Color(0xFF3B82F6),
        UrgencyLevel.low => const Color(0xFF10B981),
      };

  static const _statusOptions = [
    (RequestStatus.pending, 'قيد الانتظار', Color(0xFFF59E0B),
        Icons.hourglass_top_rounded),
    (RequestStatus.underReview, 'قيد المراجعة', Color(0xFF6366F1),
        Icons.manage_search_rounded),
    (RequestStatus.approved, 'تمت الموافقة', Color(0xFF10B981),
        Icons.check_circle_rounded),
    (RequestStatus.rejected, 'مرفوض', Color(0xFFEF4444),
        Icons.cancel_rounded),
    (RequestStatus.completed, 'مكتمل', Color(0xFF00C9A7),
        Icons.verified_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── Always read fresh state → live updates after status change ──────────
    final providerState = ref.watch(helpRequestsProvider);
    final request = [
      ...providerState.all,
      ...providerState.filtered,
    ].fold<HelpRequest?>(
      null,
      (found, r) => found ?? (r.id == requestId ? r : null),
    );
    if (request == null) return const SizedBox.shrink();

    final isPrivileged = providerState.isPrivileged;
    final (gradient, typeIcon) = _typeConfig(request.type);
    final urgColor = _urgencyColor(request.urgency);
    final dateStr =
        intl.DateFormat('dd/MM/yyyy  HH:mm').format(request.submittedAt);
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);
    final cardBorder =
        isDark ? AppColors.borderDark : const Color(0xFFE8ECF0);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        color: isDark ? AppColors.surfaceDark : Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Gradient Hero Header ─────────────────────────────────────
            Container(
              decoration: BoxDecoration(gradient: gradient),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // drag handle
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Type icon circle
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  width: 1.5),
                            ),
                            child: Icon(typeIcon,
                                color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    request.type.labelAr,
                                    style: GoogleFonts.cairo(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  request.title,
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1.25,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Scrollable body ──────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    16, 18, 16, 16 + MediaQuery.of(context).padding.bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status + urgency row
                    Row(
                      children: [
                        RequestStatusBadge(status: request.status),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: urgColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: urgColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flag_rounded,
                                  size: 12, color: urgColor),
                              const SizedBox(width: 4),
                              Text(
                                request.urgency.labelAr,
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: urgColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (request.familySize != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.group_rounded,
                                    size: 12,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight),
                                const SizedBox(width: 4),
                                Text(
                                  '${request.familySize} أفراد',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Info card
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        children: [
                          _SheetInfoTile(
                            icon: Icons.person_outline_rounded,
                            title: 'مقدم الطلب',
                            value: request.fullName,
                            accent: gradient.colors.first,
                            isDark: isDark,
                            isFirst: true,
                          ),
                          _SheetInfoTile(
                            icon: Icons.location_on_outlined,
                            title: 'الموقع',
                            value: '${request.governorate} — ${request.area}',
                            accent: gradient.colors.first,
                            isDark: isDark,
                          ),
                          _SheetInfoTile(
                            icon: Icons.access_time_rounded,
                            title: 'تاريخ التقديم',
                            value: dateStr,
                            accent: gradient.colors.first,
                            isDark: isDark,
                          ),
                          if (request.attachments.isNotEmpty)
                            _SheetInfoTile(
                              icon: Icons.attach_file_rounded,
                              title: 'المرفقات',
                              value:
                                  '${request.attachments.length} ملف مرفق',
                              accent: gradient.colors.first,
                              isDark: isDark,
                              isLast: true,
                            )
                          else
                            const SizedBox.shrink(),
                        ],
                      ),
                    ),

                    // Description card
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              width: 3,
                              height: 14,
                              decoration: BoxDecoration(
                                color: gradient.colors.first,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'وصف الطلب',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: gradient.colors.first,
                              ),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Text(
                            request.description,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                              height: 1.65,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Edit window — beneficiary only
                    if (!isPrivileged) ...[
                      const SizedBox(height: 10),
                      EditWindowIndicator(
                        request: request,
                        onEditTap: request.isEditable
                            ? () {
                                Navigator.pop(context);
                                context.push(
                                    '/help-requests/${request.id}/edit');
                              }
                            : null,
                      ),
                    ],

                    // ── Status update — privileged only ──────────────────
                    if (isPrivileged) ...[
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                width: 3,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'تغيير حالة الطلب',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'الحالة الحالية',
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(width: 6),
                              RequestStatusBadge(
                                  status: request.status, compact: true),
                            ]),
                            const SizedBox(height: 12),
                            GridView.count(
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 2.1,
                              children: _statusOptions.map((opt) {
                                final (
                                  status,
                                  label,
                                  color,
                                  sIcon
                                ) = opt;
                                final isCurrent =
                                    request.status == status;
                                return GestureDetector(
                                  onTap: isCurrent
                                      ? null
                                      : () => ref
                                          .read(helpRequestsProvider
                                              .notifier)
                                          .updateStatus(
                                              request.id, status),
                                  child: AnimatedContainer(
                                    duration: const Duration(
                                        milliseconds: 200),
                                    curve: Curves.easeOut,
                                    decoration: BoxDecoration(
                                      color: isCurrent
                                          ? color
                                          : color.withValues(alpha: 0.08),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isCurrent
                                            ? color
                                            : color.withValues(alpha: 0.25),
                                        width: isCurrent ? 1.5 : 1,
                                      ),
                                      boxShadow: isCurrent
                                          ? [
                                              BoxShadow(
                                                color: color.withValues(
                                                    alpha: 0.3),
                                                blurRadius: 8,
                                                offset:
                                                    const Offset(0, 3),
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isCurrent
                                              ? Icons.check_circle_rounded
                                              : sIcon,
                                          size: 14,
                                          color: isCurrent
                                              ? Colors.white
                                              : color,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          label,
                                          style: GoogleFonts.cairo(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: isCurrent
                                                ? Colors.white
                                                : color,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Action button ────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: gradient.colors.first
                                  .withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.push('/help-requests/${request.id}');
                          },
                          style: TextButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'عرض التفاصيل الكاملة',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_ios_rounded,
                                  size: 13, color: Colors.white),
                            ],
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
      ),
    );
  }
}

// ── Sheet info tile ───────────────────────────────────────────────────────────

class _SheetInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color accent;
  final bool isDark;
  final bool isFirst;
  final bool isLast;

  const _SheetInfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.accent,
    required this.isDark,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final dividerColor =
        isDark ? AppColors.borderDark : const Color(0xFFE8ECF0);
    return Column(
      children: [
        if (!isFirst)
          Divider(height: 1, thickness: 1, color: dividerColor, indent: 44),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 15, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
