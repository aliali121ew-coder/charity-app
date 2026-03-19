import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:charity_app/shared/models/family_model.dart';
import 'package:charity_app/features/families/data/mock_families_repository.dart';

class FamiliesState {
  final List<FamilyModel> all;
  final List<FamilyModel> filtered;
  final String query;
  final FamilyStatus? statusFilter;

  const FamiliesState({
    required this.all,
    required this.filtered,
    this.query = '',
    this.statusFilter,
  });

  FamiliesState copyWith({
    List<FamilyModel>? all,
    List<FamilyModel>? filtered,
    String? query,
    FamilyStatus? statusFilter,
    bool clearStatus = false,
  }) {
    return FamiliesState(
      all: all ?? this.all,
      filtered: filtered ?? this.filtered,
      query: query ?? this.query,
      statusFilter: clearStatus ? null : statusFilter ?? this.statusFilter,
    );
  }
}

class FamiliesNotifier extends Notifier<FamiliesState> {
  late final MockFamiliesRepository _repo;

  @override
  FamiliesState build() {
    _repo = MockFamiliesRepository();
    return FamiliesState(
      all: _repo.getAll(),
      filtered: _repo.getAll(),
    );
  }

  void search(String query) {
    state = state.copyWith(
      query: query,
      filtered: _applyFilters(query: query, status: state.statusFilter),
    );
  }

  void filterByStatus(FamilyStatus? status) {
    state = state.copyWith(
      statusFilter: status,
      clearStatus: status == null,
      filtered: _applyFilters(query: state.query, status: status),
    );
  }

  List<FamilyModel> _applyFilters({
    required String query,
    FamilyStatus? status,
  }) {
    var list = _repo.getAll();
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

  void deleteFamily(String id) {
    final updated = state.all.where((f) => f.id != id).toList();
    state = state.copyWith(
      all: updated,
      filtered: _applyFilters(query: state.query, status: state.statusFilter),
    );
  }
}

final familiesProvider =
    NotifierProvider<FamiliesNotifier, FamiliesState>(FamiliesNotifier.new);
