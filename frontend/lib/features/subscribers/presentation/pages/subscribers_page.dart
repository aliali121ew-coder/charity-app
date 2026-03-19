import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/shared/models/family_model.dart';
import 'package:charity_app/features/families/data/mock_families_repository.dart';

// ── Rating helpers ─────────────────────────────────────────────────────────────
String _familyRating(IncomeLevel level) {
  switch (level) {
    case IncomeLevel.veryLow:
      return 'ضعيف';
    case IncomeLevel.low:
      return 'متوسط';
    case IncomeLevel.medium:
      return 'ممتاز';
    case IncomeLevel.aboveAverage:
      return 'ممتاز';
  }
}

Color _ratingColor(IncomeLevel level) {
  switch (level) {
    case IncomeLevel.veryLow:
      return AppColors.error;
    case IncomeLevel.low:
      return AppColors.warning;
    case IncomeLevel.medium:
      return AppColors.success;
    case IncomeLevel.aboveAverage:
      return AppColors.success;
  }
}

Color _statusHeaderColor(FamilyStatus status) {
  switch (status) {
    case FamilyStatus.eligible:
      return const Color(0xFF10B981);
    case FamilyStatus.ineligible:
      return const Color(0xFFEF4444);
    case FamilyStatus.pending:
      return const Color(0xFFF59E0B);
    case FamilyStatus.suspended:
      return const Color(0xFF64748B);
  }
}


String _occupation(FamilyModel f) {
  if (f.maritalStatus == MaritalStatus.widowed) return 'أرمل/ة';
  if (f.maritalStatus == MaritalStatus.divorced) return 'مطلق/ة';
  switch (f.incomeLevel) {
    case IncomeLevel.veryLow:
      return 'عاطل';
    case IncomeLevel.low:
      return 'يومي';
    case IncomeLevel.medium:
      return 'موظف';
    case IncomeLevel.aboveAverage:
      return 'متقاعد';
  }
}

// ── Page ──────────────────────────────────────────────────────────────────────
class SubscribersPage extends ConsumerStatefulWidget {
  const SubscribersPage({super.key});

  @override
  ConsumerState<SubscribersPage> createState() => _SubscribersPageState();
}

class _SubscribersPageState extends ConsumerState<SubscribersPage> {
  final _repo = MockFamiliesRepository();
  final _searchController = TextEditingController();
  FamilyStatus? _statusFilter;
  String _searchQuery = '';
  late List<FamilyModel> _localFamilies;

  @override
  void initState() {
    super.initState();
    _localFamilies = _repo.getAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FamilyModel> get _filtered {
    var list = List<FamilyModel>.from(_localFamilies);
    if (_statusFilter != null) {
      list = list.where((f) => f.status == _statusFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((f) =>
              f.headName.toLowerCase().contains(q) ||
              f.area.toLowerCase().contains(q) ||
              f.address.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  void _updateFamily(FamilyModel updated) {
    setState(() {
      final idx = _localFamilies.indexWhere((f) => f.id == updated.id);
      if (idx != -1) _localFamilies[idx] = updated;
    });
  }

  void _showFamilyView(BuildContext context, FamilyModel family, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FamilyViewSheet(family: family, isDark: isDark),
    );
  }

  void _showFamilyEdit(BuildContext context, FamilyModel family, bool isDark) async {
    final updated = await showModalBottomSheet<FamilyModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FamilyEditSheet(family: family, isDark: isDark),
    );
    if (updated != null) _updateFamily(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final all = _localFamilies;
    final eligibleCount = all.where((f) => f.status == FamilyStatus.eligible).length;
    final totalMembers = all.fold<int>(0, (sum, f) => sum + f.membersCount);
    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ───────────────────────────────────────────────────────────
        _PageHeader(
          isDark: isDark,
          totalFamilies: all.length,
          eligibleCount: eligibleCount,
          totalMembers: totalMembers,
          searchController: _searchController,
          statusFilter: _statusFilter,
          onSearch: (q) => setState(() => _searchQuery = q),
          onStatusFilter: (s) => setState(() => _statusFilter = s),
          onAddFamily: () => _showAddFamilySheet(context, isDark),
        ),

        // ── Grid / List ──────────────────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? _EmptyState(isDark: isDark)
              : LayoutBuilder(builder: (ctx, cst) {
                  final cols = _crossAxisCount(context);
                  if (cols == 1) {
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
                      itemCount: filtered.length,
                      itemBuilder: (c, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _FamilyCard(
                          family: filtered[i],
                          isDark: isDark,
                          single: true,
                          onView: () => _showFamilyView(context, filtered[i], isDark),
                          onEdit: () => _showFamilyEdit(context, filtered[i], isDark),
                        ),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (c, i) => _FamilyCard(
                      family: filtered[i],
                      isDark: isDark,
                      single: false,
                      onView: () => _showFamilyView(context, filtered[i], isDark),
                      onEdit: () => _showFamilyEdit(context, filtered[i], isDark),
                    ),
                  );
                }),
        ),
      ],
    );
  }

  int _crossAxisCount(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w > 1000) return 4;
    if (w > 700) return 3;
    if (w > 560) return 2;
    return 1;
  }

  void _showAddFamilySheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddFamilySheet(isDark: isDark),
    );
  }
}

