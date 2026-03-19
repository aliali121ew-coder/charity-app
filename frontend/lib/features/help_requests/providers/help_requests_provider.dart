import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:charity_app/features/help_requests/data/mock_help_requests_repository.dart';
import 'package:charity_app/features/help_requests/domain/entities/help_request.dart';
import 'package:charity_app/features/help_requests/domain/entities/request_status.dart';
import 'package:charity_app/features/help_requests/domain/entities/request_type.dart';
import 'package:charity_app/features/help_requests/domain/repositories/help_requests_repository.dart';

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

class HelpRequestsNotifier extends Notifier<HelpRequestsState> {
  late final HelpRequestsRepository _repo;

  @override
  HelpRequestsState build() {
    _repo = MockHelpRequestsRepository();
    return HelpRequestsState(
      all: _repo.getAll(),
      filtered: _repo.getAll(),
    );
  }

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

  void addRequest(HelpRequest request) {
    _repo.add(request);
    final all = _repo.getAll();
    state = state.copyWith(
      all: all,
      filtered: _applyFilters(
          query: state.query,
          type: state.typeFilter,
          status: state.statusFilter),
    );
  }

  bool updateRequest(HelpRequest request) {
    final updated = _repo.update(request);
    if (updated == null) return false;
    final all = _repo.getAll();
    state = state.copyWith(
      all: all,
      filtered: _applyFilters(
          query: state.query,
          type: state.typeFilter,
          status: state.statusFilter),
    );
    return true;
  }

  HelpRequest? getById(String id) => _repo.getById(id);

  List<HelpRequest> _applyFilters({
    required String query,
    RequestType? type,
    RequestStatus? status,
  }) {
    var list = _repo.getAll();

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
    NotifierProvider<HelpRequestsNotifier, HelpRequestsState>(HelpRequestsNotifier.new);
