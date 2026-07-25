part of '../pages/works_page.dart';

class _FeaturedSection extends ConsumerWidget {
  final bool isDark;
  final double screenW;
  const _FeaturedSection({required this.isDark, required this.screenW});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = ref
        .read(worksProvider.notifier)
        .state
        .all
        .where((p) => p.isFeatured)
        .toList();
    if (featured.isEmpty) return const SizedBox.shrink();

    final isDesktop = screenW > 800;
    final cardH = isDesktop ? 260.0 : 220.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientOrange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'أعمال مميزة',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.star_rounded,
                  size: 16, color: AppColors.orange),
            ],
          ),
        ),
        if (isDesktop)
          // Desktop: 2-column row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: [
                for (int i = 0; i < featured.take(2).length; i++) ...[
                  if (i > 0) const SizedBox(width: 14),
                  Expanded(
                    child: SizedBox(
                      height: cardH,
                      child: _FeaturedCard(
                          post: featured[i], isDark: isDark),
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          // Mobile: horizontal scroll
          SizedBox(
            height: cardH,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              physics: const BouncingScrollPhysics(),
              itemCount: featured.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.only(left: 14),
                child: SizedBox(
                  width: 300,
                  child: _FeaturedCard(
                      post: featured[i], isDark: isDark),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Featured Hero Card
// ─────────────────────────────────────────────────────────────────────────────
class _FeaturedCard extends StatefulWidget {
  final WorkPost post;
  final bool isDark;
  const _FeaturedCard({required this.post, required this.isDark});

  @override
  State<_FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<_FeaturedCard> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return GestureDetector(
      onTap: () => _showDetail(context, post),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: widget.isDark ? 0.4 : 0.14),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _NetworkImage(url: post.imageUrl),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.25),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.3, 0.6, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _CategoryBadge(category: post.category),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: _LikeButton(
                  liked: _liked,
                  size: 34,
                  onTap: () => setState(() => _liked = !_liked),
                ),
              ),
              // ⭐ مميز ribbon
              Positioned(
                top: 10,
                left: 52,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color:
                            const Color(0xFFF59E0B).withValues(alpha: 0.5),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 11, color: Colors.white),
                      const SizedBox(width: 3),
                      Text(
                        'مميز',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      post.title,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.8)),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            post.location,
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.people_alt_rounded,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.8)),
                        const SizedBox(width: 3),
                        Text(
                          '${post.beneficiaryCount} مستفيد',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Work Card  — fixed imageHeight, no Expanded in footer
// ─────────────────────────────────────────────────────────────────────────────
class _WorkCard extends StatefulWidget {
  final WorkPost post;
  final bool isDark;
  final double imageHeight;
  final int maxBeneficiaries;

  const _WorkCard({
    required this.post,
    required this.isDark,
    required this.imageHeight,
    required this.maxBeneficiaries,
  });

  @override
  State<_WorkCard> createState() => _WorkCardState();
}

class _WorkCardState extends State<_WorkCard>
    with SingleTickerProviderStateMixin {
  bool _liked = false;
  late final AnimationController _scaleCtrl;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isDark = widget.isDark;

    return ScaleTransition(
      scale: _scaleCtrl,
      child: GestureDetector(
        onTapDown: (_) => _scaleCtrl.reverse(),
        onTapUp: (_) => _scaleCtrl.forward(),
        onTapCancel: () => _scaleCtrl.forward(),
        onTap: () => _showDetail(context, post),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image: fixed pixel height ─────────────────────────
              SizedBox(
                height: widget.imageHeight,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _NetworkImage(url: post.imageUrl),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.82),
                            ],
                            stops: const [0.25, 0.55, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _CategoryBadge(
                            category: post.category, small: true),
                      ),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: _LikeButton(
                          liked: _liked,
                          size: 30,
                          onTap: () =>
                              setState(() => _liked = !_liked),
                        ),
                      ),
                      // Title + description on the image
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 10,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              post.title,
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              post.description,
                              style: GoogleFonts.cairo(
                                fontSize: 9,
                                color: Colors.white
                                    .withValues(alpha: 0.75),
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Footer: FIXED 108px, no Expanded ─────────────────
              SizedBox(
                height: 108,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Location + date pill
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 11,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              post.location,
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: post.category.color
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              DateFormat('d/M', 'ar').format(post.date),
                              style: GoogleFonts.cairo(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: post.category.color,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Progress bar (beneficiaries)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.people_alt_rounded,
                                  size: 10, color: post.category.color),
                              const SizedBox(width: 3),
                              Text(
                                '${_fmtNum(post.beneficiaryCount)} مستفيد',
                                style: GoogleFonts.cairo(
                                  fontSize: 9,
                                  color: post.category.color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: widget.maxBeneficiaries > 0
                                  ? post.beneficiaryCount /
                                      widget.maxBeneficiaries
                                  : 0,
                              minHeight: 4,
                              backgroundColor: post.category.color
                                  .withValues(alpha: 0.12),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  post.category.color),
                            ),
                          ),
                        ],
                      ),

                      // Views + action button (mobile only)
                      Row(
                        children: [
                          _MiniStat(
                            icon: Icons.remove_red_eye_rounded,
                            label: _fmtNum(post.viewCount),
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                          const Spacer(),
                          if (MediaQuery.of(context).size.width < 480)
                            SizedBox(
                              height: 24,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      post.category.color,
                                      post.category.gradientColors.last,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  child: Center(
                                    child: Text(
                                      'عرض التفاصيل',
                                      style: GoogleFonts.cairo(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryBadge extends StatelessWidget {
  final WorkCategory category;
  final bool small;
  const _CategoryBadge({required this.category, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 8 : 10, vertical: small ? 3 : 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: category.gradientColors),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!small) ...[
            Icon(category.icon, size: 11, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            category.labelAr,
            style: GoogleFonts.cairo(
              fontSize: small ? 9 : 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _LikeButton extends StatelessWidget {
  final bool liked;
  final double size;
  final VoidCallback onTap;
  const _LikeButton(
      {required this.liked, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: liked ? 1.0 : 0.18),
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.4)),
        ),
        child: Icon(
          liked
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          size: size * 0.5,
          color: liked ? AppColors.red : Colors.white,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MiniStat(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: GoogleFonts.cairo(fontSize: 10, color: color)),
      ],
    );
  }
}

String _fmtNum(int n) =>
    n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

// ─────────────────────────────────────────────────────────────────────────────
//  Detail Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
void _showDetail(BuildContext context, WorkPost post) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _WorkDetailSheet(post: post),
  );
}

