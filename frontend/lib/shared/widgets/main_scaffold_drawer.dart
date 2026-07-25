part of 'main_scaffold.dart';

class _AppDrawer extends ConsumerStatefulWidget {
  final String currentPath;
  const _AppDrawer({required this.currentPath});

  @override
  ConsumerState<_AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<_AppDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _headerAnim;

  static const _navItems = [
    _NavItemData(icon: Icons.home_outlined, activeIcon: Icons.home_rounded,
        label: 'أعمال المؤسسة', path: AppRoutes.works, accent: Color(0xFF7C3AED)),
    _NavItemData(icon: Icons.family_restroom_rounded, activeIcon: Icons.family_restroom_rounded,
        label: 'بيانات العوائل', path: AppRoutes.subscribers, accent: Color(0xFF10B981)),
    _NavItemData(icon: Icons.badge_outlined, activeIcon: Icons.badge_rounded,
        label: 'المندوبين', path: AppRoutes.families, accent: Color(0xFF06B6D4)),
    _NavItemData(icon: Icons.volunteer_activism_outlined, activeIcon: Icons.volunteer_activism_rounded,
        label: 'المساعدات', path: AppRoutes.aid, accent: Color(0xFFF59E0B)),
    _NavItemData(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded,
        label: 'سجل العمليات', path: AppRoutes.logs, accent: Color(0xFF8B5CF6)),
    _NavItemData(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded,
        label: 'التقارير', path: AppRoutes.reports, accent: Color(0xFFEF4444)),
    _NavItemData(icon: Icons.support_agent_outlined, activeIcon: Icons.support_agent_rounded,
        label: 'طلبات المساعدة', path: AppRoutes.helpRequests, accent: Color(0xFF059669)),
    _NavItemData(icon: Icons.payments_outlined, activeIcon: Icons.payments_rounded,
        label: 'التبرعات', path: AppRoutes.donations, accent: Color(0xFF10B981)),
    _NavItemData(icon: Icons.mosque_outlined, activeIcon: Icons.mosque_rounded,
        label: 'العبادات', path: AppRoutes.ibadat, accent: Color(0xFF0E7A5B)),
    _NavItemData(icon: Icons.emoji_events_outlined, activeIcon: Icons.emoji_events_rounded,
        label: 'المسابقات والجوائز', path: AppRoutes.competitions, accent: Color(0xFFFBBF24)),
    _NavItemData(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded,
        label: 'الإعدادات', path: AppRoutes.settings, accent: Color(0xFF64748B)),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _headerAnim = CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Animation<double> _itemAnim(int index) {
    final start = (0.1 + index * 0.07).clamp(0.0, 0.85);
    final end = (start + 0.35).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _ctrl,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;
    final drawerBg = isDark ? AppColors.drawerBgDark : AppColors.drawerBgLight;

    return Drawer(
      width: 270,
      backgroundColor: drawerBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Animated Header ──────────────────────────────────────────
          AnimatedBuilder(
            animation: _headerAnim,
            builder: (_, __) => Opacity(
              opacity: _headerAnim.value,
              child: Transform.translate(
                offset: Offset(0, -20 * (1 - _headerAnim.value)),
                child: _DrawerHeader(user: user, l10n: l10n),
              ),
            ),
          ),

          // ── Nav Items ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              child: Column(
                children: [
                  // Main section
                  _SectionLabel(label: 'القائمة الرئيسية', isDark: isDark),
                  ..._navItems.take(5).toList().asMap().entries.map((e) =>
                    _AnimatedNavItem(
                      anim: _itemAnim(e.key),
                      item: e.value,
                      currentPath: widget.currentPath,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _SectionLabel(label: 'الإدارة والتقارير', isDark: isDark),
                  ..._navItems.skip(5).toList().asMap().entries.map((e) =>
                    _AnimatedNavItem(
                      anim: _itemAnim(e.key + 5),
                      item: e.value,
                      currentPath: widget.currentPath,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Footer ────────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _itemAnim(10),
            builder: (_, __) => Opacity(
              opacity: _itemAnim(10).value,
              child: _DrawerFooter(ref: ref, l10n: l10n, isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Drawer Header ─────────────────────────────────────────────────────────────
class _DrawerHeader extends StatelessWidget {
  final dynamic user;
  final AppLocalizations l10n;
  const _DrawerHeader({required this.user, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4C3BC5), Color(0xFF2D1FA3), Color(0xFF1A1266)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          // Decorative circles
          const Positioned(right: -20, top: -20, child: _Circle(size: 100, alpha: 0.06)),
          const Positioned(left: 10, bottom: 10, child: _Circle(size: 60, alpha: 0.05)),
          const Positioned(right: 40, top: 50, child: _Circle(size: 40, alpha: 0.08)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(height: 12),
                Text(l10n.tr('app_name'),
                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                Text(l10n.tr('app_tagline'),
                    style: GoogleFonts.cairo(fontSize: 10, color: Colors.white.withValues(alpha: 0.65))),
                if (user != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                          ),
                          child: Center(child: Text(
                            user.name.isNotEmpty ? user.name.trim().split(' ').take(2).map((w) => w[0]).join() : '?',
                            style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                          )),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name,
                                  style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(
                                user.role == UserRole.admin ? 'مدير النظام' : 'موظف',
                                style: GoogleFonts.cairo(fontSize: 9, color: Colors.white.withValues(alpha: 0.7)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: user.role == UserRole.admin
                                ? const Color(0xFFFBBF24).withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user.role == UserRole.admin ? '👑' : '👤',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final double alpha;
  const _Circle({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
      child: Row(
        children: [
          Expanded(child: Container(
            height: 1,
            color: (isDark ? AppColors.borderDark : AppColors.borderLight).withValues(alpha: 0.5),
          )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(label,
                style: GoogleFonts.cairo(fontSize: 9, fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                    letterSpacing: 0.5)),
          ),
          Expanded(child: Container(
            height: 1,
            color: (isDark ? AppColors.borderDark : AppColors.borderLight).withValues(alpha: 0.5),
          )),
        ],
      ),
    );
  }
}

// ── Animated Nav Item ─────────────────────────────────────────────────────────
class _AnimatedNavItem extends StatelessWidget {
  final Animation<double> anim;
  final _NavItemData item;
  final String currentPath;
  final bool isDark;
  const _AnimatedNavItem({
    required this.anim, required this.item,
    required this.currentPath, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(24 * (1 - anim.value), 0),
          child: _NavItem(item: item, currentPath: currentPath, isDark: isDark),
        ),
      ),
    );
  }
}

// ── Nav Item ──────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final _NavItemData item;
  final String currentPath;
  final bool isDark;
  const _NavItem({required this.item, required this.currentPath, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isActive = currentPath == item.path;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
            if (isActive) return;
            // Navigate immediately; the shell keeps each page alive so this is
            // instant and doesn't need to wait for the drawer-close animation.
            context.go(item.path);
          },
          borderRadius: BorderRadius.circular(14),
          splashColor: item.accent.withValues(alpha: 0.12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isActive
                  ? item.accent.withValues(alpha: isDark ? 0.18 : 0.1)
                  : Colors.transparent,
              border: isActive
                  ? Border.all(color: item.accent.withValues(alpha: 0.3))
                  : null,
            ),
            child: Row(
              children: [
                // Icon container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? LinearGradient(
                            colors: [item.accent, item.accent.withValues(alpha: 0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isActive ? null : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isActive
                        ? [BoxShadow(color: item.accent.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))]
                        : null,
                  ),
                  child: Icon(
                    isActive ? item.activeIcon : item.icon,
                    size: 18,
                    color: isActive
                        ? Colors.white
                        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                      color: isActive
                          ? item.accent
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(color: item.accent, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: item.accent.withValues(alpha: 0.5), blurRadius: 4)]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Drawer Footer ─────────────────────────────────────────────────────────────
class _DrawerFooter extends StatelessWidget {
  final WidgetRef ref;
  final AppLocalizations l10n;
  final bool isDark;
  const _DrawerFooter({required this.ref, required this.l10n, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FooterBtn(
              icon: Icons.language_rounded,
              label: l10n.isArabic ? 'English' : 'العربية',
              color: AppColors.primary,
              onTap: () => ref.read(localeProvider.notifier).toggle(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FooterBtn(
              icon: Icons.logout_rounded,
              label: l10n.tr('logout'),
              color: AppColors.error,
              onTap: () async {
                Navigator.of(context).pop();
                await ref.read(authProvider.notifier).logout();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _FooterBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Column(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 3),
              Text(label, style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
