import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:charity_app/shared/models/subscriber_model.dart';
import 'package:charity_app/features/subscribers/data/mock_subscribers_repository.dart';

class SubscribersState {
  final List<SubscriberModel> all;
  final List<SubscriberModel> filtered;
  final String query;
  final SubscriberStatus? statusFilter;
  final bool isLoading;

  const SubscribersState({
    required this.all,
    required this.filtered,
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

class SubscribersNotifier extends Notifier<SubscribersState> {
  late final MockSubscribersRepository _repo;

  @override
  SubscribersState build() {
    _repo = MockSubscribersRepository();
    return SubscribersState(
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

  void filterByStatus(SubscriberStatus? status) {
    state = state.copyWith(
      statusFilter: status,
      clearStatus: status == null,
      filtered: _applyFilters(query: state.query, status: status),
    );
  }

  List<SubscriberModel> _applyFilters({
    required String query,
    SubscriberStatus? status,
  }) {
    var list = _repo.getAll();
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

  void addSubscriber(SubscriberModel subscriber) {
    final updated = [...state.all, subscriber];
    state = state.copyWith(
      all: updated,
      filtered: _applyFilters(query: state.query, status: state.statusFilter),
    );
  }

  void deleteSubscriber(String id) {
    final updated = state.all.where((s) => s.id != id).toList();
    state = state.copyWith(
      all: updated,
      filtered: _applyFilters(query: state.query, status: state.statusFilter),
    );
  }
}

final subscribersProvider =
    NotifierProvider<SubscribersNotifier, SubscribersState>(SubscribersNotifier.new);
