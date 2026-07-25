part of 'main_scaffold.dart';

class _BottomNavBar extends StatelessWidget {
  final String currentPath;

  const _BottomNavBar({required this.currentPath});

  static const _navItems = [
    _BottomNavItem(
      icon: Icons.home_rounded,
      label: 'الرئيسية',
      path: AppRoutes.works,
      accent: Color(0xFF7C3AED),
    ),
    _BottomNavItem(
      icon: Icons.mosque_rounded,
      label: 'العبادات',
      path: AppRoutes.ibadat,
      accent: Color(0xFF0E7A5B),
    ),
    _BottomNavItem(
      icon: Icons.family_restroom_rounded,
      label: 'العوائل',
      path: AppRoutes.subscribers,
      accent: Color(0xFF10B981),
    ),
    _BottomNavItem(
      icon: Icons.bar_chart_rounded,
      label: 'التقارير',
      path: AppRoutes.reports,
      accent: Color(0xFFEF4444),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // كبح تكبير الخط حتى لا ينكسر الشريط على إعدادات الخط الكبيرة أو الشاشات الصغيرة.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.10),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 8,
          right: 8,
          top: 5,
          bottom: bottomPadding > 0 ? bottomPadding + 2 : 8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Item 1: أعمال المؤسسة
            _BottomNavTile(
              item: _navItems[0],
              isActive: currentPath == _navItems[0].path,
              isDark: isDark,
            ),
            // Item 2: المنشورات
            _BottomNavTile(
              item: _navItems[1],
              isActive: currentPath == _navItems[1].path,
              isDark: isDark,
            ),
            // Center FAB
            _CenterFab(currentPath: currentPath),
            // Item 3: بيانات العوائل
            _BottomNavTile(
              item: _navItems[2],
              isActive: currentPath == _navItems[2].path,
              isDark: isDark,
            ),
            // Item 4: المندوبين
            _BottomNavTile(
              item: _navItems[3],
              isActive: currentPath == _navItems[3].path,
              isDark: isDark,
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _BottomNavItem {
  final IconData icon;
  final String label;
  final String path;
  final Color accent;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.accent,
  });
}

class _BottomNavTile extends StatelessWidget {
  final _BottomNavItem item;
  final bool isActive;
  final bool isDark;

  const _BottomNavTile({
    required this.item,
    required this.isActive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isActive) return;
          context.go(item.path);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? item.accent.withValues(alpha: isDark ? 0.15 : 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: 21,
                color: isActive
                    ? item.accent
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? item.accent
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isActive ? 18 : 0,
                height: isActive ? 3 : 0,
                decoration: BoxDecoration(
                  color: item.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterFab extends StatelessWidget {
  final String currentPath;

  const _CenterFab({required this.currentPath});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: GestureDetector(
        onTap: () {
          // FAB action — start a new help request (the "+" action)
          context.go(AppRoutes.helpRequestType);
        },
        child: Container(
          width: 48,
          height: 48,
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.45),
                blurRadius: 14,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────
