import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:charity_app/shared/models/log_model.dart';
import 'package:charity_app/features/logs/data/supabase_logs_repository.dart';

class LogsState {
  final List<LogModel> all;
  final List<LogModel> filtered;
  final String query;
  final LogActionType? actionTypeFilter;
  final String? userFilter;
  final bool isLoading;

  const LogsState({
    this.all = const [],
    this.filtered = const [],
    this.query = '',
    this.actionTypeFilter,
    this.userFilter,
    this.isLoading = false,
  });

  LogsState copyWith({
    List<LogModel>? all,
    List<LogModel>? filtered,
    String? query,
    LogActionType? actionTypeFilter,
    String? userFilter,
    bool? isLoading,
    bool clearAction = false,
    bool clearUser = false,
  }) {
    return LogsState(
      all: all ?? this.all,
      filtered: filtered ?? this.filtered,
      query: query ?? this.query,
      actionTypeFilter:
          clearAction ? null : actionTypeFilter ?? this.actionTypeFilter,
      userFilter: clearUser ? null : userFilter ?? this.userFilter,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// LogsNotifier مدعوم بـ Supabase — نفس واجهة النسخة القديمة تماماً (نفس الحقول
/// والدوال) حتى لا تتغيّر logs_page:
///  - التحميل الأولي async من Supabase (getAll)، ثم الفلترة/البحث محلياً على state.all.
///  - todayCount يبقى getter متزامن SYNC يُحسب من state.all (بدون طلب شبكة جديد).
class LogsNotifier extends StateNotifier<LogsState> {
  final SupabaseLogsRepository _repo = SupabaseLogsRepository();

  LogsNotifier() : super(const LogsState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await _repo.getAll();
      state = state.copyWith(
        all: all,
        filtered: _applyFilters(
          all: all,
          query: state.query,
          actionType: state.actionTypeFilter,
          userId: state.userFilter,
        ),
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
        all: state.all,
        query: query,
        actionType: state.actionTypeFilter,
        userId: state.userFilter,
      ),
    );
  }

  void filterByAction(LogActionType? type) {
    state = state.copyWith(
      actionTypeFilter: type,
      clearAction: type == null,
      filtered: _applyFilters(
        all: state.all,
        query: state.query,
        actionType: type,
        userId: state.userFilter,
      ),
    );
  }

  /// فلترة/بحث محلياً على state.all (تبقى متزامنة SYNC حتى لا تتغيّر logs_page).
  List<LogModel> _applyFilters({
    required List<LogModel> all,
    required String query,
    LogActionType? actionType,
    String? userId,
  }) {
    var list = all;
    if (actionType != null) {
      list = list.where((l) => l.actionType == actionType).toList();
    }
    if (userId != null && userId.isNotEmpty) {
      list = list.where((l) => l.performedById == userId).toList();
    }
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list
          .where((l) =>
              l.actionTitle.toLowerCase().contains(q) ||
              l.description.toLowerCase().contains(q) ||
              l.performedBy.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  /// يبقى getter متزامن (SYNC) — يُحسب من state.all بدل استدعاء الخادم مباشرة،
  /// حتى تتوافق قراءته الفورية في logs_page مع بقية النسخة القديمة.
  int get todayCount {
    final today = DateTime.now();
    return state.all
        .where((l) =>
            l.timestamp.day == today.day &&
            l.timestamp.month == today.month &&
            l.timestamp.year == today.year)
        .length;
  }
}

final logsProvider = StateNotifierProvider<LogsNotifier, LogsState>((ref) {
  return LogsNotifier();
});