// ── Page Header ───────────────────────────────────────────────────────────────
class _PageHeader extends StatelessWidget {
  final bool isDark;
  final int totalFamilies;
  final int eligibleCount;
  final int totalMembers;
  final TextEditingController searchController;
  final FamilyStatus? statusFilter;
  final ValueChanged<String> onSearch;
  final ValueChanged<FamilyStatus?> onStatusFilter;
  final VoidCallback onAddFamily;

  const _PageHeader({
    required this.isDark,
    required this.totalFamilies,
    required this.eligibleCount,
    required this.totalMembers,
    required this.searchController,
    required this.statusFilter,
    required this.onSearch,
    required this.onStatusFilter,
    required this.onAddFamily,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'بيانات العوائل',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      'إدارة ومتابعة بيانات العوائل المستفيدة',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onAddFamily,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPurple,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        'إضافة عائلة',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'إجمالي العوائل',
                  value: '$totalFamilies',
                  icon: Icons.home_rounded,
                  gradient: AppColors.gradientPurple,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'العوائل المؤهلة',
                  value: '$eligibleCount',
                  icon: Icons.check_circle_rounded,
                  gradient: AppColors.gradientGreen,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'إجمالي الأفراد',
                  value: '$totalMembers',
                  icon: Icons.people_rounded,
                  gradient: AppColors.gradientBlue,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search + filter row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearch,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                    decoration: InputDecoration(
                      hintText: 'بحث عن عائلة...',
                      hintStyle: GoogleFonts.cairo(
                        fontSize: 13,
                        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusFilterDropdown(
                value: statusFilter,
                onChanged: onStatusFilter,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final LinearGradient gradient;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 9,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Filter Dropdown ─────────────────────────────────────────────────────
class _StatusFilterDropdown extends StatelessWidget {
  final FamilyStatus? value;
  final ValueChanged<FamilyStatus?> onChanged;
  final bool isDark;

  const _StatusFilterDropdown({
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FamilyStatus?>(
          value: value,
          isDense: true,
          hint: Text(
            'الكل',
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          dropdownColor: isDark ? AppColors.cardDark : AppColors.cardLight,
          items: [
            DropdownMenuItem(
              value: null,
              child: Text('الكل', style: GoogleFonts.cairo(fontSize: 12)),
            ),
            ...FamilyStatus.values.map(
              (s) => DropdownMenuItem(
                value: s,
                child: Text(s.labelAr, style: GoogleFonts.cairo(fontSize: 12)),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Family Card ───────────────────────────────────────────────────────────────
class _FamilyCard extends StatelessWidget {
  final FamilyModel family;
  final bool isDark;
  final bool single;
  final VoidCallback? onView;
  final VoidCallback? onEdit;

  const _FamilyCard({required this.family, required this.isDark, this.single = false, this.onView, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return single ? _buildHorizontal(context) : _buildVertical(context);
  }

  // ── Horizontal card (single column) ──────────────────────────────────────
  Widget _buildHorizontal(BuildContext context) {
    const gradient = LinearGradient(
      colors: [Color(0xFF6D28D9), Color(0xFF4F46E5)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    );
    const accentColor = Color(0xFF6D28D9);
    final rating = _familyRating(family.incomeLevel);
    final ratingColor = _ratingColor(family.incomeLevel);
    final occupation = _occupation(family);
    final initials = _initials();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: isDark ? 0.25 : 0.14)),
        boxShadow: [
          BoxShadow(color: accentColor.withValues(alpha: isDark ? 0.18 : 0.1),
              blurRadius: 14, spreadRadius: -3, offset: const Offset(0, 6)),
          if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left gradient panel ──────────────────────────────────
              Container(
                width: 88,
                decoration: const BoxDecoration(gradient: gradient),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.25),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 2),
                      ),
                      child: Center(child: Text(initials,
                          style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white))),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: ratingColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                      ),
                      child: Text(rating, style: GoogleFonts.cairo(
                          fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ],
                ),
              ),

              // ── Right content ────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + status chip
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 12, 6),
                      child: Row(
                        children: [
                          Expanded(child: Text(family.headName,
                              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w900,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                              maxLines: 1, overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 6),
                          _StatusChipWidget(status: family.status),
                        ],
                      ),
                    ),

                    // Info grid 2-per-row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        children: [
                          Row(children: [
                            Expanded(child: _InfoChip(icon: Icons.calendar_today_rounded,
                                text: DateFormat('dd/MM/yy').format(family.registrationDate), isDark: isDark)),
                            Expanded(child: _InfoChip(icon: Icons.people_rounded,
                                text: '${family.membersCount} أفراد', isDark: isDark)),
                          ]),
                          const SizedBox(height: 6),
                          Row(children: [
                            Expanded(child: _InfoChip(icon: Icons.location_on_rounded,
                                text: family.area, isDark: isDark)),
                            Expanded(child: _InfoChip(icon: Icons.work_rounded,
                                text: occupation, isDark: isDark)),
                          ]),
                          const SizedBox(height: 6),
                          _InfoChip(icon: Icons.volunteer_activism_rounded,
                              text: 'إجمالي المساعدات: ${_formatAmount(family.totalAidAmount)}',
                              isDark: isDark, valueColor: AppColors.success, fullWidth: true),
                        ],
                      ),
                    ),

                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 12, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _ActionBtn(icon: Icons.visibility_rounded, color: AppColors.info, onTap: onView),
                          const SizedBox(width: 8),
                          _ActionBtn(icon: Icons.edit_rounded, color: AppColors.success, onTap: onEdit),
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
    );
  }

  // ── Vertical card (multi-column grid) ────────────────────────────────────
  Widget _buildVertical(BuildContext context) {
    const gradient = LinearGradient(
      colors: [Color(0xFF6D28D9), Color(0xFF4F46E5)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    );
    const accentColor = Color(0xFF6D28D9);
    final rating = _familyRating(family.incomeLevel);
    final ratingColor = _ratingColor(family.incomeLevel);
    final occupation = _occupation(family);
    final initials = _initials();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: isDark ? 0.22 : 0.12)),
        boxShadow: [
          BoxShadow(color: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
              blurRadius: 14, spreadRadius: -4, offset: const Offset(0, 6)),
          if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gradient header
            Container(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              decoration: const BoxDecoration(gradient: gradient),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.25),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.5),
                  ),
                  child: Center(child: Text(initials,
                      style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white))),
                ),
                const SizedBox(width: 9),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(family.headName,
                      style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ratingColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Text(rating, style: GoogleFonts.cairo(
                        fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ])),
              ]),
            ),

            // Body
            Expanded(child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _CardInfoRow(icon: Icons.calendar_today_rounded,
                    text: DateFormat('dd/MM/yyyy').format(family.registrationDate), isDark: isDark),
                const SizedBox(height: 7),
                _CardInfoRow(icon: Icons.people_rounded,
                    text: '${family.membersCount} أفراد', isDark: isDark),
                const SizedBox(height: 7),
                _CardInfoRow(icon: Icons.location_on_rounded,
                    text: family.area, isDark: isDark),
                const SizedBox(height: 7),
                _CardInfoRow(icon: Icons.work_rounded,
                    text: occupation, isDark: isDark, label: 'العمل'),
                const SizedBox(height: 7),
                _CardInfoRow(icon: Icons.volunteer_activism_rounded,
                    text: _formatAmount(family.totalAidAmount),
                    isDark: isDark, label: 'المساعدات', valueColor: AppColors.success),
              ]),
            )),

            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatusChipWidget(status: family.status),
                  Row(children: [
                    _ActionBtn(icon: Icons.visibility_rounded, color: AppColors.info, onTap: onView),
                    const SizedBox(width: 6),
                    _ActionBtn(icon: Icons.edit_rounded, color: AppColors.success, onTap: onEdit),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials() => family.headName.trim().split(' ').take(2)
      .map((w) => w.isNotEmpty ? w[0] : '').join();

  String _formatAmount(double amount) {
    if (amount == 0) return 'لا يوجد';
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)} م.د';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K د.ع';
    return '${amount.toStringAsFixed(0)} د.ع';
  }
}

