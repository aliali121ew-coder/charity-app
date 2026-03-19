import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:charity_app/core/permissions/role.dart';
import 'package:charity_app/shared/models/work_post_model.dart';
import 'package:charity_app/shared/providers/app_providers.dart';
import 'package:charity_app/features/works/presentation/providers/works_provider.dart';
import 'package:charity_app/core/router/app_router.dart';

// ── Feed Page (Instagram-style) ───────────────────────────────────────────────
class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _scrollCtrl = ScrollController();
  bool _showFab = true;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _scrollCtrl.addListener(() {
      final offset = _scrollCtrl.offset;
      if ((offset - _lastScrollOffset).abs() > 10) {
        final show = offset < _lastScrollOffset || offset <= 50;
        if (show != _showFab) setState(() => _showFab = show);
        _lastScrollOffset = offset;
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final worksState = ref.watch(worksProvider);
    final worksNotifier = ref.read(worksProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == UserRole.admin;
    final posts = worksState.all;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F5),
      body: NestedScrollView(
        controller: _scrollCtrl,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── Profile Header ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ProfileHeader(
              totalPosts: worksNotifier.totalPosts,
              totalBeneficiaries: worksNotifier.totalBeneficiaries,
              totalViews: worksNotifier.totalViews,
              isDark: isDark,
            ),
          ),
          // ── Highlights (Stories) ──────────────────────────────────────
          SliverToBoxAdapter(
            child: _HighlightsRow(isDark: isDark),
          ),
          // ── Divider + Tabs ────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              tabController: _tabCtrl,
              isDark: isDark,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            // Feed View
            _FeedList(posts: posts, isDark: isDark),
            // Grid View
            _GridView(posts: posts, isDark: isDark),
          ],
        ),
      ),
      floatingActionButton: isAdmin
          ? AnimatedSlide(
              duration: const Duration(milliseconds: 250),
              offset: _showFab ? Offset.zero : const Offset(0, 2),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _showFab ? 1 : 0,
                child: FloatingActionButton.extended(
                  onPressed: () => context.push(AppRoutes.feedCreate),
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  icon: const Icon(Icons.add_photo_alternate_rounded),
                  label: Text(
                    'نشر جديد',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

// ── Profile Header ────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final int totalPosts;
  final int totalBeneficiaries;
  final int totalViews;
  final bool isDark;

  const _ProfileHeader({
    required this.totalPosts,
    required this.totalBeneficiaries,
    required this.totalViews,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: Avatar + Stats ──────────────────────────────────
          Row(
            children: [
              // Avatar with gradient ring
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF7C3AED),
                      Color(0xFFEC4899),
                      Color(0xFFF59E0B)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  ),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF4C3BC5), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.volunteer_activism_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Stats
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatCol(
                      value: totalPosts.toString(),
                      label: 'منشور',
                      isDark: isDark,
                    ),
                    _StatCol(
                      value: _formatNum(totalBeneficiaries),
                      label: 'مستفيد',
                      isDark: isDark,
                    ),
                    _StatCol(
                      value: _formatNum(totalViews),
                      label: 'مشاهدة',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Bio ───────────────────────────────────────────────────────
          Text(
            ' مؤسسة أحباب الحسين   ',
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'مؤسسة  خيرية غير ربحية • نعمل من أجل مستقبل أفضل',
            style: GoogleFonts.cairo(
              fontSize: 12.5,
              color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF555555),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 13, color: Color(0xFF7C3AED)),
              const SizedBox(width: 3),
              Text(
                'محافظة بابل  ',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: const Color(0xFF7C3AED),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // ── Verified badge ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded,
                    size: 13, color: Color(0xFF7C3AED)),
                const SizedBox(width: 4),
                Text(
                  'مؤسسة خيرية موثقة',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  String _formatNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}م';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}ك';
    return n.toString();
  }
}

class _StatCol extends StatelessWidget {
  final String value;
  final String label;
  final bool isDark;
  const _StatCol(
      {required this.value, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF111111),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF888888),
          ),
        ),
      ],
    );
  }
}

// ── Highlights Row ────────────────────────────────────────────────────────────
class _HighlightsRow extends StatelessWidget {
  final bool isDark;
  const _HighlightsRow({required this.isDark});

