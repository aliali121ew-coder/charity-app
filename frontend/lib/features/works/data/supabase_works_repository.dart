import 'package:charity_app/core/supabase/supabase_config.dart';
import 'package:charity_app/shared/models/work_post_model.dart';

/// مستودع أعمال المؤسسة عبر Supabase — يحلّ محل MockWorksRepository (async).
/// الجداول: work_posts + work_comments.
/// ملاحظة: WorkCategory.all قيمة فلترة فقط ولا تُخزَّن أبداً في القاعدة.
/// isLiked / isSaved حالة واجهة خاصة بكل مستخدم (غير مخزّنة) → افتراضياً false.
class SupabaseWorksRepository {
  static const _table = 'work_posts';
  static const _commentsTable = 'work_comments';

  // ── تحويل صف تعليق ──────────────────────────────────────────────────────────
  WorkComment _mapComment(Map<String, dynamic> r) => WorkComment(
        id: r['id'] as String,
        authorName: (r['author_name'] ?? '') as String,
        authorRole: (r['author_role'] ?? '') as String,
        text: (r['text'] ?? '') as String,
        date: DateTime.parse(r['created_at'] as String),
        likeCount: (r['like_count'] ?? 0) as int,
      );

  Map<String, dynamic> _commentToRow(String postId, WorkComment c) => {
        'post_id': postId,
        'author_name': c.authorName,
        'author_role': c.authorRole,
        'text': c.text,
        'like_count': c.likeCount,
      };

  // ── تحويل صف منشور ──────────────────────────────────────────────────────────
  WorkPost _mapPost(Map<String, dynamic> r, {List<WorkComment> comments = const []}) => WorkPost(
        id: r['id'] as String,
        title: (r['title'] ?? '') as String,
        description: (r['description'] ?? '') as String,
        imageUrl: r['cover_image_url'] as String?,
        category: WorkCategory.values.byName((r['category'] ?? 'general') as String),
        date: DateTime.parse(r['published_at'] as String),
        location: (r['location'] ?? '') as String,
        tags: ((r['tags'] ?? const []) as List).map((e) => e as String).toList(),
        viewCount: (r['view_count'] ?? 0) as int,
        likeCount: (r['like_count'] ?? 0) as int,
        beneficiaryCount: (r['beneficiary_count'] ?? 0) as int,
        isFeatured: (r['is_featured'] ?? false) as bool,
        videoUrl: r['video_url'] as String?,
        authorName: (r['author_name'] ?? '') as String,
        authorRole: (r['author_role'] ?? '') as String,
        shareCount: (r['share_count'] ?? 0) as int,
        comments: comments,
        imageUrls: ((r['image_urls'] ?? const []) as List).map((e) => e as String).toList(),
      );

  /// لا نُخزّن id (تولّده القاعدة) ولا WorkCategory.all (قيمة فلترة فقط).
  /// التعليقات تُخزَّن في جدول منفصل، لذا لا تُدرج هنا.
  Map<String, dynamic> _postToRow(WorkPost p) => {
        'title': p.title,
        'description': p.description,
        'cover_image_url': p.imageUrl,
        'category': p.category.name,
        'published_at': p.date.toIso8601String(),
        'location': p.location,
        'tags': p.tags,
        'image_urls': p.imageUrls ?? const <String>[],
        'video_url': p.videoUrl,
        'beneficiary_count': p.beneficiaryCount,
        'view_count': p.viewCount,
        'like_count': p.likeCount,
        'share_count': p.shareCount,
        'is_featured': p.isFeatured,
        'author_name': p.authorName,
        'author_role': p.authorRole,
      };

  // ── تعليقات ─────────────────────────────────────────────────────────────────
  Future<List<WorkComment>> getComments(String postId) async {
    final rows = await supabase
        .from(_commentsTable)
        .select()
        .eq('post_id', postId)
        .order('created_at', ascending: false);
    return rows.map((e) => _mapComment(e)).toList();
  }