// ── Card Info Row ──────────────────────────────────────────────────────────────
class _CardInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  final String? label;
  final Color? valueColor;

  const _CardInfoRow({
    required this.icon,
    required this.text,
    required this.isDark,
    this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 13,
          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label != null)
                Text(
                  label!,
                  style: GoogleFonts.cairo(
                    fontSize: 9,
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                  ),
                ),
              Text(
                text,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: valueColor ??
                      (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Info Chip (used in horizontal card) ───────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  final Color? valueColor;
  final bool fullWidth;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.isDark,
    this.valueColor,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = valueColor ??
        (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);
    final iconColor = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
    return Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionBtn({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ── Status Chip ───────────────────────────────────────────────────────────────
class _StatusChipWidget extends StatelessWidget {
  final FamilyStatus status;

  const _StatusChipWidget({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;

    switch (status) {
      case FamilyStatus.eligible:
        bg = AppColors.statusActiveBg;
        text = AppColors.statusActiveText;
        break;
      case FamilyStatus.ineligible:
        bg = AppColors.statusRejectedBg;
        text = AppColors.statusRejectedText;
        break;
      case FamilyStatus.pending:
        bg = AppColors.statusPendingBg;
        text = AppColors.statusPendingText;
        break;
      case FamilyStatus.suspended:
        bg = AppColors.statusInactiveBg;
        text = AppColors.statusInactiveText;
        break;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      bg = bg.withValues(alpha: 0.15);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.labelAr,
        style: GoogleFonts.cairo(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.family_restroom_rounded,
            size: 64,
            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد عوائل',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'لم يتم العثور على نتائج مطابقة',
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Family View Sheet ─────────────────────────────────────────────────────────
class _FamilyViewSheet extends StatelessWidget {
  final FamilyModel family;
  final bool isDark;
  const _FamilyViewSheet({required this.family, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final rating = _familyRating(family.incomeLevel);
    final ratingColor = _ratingColor(family.incomeLevel);
    final statusColor = _statusHeaderColor(family.status);
    final initials = family.headName.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join();
    const cardGradient = LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF4F46E5)], begin: Alignment.topLeft, end: Alignment.bottomRight);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(children: [
          // Handle
          Center(child: Container(margin: const EdgeInsets.only(top: 10), width: 40, height: 4,
              decoration: BoxDecoration(color: isDark ? AppColors.borderDark : AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
          Expanded(
            child: SingleChildScrollView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Header card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(gradient: cardGradient, borderRadius: BorderRadius.circular(20)),
                  child: Column(children: [
                    // Avatar
                    Container(width: 72, height: 72,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.2),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2)),
                      child: Center(child: Text(initials, style: GoogleFonts.cairo(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white))),
                    ),
                    const SizedBox(height: 12),
                    Text(family.headName, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      // Status
                      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
                        child: Text(family.status.labelAr, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                      const SizedBox(width: 8),
                      // Rating
                      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: ratingColor.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
                        child: Text('تقييم: $rating', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    // Quick stats
                    Row(children: [
                      Expanded(child: _ViewStat(label: 'عدد الأفراد', value: '${family.membersCount}', icon: Icons.people_rounded)),
                      Expanded(child: _ViewStat(label: 'المساعدات', value: '${family.aidCount}', icon: Icons.volunteer_activism_rounded)),
                      Expanded(child: _ViewStat(label: 'إجمالي الصرف', value: family.totalAidAmount >= 1000 ? '${(family.totalAidAmount/1000).toStringAsFixed(0)}K' : family.totalAidAmount.toStringAsFixed(0), icon: Icons.payments_rounded)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 20),

                // Section: بيانات أساسية
                _ViewSection(title: 'البيانات الأساسية', isDark: isDark, children: [
                  _ViewRow(icon: Icons.location_on_rounded, label: 'المنطقة', value: family.area, isDark: isDark),
                  _ViewRow(icon: Icons.home_rounded, label: 'العنوان التفصيلي', value: family.address, isDark: isDark),
                  if (family.phone != null)
                    _ViewRow(icon: Icons.phone_rounded, label: 'رقم الهاتف', value: family.phone!, isDark: isDark),
                  _ViewRow(icon: Icons.calendar_today_rounded, label: 'تاريخ التسجيل', value: DateFormat('dd/MM/yyyy').format(family.registrationDate), isDark: isDark),
                ]),
                const SizedBox(height: 14),

                // Section: الحالة الاجتماعية
                _ViewSection(title: 'الحالة الاجتماعية والمالية', isDark: isDark, children: [
                  _ViewRow(icon: Icons.favorite_rounded, label: 'الحالة الاجتماعية', value: family.maritalStatus.labelAr, isDark: isDark),
                  _ViewRow(icon: Icons.trending_up_rounded, label: 'مستوى الدخل', value: family.incomeLevel.labelAr, isDark: isDark),
                  _ViewRow(icon: Icons.work_rounded, label: 'طبيعة العمل', value: _occupation(family), isDark: isDark),
                ]),
                const SizedBox(height: 14),

                // Notes
                if (family.notes != null && family.notes!.isNotEmpty) ...[
                  _ViewSection(title: 'ملاحظات', isDark: isDark, children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(family.notes!, style: GoogleFonts.cairo(fontSize: 13,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                    ),
                  ]),
                ],
              ]),
            ),
          ),
          // Close button
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(backgroundColor: isDark ? AppColors.cardDark : const Color(0xFFF1F5F9),
                    padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Text('إغلاق', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ViewStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _ViewStat({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.85)),
    const SizedBox(height: 4),
    Text(value, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
    Text(label, style: GoogleFonts.cairo(fontSize: 9, color: Colors.white.withValues(alpha: 0.7))),
  ]);
}

class _ViewSection extends StatelessWidget {
  final String title;
  final bool isDark;
  final List<Widget> children;
  const _ViewSection({required this.title, required this.isDark, required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Text(title, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight))),
      Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
      Padding(padding: const EdgeInsets.all(14), child: Column(children: children)),
    ]),
  );
}

class _ViewRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool isDark;
  const _ViewRow({required this.icon, required this.label, required this.value, required this.isDark});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFF6D28D9).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 15, color: const Color(0xFF6D28D9))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.cairo(fontSize: 10, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight)),
        Text(value, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
      ])),
    ]),
  );
}

// ── Family Edit Sheet ─────────────────────────────────────────────────────────
class _FamilyEditSheet extends StatefulWidget {
  final FamilyModel family;
  final bool isDark;
  const _FamilyEditSheet({required this.family, required this.isDark});
  @override
  State<_FamilyEditSheet> createState() => _FamilyEditSheetState();
}

class _FamilyEditSheetState extends State<_FamilyEditSheet> with TickerProviderStateMixin {
  late AnimationController _entryCtr;
  late AnimationController _saveCtr;
  late Animation<double> _saveScale;
  bool _saved = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _areaCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _notesCtrl;
  late int _members;
  late MaritalStatus _marital;
  late IncomeLevel _income;
  late FamilyStatus _status;

  @override
  void initState() {
    super.initState();
    final f = widget.family;
    _nameCtrl    = TextEditingController(text: f.headName);
    _phoneCtrl   = TextEditingController(text: f.phone ?? '');
    _areaCtrl    = TextEditingController(text: f.area);
    _addressCtrl = TextEditingController(text: f.address);
    _notesCtrl   = TextEditingController(text: f.notes ?? '');
    _members = f.membersCount;
    _marital = f.maritalStatus;
    _income  = f.incomeLevel;
    _status  = f.status;

    _entryCtr = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _saveCtr  = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _saveScale = Tween(begin: 1.0, end: 0.92).animate(CurvedAnimation(parent: _saveCtr, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _entryCtr.dispose(); _saveCtr.dispose();
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _areaCtrl.dispose();
    _addressCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Animation<Offset> _slideAnim(int index) => Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
      .animate(CurvedAnimation(parent: _entryCtr, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: Curves.easeOutCubic)));
  Animation<double> _fadeAnim(int index) => Tween<double>(begin: 0, end: 1)
      .animate(CurvedAnimation(parent: _entryCtr, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: Curves.easeOut)));

  void _save() async {
    _saveCtr.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    setState(() => _saved = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final updated = widget.family.copyWith(
      headName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      area: _areaCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      membersCount: _members,
      maritalStatus: _marital,
      incomeLevel: _income,
      status: _status,
    );
    Navigator.pop(context, updated);
  }

  Color get _ratingClr => _ratingColor(_income);
  String get _ratingStr => _familyRating(_income);

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(children: [
          // Handle + title
          Center(child: Container(margin: const EdgeInsets.only(top: 10), width: 40, height: 4,
              decoration: BoxDecoration(color: isDark ? AppColors.borderDark : AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF4F46E5)]), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.edit_rounded, size: 20, color: Colors.white)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('تعديل بيانات العائلة', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                Text(widget.family.headName, style: GoogleFonts.cairo(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              ])),
              GestureDetector(onTap: () => Navigator.pop(context),
                child: Container(width: 36, height: 36, decoration: BoxDecoration(color: isDark ? AppColors.cardDark : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.close_rounded, size: 18, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
            ]),
          ),
          Divider(height: 16, color: isDark ? AppColors.borderDark : AppColors.borderLight),

          // Form
          Expanded(child: SingleChildScrollView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Section 1: أساسية
              _animField(0, _EditSectionTitle(title: 'البيانات الأساسية', icon: Icons.person_rounded, isDark: isDark)),
              _animField(1, _EditField(label: 'اسم رب الأسرة', icon: Icons.person_outline_rounded, ctrl: _nameCtrl, isDark: isDark)),
              _animField(2, _EditField(label: 'رقم الهاتف', icon: Icons.phone_outlined, ctrl: _phoneCtrl, isDark: isDark, keyboardType: TextInputType.phone)),
              _animField(3, _EditField(label: 'المنطقة', icon: Icons.location_on_outlined, ctrl: _areaCtrl, isDark: isDark)),
              _animField(4, _EditField(label: 'العنوان التفصيلي', icon: Icons.home_outlined, ctrl: _addressCtrl, isDark: isDark)),
              const SizedBox(height: 16),

              // Section 2: الأفراد
              _animField(5, _EditSectionTitle(title: 'البيانات الاجتماعية', icon: Icons.people_rounded, isDark: isDark)),
              _animField(6, _MemberCounter(value: _members, onChanged: (v) => setState(() => _members = v), isDark: isDark)),
              const SizedBox(height: 12),
              _animField(7, _EnumSelector<MaritalStatus>(
                label: 'الحالة الاجتماعية',
                values: MaritalStatus.values,
                selected: _marital,
                labelOf: (v) => v.labelAr,
                onChanged: (v) => setState(() => _marital = v),
                isDark: isDark,
              )),
              const SizedBox(height: 12),
              _animField(8, _EnumSelector<IncomeLevel>(
                label: 'مستوى الدخل',
                values: IncomeLevel.values,
                selected: _income,
                labelOf: (v) => v.labelAr,
                onChanged: (v) => setState(() => _income = v),
                isDark: isDark,
                accent: _ratingClr,
              )),
              const SizedBox(height: 8),
              // Live rating preview
              _animField(9, AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: _ratingClr.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: _ratingClr.withValues(alpha: 0.3))),
                child: Row(children: [
                  Icon(Icons.star_rounded, size: 18, color: _ratingClr),
                  const SizedBox(width: 8),
                  Text('تقييم العائلة: $_ratingStr', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: _ratingClr)),
                ]),
              )),
              const SizedBox(height: 16),

              // Section 3: الحالة
              _animField(10, _EditSectionTitle(title: 'حالة العائلة', icon: Icons.verified_rounded, isDark: isDark)),
              _animField(11, _StatusSelector(selected: _status, onChanged: (v) => setState(() => _status = v), isDark: isDark)),
              const SizedBox(height: 16),

              // Section 4: ملاحظات
              _animField(12, _EditSectionTitle(title: 'ملاحظات', icon: Icons.notes_rounded, isDark: isDark)),
              _animField(13, _EditField(label: 'أضف ملاحظة...', icon: Icons.edit_note_rounded, ctrl: _notesCtrl, isDark: isDark, maxLines: 3)),
              const SizedBox(height: 24),
            ]),
          )),

          // Save button
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
            child: ScaleTransition(
              scale: _saveScale,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: _saved
                      ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                      : const LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF4F46E5)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: (_saved ? const Color(0xFF10B981) : const Color(0xFF6D28D9)).withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 5))],
                ),
                child: GestureDetector(
                  onTap: _saved ? null : _save,
                  child: Center(child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _saved
                        ? Row(key: const ValueKey('done'), mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                            const SizedBox(width: 8),
                            Text('تم الحفظ بنجاح', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                          ])
                        : Row(key: const ValueKey('save'), mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.save_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text('حفظ التعديلات', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                          ]),
                  )),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _animField(int i, Widget child) => FadeTransition(
    opacity: _fadeAnim(i),
    child: SlideTransition(position: _slideAnim(i), child: child),
  );
}

