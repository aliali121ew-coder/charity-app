import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/shared/models/work_post_model.dart';
import 'package:charity_app/features/works/presentation/providers/works_provider.dart';

// ── Responsive helpers ────────────────────────────────────────────────────────
int _crossCount(double w) {
  if (w < 480) return 2;
  if (w < 720) return 3;
  if (w < 1050) return 4;
  return 5;
}

double _imageHeight(double cardW) => cardW > 260 ? cardW * 0.9 : cardW;

// ─────────────────────────────────────────────────────────────────────────────
//  Works Page
// ─────────────────────────────────────────────────────────────────────────────
class WorksPage extends ConsumerStatefulWidget {
  const WorksPage({super.key});

  @override
  ConsumerState<WorksPage> createState() => _WorksPageState();
}

class _WorksPageState extends ConsumerState<WorksPage>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final works = ref.watch(worksProvider);
    final screenW = MediaQuery.of(context).size.width;
    final cols = _crossCount(screenW);

    // Compute exact card dimensions so the footer never has empty space
    const hPad = 16.0 * 2;
    final gaps = 14.0 * (cols - 1);
    final cardW = (screenW - hPad - gaps) / cols;
    final imgH = _imageHeight(cardW);
    const footerH = 108.0;
    final aspectRatio = cardW / (imgH + footerH);
    final maxBeneficiaries = works.all.isEmpty
        ? 1
        : works.all.map((p) => p.beneficiaryCount).reduce(
            (a, b) => a > b ? a : b);

    return FadeTransition(
      opacity: _fadeAnim,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero Banner ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _HeroBanner(
              totalPosts: ref.read(worksProvider.notifier).totalPosts,
              totalBeneficiaries:
                  ref.read(worksProvider.notifier).totalBeneficiaries,
              totalViews: ref.read(worksProvider.notifier).totalViews,
              monthlyPosts: ref.read(worksProvider.notifier).monthlyPosts,
              isDark: isDark,
              isWide: screenW > 900,
            ),
          ),

          // ── Search + Filters ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SearchAndFilters(
              controller: _searchCtrl,
              selected: works.selectedCategory,
              counts: ref.read(worksProvider.notifier).categoryCounts,
              totalPosts: ref.read(worksProvider.notifier).totalPosts,
              isDark: isDark,
              isWide: screenW > 900,
              onSearch: (q) => ref.read(worksProvider.notifier).search(q),
              onCategory: (cat) =>
                  ref.read(worksProvider.notifier).filterByCategory(cat),
            ),
          ),

          // ── Featured Section ──────────────────────────────────────────────
          if (works.selectedCategory == WorkCategory.all &&
              works.searchQuery.isEmpty)
            SliverToBoxAdapter(
              child: _FeaturedSection(isDark: isDark, screenW: screenW),
            ),

          // ── Section Label ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPurple,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    works.selectedCategory == WorkCategory.all &&
                            works.searchQuery.isEmpty
                        ? 'جميع الأعمال'
                        : 'نتائج البحث',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${works.filtered.length}',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Works Grid ────────────────────────────────────────────────────
          works.filtered.isEmpty
              ? SliverToBoxAdapter(child: _EmptyState(isDark: isDark))
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverGrid(
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: aspectRatio,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _WorkCard(
                        post: works.filtered[i],
                        isDark: isDark,
                        imageHeight: imgH,
                        maxBeneficiaries: maxBeneficiaries,
                      ),
                      childCount: works.filtered.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Hero Banner  (replaces _StatsHeader)
// ─────────────────────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final int totalPosts;
  final int totalBeneficiaries;
  final int totalViews;
  final int monthlyPosts;
  final bool isDark;
  final bool isWide;

  const _HeroBanner({
    required this.totalPosts,
    required this.totalBeneficiaries,
    required this.totalViews,
    required this.monthlyPosts,
    required this.isDark,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: isWide
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: _banner(context),
              ),
            )
          : _banner(context),
    );
  }

  Widget _banner(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4C1D95), Color(0xFF7C3AED), Color(0xFF5B4FCF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -10,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    const Icon(Icons.volunteer_activism_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'أعمالنا الخيرية',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // KPI row
                Row(
                  children: [
                    Expanded(
                      child: _BannerStat(
                        label: 'الأعمال',
                        value: totalPosts,
                        icon: Icons.workspace_premium_rounded,
                      ),
                    ),
                    _VertDivider(),
                    Expanded(
                      child: _BannerStat(
                        label: 'المستفيدون',
                        value: totalBeneficiaries,
                        icon: Icons.people_alt_rounded,
                      ),
                    ),
                    _VertDivider(),
                    Expanded(
                      child: _BannerStat(
                        label: 'الزوار',
                        value: totalViews,
                        icon: Icons.remove_red_eye_rounded,
                      ),
                    ),
                    if (isWide) ...[
                      _VertDivider(),
                      Expanded(
                        child: _BannerStat(
                          label: 'هذا الشهر',
                          value: monthlyPosts,
                          icon: Icons.calendar_month_rounded,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 48,
        color: Colors.white.withValues(alpha: 0.2),
      );
}

class _BannerStat extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  const _BannerStat(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 18),
          const SizedBox(height: 6),
          Text(
            _fmtNum(v.round()),
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Search + Filters
// ─────────────────────────────────────────────────────────────────────────────
class _SearchAndFilters extends StatelessWidget {
  final TextEditingController controller;
  final WorkCategory selected;
  final Map<WorkCategory, int> counts;
  final int totalPosts;
  final bool isDark;
  final bool isWide;
  final ValueChanged<String> onSearch;
  final ValueChanged<WorkCategory> onCategory;

  const _SearchAndFilters({
    required this.controller,
    required this.selected,
    required this.counts,
    required this.totalPosts,
    required this.isDark,
    required this.isWide,
    required this.onSearch,
    required this.onCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: isWide
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: _searchField,
                  ),
                )
              : _searchField,
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            children: WorkCategory.values.map((cat) {
              final count = cat == WorkCategory.all
                  ? totalPosts
                  : (counts[cat] ?? 0);
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _CategoryChip(
                  category: cat,
                  isSelected: selected == cat,
                  count: count,
                  isDark: isDark,
                  onTap: () => onCategory(cat),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget get _searchField => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          onChanged: onSearch,
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: 'ابحث في أعمال المؤسسة...',
            hintStyle: GoogleFonts.cairo(
              fontSize: 13,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
        ),
      );
}

class _CategoryChip extends StatelessWidget {
  final WorkCategory category;
  final bool isSelected;
  final int count;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.count,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: category.gradientColors)
              : null,
          color: isSelected
              ? null
              : isDark
                  ? AppColors.cardDark
                  : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: category.color.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
            ),
            const SizedBox(width: 6),
            Text(
              category.labelAr,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : category.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : category.color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Featured Section
// ─────────────────────────────────────────────────────────────────────────────
class _FeaturedSection extends ConsumerWidget {
  final bool isDark;
  final double screenW;
  const _FeaturedSection({required this.isDark, required this.screenW});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = ref
        .read(worksProvider)
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

class _WorkDetailSheet extends StatefulWidget {
  final WorkPost post;
  const _WorkDetailSheet({required this.post});

  @override
  State<_WorkDetailSheet> createState() => _WorkDetailSheetState();
}

class _WorkDetailSheetState extends State<_WorkDetailSheet> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final screenW = MediaQuery.of(context).size.width;
    final isDesktop = screenW > 800;

    return DraggableScrollableSheet(
      initialChildSize: isDesktop ? 0.95 : 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color:
                    isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                physics: const BouncingScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: isDesktop ? 700 : double.infinity),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero image
                        Container(
                          margin: const EdgeInsets.all(16),
                          height: isDesktop ? 320 : 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                    alpha: isDark ? 0.4 : 0.12),
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
                                        Colors.black
                                            .withValues(alpha: 0.6),
                                      ],
                                      stops: const [0.5, 1.0],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 14,
                                  left: 14,
                                  child: Row(
                                    children: [
                                      _CategoryBadge(
                                          category: post.category),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.18),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Text(
                                          DateFormat('d MMM yyyy', 'ar')
                                              .format(post.date),
                                          style: GoogleFonts.cairo(
                                            fontSize: 11,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.title,
                                style: GoogleFonts.cairo(
                                  fontSize: isDesktop ? 22 : 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _InfoChip(
                                      icon: Icons.location_on_rounded,
                                      label: post.location,
                                      color: AppColors.info,
                                      isDark: isDark),
                                  _InfoChip(
                                      icon: Icons.people_alt_rounded,
                                      label:
                                          '${post.beneficiaryCount} مستفيد',
                                      color: AppColors.success,
                                      isDark: isDark),
                                  _InfoChip(
                                      icon: Icons.remove_red_eye_rounded,
                                      label:
                                          '${_fmtNum(post.viewCount)} مشاهدة',
                                      color: AppColors.primary,
                                      isDark: isDark),
                                  _InfoChip(
                                      icon: Icons.favorite_rounded,
                                      label: '${post.likeCount} إعجاب',
                                      color: AppColors.red,
                                      isDark: isDark),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'تفاصيل العمل',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                post.description,
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                  height: 1.8,
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (post.tags.isNotEmpty) ...[
                                Text(
                                  'الوسوم',
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: post.tags
                                      .map((t) => Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 5),
                                            decoration: BoxDecoration(
                                              color: post.category.color
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: post.category.color
                                                    .withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Text(
                                              '#$t',
                                              style: GoogleFonts.cairo(
                                                fontSize: 12,
                                                color: post.category.color,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                                const SizedBox(height: 24),
                              ],
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: post
                                              .category.gradientColors,
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: post.category.color
                                                .withValues(alpha: 0.35),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          onTap: () =>
                                              Navigator.of(context).pop(),
                                          child: Center(
                                            child: Text(
                                              'مشاركة العمل',
                                              style: GoogleFonts.cairo(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _liked = !_liked),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: _liked
                                            ? AppColors.red
                                                .withValues(alpha: 0.12)
                                            : isDark
                                                ? AppColors.cardDark
                                                : AppColors
                                                    .surfaceVariantLight,
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        border: Border.all(
                                          color: _liked
                                              ? AppColors.red
                                                  .withValues(alpha: 0.4)
                                              : isDark
                                                  ? AppColors.borderDark
                                                  : AppColors.borderLight,
                                        ),
                                      ),
                                      child: Icon(
                                        _liked
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        color: _liked
                                            ? AppColors.red
                                            : isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Network Image with shimmer
// ─────────────────────────────────────────────────────────────────────────────
class _NetworkImage extends StatelessWidget {
  final String? url;
  const _NetworkImage({this.url});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (url == null) {
      return Container(
        color:
            isDark ? AppColors.cardDark : AppColors.surfaceVariantLight,
        child: const Center(
            child:
                Icon(Icons.image_rounded, size: 40, color: Colors.grey)),
      );
    }
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (_, __) => Shimmer.fromColors(
        baseColor:
            isDark ? AppColors.cardDark : const Color(0xFFE2E8F0),
        highlightColor:
            isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
        child: Container(color: Colors.white),
      ),
      errorWidget: (_, __, ___) => Container(
        color:
            isDark ? AppColors.cardDark : AppColors.surfaceVariantLight,
        child: const Center(
          child: Icon(Icons.broken_image_rounded,
              size: 40, color: Colors.grey),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Empty State
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded,
                size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'جرّب البحث بكلمات مختلفة أو اختر فئة أخرى',
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
