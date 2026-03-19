import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:charity_app/shared/models/work_post_model.dart';
import 'package:charity_app/shared/providers/app_providers.dart';
import 'package:charity_app/features/works/presentation/providers/works_provider.dart';

class PostDetailPage extends ConsumerStatefulWidget {
  final String postId;
  const PostDetailPage({super.key, required this.postId});

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage>
    with SingleTickerProviderStateMixin {
  final _commentCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  late AnimationController _likeCtrl;
  late Animation<double> _likeAnim;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _likeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _likeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _likeCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _likeCtrl.dispose();
    super.dispose();
  }

  void _submitComment(WorkPost post) {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(authProvider).user;
    ref.read(worksProvider.notifier).addComment(
          post.id,
          user?.name ?? 'مستخدم',
          user?.role.name == 'admin' ? 'مدير النظام' : 'موظف',
          text,
        );
    _commentCtrl.clear();
    _focusNode.unfocus();
    HapticFeedback.lightImpact();
    // Scroll to bottom to show new comment
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final worksState = ref.watch(worksProvider);
    final post = ref.read(worksProvider.notifier).getById(widget.postId) ??
        worksState.all.firstWhere(
          (p) => p.id == widget.postId,
          orElse: () => worksState.all.first,
        );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final images =
        post.imageUrls ?? (post.imageUrl != null ? [post.imageUrl!] : <String>[]);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark ? Colors.white : const Color(0xFF111111),
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'المنشور',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF111111),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_horiz_rounded,
              color: isDark ? Colors.white : const Color(0xFF111111),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _scrollCtrl,
              slivers: [
                // ── Post Header ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: post.category.gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Icon(post.category.icon,
                                color: Colors.white, size: 22),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    post.authorName,
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF111111),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified_rounded,
                                      size: 14, color: Color(0xFF7C3AED)),
                                ],
                              ),
                              Text(
                                post.authorRole,
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: isDark
                                      ? const Color(0xFF888888)
                                      : const Color(0xFF999999),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: post.category.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(post.category.icon,
                                  size: 13, color: post.category.color),
                              const SizedBox(width: 4),
                              Text(
                                post.category.labelAr,
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: post.category.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Images ─────────────────────────────────────────────
                if (images.isNotEmpty)
                  SliverToBoxAdapter(
                    child: GestureDetector(
                      onDoubleTap: () {
                        HapticFeedback.lightImpact();
                        ref
                            .read(worksProvider.notifier)
                            .toggleLike(post.id);
                        _likeCtrl.forward(from: 0);
                      },
                      child: Stack(
                        children: [
                          SizedBox(
                            height: 340,
                            child: images.length > 1
                                ? PageView.builder(
                                    itemCount: images.length,
                                    onPageChanged: (i) =>
                                        setState(() => _currentImageIndex = i),
                                    itemBuilder: (_, i) => CachedNetworkImage(
                                      imageUrl: images[i],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: images[0],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                          ),
                          if (images.length > 1)
                            Positioned(
                              bottom: 10,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  images.length,
                                  (i) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width:
                                        i == _currentImageIndex ? 20 : 6,
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 2),
                                    decoration: BoxDecoration(
                                      color: i == _currentImageIndex
                                          ? Colors.white
                                          : Colors.white
                                              .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                // ── Action Row ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                    child: Row(
                      children: [
                        ScaleTransition(
                          scale: _likeAnim,
                          child: IconButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              ref
                                  .read(worksProvider.notifier)
                                  .toggleLike(post.id);
                              _likeCtrl.forward(from: 0);
                            },
                            icon: Icon(
                              post.isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: post.isLiked
                                  ? const Color(0xFFEF4444)
                                  : (isDark
                                      ? Colors.white
                                      : const Color(0xFF222222)),
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _focusNode.requestFocus(),
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF222222),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.near_me_outlined,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF222222),
                          size: 26,
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref
                                .read(worksProvider.notifier)
                                .toggleSave(post.id);
                          },
                          icon: Icon(
                            post.isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: post.isSaved
                                ? const Color(0xFF7C3AED)
                                : (isDark
                                    ? Colors.white
                                    : const Color(0xFF222222)),
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Stats ──────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _StatBadge(
                              icon: Icons.favorite_rounded,
                              value: _fmt(post.likeCount),
                              label: 'إعجاب',
                              color: const Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 12),
                            _StatBadge(
                              icon: Icons.people_alt_rounded,
                              value: _fmt(post.beneficiaryCount),
                              label: 'مستفيد',
                              color: const Color(0xFF7C3AED),
                            ),
                            const SizedBox(width: 12),
                            _StatBadge(
                              icon: Icons.visibility_rounded,
                              value: _fmt(post.viewCount),
                              label: 'مشاهدة',
                              color: const Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 12),
                            _StatBadge(
                              icon: Icons.near_me_rounded,
                              value: _fmt(post.shareCount),
                              label: 'مشاركة',
                              color: const Color(0xFF10B981),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Title & Description
                        Text(
                          post.title,
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF111111),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          post.description,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFFCCCCCC)
                                : const Color(0xFF444444),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Tags
                        if (post.tags.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            children: post.tags
                                .map((t) => Text(
                                      '#$t',
                                      style: GoogleFonts.cairo(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF3B82F6),
                                      ),
                                    ))
                                .toList(),
                          ),
                        const SizedBox(height: 6),
                        // Location & Date
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 14, color: Color(0xFF7C3AED)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                post.location,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: isDark
                                      ? const Color(0xFF888888)
                                      : const Color(0xFF999999),
                                ),
                              ),
                            ),
                            Text(
                              DateFormat('dd MMM yyyy', 'ar').format(post.date),
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: isDark
                                    ? const Color(0xFF666666)
                                    : const Color(0xFFAAAAAA),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // ── Comments Section ───────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                    child: Text(
                      'التعليقات (${post.comments.length})',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF111111),
                      ),
                    ),
                  ),
                ),

                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _CommentTile(
                      comment: post.comments[index],
                      isDark: isDark,
                    ),
                    childCount: post.comments.length,
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),

          // ── Comment Input ──────────────────────────────────────────────
          _CommentInput(
            controller: _commentCtrl,
            focusNode: _focusNode,
            isDark: isDark,
            onSubmit: () => _submitComment(post),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}م';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}ك';
    return n.toString();
  }
}

