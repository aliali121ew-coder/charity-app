part of '../pages/works_page.dart';

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
