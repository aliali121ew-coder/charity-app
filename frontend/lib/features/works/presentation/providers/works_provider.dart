import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:charity_app/shared/models/work_post_model.dart';
import 'package:charity_app/features/works/data/mock_works_repository.dart';

class WorksState {
  final List<WorkPost> all;
  final List<WorkPost> filtered;
  final WorkCategory selectedCategory;
  final String searchQuery;
  final bool isLoading;

  const WorksState({
    this.all = const [],
    this.filtered = const [],
    this.selectedCategory = WorkCategory.all,
    this.searchQuery = '',
    this.isLoading = false,
  });

  WorksState copyWith({
    List<WorkPost>? all,
    List<WorkPost>? filtered,
    WorkCategory? selectedCategory,
    String? searchQuery,
    bool? isLoading,
  }) {
    return WorksState(
      all: all ?? this.all,
      filtered: filtered ?? this.filtered,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class WorksNotifier extends Notifier<WorksState> {
  final MockWorksRepository _repo = MockWorksRepository();
  static const _uuid = Uuid();

  @override
  WorksState build() {
    final all = _repo.getAll();
    return WorksState(all: all, filtered: all);
  }

  void _load() {
    final all = _repo.getAll();
    state = state.copyWith(all: all, filtered: all);
  }

  void filterByCategory(WorkCategory category) {
    List<WorkPost> base;
    if (state.searchQuery.isNotEmpty) {
      base = _repo.search(state.searchQuery);
    } else {
      base = _repo.getAll();
    }
    final filtered = category == WorkCategory.all
        ? base
        : base.where((p) => p.category == category).toList();
    state = state.copyWith(selectedCategory: category, filtered: filtered);
  }

  void search(String query) {
    final base = _repo.search(query);
    final filtered = state.selectedCategory == WorkCategory.all
        ? base
        : base.where((p) => p.category == state.selectedCategory).toList();
    state = state.copyWith(searchQuery: query, filtered: filtered);
  }

  void toggleLike(String postId) {
    _repo.toggleLike(postId);
    _load();
    filterByCategory(state.selectedCategory);
  }

  void toggleSave(String postId) {
    _repo.toggleSave(postId);
    _load();
    filterByCategory(state.selectedCategory);
  }

  void addComment(String postId, String authorName, String authorRole, String text) {
    final comment = WorkComment(
      id: _uuid.v4(),
      authorName: authorName,
      authorRole: authorRole,
      text: text,
      date: DateTime.now(),
    );
    _repo.addComment(postId, comment);
    _load();
    filterByCategory(state.selectedCategory);
  }

  void createPost({
    required String title,
    required String description,
    required WorkCategory category,
    required String location,
    required List<String> tags,
    String? imageUrl,
    required String authorName,
    required String authorRole,
    int beneficiaryCount = 0,
  }) {
    final post = WorkPost(
      id: _uuid.v4(),
      title: title,
      description: description,
      imageUrl: imageUrl,
      category: category,
      date: DateTime.now(),
      location: location,
      tags: tags,
      authorName: authorName,
      authorRole: authorRole,
      beneficiaryCount: beneficiaryCount,
    );
    _repo.addPost(post);
    _load();
    filterByCategory(state.selectedCategory);
  }

  WorkPost? getById(String id) => _repo.getById(id);

  int get totalBeneficiaries => _repo.totalBeneficiaries;
  int get totalPosts => _repo.totalPosts;
  int get totalViews => _repo.totalViews;
  int get monthlyPosts => _repo.monthlyPosts;
  Map<WorkCategory, int> get categoryCounts => _repo.getCategoryCounts();
}

final worksProvider = NotifierProvider<WorksNotifier, WorksState>(WorksNotifier.new);
