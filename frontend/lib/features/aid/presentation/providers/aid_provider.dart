import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:charity_app/shared/models/aid_model.dart';
import 'package:charity_app/features/aid/data/supabase_aid_repository.dart';

class AidState {
  final List<AidModel> all;
  final List<AidModel> filtered;
  final String query;
  final AidType? typeFilter;
  final AidStatus? statusFilter;
  final bool isLoading;

  const AidState({
    this.all = const [],
    this.filtered = const [],
    this.query = '',
    this.typeFilter,
    this.statusFilter,
    this.isLoading = false,
  });

  AidState copyWith({
    List<AidModel>? all,
    List<AidModel>? filtered,
    String? query,
    AidType? typeFilter,
    AidStatus? statusFilter,
    bool? isLoading,
    bool clearType = false,
    bool clearStatus = false,
  }) {
    return AidState(
      all: all ?? this.all,
      filtered: filtered ?? this.filtered,
      query: query ?? this.query,
      typeFilter: clearType ? null : typeFilter ?? this.typeFilter,
      statusFilter: clearStatus ? null : statusFilter ?? this.statusFilter,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// AidNotifier مدعوم بـ Supabase — نفس واجهة النسخة القديمة تماماً (نفس الحقول
/// والدوال) حتى لا تتغيّر aid_page:
///  - التحميل الأولي async من Supabase (getAll)، ثم الفلترة/البحث محلياً على state.all.
///  - approveAid/distributeAid/addAid يكتبون في Supabase (async) ثم يحدّثون الحالة.
class AidNotifier extends StateNotifier<AidState> {
  final SupabaseAidRepository _repo = SupabaseAidRepository();

  AidNotifier() : super(const AidState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await _repo.getAll();
      state = state.copyWith(
        all: all,
        filtered: _applyFilters(
            all: all, query: state.query, type: state.typeFilter, status: state.statusFilter),
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
      filtered: _applyFilters(
          all: state.all, query: query, type: state.typeFilter, status: state.statusFilter),
    );
  }

  void filterByType(AidType? type) {
    state = state.copyWith(
      typeFilter: type,
      clearType: type == null,
      filtered: _applyFilters(
          all: state.all, query: state.query, type: type, status: state.statusFilter),
    );
  }

  void filterByStatus(AidStatus? status) {
    state = state.copyWith(
      statusFilter: status,
      clearStatus: status == null,
      filtered: _applyFilters(
          all: state.all, query: state.query, type: state.typeFilter, status: status),
    );
  }

  /// فلترة/بحث محلياً على state.all (تبقى متزامنة SYNC حتى لا تتغيّر aid_page).
  List<AidModel> _applyFilters({
    required List<AidModel> all,
    required String query,
    AidType? type,
    AidStatus? status,
  }) {
    var list = all;
    if (type != null) list = list.where((a) => a.type == type).toList();
    if (status != null) list = list.where((a) => a.status == status).toList();
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list
          .where((a) =>
              a.beneficiaryName.toLowerCase().contains(q) ||
              a.referenceNumber.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  Future<void> approveAid(String id) async {
    await _repo.updateStatus(id, AidStatus.approved);
    final updated = state.all
        .map((a) => a.id == id ? a.copyWith(status: AidStatus.approved) : a)
        .toList();
    state = state.copyWith(
      all: updated,
      filtered: _applyFilters(
          all: updated, query: state.query, type: state.typeFilter, status: state.statusFilter),
    );
  }

  Future<void> distributeAid(String id) async {
    await _repo.updateStatus(id, AidStatus.distributed);
    final updated = state.all
        .map((a) => a.id == id ? a.copyWith(status: AidStatus.distributed) : a)
        .toList();
    state = state.copyWith(
      all: updated,
      filtered: _applyFilters(
          all: updated, query: state.query, type: state.typeFilter, status: state.statusFilter),
    );
  }

  Future<void> addAid(AidModel record) async {
    final created = await _repo.add(record);
    final updated = [created, ...state.all];
    state = state.copyWith(
      all: updated,
      filtered: _applyFilters(
          all: updated, query: state.query, type: state.typeFilter, status: state.statusFilter),
    );
  }
}

final aidProvider = StateNotifierProvider<AidNotifier, AidState>((ref) {
  return AidNotifier();
});
