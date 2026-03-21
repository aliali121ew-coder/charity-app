import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:charity_app/features/help_requests/data/mock_help_requests_repository.dart';
import 'package:charity_app/features/help_requests/domain/entities/help_request.dart';
import 'package:charity_app/features/help_requests/domain/entities/request_status.dart';
import 'package:charity_app/features/help_requests/domain/entities/request_type.dart';
import 'package:charity_app/features/help_requests/domain/repositories/help_requests_repository.dart';
import 'package:charity_app/shared/providers/app_providers.dart';

class HelpRequestsState {
  final List<HelpRequest> all;
  final List<HelpRequest> filtered;
  final String query;
  final RequestType? typeFilter;
  final RequestStatus? statusFilter;
  final DateTime? dateFilter;
  final bool isPrivileged;
  final bool isLoading;
  final String? error;

  const HelpRequestsState({
    required this.all,
    required this.filtered,
    this.query = '',
    this.typeFilter,
    this.statusFilter,
    this.dateFilter,
    this.isPrivileged = false,
    this.isLoading = false,
    this.error,
  });

  HelpRequestsState copyWith({
    List<HelpRequest>? all,
    List<HelpRequest>? filtered,
    String? query,
    RequestType? typeFilter,
    RequestStatus? statusFilter,
    DateTime? dateFilter,
    bool? isPrivileged,
    bool? isLoading,
    String? error,
    bool clearTypeFilter = false,
    bool clearStatusFilter = false,
    bool clearDateFilter = false,
  }) {
    return HelpRequestsState(
      all: all ?? this.all,
      filtered: filtered ?? this.filtered,
      query: query ?? this.query,
      typeFilter: clearTypeFilter ? null : typeFilter ?? this.typeFilter,
      statusFilter:
          clearStatusFilter ? null : statusFilter ?? this.statusFilter,
      dateFilter: clearDateFilter ? null : dateFilter ?? this.dateFilter,
      isPrivileged: isPrivileged ?? this.isPrivileged,
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
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isPrivileged = user?.isPrivileged ?? false;
    final currentUserId = user?.id;

    final owned = _ownedRequests(isPrivileged, currentUserId);
    return HelpRequestsState(
      all: owned,
      filtered: owned,
      isPrivileged: isPrivileged,
    );
  }

  // ── Public actions ─────────────────────────────────────────────────────────

  void search(String query) {
    state = state.copyWith(
      query: query,
      filtered: _applyFilters(
        query: query,
        type: state.typeFilter,
        status: state.statusFilter,
        date: state.dateFilter,
      ),
    );
  }

  void filterByType(RequestType? type) {
    state = state.copyWith(
      typeFilter: type,
      clearTypeFilter: type == null,
      filtered: _applyFilters(
        query: state.query,
        type: type,
        status: state.statusFilter,
        date: state.dateFilter,
      ),
    );
  }

  void filterByStatus(RequestStatus? status) {
    state = state.copyWith(
      statusFilter: status,
      clearStatusFilter: status == null,
      filtered: _applyFilters(
        query: state.query,
        type: state.typeFilter,
        status: status,
        date: state.dateFilter,
      ),
    );
  }

  void filterByDate(DateTime? date) {
    state = state.copyWith(
      dateFilter: date,
      clearDateFilter: date == null,
      filtered: _applyFilters(
        query: state.query,
        type: state.typeFilter,
        status: state.statusFilter,
        date: date,
      ),
    );
  }

  void clearAllFilters() {
    state = state.copyWith(
      filtered: _applyFilters(
          query: state.query, type: null, status: null, date: null),
      clearTypeFilter: true,
      clearStatusFilter: true,
      clearDateFilter: true,
    );
  }

  void addRequest(HelpRequest request) {
    final currentUserId = ref.read(authProvider).user?.id;
    final owned = request.copyWith(submittedByUserId: currentUserId);
    _repo.add(owned);
    _refreshAll();
  }

  bool updateRequest(HelpRequest request) {
    final updated = _repo.update(request);
    if (updated == null) return false;
    _refreshAll();
    return true;
  }

  /// Only privileged users (admin/employee with approveAid) can call this.
  void updateStatus(String requestId, RequestStatus newStatus) {
    if (!state.isPrivileged) return;
    final existing = _repo.getById(requestId);
    if (existing == null) return;
    // Use internal force-update (bypasses edit-window check)
    _repo.forceUpdateStatus(requestId, newStatus);
    _refreshAll();
  }

  HelpRequest? getById(String id) => _repo.getById(id);

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _refreshAll() {
    final authState = ref.read(authProvider);
    final user = authState.user;
    final isPrivileged = user?.isPrivileged ?? false;
    final currentUserId = user?.id;
    final owned = _ownedRequests(isPrivileged, currentUserId);
    state = state.copyWith(
      all: owned,
      filtered: _applyFilters(
        query: state.query,
        type: state.typeFilter,
        status: state.statusFilter,
        date: state.dateFilter,
        base: owned,
      ),
    );
  }

  List<HelpRequest> _ownedRequests(bool isPrivileged, String? currentUserId) {
    final all = _repo.getAll();
    if (isPrivileged) return all;
    if (currentUserId == null) return [];
    return all.where((r) => r.submittedByUserId == currentUserId).toList();
  }

  List<HelpRequest> _applyFilters({
    required String query,
    RequestType? type,
    RequestStatus? status,
    DateTime? date,
    List<HelpRequest>? base,
  }) {
    var list = base ?? _ownedRequests(state.isPrivileged, _currentUserId);

    if (type != null) list = list.where((r) => r.type == type).toList();
    if (status != null) list = list.where((r) => r.status == status).toList();

    if (date != null) {
      list = list
          .where((r) =>
              r.submittedAt.year == date.year &&
              r.submittedAt.month == date.month &&
              r.submittedAt.day == date.day)
          .toList();
    }

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

  String? get _currentUserId => ref.read(authProvider).user?.id;
}

final helpRequestsProvider =
    NotifierProvider<HelpRequestsNotifier, HelpRequestsState>(
        HelpRequestsNotifier.new);