  static const _highlights = [
    _Highlight('جميع الأعمال', Icons.apps_rounded, Color(0xFF7C3AED)),
    _Highlight('غذاء', Icons.restaurant_rounded, Color(0xFF10B981)),
    _Highlight('طبي', Icons.medical_services_rounded, Color(0xFFEF4444)),
    _Highlight('تعليم', Icons.school_rounded, Color(0xFF3B82F6)),
    _Highlight('موسمي', Icons.celebration_rounded, Color(0xFFF59E0B)),
    _Highlight('فعاليات', Icons.event_rounded, Color(0xFF14B8A6)),
    _Highlight('مالي', Icons.account_balance_wallet_rounded, Color(0xFF8B5CF6)),
    _Highlight('عام', Icons.volunteer_activism_rounded, Color(0xFF6366F1)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, thickness: 0.5),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _highlights.length,
              itemBuilder: (context, index) {
                return _HighlightItem(h: _highlights[index], isDark: isDark);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Highlight {
  final String label;
  final IconData icon;
  final Color color;
  const _Highlight(this.label, this.icon, this.color);
}

class _HighlightItem extends StatelessWidget {
  final _Highlight h;
  final bool isDark;
  const _HighlightItem({required this.h, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [h.color, h.color.withValues(alpha: 0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: h.color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(h.icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 5),
          Text(
            h.label,
            style: GoogleFonts.cairo(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF444444),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab Bar Delegate ──────────────────────────────────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final bool isDark;

  const _TabBarDelegate({required this.tabController, required this.isDark});

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      child: TabBar(
        controller: tabController,
        indicatorColor: const Color(0xFF7C3AED),
        indicatorWeight: 2,
        labelColor: const Color(0xFF7C3AED),
        unselectedLabelColor:
            isDark ? const Color(0xFF888888) : const Color(0xFF999999),
        tabs: const [
          Tab(icon: Icon(Icons.view_agenda_rounded, size: 22)),
          Tab(icon: Icon(Icons.grid_view_rounded, size: 22)),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) =>
      oldDelegate.isDark != isDark;
}

// ── Feed List ────────────────────────────────────────────────────────────────
class _FeedList extends ConsumerWidget {
  final List<WorkPost> posts;
  final bool isDark;
  const _FeedList({required this.posts, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (posts.isEmpty) {
      return Center(
        child: Text(
          'لا توجد منشورات',
          style: GoogleFonts.cairo(color: Colors.grey),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(top: 4, bottom: 100),
      itemCount: posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _PostCard(
        post: posts[index],
        isDark: isDark,
      ),
    );
  }
}

// ── Post Card (Instagram-style) ───────────────────────────────────────────────
class _PostCard extends ConsumerStatefulWidget {
  final WorkPost post;
  final bool isDark;
  const _PostCard({required this.post, required this.isDark});

  @override
  ConsumerState<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<_PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeCtrl;
  late Animation<double> _likeAnim;
  bool _expanded = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _likeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _likeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _likeCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _likeCtrl.dispose();
    super.dispose();
  }

  void _handleLike() {
    HapticFeedback.lightImpact();
    ref.read(worksProvider.notifier).toggleLike(widget.post.id);
    _likeCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isDark = widget.isDark;
    final images = post.imageUrls ??
        (post.imageUrl != null ? [post.imageUrl!] : <String>[]);

    return Container(
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Post Header ────────────────────────────────────────────────
          _PostHeader(post: post, isDark: isDark),

          // ── Image(s) ───────────────────────────────────────────────────
          if (images.isNotEmpty)
            GestureDetector(
              onDoubleTap: _handleLike,
              child: Stack(
                children: [
                  SizedBox(
                    height: 320,
                    child: images.length > 1
                        ? PageView.builder(
                            itemCount: images.length,
                            onPageChanged: (i) =>
                                setState(() => _currentImageIndex = i),
                            itemBuilder: (_, i) => _PostImage(
                              url: images[i],
                              category: post.category,
                            ),
                          )
                        : _PostImage(
                            url: images[0],
                            category: post.category,
                          ),
                  ),
                  // Image count indicator
                  if (images.length > 1)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1}/${images.length}',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  // Dot indicators
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
                            width: i == _currentImageIndex ? 16 : 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: i == _currentImageIndex
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Category badge overlay
                  Positioned(
                    bottom: images.length > 1 ? 28 : 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: post.category.color.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(post.category.icon,
                              size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            post.category.labelAr,
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Action Row ──────────────────────────────────────────────────
          _ActionRow(
            post: post,
            isDark: isDark,
            likeAnim: _likeAnim,
            onLike: _handleLike,
            onComment: () => context.push('${AppRoutes.feedDetail}/${post.id}'),
            onSave: () {
              HapticFeedback.lightImpact();
              ref.read(worksProvider.notifier).toggleSave(post.id);
            },
          ),

          // ── Likes & Beneficiaries ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 4),
            child: Row(
              children: [
                Text(
                  '${_formatNum(post.likeCount)} إعجاب',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF111111),
                  ),
                ),
                if (post.beneficiaryCount > 0) ...[
                  const SizedBox(width: 8),
                  Text('•',
                      style: TextStyle(
                          color: isDark
                              ? const Color(0xFF777777)
                              : const Color(0xFFAAAAAA))),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      const Icon(Icons.people_alt_rounded,
                          size: 14, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 3),
                      Text(
                        '${_formatNum(post.beneficiaryCount)} مستفيد',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7C3AED),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── Caption ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: GoogleFonts.cairo(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.description.length > 120
                            ? '${post.description.substring(0, 120)}...'
                            : post.description,
                        style: GoogleFonts.cairo(
                          fontSize: 12.5,
                          color: isDark
                              ? const Color(0xFFCCCCCC)
                              : const Color(0xFF444444),
                          height: 1.5,
                        ),
                      ),
                      if (post.description.length > 120)
                        GestureDetector(
                          onTap: () => setState(() => _expanded = true),
                          child: Text(
                            'المزيد',
                            style: GoogleFonts.cairo(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFF888888)
                                  : const Color(0xFF999999),
                            ),
                          ),
                        ),
                    ],
                  ),
                  secondChild: Text(
                    post.description,
                    style: GoogleFonts.cairo(
                      fontSize: 12.5,
                      color: isDark
                          ? const Color(0xFFCCCCCC)
                          : const Color(0xFF444444),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Tags ───────────────────────────────────────────────────────
          if (post.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Wrap(
                spacing: 4,
                children: post.tags
                    .map((t) => _TagChip(tag: t, isDark: isDark))
                    .toList(),
              ),
            ),

          // ── Location ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 13,
                    color: isDark
                        ? const Color(0xFF888888)
                        : const Color(0xFF999999)),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    post.location,
                    style: GoogleFonts.cairo(
                      fontSize: 11.5,
                      color: isDark
                          ? const Color(0xFF888888)
                          : const Color(0xFF999999),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // ── Comments Preview ──────────────────────────────────────────
          if (post.comments.isNotEmpty)
            _CommentsPreview(
              post: post,
              isDark: isDark,
              onViewAll: () =>
                  context.push('${AppRoutes.feedDetail}/${post.id}'),
            ),

          // ── Date ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 12),
            child: Text(
              _formatDate(post.date),
              style: GoogleFonts.cairo(
                fontSize: 10.5,
                color:
                    isDark ? const Color(0xFF666666) : const Color(0xFFAAAAAA),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNum(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}ك';
    return n.toString();
  }

  String _formatDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays == 0) return 'اليوم';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    return DateFormat('dd MMM yyyy', 'ar').format(d);
  }
}

// ── Post Header ──────────────────────────────────────────────────────────────
class _PostHeader extends StatelessWidget {
  final WorkPost post;
  final bool isDark;
  const _PostHeader({required this.post, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        children: [
          // Author avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: post.category.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Icon(post.category.icon, color: Colors.white, size: 20),
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
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF111111),
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
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.more_horiz_rounded,
              color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Post Image ────────────────────────────────────────────────────────────────
class _PostImage extends StatelessWidget {
  final String url;
  final WorkCategory category;
  const _PostImage({required this.url, required this.category});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (_, __) => Container(
        color: category.color.withValues(alpha: 0.1),
        child: Center(
          child: Icon(category.icon,
              size: 48, color: category.color.withValues(alpha: 0.3)),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        color: category.color.withValues(alpha: 0.1),
        child:
            Center(child: Icon(category.icon, size: 48, color: category.color)),
      ),
    );
  }
}

// ── Action Row ────────────────────────────────────────────────────────────────
class _ActionRow extends StatelessWidget {
  final WorkPost post;
  final bool isDark;
  final Animation<double> likeAnim;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onSave;

  const _ActionRow({
    required this.post,
    required this.isDark,
    required this.likeAnim,
    required this.onLike,
    required this.onComment,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor =
        isDark ? const Color(0xFFDDDDDD) : const Color(0xFF222222);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      child: Row(
        children: [
          // Like
          ScaleTransition(
            scale: likeAnim,
            child: IconButton(
              onPressed: onLike,
              icon: Icon(
                post.isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: post.isLiked ? const Color(0xFFEF4444) : iconColor,
                size: 26,
              ),
            ),
          ),
          // Comment
          IconButton(
            onPressed: onComment,
            icon: Icon(Icons.chat_bubble_outline_rounded,
                color: iconColor, size: 24),
          ),
          // Share
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.near_me_outlined, color: iconColor, size: 24),
          ),
          const Spacer(),
          // Views
          Row(
            children: [
              Icon(Icons.visibility_outlined,
                  size: 15,
                  color: isDark
                      ? const Color(0xFF888888)
                      : const Color(0xFFAAAAAA)),
              const SizedBox(width: 3),
              Text(
                _fmt(post.viewCount),
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: isDark
                      ? const Color(0xFF888888)
                      : const Color(0xFFAAAAAA),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          // Save
          IconButton(
            onPressed: onSave,
            icon: Icon(
              post.isSaved
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: post.isSaved ? const Color(0xFF7C3AED) : iconColor,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}ك';
    return n.toString();
  }
}

// ── Tag Chip ─────────────────────────────────────────────────────────────────
class _TagChip extends StatelessWidget {
  final String tag;
  final bool isDark;
  const _TagChip({required this.tag, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      '#$tag',
      style: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF3B82F6),
      ),
    );
  }
}

// ── Comments Preview ──────────────────────────────────────────────────────────
class _CommentsPreview extends StatelessWidget {
  final WorkPost post;
  final bool isDark;
  final VoidCallback onViewAll;
  const _CommentsPreview(
      {required this.post, required this.isDark, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final comments = post.comments.take(2).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.comments.length > 2)
            GestureDetector(
              onTap: onViewAll,
              child: Text(
                'عرض جميع التعليقات ${post.comments.length}',
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  color: isDark
                      ? const Color(0xFF888888)
                      : const Color(0xFF999999),
                ),
              ),
            ),
          ...comments.map(
            (c) => Padding(
              padding: const EdgeInsets.only(top: 3),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${c.authorName} ',
                      style: GoogleFonts.cairo(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF111111),
                      ),
                    ),
                    TextSpan(
                      text: c.text.length > 80
                          ? '${c.text.substring(0, 80)}...'
                          : c.text,
                      style: GoogleFonts.cairo(
                        fontSize: 12.5,
                        color: isDark
                            ? const Color(0xFFCCCCCC)
                            : const Color(0xFF444444),
                      ),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grid View ─────────────────────────────────────────────────────────────────
class _GridView extends StatelessWidget {
  final List<WorkPost> posts;
  final bool isDark;
  const _GridView({required this.posts, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Center(
        child: Text('لا توجد منشورات',
            style: GoogleFonts.cairo(color: Colors.grey)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return GestureDetector(
          onTap: () => context.push('${AppRoutes.feedDetail}/${post.id}'),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (post.imageUrl != null)
                CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: post.category.color.withValues(alpha: 0.15),
                    child: Center(
                      child:
                          Icon(post.category.icon, color: post.category.color),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: post.category.color.withValues(alpha: 0.15),
                    child: Center(
                      child:
                          Icon(post.category.icon, color: post.category.color),
                    ),
                  ),
                )
              else
                Container(
                  color: post.category.color.withValues(alpha: 0.15),
                  child: Center(
                    child: Icon(post.category.icon,
                        size: 32, color: post.category.color),
                  ),
                ),
              // Featured indicator
              if (post.isFeatured)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star_rounded,
                        size: 12, color: Colors.white),
                  ),
                ),
              // Multiple images indicator
              if ((post.imageUrls?.length ?? 0) > 1)
                const Positioned(
                  top: 4,
                  left: 4,
                  child: Icon(Icons.collections_rounded,
                      size: 16, color: Colors.white),
                ),
            ],
          ),
        );
      },
    );
  }
}
