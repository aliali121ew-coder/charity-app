import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/shared/models/family_model.dart';
import 'package:charity_app/shared/providers/repository_providers.dart';
import 'package:charity_app/shared/providers/supabase_repository_providers.dart';

part '../widgets/subscribers_header_cards.dart';
part '../widgets/subscribers_view_sheet.dart';
part '../widgets/subscribers_edit_sheet.dart';
part '../widgets/subscribers_add_sheet.dart';

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
  final _searchController = TextEditingController();
  FamilyStatus? _statusFilter;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FamilyModel> _applyFilters(List<FamilyModel> source) {
    var list = List<FamilyModel>.from(source);
    if (_statusFilter != null) {
      list = list.where((f) => f.status == _statusFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((f) =>
              f.headName.toLowerCase().contains(q) ||
              f.area.toLowerCase().contains(q) ||
              f.address.toLowerCase().contains(q) ||
              (f.delegateName != null && f.delegateName!.toLowerCase().contains(q)))
          .toList();
    }
    return list;
  }

  Future<void> _updateFamily(FamilyModel updated) async {
    await ref.read(supabaseFamiliesRepositoryProvider).update(updated);
    ref.invalidate(familiesListProvider);
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
    final asyncFamilies = ref.watch(familiesListProvider);

    return asyncFamilies.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                'تعذّر تحميل البيانات',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(familiesListProvider),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
      data: (all) {
        final eligibleCount =
            all.where((f) => f.status == FamilyStatus.eligible).length;
        final totalMembers = all.fold<int>(0, (sum, f) => sum + f.membersCount);
        final filtered = _applyFilters(all);

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
      },
    );
  }

  int _crossAxisCount(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w > 1000) return 4;
    if (w > 700) return 3;
    if (w > 560) return 2;
    return 1;
  }

  void _showAddFamilySheet(BuildContext context, bool isDark) async {
    final newFamily = await showModalBottomSheet<FamilyModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddFamilySheet(isDark: isDark),
    );
    if (newFamily != null) {
      await ref.read(supabaseFamiliesRepositoryProvider).create(newFamily);
      ref.invalidate(familiesListProvider);
    }
  }
}

// ── Page Header ───────────────────────────────────────────────────────────────
