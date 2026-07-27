import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:charity_app/shared/models/family_model.dart';
import 'package:charity_app/features/families/data/supabase_families_repository.dart';

class FamiliesState {
  final List<FamilyModel> all;
  final List<FamilyModel> filtered;
  final String query;
  final FamilyStatus? statusFilter;
  final bool isLoading;

  const FamiliesState({
    this.all = const [],
    this.filtered = const [],
    this.query = '',
    this.statusFilter,
    this.isLoading = false,
  });

  FamiliesState copyWith({
    List<FamilyModel>? all,
    List<FamilyModel>? filtered,
    String? query,
    FamilyStatus? statusFilter,
    bool? isLoading,
    bool clearStatus = false,
  }) {
    return FamiliesState(
      all: all ?? this.all,
      filtered: filtered ?? this.filtered,
      query: query ?? this.query,
      statusFilter: clearStatus ? null : statusFilter ?? this.statusFilter,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// FamiliesNotifier مدعوم بـ Supabase — نفس واجهة النسخة القديمة تماماً (نفس
/// الحقول والدوال) حتى لا تتغيّر الصفحات المعتمِدة عليها:
///  - التحميل الأولي async من Supabase (getAll)، ثم الفلترة/البحث محلياً على state.all.
///  - deleteFamily يحذف عبر Supabase (async) ثم يحدّث الحالة محلياً.
class FamiliesNotifier extends StateNotifier<FamiliesState> {
  final SupabaseFamiliesRepository _repo = SupabaseFamiliesRepository();

  FamiliesNotifier() : super(const FamiliesState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await _repo.getAll();
      state = state.copyWith(
        all: all,
        filtered: _applyFilters(all: all, query: state.query, status: state.statusFilter),
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// إعادة تحميل من الخادم (مفيدة للسحب-للتحديث).
  Future<void> reload() => _load();

  void search(String query) {
    state = state.copyWith(
      query: query,
      filtered: _applyFilters(all: state.all, query: query, status: state.statusFilter),
    );
  }

  void filterByStatus(FamilyStatus? status) {
    state = state.copyWith(
      statusFilter: status,
      clearStatus: status == null,
      filtered: _applyFilters(all: state.all, query: state.query, status: status),
    );
  }

  /// فلترة/بحث محلياً على state.all (تبقى متزامنة SYNC حتى لا تتغيّر الصفحات).
  List<FamilyModel> _applyFilters({
    required List<FamilyModel> all,
    required String query,
    FamilyStatus? status,
  }) {
    var list = all;
    if (status != null) list = list.where((f) => f.status == status).toList();
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list
          .where((f) =>
              f.headName.toLowerCase().contains(q) ||
              f.area.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  Future<void> addFamily(FamilyModel family) async {
    final created = await _repo.create(family);
    final updated = [created, ...state.all];
    state = state.copyWith(
      all: updated,
      filtered: _applyFilters(all: updated, query: state.query, status: state.statusFilter),
    );
  }

  Future<void> updateFamily(FamilyModel family) async {
    final saved = await _repo.update(family);
    final updated = state.all.map((f) => f.id == saved.id ? saved : f).toList();
    state = state.copyWith(
      all: updated,
      filtered: _applyFilters(all: updated, query: state.query, status: state.statusFilter),
    );
  }

  Future<void> deleteFamily(String id) async {
    await _repo.delete(id);
    final updated = state.all.where((f) => f.id != id).toList();
    state = state.copyWith(
      all: updated,
      filtered: _applyFilters(all: updated, query: state.query, status: state.statusFilter),
    );
  }
}

final familiesProvider =
    StateNotifierProvider<FamiliesNotifier, FamiliesState>((ref) {
  return FamiliesNotifier();
});
