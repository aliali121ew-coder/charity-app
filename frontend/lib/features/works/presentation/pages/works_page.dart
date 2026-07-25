import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/shared/models/work_post_model.dart';
import 'package:charity_app/features/works/presentation/providers/works_provider.dart';

part '../widgets/works_banner_filters.dart';
part '../widgets/works_cards.dart';
part '../widgets/works_detail_sheet.dart';

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
