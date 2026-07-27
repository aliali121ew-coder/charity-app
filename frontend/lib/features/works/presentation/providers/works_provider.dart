import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:charity_app/shared/models/work_post_model.dart';
import 'package:charity_app/features/works/data/supabase_works_repository.dart';

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

/// WorksNotifier مدعوم بـ Supabase.
/// نفس واجهة النسخة القديمة تماماً (نفس الحقول والدوال) حتى لا تتغيّر works_page:
///  - التحميل الأولي async من Supabase (getAll)، ثم الفلترة/البحث محلياً على state.all.
///  - createPost/addComment يكتبان في Supabase (async) ثم يحدّثان الحالة.
///  - toggleLike/toggleSave تفاؤلية محلياً (per-user reactions لاحقاً عبر work_reactions).
class WorksNotifier extends StateNotifier<WorksState> {
  final SupabaseWorksRepository _repo = SupabaseWorksRepository();
  static const _uuid = Uuid();

  WorksNotifier() : super(const WorksState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await _repo.getAll();
      state = state.copyWith(
        all: all,
        filtered: _apply(all, state.selectedCategory, state.searchQuery),
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// إعادة تحميل من الخادم (مفيدة للسحب-للتحديث).
  Future<void> reload() => _load();

  List<WorkPost> _apply(List<WorkPost> src, WorkCategory cat, String query) {
    var list =
        cat == WorkCategory.all ? src : src.where((p) => p.category == cat).toList();
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((p) =>
              p.title.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q) ||
              p.location.toLowerCase().contains(q) ||
              p.authorName.toLowerCase().contains(q) ||
              p.tags.any((t) => t.toLowerCase().contains(q)))
          .toList();
    }
    return list;
  }

  void filterByCategory(WorkCategory category) {
    state = state.copyWith(
      selectedCategory: category,
      filtered: _apply(state.all, category, state.searchQuery),
    );
  }

  void search(String query) {
    state = state.copyWith(
      searchQuery: query,
      filtered: _apply(state.all, state.selectedCategory, query),
    );
  }

  void toggleLike(String postId) {
    final all = state.all.map((p) {
      if (p.id != postId) return p;
      final liked = !p.isLiked;
      return p.copyWith(isLiked: liked, likeCount: p.likeCount + (liked ? 1 : -1));
    }).toList();
    state = state.copyWith(
      all: all,
      filtered: _apply(all, state.selectedCategory, state.searchQuery),
    );
    // TODO: persist per-user like to work_reactions (kind='like') once auth.uid is wired.
  }

  void toggleSave(String postId) {
    final all = state.all.map((p) {
      if (p.id != postId) return p;
      return p.copyWith(isSaved: !p.isSaved);
    }).toList();
    state = state.copyWith(
      all: all,
      filtered: _apply(all, state.selectedCategory, state.searchQuery),
    );
    // TODO: persist per-user save to work_reactions (kind='save').
  }

  Future<void> addComment(
      String postId, String authorName, String authorRole, String text) async {
    final saved = await _repo.addComment(
      postId,
      WorkComment(
        id: _uuid.v4(),
        authorName: authorName,
        authorRole: authorRole,
        text: text,
        date: DateTime.now(),
      ),
    );
    final all = state.all
        .map((p) => p.id == postId
            ? p.copyWith(comments: [...p.comments, saved])
            : p)
        .toList();
    state = state.copyWith(
      all: all,
      filtered: _apply(all, state.selectedCategory, state.searchQuery),
    );
  }

  Future<void> createPost({
    required String title,
    required String description,
    required WorkCategory category,
    required String location,
    required List<String> tags,
    String? imageUrl,
    required String authorName,
    required String authorRole,
    int beneficiaryCount = 0,
  }) async {
    final created = await _repo.addPost(
      WorkPost(
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
      ),
    );
    final all = [created, ...state.all];
    state = state.copyWith(
      all: all,
      filtered: _apply(all, state.selectedCategory, state.searchQuery),
    );
  }

  WorkPost? getById(String id) {
    for (final p in state.all) {
      if (p.id == id) return p;
    }
    return null;
  }

  int get totalBeneficiaries =>
      state.all.fold(0, (s, p) => s + p.beneficiaryCount);
  int get totalPosts => state.all.length;
  int get totalViews => state.all.fold(0, (s, p) => s + p.viewCount);
  int get monthlyPosts {
    final n = DateTime.now();
    return state.all
        .where((p) => p.date.year == n.year && p.date.month == n.month)
        .length;
  }

  Map<WorkCategory, int> get categoryCounts {
    final m = <WorkCategory, int>{};
    for (final c in WorkCategory.values) {
      m[c] = c == WorkCategory.all
          ? state.all.length
          : state.all.where((p) => p.category == c).length;
    }
    return m;
  }
}

final worksProvider = StateNotifierProvider<WorksNotifier, WorksState>((ref) {
  return WorksNotifier();
});