  // ── قراءة المنشورات ──────────────────────────────────────────────────────────
  Future<List<WorkPost>> getAll() async {
    final rows = await supabase.from(_table).select().order('published_at', ascending: false);
    return rows.map((e) => _mapPost(e)).toList();
  }

  Future<List<WorkPost>> getByCategory(WorkCategory category) async {
    if (category == WorkCategory.all) return getAll();
    final rows = await supabase
        .from(_table)
        .select()
        .eq('category', category.name)
        .order('published_at', ascending: false);
    return rows.map((e) => _mapPost(e)).toList();
  }

  Future<List<WorkPost>> search(String query) async {
    if (query.isEmpty) return getAll();
    final q = query.replaceAll(',', ' ').trim();
    final rows = await supabase
        .from(_table)
        .select()
        .or('title.ilike.%$q%,description.ilike.%$q%,location.ilike.%$q%')
        .order('published_at', ascending: false);
    return rows.map((e) => _mapPost(e)).toList();
  }

  Future<List<WorkPost>> getFeatured() async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('is_featured', true)
        .order('published_at', ascending: false);
    return rows.map((e) => _mapPost(e)).toList();
  }

  /// يتضمّن التعليقات (تُجلب من work_comments).
  Future<WorkPost?> getById(String id) async {
    final row = await supabase.from(_table).select().eq('id', id).maybeSingle();
    if (row == null) return null;
    final comments = await getComments(id);
    return _mapPost(row, comments: comments);
  }

  Future<Map<WorkCategory, int>> getCategoryCounts() async {
    final rows = await supabase.from(_table).select('category');
    final counts = <WorkCategory, int>{};
    for (final cat in WorkCategory.values) {
      if (cat == WorkCategory.all) continue;
      counts[cat] = 0;
    }
    for (final r in rows) {
      final cat = WorkCategory.values.byName(r['category'] as String);
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
    return counts;
  }

  // ── إحصاءات مُجمّعة (محسوبة على العميل، مطابقة لمنطق الـ mock) ─────────────────
  Future<int> getTotalBeneficiaries() async {
    final rows = await supabase.from(_table).select('beneficiary_count');
    return rows.fold<int>(0, (sum, r) => sum + ((r['beneficiary_count'] ?? 0) as int));
  }

  Future<int> getTotalPosts() async {
    final rows = await supabase.from(_table).select('id');
    return rows.length;
  }

  Future<int> getTotalViews() async {
    final rows = await supabase.from(_table).select('view_count');
    return rows.fold<int>(0, (sum, r) => sum + ((r['view_count'] ?? 0) as int));
  }

  Future<int> getMonthlyPosts() async {
    final rows = await supabase.from(_table).select('published_at');
    final now = DateTime.now();
    return rows.where((r) {
      final d = DateTime.parse(r['published_at'] as String);
      return d.year == now.year && d.month == now.month;
    }).length;
  }

  // ── إجراءات ──────────────────────────────────────────────────────────────────
  /// إعجاب/إلغاء: نحدّث العدّاد فقط (حالة الإعجاب لكل مستخدم غير مخزّنة هنا).
  Future<void> toggleLike(String postId, {required bool liked}) async {
    final row = await supabase.from(_table).select('like_count').eq('id', postId).maybeSingle();
    if (row == null) return;
    final current = (row['like_count'] ?? 0) as int;
    final next = liked ? current + 1 : (current - 1).clamp(0, 1 << 30);
    await supabase.from(_table).update({'like_count': next}).eq('id', postId);
  }

  Future<WorkComment> addComment(String postId, WorkComment comment) async {
    final row = await supabase
        .from(_commentsTable)
        .insert(_commentToRow(postId, comment))
        .select()
        .single();
    return _mapComment(row);
  }

  /// إضافة منشور — نترك id لتوليده في القاعدة ونعيد الصف الناتج.
  Future<WorkPost> addPost(WorkPost post) async {
    final row = await supabase.from(_table).insert(_postToRow(post)).select().single();
    return _mapPost(row);
  }
}