// ── Edit Helper Widgets ────────────────────────────────────────────────────────
class _EditSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  const _EditSectionTitle({required this.title, required this.icon, required this.isDark});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(width: 28, height: 28, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF4F46E5)]), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: Colors.white)),
      const SizedBox(width: 8),
      Text(title, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
    ]),
  );
}

class _EditField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController ctrl;
  final bool isDark;
  final TextInputType? keyboardType;
  final int maxLines;
  const _EditField({required this.label, required this.icon, required this.ctrl, required this.isDark, this.keyboardType, this.maxLines = 1});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.cairo(fontSize: 13, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(fontSize: 12, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF6D28D9)),
        filled: true,
        fillColor: isDark ? AppColors.cardDark : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6D28D9), width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    ),
  );
}

class _MemberCounter extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final bool isDark;
  const _MemberCounter({required this.value, required this.onChanged, required this.isDark});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(children: [
        const Icon(Icons.people_outline_rounded, size: 18, color: Color(0xFF6D28D9)),
        const SizedBox(width: 10),
        Expanded(child: Text('عدد أفراد الأسرة', style: GoogleFonts.cairo(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
        _CounterBtn(icon: Icons.remove_rounded, onTap: value > 1 ? () => onChanged(value - 1) : null),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('$value', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF6D28D9)))),
        _CounterBtn(icon: Icons.add_rounded, onTap: value < 20 ? () => onChanged(value + 1) : null),
      ]),
    ),
  );
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CounterBtn({required this.icon, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: onTap == null ? Colors.grey.withValues(alpha: 0.12) : const Color(0xFF6D28D9).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: onTap == null ? Colors.grey.withValues(alpha: 0.2) : const Color(0xFF6D28D9).withValues(alpha: 0.3)),
      ),
      child: Icon(icon, size: 16, color: onTap == null ? Colors.grey : const Color(0xFF6D28D9)),
    ),
  );
}

