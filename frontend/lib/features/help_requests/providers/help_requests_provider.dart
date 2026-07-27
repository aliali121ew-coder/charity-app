import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:charity_app/features/help_requests/data/supabase_help_requests_repository.dart';
import 'package:charity_app/features/help_requests/domain/entities/help_request.dart';
import 'package:charity_app/features/help_requests/domain/entities/request_status.dart';
import 'package:charity_app/features/help_requests/domain/entities/request_type.dart';
import 'package:charity_app/shared/providers/supabase_repository_providers.dart';

class HelpRequestsState {
  final List<HelpRequest> all;
  final List<HelpRequest> filtered;
  final String query;
  final RequestType? typeFilter;
  final RequestStatus? statusFilter;
  final bool isLoading;
  final String? error;

  const HelpRequestsState({
    required this.all,
    required this.filtered,
    this.query = '',
    this.typeFilter,
    this.statusFilter,
    this.isLoading = false,
    this.error,
  });

  HelpRequestsState copyWith({
    List<HelpRequest>? all,
    List<HelpRequest>? filtered,
    String? query,
    RequestType? typeFilter,
    RequestStatus? statusFilter,
    bool? isLoading,
    String? error,
    bool clearTypeFilter = false,
    bool clearStatusFilter = false,
  }) {
    return HelpRequestsState(
      all: all ?? this.all,
      filtered: filtered ?? this.filtered,
      query: query ?? this.query,
      typeFilter: clearTypeFilter ? null : typeFilter ?? this.typeFilter,
      statusFilter:
          clearStatusFilter ? null : statusFilter ?? this.statusFilter,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// HelpRequestsNotifier مدعوم بـ Supabase.
/// نفس واجهة النسخة القديمة (نفس الحقول والدوال) حتى لا تتغيّر الصفحات:
///  - التحميل الأولي async من Supabase (getAll)، ثم الفلترة/البحث محلياً على state.all.
///  - getById يقرأ محلياً من state.all (متزامن) مطابقةً لـ works_provider.
///  - addRequest/updateRequest يكتبان في Supabase (async) ثم يحدّثان الحالة
///    ويُبطلان helpRequestsListProvider ليبقى مزوّد القراءة العام محدّثاً.
class HelpRequestsNotifier extends StateNotifier<HelpRequestsState> {
  final SupabaseHelpRequestsRepository _repo = SupabaseHelpRequestsRepository();
  final Ref _ref;

  HelpRequestsNotifier(this._ref)
      : super(const HelpRequestsState(
          all: [],
          filtered: [],
          isLoading: true,
        )) {
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await _repo.getAll();
      state = state.copyWith(
        all: all,
        filtered: _applyFilters(
            query: state.query, type: state.typeFilter, status: state.statusFilter),
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// إعادة تحميل من الخادم (مفيدة للسحب-للتحديث).
  Future<void> reload() => _load();

  void search(String query) {
    state = state.copyWith(
      query: query,
      filtered: _applyFilters(
          query: query, type: state.typeFilter, status: state.statusFilter),
    );
  }

  void filterByType(RequestType? type) {
    state = state.copyWith(
      typeFilter: type,
      clearTypeFilter: type == null,
      filtered: _applyFilters(
          query: state.query, type: type, status: state.statusFilter),
    );
  }

  void filterByStatus(RequestStatus? status) {
    state = state.copyWith(
      statusFilter: status,
      clearStatusFilter: status == null,
      filtered: _applyFilters(
          query: state.query, type: state.typeFilter, status: status),
    );
  }

  void clearAllFilters() {
    state = HelpRequestsState(
      all: state.all,
      filtered: _applyFilters(query: state.query, type: null, status: null),
      query: state.query,
      typeFilter: null,
      statusFilter: null,
    );
  }

  Future<void> addRequest(HelpRequest request) async {
    final created = await _repo.add(request);
    final all = [created, ...state.all];
    state = state.copyWith(
      all: all,
      filtered: _applyFilters(
          query: state.query,
          type: state.typeFilter,
          status: state.statusFilter),
    );
    _ref.invalidate(helpRequestsListProvider);
  }

  Future<bool> updateRequest(HelpRequest request) async {
    final updated = await _repo.update(request);
    if (updated == null) return false;
    final all = state.all
        .map((r) => r.id == updated.id ? updated : r)
        .toList();
    state = state.copyWith(
      all: all,
      filtered: _applyFilters(
          query: state.query,
          type: state.typeFilter,
          status: state.statusFilter),
    );
    _ref.invalidate(helpRequestsListProvider);
    return true;
  }

  HelpRequest? getById(String id) {
    for (final r in state.all) {
      if (r.id == id) return r;
    }
    return null;
  }

  List<HelpRequest> _applyFilters({
    required String query,
    RequestType? type,
    RequestStatus? status,
  }) {
    var list = state.all.toList();

    if (type != null) list = list.where((r) => r.type == type).toList();
    if (status != null) list = list.where((r) => r.status == status).toList();

    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list
          .where((r) =>
              r.title.toLowerCase().contains(q) ||
              r.fullName.toLowerCase().contains(q) ||
              r.governorate.contains(q) ||
              r.area.contains(q))
          .toList();
    }

    list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return list;
  }
}

final helpRequestsProvider =
    StateNotifierProvider<HelpRequestsNotifier, HelpRequestsState>((ref) {
  return HelpRequestsNotifier(ref);
});
