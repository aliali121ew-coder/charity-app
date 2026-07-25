part of '../pages/settings_page.dart';

class _UsersManagementSheet extends ConsumerStatefulWidget {
  const _UsersManagementSheet();

  @override
  ConsumerState<_UsersManagementSheet> createState() =>
      _UsersManagementSheetState();
}

class _UsersManagementSheetState
    extends ConsumerState<_UsersManagementSheet> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final users = ref.watch(usersProvider);
    final bgColor = isDark ? AppColors.cardDark : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.people_rounded,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'إدارة المستخدمين',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showAddUserDialog(context, ref),
                    icon: const Icon(Icons.person_add_rounded, size: 16),
                    label: Text('إضافة', style: GoogleFonts.cairo()),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // User list
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) =>
                    _UserCard(user: users[i], isDark: isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  final UserModel user;
  final bool isDark;
  const _UserCard({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = user.role == UserRole.admin;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        children: [
          ListTile(
            leading: _SmallAvatar(
                name: user.name, isActive: user.isActive, isAdmin: isAdmin),
            title: Text(
              user.name,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            subtitle: Text(
              user.email,
              style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? AppColors.primaryContainer
                        : AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isAdmin ? 'مدير' : 'موظف',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isAdmin
                          ? AppColors.primary
                          : AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Actions row
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Active toggle
                Icon(
                  user.isActive
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  size: 16,
                  color: user.isActive
                      ? AppColors.success
                      : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 4),
                Text(
                  user.isActive ? 'مفعّل' : 'معطّل',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: user.isActive
                        ? AppColors.success
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: user.isActive,
                  onChanged: (_) =>
                      ref.read(usersProvider.notifier).toggleActive(user.id),
                  activeThumbColor: AppColors.success,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const Spacer(),
                // Permissions button
                TextButton.icon(
                  onPressed: () => _showUserPermissions(context, ref, user),
                  icon: const Icon(Icons.security_rounded, size: 15),
                  label: Text('الصلاحيات',
                      style: GoogleFonts.cairo(fontSize: 12)),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4)),
                ),
                // Delete button (can't delete admin)
                if (!isAdmin)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppColors.error),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('حذف المستخدم',
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w700)),
                          content: Text(
                              'هل تريد حذف "${user.name}"؟',
                              style: GoogleFonts.cairo()),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: Text('إلغاء',
                                    style: GoogleFonts.cairo())),
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error),
                              child: Text('حذف',
                                  style: GoogleFonts.cairo()),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        ref
                            .read(usersProvider.notifier)
                            .removeUser(user.id);
                      }
                    },
                    tooltip: 'حذف المستخدم',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dialog: Add User ──────────────────────────────────────────────────────────
Future<void> _showAddUserDialog(BuildContext context, WidgetRef ref) async {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  UserRole selectedRole = UserRole.employee;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text('إضافة مستخدم جديد',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: 'الاسم الكامل',
                labelStyle: GoogleFonts.cairo(),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              style: GoogleFonts.cairo(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني',
                labelStyle: GoogleFonts.cairo(),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              style: GoogleFonts.cairo(),
            ),
            const SizedBox(height: 12),
            // Role selector
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderLight),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    onTap: () => setState(() => selectedRole = UserRole.employee),
                    leading: Radio<UserRole>(
                      value: UserRole.employee,
                      groupValue: selectedRole,
                      onChanged: (v) => setState(() => selectedRole = v!),
                      activeColor: AppColors.primary,
                    ),
                    title: Text('موظف', style: GoogleFonts.cairo()),
                  ),
                  ListTile(
                    dense: true,
                    onTap: () => setState(() => selectedRole = UserRole.admin),
                    leading: Radio<UserRole>(
                      value: UserRole.admin,
                      groupValue: selectedRole,
                      onChanged: (v) => setState(() => selectedRole = v!),
                      activeColor: AppColors.primary,
                    ),
                    title: Text('مدير النظام', style: GoogleFonts.cairo()),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty &&
                  emailCtrl.text.trim().isNotEmpty) {
                ref.read(usersProvider.notifier).addUser(
                      name: nameCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      role: selectedRole,
                    );
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: Text('إضافة',
                style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
  nameCtrl.dispose();
  emailCtrl.dispose();
}

// ── Bottom Sheet: User Permissions ────────────────────────────────────────────
Future<void> _showUserPermissions(
    BuildContext context, WidgetRef ref, UserModel user) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _UserPermissionsSheet(user: user),
  );
}