class _EnumSelector<T> extends StatelessWidget {
  final String label;
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final bool isDark;
  final Color? accent;
  const _EnumSelector({required this.label, required this.values, required this.selected, required this.labelOf, required this.onChanged, required this.isDark, this.accent});
  @override
  Widget build(BuildContext context) {
    final color = accent ?? const Color(0xFF6D28D9);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.cairo(fontSize: 11, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight)),
      const SizedBox(height: 6),
      Wrap(spacing: 8, runSpacing: 8, children: values.map((v) {
        final isSelected = v == selected;
        return GestureDetector(
          onTap: () => onChanged(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color : (isDark ? AppColors.cardDark : Colors.white),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? color : (isDark ? AppColors.borderDark : AppColors.borderLight), width: isSelected ? 1.5 : 1),
              boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))] : null,
            ),
            child: Text(labelOf(v), style: GoogleFonts.cairo(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
          ),
        );
      }).toList()),
    ]);
  }
}

class _StatusSelector extends StatelessWidget {
  final FamilyStatus selected;
  final ValueChanged<FamilyStatus> onChanged;
  final bool isDark;
  const _StatusSelector({required this.selected, required this.onChanged, required this.isDark});
  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8,
    children: FamilyStatus.values.map((s) {
      final color = _statusHeaderColor(s);
      final isSelected = s == selected;
      return GestureDetector(
        onTap: () => onChanged(s),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : (isDark ? AppColors.cardDark : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : (isDark ? AppColors.borderDark : AppColors.borderLight), width: isSelected ? 2 : 1),
            boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))] : null,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (isSelected) ...[const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white), const SizedBox(width: 5)],
            Text(s.labelAr, style: GoogleFonts.cairo(fontSize: 12, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
          ]),
        ),
      );
    }).toList(),
  );
}

