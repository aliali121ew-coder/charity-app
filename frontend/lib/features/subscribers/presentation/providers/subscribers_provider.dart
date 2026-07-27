import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:charity_app/shared/models/subscriber_model.dart';
import 'package:charity_app/features/subscribers/data/supabase_subscribers_repository.dart';

class SubscribersState {
  final List<SubscriberModel> all;
  final List<SubscriberModel> filtered;
  final String query;
  final SubscriberStatus? statusFilter;
  final bool isLoading;

  const SubscribersState({
    this.all = const [],
    this.filtered = const [],
    this.query = '',
    this.statusFilter,
    this.isLoading = false,
  });

  SubscribersState copyWith({
    List<SubscriberModel>? all,
    List<SubscriberModel>? filtered,
    String? query,
    SubscriberStatus? statusFilter,
    bool? isLoading,
    bool clearStatus = false,
  }) {
    return SubscribersState(
      all: all ?? this.all,
      filtered: filtered ?? this.filtered,
      query: query ?? this.query,
      statusFilter: clearStatus ? null : statusFilter ?? this.statusFilter,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// SubscribersNotifier مدعوم بـ Supabase — نفس واجهة النسخة القديمة تماماً
/// (نفس الحقول والدوال) حتى لا تتغيّر الصفحات المعتمِدة عليها:
///  - التحميل الأولي async من Supabase (getAll)، ثم الفلترة/البحث محلياً على state.all.
///  - addSubscriber/deleteSubscriber يكتبان في Supabase (async) ثم يحدّثان الحالة.
class SubscribersNotifier extends StateNotifier<SubscribersState> {
  final SupabaseSubscribersRepository _repo = SupabaseSubscribersRepository();

  SubscribersNotifier() : super(const SubscribersState(isLoading: true)) {
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

  void filterByStatus(SubscriberStatus? status) {
    state = state.copyWith(
      statusFilter: status,
      clearStatus: status == null,
      filtered: _applyFilters(all: state.all, query: state.query, status: status),
    );
  }

  /// فلترة/بحث محلياً على state.all (تبقى متزامنة SYNC حتى لا تتغيّر الصفحات).
  List<SubscriberModel> _applyFilters({
    required List<SubscriberModel> all,
    required String query,
    SubscriberStatus? status,
  }) {
    var list = all;
    if (status != null) list = list.where((s) => s.status == status).toList();
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list
          .where((s) =>
              s.name.toLowerCase().contains(q) ||
              s.phone.contains(q) ||
              s.area.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  /// نفس اسم الدالة القديمة (addSubscriber) — الآن تكتب في Supabase (create) ثم تحدّث الحالة.
  Future<void> addSubscriber(SubscriberModel subscriber) async {
    final created = await _repo.create(subscriber);
    final updated = [...state.all, created];
    state = state.copyWith(
      all: updated,
      filtered: _applyFilters(all: updated, query: state.query, status: state.statusFilter),
    );
  }

  Future<void> updateSubscriber(SubscriberModel subscriber) async {
    final saved = await _repo.update(subscriber);
    final updated = state.all.map((s) => s.id == saved.id ? saved : s).toList();
    state = state.copyWith(
      all: updated,
      filtered: _applyFilters(all: updated, query: state.query, status: state.statusFilter),
    );
  }

  Future<void> deleteSubscriber(String id) async {
    await _repo.delete(id);
    final updated = state.all.where((s) => s.id != id).toList();
    state = state.copyWith(
      all: updated,
      filtered: _applyFilters(all: updated, query: state.query, status: state.statusFilter),
    );
  }

  /// يبقى getter متزامن (SYNC) — يُحسب من state.all.
  SubscriberModel? getById(String id) {
    for (final s in state.all) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// يبقى getter متزامن (SYNC) — يُحسب من state.all.
  List<SubscriberModel> get overdueSubscribers =>
      state.all.where((s) => s.overdueMonths > 0).toList();
}

final subscribersProvider =
    StateNotifierProvider<SubscribersNotifier, SubscribersState>((ref) {
  return SubscribersNotifier();
});