class _UserPermissionsSheet extends ConsumerStatefulWidget {
  final UserModel user;
  const _UserPermissionsSheet({required this.user});

  @override
  ConsumerState<_UserPermissionsSheet> createState() =>
      _UserPermissionsSheetState();
}

class _UserPermissionsSheetState
    extends ConsumerState<_UserPermissionsSheet> {
  late Set<Permission> _permissions;

  @override
  void initState() {
    super.initState();
    // Get latest user data from provider
    final users = ref.read(usersProvider);
    final current = users.firstWhere((u) => u.id == widget.user.id,
        orElse: () => widget.user);
    _permissions = Set.from(current.permissions);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.cardDark : Colors.white;
    final isAdmin = widget.user.role == UserRole.admin;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color:
                    isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  _SmallAvatar(
                      name: widget.user.name,
                      isActive: widget.user.isActive,
                      isAdmin: isAdmin),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'صلاحيات: ${widget.user.name}',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          widget.user.email,
                          style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isAdmin)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'المدير يمتلك جميع الصلاحيات تلقائياً',
                          style: GoogleFonts.cairo(
                              fontSize: 12, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const Divider(height: 16),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _permissionGroups.entries.map((group) {
                  return _PermissionGroup(
                    title: group.key,
                    permissions: group.value,
                    selected: _permissions,
                    isDark: isDark,
                    locked: isAdmin,
                    onChanged: (p, val) {
                      if (!isAdmin) {
                        setState(() {
                          if (val) {
                            _permissions.add(p);
                          } else {
                            _permissions.remove(p);
                          }
                        });
                      }
                    },
                  );
                }).toList(),
              ),
            ),
            if (!isAdmin)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _permissions = Set.from(
                                defaultPermissions[widget.user.role]!);
                          });
                        },
                        child: Text('استعادة الافتراضي',
                            style: GoogleFonts.cairo()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ref
                              .read(usersProvider.notifier)
                              .updatePermissions(
                                  widget.user.id, _permissions);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم حفظ الصلاحيات',
                                  style: GoogleFonts.cairo()),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary),
                        child: Text('حفظ الصلاحيات',
                            style:
                                GoogleFonts.cairo(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PermissionGroup extends StatelessWidget {
  final String title;
  final List<Permission> permissions;
  final Set<Permission> selected;
  final bool isDark;
  final bool locked;
  final void Function(Permission, bool) onChanged;

  const _PermissionGroup({
    required this.title,
    required this.permissions,
    required this.selected,
    required this.isDark,
    required this.locked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color:
                    isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(
            children: permissions.asMap().entries.map((e) {
              final idx = e.key;
              final perm = e.value;
              final isEnabled = selected.contains(perm);
              return Column(
                children: [
                  CheckboxListTile(
                    dense: true,
                    value: isEnabled,
                    onChanged: locked
                        ? null
                        : (v) => onChanged(perm, v ?? false),
                    title: Text(
                      _permissionLabels[perm] ?? perm.name,
                      style: GoogleFonts.cairo(fontSize: 13),
                    ),
                    activeColor: AppColors.primary,
                    checkboxShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
                  if (idx < permissions.length - 1)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ── Bottom Sheet: Permissions Management (select user first) ─────────────────
Future<void> _showPermissionsManagement(
    BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _PermissionsManagementSheet(),
  );
}

