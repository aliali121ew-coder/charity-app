part of 'main_scaffold.dart';

class _AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final String currentPath;
  const _AppTopBar({required this.currentPath});

  @override
  Size get preferredSize {
    final topPadding = WidgetsBinding.instance.platformDispatcher.views.first.padding.top /
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    return Size.fromHeight(56 + topPadding);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: topPadding, left: 16, right: 16),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              Builder(
                builder: (ctx) => IconButton(
                  onPressed: () {
                    Scaffold.of(ctx).openDrawer();
                  },
                  icon: Icon(
                    Icons.menu_rounded,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: l10n.isRtl ? Alignment.centerRight : Alignment.centerLeft,
                  child: Text(
                    _pageTitle(currentPath, l10n),
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ),
              Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_outlined,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    onPressed: () {},
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  size: 20,
                ),
                onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
              ),
              if (user != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: _UserAvatar(name: user.name),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _pageTitle(String path, AppLocalizations l10n) {
    switch (path) {
      case AppRoutes.subscribers: return 'بيانات العوائل';
      case AppRoutes.families: return 'المندوبين';
      case AppRoutes.aid: return l10n.tr('aid');
      case AppRoutes.logs: return l10n.tr('operations_log');
      case AppRoutes.reports: return l10n.tr('reports');
      case AppRoutes.settings: return l10n.tr('settings');
      case AppRoutes.works: return l10n.tr('works');
      case AppRoutes.helpRequests: return l10n.tr('help_requests');
      case AppRoutes.donations: return 'التبرعات والمدفوعات';
      case AppRoutes.competitions: return 'المسابقات والجوائز';
      case AppRoutes.ibadat: return 'العبادات';
      default: return l10n.tr('works');
    }
  }
}

class _UserAvatar extends StatelessWidget {
  final String name;
  const _UserAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0]).join()
        : '?';
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.kpiPurple,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }
}

// ── Nav Item Data ─────────────────────────────────────────────────────────────
class _NavItemData {
  final IconData icon, activeIcon;
  final String label, path;
  final Color accent;
  const _NavItemData({
    required this.icon, required this.activeIcon,
    required this.label, required this.path, required this.accent,
  });
}

// ── Drawer ────────────────────────────────────────────────────────────────────
