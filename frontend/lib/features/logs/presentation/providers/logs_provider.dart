import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:charity_app/shared/models/log_model.dart';
import 'package:charity_app/features/logs/data/mock_logs_repository.dart';

class LogsState {
  final List<LogModel> all;
  final List<LogModel> filtered;
  final String query;
  final LogActionType? actionTypeFilter;
  final String? userFilter;

  const LogsState({
    required this.all,
    required this.filtered,
    this.query = '',
    this.actionTypeFilter,
    this.userFilter,
  });

  LogsState copyWith({
    List<LogModel>? all,
    List<LogModel>? filtered,
    String? query,
    LogActionType? actionTypeFilter,
    String? userFilter,
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
    );
  }
}

class LogsNotifier extends Notifier<LogsState> {
  late final MockLogsRepository _repo;

  @override
  LogsState build() {
    _repo = MockLogsRepository();
    return LogsState(
      all: _repo.getAll(),
      filtered: _repo.getAll(),
    );
  }

  void search(String query) {
    state = state.copyWith(
      query: query,
      filtered: _applyFilters(
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
        query: state.query,
        actionType: type,
        userId: state.userFilter,
      ),
    );
  }

  List<LogModel> _applyFilters({
    required String query,
    LogActionType? actionType,
    String? userId,
  }) {
    var list = _repo.getAll();
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

  int get todayCount => _repo.getTodayCount();
}

final logsProvider =
    NotifierProvider<LogsNotifier, LogsState>(LogsNotifier.new);
