import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:charity_app/shared/models/aid_model.dart';
import 'package:charity_app/features/aid/data/mock_aid_repository.dart';

class AidState {
  final List<AidModel> all;
  final List<AidModel> filtered;
  final String query;
  final AidType? typeFilter;
  final AidStatus? statusFilter;

  const AidState({
    required this.all,
    required this.filtered,
    this.query = '',
    this.typeFilter,
    this.statusFilter,
  });

  AidState copyWith({
    List<AidModel>? all,
    List<AidModel>? filtered,
    String? query,
    AidType? typeFilter,
    AidStatus? statusFilter,
    bool clearType = false,
    bool clearStatus = false,
  }) {
    return AidState(
      all: all ?? this.all,
      filtered: filtered ?? this.filtered,
      query: query ?? this.query,
      typeFilter: clearType ? null : typeFilter ?? this.typeFilter,
      statusFilter: clearStatus ? null : statusFilter ?? this.statusFilter,
    );
  }
}

class AidNotifier extends Notifier<AidState> {
  late final MockAidRepository _repo;

  @override
  AidState build() {
    _repo = MockAidRepository();
    return AidState(
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

  void filterByType(AidType? type) {
    state = state.copyWith(
      typeFilter: type,
      clearType: type == null,
      filtered: _applyFilters(
          query: state.query, type: type, status: state.statusFilter),
    );
  }

  void filterByStatus(AidStatus? status) {
    state = state.copyWith(
      statusFilter: status,
      clearStatus: status == null,
      filtered: _applyFilters(
          query: state.query, type: state.typeFilter, status: status),
    );
  }

  List<AidModel> _applyFilters({
    required String query,
    AidType? type,
    AidStatus? status,
  }) {
    var list = _repo.getAll();
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

  void approveAid(String id) {
    final updated = state.all
        .map((a) => a.id == id ? a.copyWith(status: AidStatus.approved) : a)
        .toList();
    state = state.copyWith(all: updated, filtered: updated);
  }

  void distributeAid(String id) {
    final updated = state.all
        .map((a) => a.id == id ? a.copyWith(status: AidStatus.distributed) : a)
        .toList();
    state = state.copyWith(all: updated, filtered: updated);
  }
}

final aidProvider =
    NotifierProvider<AidNotifier, AidState>(AidNotifier.new);
