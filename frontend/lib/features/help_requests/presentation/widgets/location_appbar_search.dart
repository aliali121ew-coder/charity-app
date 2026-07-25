part of '../pages/location_step_page.dart';

class _TapMarker extends StatelessWidget {
  const _TapMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 8,
              ),
            ],
          ),
          child:
              const Icon(Icons.place, color: AppColors.primary, size: 16),
        ),
        Container(width: 2, height: 8, color: AppColors.primary),
      ],
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────

class _MapAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDark;
  final bool isSearchActive;
  final VoidCallback onManual;
  final VoidCallback onSearch;

  const _MapAppBar({
    required this.isDark,
    required this.onManual,
    required this.onSearch,
    required this.isSearchActive,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Color get _cardBg =>
      isDark ? const Color(0xE6111827) : const Color(0xF5FFFFFF);

  BoxDecoration get _floatingDecoration => BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: _floatingDecoration,
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              size: 16,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/help-requests/type');
            }
          },
        ),
      ),
      title: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pin_drop_outlined,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              'حدد موقعك',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
      centerTitle: false,
      actions: [
        // زر البحث
        Container(
          margin: const EdgeInsets.only(right: 4, top: 8, bottom: 8),
          decoration: isSearchActive
              ? BoxDecoration(
                  gradient: AppColors.gradientPurple,
                  borderRadius: BorderRadius.circular(12),
                )
              : _floatingDecoration,
          child: IconButton(
            icon: Icon(
              isSearchActive ? Icons.search_off : Icons.search_rounded,
              size: 18,
              color: isSearchActive
                  ? Colors.white
                  : AppColors.primary,
            ),
            onPressed: onSearch,
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ),
        // زر يدوي
        Container(
          margin:
              const EdgeInsets.only(right: 8, top: 8, bottom: 8),
          decoration: _floatingDecoration,
          child: TextButton.icon(
            onPressed: onManual,
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.edit_location_alt_outlined,
                size: 15, color: AppColors.primary),
            label: Text(
              'يدوي',
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── لوحة البحث ────────────────────────────────────────────────────────────────

class _SearchPanel extends StatelessWidget {
  final TextEditingController controller;
  final List<_SearchResult> results;
  final bool isSearching;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final ValueChanged<_SearchResult> onSelect;
  final VoidCallback onClose;

  const _SearchPanel({
    required this.controller,
    required this.results,
    required this.isSearching,
    required this.isDark,
    required this.onChanged,
    required this.onSelect,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xF0111827) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // حقل البحث
          Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 14),
                child: Icon(Icons.search_rounded,
                    color: AppColors.primary, size: 20),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن منطقة، شارع، مكان...',
                    hintStyle: GoogleFonts.cairo(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                  ),
                  onChanged: onChanged,
                ),
              ),
              if (isSearching)
                const Padding(
                  padding: EdgeInsets.only(right: 14),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),

          // النتائج
          if (results.isNotEmpty) ...[
            Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: results.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  indent: 50,
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
                ),
                itemBuilder: (ctx, i) {
                  final r = results[i];
                  return InkWell(
                    onTap: () => onSelect(r),
                    borderRadius: i == results.length - 1
                        ? const BorderRadius.vertical(
                            bottom: Radius.circular(16))
                        : BorderRadius.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: AppColors.primary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.shortName,
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                                Text(
                                  r.displayName
                                      .split('،')
                                      .take(3)
                                      .join('،'),
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (r.type.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(top: 3),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.08),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      r.type,
                                      style: GoogleFonts.cairo(
                                        fontSize: 10,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_left_rounded,
                              size: 16,
                              color: AppColors.primary),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          if (!isSearching &&
              results.isEmpty &&
              controller.text.length > 1)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'لا توجد نتائج',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Step Badge ────────────────────────────────────────────────────────────────

