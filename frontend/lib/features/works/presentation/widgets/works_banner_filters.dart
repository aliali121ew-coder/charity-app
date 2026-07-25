part of '../pages/works_page.dart';

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