// ── Add Family Bottom Sheet ───────────────────────────────────────────────────
class _AddFamilySheet extends StatefulWidget {
  final bool isDark;

  const _AddFamilySheet({required this.isDark});

  @override
  State<_AddFamilySheet> createState() => _AddFamilySheetState();
}

class _AddFamilySheetState extends State<_AddFamilySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _membersCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  FamilyStatus _status = FamilyStatus.pending;
  IncomeLevel _incomeLevel = IncomeLevel.veryLow;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _areaCtrl.dispose();
    _membersCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final sheetBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPurple,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'إضافة عائلة جديدة',
                    style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              height: 1,
            ),
            // Form
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FormField(
                        label: 'اسم رب الأسرة',
                        controller: _nameCtrl,
                        hint: 'أدخل الاسم الكامل',
                        icon: Icons.person_rounded,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      _FormField(
                        label: 'المنطقة',
                        controller: _areaCtrl,
                        hint: 'المنطقة السكنية',
                        icon: Icons.location_on_rounded,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      _FormField(
                        label: 'عدد أفراد الأسرة',
                        controller: _membersCtrl,
                        hint: 'العدد الإجمالي',
                        icon: Icons.people_rounded,
                        isDark: isDark,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      _FormField(
                        label: 'رقم الهاتف',
                        controller: _phoneCtrl,
                        hint: '07XX XXXXXXX',
                        icon: Icons.phone_rounded,
                        isDark: isDark,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'مستوى الدخل',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<IncomeLevel>(
                            value: _incomeLevel,
                            isExpanded: true,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                            dropdownColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                            items: IncomeLevel.values
                                .map((l) => DropdownMenuItem(
                                      value: l,
                                      child: Text(l.labelAr, style: GoogleFonts.cairo(fontSize: 13)),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _incomeLevel = v);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'حالة الأسرة',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: FamilyStatus.values.map((s) {
                          final selected = _status == s;
                          final color = _statusHeaderColor(s);
                          return GestureDetector(
                            onTap: () => setState(() => _status = s),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: selected
                                    ? color.withValues(alpha: 0.15)
                                    : (isDark
                                        ? AppColors.surfaceVariantDark
                                        : AppColors.surfaceVariantLight),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected ? color : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Text(
                                s.labelAr,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                  color: selected
                                      ? color
                                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),
                      // Submit button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientPurple,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'حفظ البيانات',
                              style: GoogleFonts.cairo(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              'إلغاء',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Form Field ────────────────────────────────────────────────────────────────
class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool isDark;
  final TextInputType? keyboardType;

  const _FormField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.isDark,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.cairo(
                fontSize: 13,
                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
              ),
              prefixIcon: Icon(
                icon,
                size: 18,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