// ── Stat Badge ────────────────────────────────────────────────────────────────
class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatBadge(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}

// ── Comment Tile ──────────────────────────────────────────────────────────────
class _CommentTile extends StatelessWidget {
  final WorkComment comment;
  final bool isDark;
  const _CommentTile({required this.comment, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final initials = comment.authorName.isNotEmpty
        ? comment.authorName.trim().split(' ').take(2).map((w) => w[0]).join()
        : '?';

    return Container(
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF4C3BC5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        comment.authorRole,
                        style: GoogleFonts.cairo(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _timeAgo(comment.date),
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: isDark
                            ? const Color(0xFF666666)
                            : const Color(0xFFAAAAAA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.text,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFFCCCCCC)
                        : const Color(0xFF444444),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      comment.isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 14,
                      color: comment.isLiked
                          ? const Color(0xFFEF4444)
                          : (isDark
                              ? const Color(0xFF666666)
                              : const Color(0xFFAAAAAA)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      comment.likeCount.toString(),
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF888888)
                            : const Color(0xFF999999),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'رد',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFF888888)
                            : const Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} ي';
    return DateFormat('dd/MM', 'ar').format(d);
  }
}

// ── Comment Input ─────────────────────────────────────────────────────────────
class _CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final VoidCallback onSubmit;
  const _CommentInput({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFF333333)
                : const Color(0xFFEEEEEE),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: isDark ? Colors.white : const Color(0xFF111111),
                ),
                decoration: InputDecoration(
                  hintText: 'أضف تعليقاً...',
                  hintStyle: GoogleFonts.cairo(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFF666666)
                        : const Color(0xFFAAAAAA),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => onSubmit(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSubmit,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4C3BC5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
