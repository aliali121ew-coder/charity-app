import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/core/localization/app_localizations.dart';
import 'package:charity_app/core/permissions/role.dart';
import 'package:charity_app/shared/providers/app_providers.dart';
import 'package:charity_app/shared/models/user_model.dart';
import 'package:charity_app/shared/widgets/section_header.dart';
import 'package:charity_app/features/settings/providers/settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == UserRole.admin;
    final orgSettings = ref.watch(orgSettingsProvider);
    final notifSettings = ref.watch(notificationSettingsProvider);

    // ── Access Guard: Only admin can access settings ──────────────────────────
    if (!isAdmin) {
      return _AccessDeniedView(isDark: isDark);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
              title: l10n.tr('settings'),
              subtitle: 'تخصيص التطبيق والإعدادات'),
          const SizedBox(height: 20),

          // ── Profile ──────────────────────────────────────────────────────
          _SettingsSection(
            title: l10n.tr('profile_settings'),
            icon: Icons.person_outline_rounded,
            isDark: isDark,
            children: [
              if (user != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _ProfileAvatar(name: user.name),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                            Text(
                              user.email,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isAdmin
                                    ? AppColors.primaryContainer
                                    : AppColors.secondaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isAdmin ? 'مدير النظام' : 'موظف',
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
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () =>
                            _showEditProfileDialog(context, ref, user),
                        tooltip: l10n.tr('edit'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Appearance ───────────────────────────────────────────────────
          _SettingsSection(
            title: 'المظهر والإعدادات',
            icon: Icons.palette_outlined,
            isDark: isDark,
            children: [
              _SettingsTile(
                icon: Icons.language_rounded,
                iconColor: AppColors.kpiBlue.first,
                title: l10n.tr('language'),
                subtitle: l10n.isArabic ? 'العربية' : 'English',
                isDark: isDark,
                trailing: Switch(
                  value: locale.languageCode == 'en',
                  onChanged: (_) =>
                      ref.read(localeProvider.notifier).toggle(),
                  activeThumbColor: AppColors.primary,
                ),
              ),
              _Divider(isDark: isDark),
              _SettingsTile(
                icon: isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                iconColor: AppColors.kpiOrange.first,
                title: l10n.tr('theme'),
                subtitle: themeMode == ThemeMode.dark
                    ? l10n.tr('dark_mode')
                    : l10n.tr('light_mode'),
                isDark: isDark,
                trailing: Switch(
                  value: themeMode == ThemeMode.dark,
                  onChanged: (_) =>
                      ref.read(themeModeProvider.notifier).toggle(),
                  activeThumbColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Organization ─────────────────────────────────────────────────
          _SettingsSection(
            title: l10n.tr('organization_settings'),
            icon: Icons.business_outlined,
            isDark: isDark,
            children: [
              _SettingsTile(
                icon: Icons.business_rounded,
                iconColor: AppColors.kpiPurple.first,
                title: 'اسم المنظمة',
                subtitle: orgSettings.name,
                isDark: isDark,
                trailing: isAdmin
                    ? Icon(Icons.edit_outlined,
                        size: 16,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight)
                    : null,
                onTap: isAdmin
                    ? () => _showEditOrgField(
                          context,
                          'اسم المنظمة',
                          orgSettings.name,
                          (v) => ref
                              .read(orgSettingsProvider.notifier)
                              .update(name: v),
                        )
                    : null,
              ),
              _Divider(isDark: isDark),
              _SettingsTile(
                icon: Icons.phone_rounded,
                iconColor: AppColors.kpiGreen.first,
                title: 'رقم التواصل',
                subtitle: orgSettings.phone,
                isDark: isDark,
                trailing: isAdmin
                    ? Icon(Icons.edit_outlined,
                        size: 16,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight)
                    : null,
                onTap: isAdmin
                    ? () => _showEditOrgField(
                          context,
                          'رقم التواصل',
                          orgSettings.phone,
                          (v) => ref
                              .read(orgSettingsProvider.notifier)
                              .update(phone: v),
                          keyboardType: TextInputType.phone,
                        )
                    : null,
              ),
              _Divider(isDark: isDark),
              _SettingsTile(
                icon: Icons.location_on_rounded,
                iconColor: AppColors.kpiRose.first,
                title: 'عنوان المنظمة',
                subtitle: orgSettings.address,
                isDark: isDark,
                trailing: isAdmin
                    ? Icon(Icons.edit_outlined,
                        size: 16,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight)
                    : null,
                onTap: isAdmin
                    ? () => _showEditOrgField(
                          context,
                          'عنوان المنظمة',
                          orgSettings.address,
                          (v) => ref
                              .read(orgSettingsProvider.notifier)
                              .update(address: v),
                        )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Admin: Users & Permissions ────────────────────────────────────
          if (isAdmin) ...[
            _SettingsSection(
              title: l10n.tr('users_management'),
              icon: Icons.manage_accounts_outlined,
              isDark: isDark,
              children: [
                _SettingsTile(
                  icon: Icons.people_rounded,
                  iconColor: AppColors.kpiBlue.first,
                  title: 'إدارة المستخدمين',
                  subtitle: 'إضافة وتفعيل وإدارة المستخدمين',
                  isDark: isDark,
                  onTap: () => _showUsersManagement(context, ref),
                  trailing:
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                ),
                _Divider(isDark: isDark),
                _SettingsTile(
                  icon: Icons.security_rounded,
                  iconColor: AppColors.kpiOrange.first,
                  title: l10n.tr('permissions_management'),
                  subtitle: 'تعيين صلاحيات لكل مستخدم',
                  isDark: isDark,
                  onTap: () => _showPermissionsManagement(context, ref),
                  trailing:
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // ── Notifications ────────────────────────────────────────────────
          _SettingsSection(
            title: l10n.tr('notifications'),
            icon: Icons.notifications_outlined,
            isDark: isDark,
            children: [
              _SettingsTile(
                icon: Icons.notifications_active_outlined,
                iconColor: AppColors.kpiTeal.first,
                title: 'إشعارات المساعدات',
                subtitle: 'تنبيهات عند اعتماد المساعدات',
                isDark: isDark,
                trailing: Switch(
                  value: notifSettings.aidAlerts,
                  onChanged: (_) => ref
                      .read(notificationSettingsProvider.notifier)
                      .toggleAidAlerts(),
                  activeThumbColor: AppColors.primary,
                ),
              ),
              _Divider(isDark: isDark),
              _SettingsTile(
                icon: Icons.mail_outline_rounded,
                iconColor: AppColors.kpiPurple.first,
                title: 'إشعارات البريد',
                subtitle: 'استقبال ملخص يومي عبر البريد',
                isDark: isDark,
                trailing: Switch(
                  value: notifSettings.emailDigest,
                  onChanged: (_) => ref
                      .read(notificationSettingsProvider.notifier)
                      .toggleEmailDigest(),
                  activeThumbColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── App Info ──────────────────────────────────────────────────────
          _SettingsSection(
            title: 'معلومات التطبيق',
            icon: Icons.info_outline_rounded,
            isDark: isDark,
            children: [
              _SettingsTile(
                icon: Icons.info_rounded,
                iconColor: AppColors.textSecondaryLight,
                title: l10n.tr('app_version'),
                subtitle: '1.0.0+1',
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Logout ────────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(l10n.tr('logout'),
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                    content: Text('هل أنت متأكد من تسجيل الخروج؟',
                        style: GoogleFonts.cairo()),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(l10n.tr('cancel'),
                              style: GoogleFonts.cairo())),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error),
                        child: Text(l10n.tr('logout'),
                            style: GoogleFonts.cairo()),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  ref.read(authProvider.notifier).logout();
                }
              },
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              label: Text(l10n.tr('logout'),
                  style: GoogleFonts.cairo(
                      color: AppColors.error, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Dialog: Edit Org Field ────────────────────────────────────────────────────
Future<void> _showEditOrgField(
  BuildContext context,
  String label,
  String initialValue,
  void Function(String) onSave, {
  TextInputType keyboardType = TextInputType.text,
}) async {
  final controller = TextEditingController(text: initialValue);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('تعديل $label',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(),
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        style: GoogleFonts.cairo(),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('إلغاء', style: GoogleFonts.cairo()),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style:
              ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child:
              Text('حفظ', style: GoogleFonts.cairo(color: Colors.white)),
        ),
      ],
    ),
  );
  if (confirmed == true && controller.text.trim().isNotEmpty) {
    onSave(controller.text.trim());
  }
  controller.dispose();
}

// ── Dialog: Edit Profile ──────────────────────────────────────────────────────
Future<void> _showEditProfileDialog(
    BuildContext context, WidgetRef ref, UserModel user) async {
  final nameCtrl = TextEditingController(text: user.name);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('تعديل الملف الشخصي',
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
              labelText: 'الاسم',
              labelStyle: GoogleFonts.cairo(),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.person_outline),
            ),
            style: GoogleFonts.cairo(),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('إلغاء', style: GoogleFonts.cairo()),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style:
              ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child:
              Text('حفظ', style: GoogleFonts.cairo(color: Colors.white)),
        ),
      ],
    ),
  );
  if (confirmed == true && nameCtrl.text.trim().isNotEmpty) {
    // Update the user in usersProvider
    final updatedUser = user.copyWith(name: nameCtrl.text.trim());
    ref.read(usersProvider.notifier).updateUser(updatedUser);
  }
  nameCtrl.dispose();
}

// ── Bottom Sheet: Users Management ───────────────────────────────────────────
Future<void> _showUsersManagement(
    BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _UsersManagementSheet(),
  );
}

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

// ── Bottom Sheet: Add User ────────────────────────────────────────────────────
Future<void> _showAddUserDialog(BuildContext context, WidgetRef ref) async {
  final nameCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();
  UserRole selectedRole = UserRole.employee;
  bool passVisible = false;
  bool confirmPassVisible = false;
  String? errorMsg;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final sheetBg = isDark ? const Color(0xFF1E2235) : Colors.white;
        final inputBorder = OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        );
        final focusedBorder = OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        );

        Widget field({
          required TextEditingController controller,
          required String label,
          required IconData icon,
          TextInputType keyboardType = TextInputType.text,
          bool obscure = false,
          bool? isVisible,
          VoidCallback? onToggleVisibility,
        }) {
          return TextField(
            controller: controller,
            textDirection: TextDirection.rtl,
            keyboardType: keyboardType,
            obscureText: obscure && !(isVisible ?? false),
            style: GoogleFonts.cairo(fontSize: 14),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: GoogleFonts.cairo(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
              suffixIcon: obscure
                  ? IconButton(
                      icon: Icon(
                        (isVisible ?? false)
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      onPressed: onToggleVisibility,
                    )
                  : null,
              border: inputBorder,
              enabledBorder: inputBorder,
              focusedBorder: focusedBorder,
              filled: true,
              fillColor: isDark
                  ? AppColors.surfaceVariantDark
                  : const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          );
        }

        final roles = [
          (UserRole.admin, 'مدير النظام', Icons.admin_panel_settings_rounded,
              const Color(0xFF7C3AED)),
          (UserRole.employee, 'موظف', Icons.badge_rounded,
              const Color(0xFF0EA5E9)),
          (UserRole.beneficiary, 'مستخدم', Icons.person_rounded,
              const Color(0xFF10B981)),
        ];

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person_add_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إضافة مستخدم جديد',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          Text(
                            'أدخل بيانات المستخدم والصلاحيات',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(Icons.close_rounded,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 24),

                // Form fields
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      field(
                        controller: nameCtrl,
                        label: 'الاسم الكامل',
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 10),
                      field(
                        controller: usernameCtrl,
                        label: 'اسم المستخدم',
                        icon: Icons.alternate_email_rounded,
                      ),
                      const SizedBox(height: 10),
                      field(
                        controller: emailCtrl,
                        label: 'البريد الإلكتروني',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),
                      field(
                        controller: passCtrl,
                        label: 'كلمة المرور',
                        icon: Icons.lock_outline_rounded,
                        obscure: true,
                        isVisible: passVisible,
                        onToggleVisibility: () =>
                            setState(() => passVisible = !passVisible),
                      ),
                      const SizedBox(height: 10),
                      field(
                        controller: confirmPassCtrl,
                        label: 'تأكيد كلمة المرور',
                        icon: Icons.lock_reset_rounded,
                        obscure: true,
                        isVisible: confirmPassVisible,
                        onToggleVisibility: () => setState(
                            () => confirmPassVisible = !confirmPassVisible),
                      ),
                      const SizedBox(height: 16),

                      // Role selector
                      Text(
                        'نوع الحساب',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: roles.map((item) {
                          final (role, label, icon, color) = item;
                          final isSelected = selectedRole == role;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => selectedRole = role),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? color.withValues(alpha: 0.12)
                                      : isDark
                                          ? AppColors.surfaceVariantDark
                                          : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? color
                                        : isDark
                                            ? AppColors.borderDark
                                            : AppColors.borderLight,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(icon,
                                        size: 22,
                                        color: isSelected
                                            ? color
                                            : isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors
                                                    .textSecondaryLight),
                                    const SizedBox(height: 4),
                                    Text(
                                      label,
                                      style: GoogleFonts.cairo(
                                        fontSize: 11,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? color
                                            : isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors
                                                    .textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      // Error message
                      if (errorMsg != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  size: 14, color: Color(0xFFEF4444)),
                              const SizedBox(width: 6),
                              Text(
                                errorMsg!,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final name = nameCtrl.text.trim();
                            final email = emailCtrl.text.trim();
                            final pass = passCtrl.text;
                            final confirm = confirmPassCtrl.text;

                            if (name.isEmpty || email.isEmpty || pass.isEmpty) {
                              setState(() =>
                                  errorMsg = 'يرجى تعبئة جميع الحقول المطلوبة');
                              return;
                            }
                            if (pass != confirm) {
                              setState(() =>
                                  errorMsg = 'كلمة المرور غير متطابقة');
                              return;
                            }

                            ref.read(usersProvider.notifier).addUser(
                                  name: name,
                                  email: email,
                                  role: selectedRole,
                                );
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'إضافة المستخدم',
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(ctx).padding.bottom + 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  nameCtrl.dispose();
  usernameCtrl.dispose();
  emailCtrl.dispose();
  passCtrl.dispose();
  confirmPassCtrl.dispose();
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

class _PermissionsManagementSheet extends ConsumerWidget {
  const _PermissionsManagementSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.cardDark : Colors.white;
    final users = ref.watch(usersProvider);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.security_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'إدارة الصلاحيات',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'اختر مستخدماً لتعديل صلاحياته',
            style: GoogleFonts.cairo(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 16),
          ...users.map(
            (u) => ListTile(
              leading: _SmallAvatar(
                  name: u.name,
                  isActive: u.isActive,
                  isAdmin: u.role == UserRole.admin),
              title: Text(u.name, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${u.permissions.length} صلاحية مفعّلة',
                style: GoogleFonts.cairo(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              onTap: () {
                Navigator.pop(context);
                _showUserPermissions(context, ref, u);
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Permission Groups & Labels ────────────────────────────────────────────────
const _permissionGroups = <String, List<Permission>>{
  'المشتركون': [
    Permission.viewSubscribers,
    Permission.addSubscriber,
    Permission.editSubscriber,
    Permission.deleteSubscriber,
  ],
  'العائلات': [
    Permission.viewFamilies,
    Permission.addFamily,
    Permission.editFamily,
    Permission.deleteFamily,
  ],
  'المساعدات': [
    Permission.viewAid,
    Permission.addAid,
    Permission.editAid,
    Permission.deleteAid,
    Permission.approveAid,
    Permission.distributeAid,
  ],
  'التقارير': [
    Permission.viewReports,
    Permission.exportReports,
  ],
  'السجلات': [
    Permission.viewLogs,
  ],
  'لوحة التحكم': [
    Permission.viewDashboard,
  ],
  'الإعدادات': [
    Permission.viewSettings,
    Permission.editSettings,
    Permission.manageUsers,
    Permission.managePermissions,
  ],
};

const _permissionLabels = <Permission, String>{
  Permission.viewSubscribers: 'عرض المشتركين',
  Permission.addSubscriber: 'إضافة مشترك',
  Permission.editSubscriber: 'تعديل مشترك',
  Permission.deleteSubscriber: 'حذف مشترك',
  Permission.viewFamilies: 'عرض العائلات',
  Permission.addFamily: 'إضافة عائلة',
  Permission.editFamily: 'تعديل عائلة',
  Permission.deleteFamily: 'حذف عائلة',
  Permission.viewAid: 'عرض المساعدات',
  Permission.addAid: 'إضافة مساعدة',
  Permission.editAid: 'تعديل مساعدة',
  Permission.deleteAid: 'حذف مساعدة',
  Permission.approveAid: 'اعتماد المساعدات',
  Permission.distributeAid: 'توزيع المساعدات',
  Permission.viewReports: 'عرض التقارير',
  Permission.exportReports: 'تصدير التقارير',
  Permission.viewLogs: 'عرض السجلات',
  Permission.viewDashboard: 'عرض لوحة التحكم',
  Permission.viewSettings: 'عرض الإعدادات',
  Permission.editSettings: 'تعديل الإعدادات',
  Permission.manageUsers: 'إدارة المستخدمين',
  Permission.managePermissions: 'إدارة الصلاحيات',
};

// ── Reusable widgets ──────────────────────────────────────────────────────────
class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool isDark;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color:
                    isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDark;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      dense: true,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
      title: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            )
          : null,
      trailing: trailing,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 60,
      endIndent: 16,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String name;
  const _ProfileAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials =
        name.trim().split(' ').take(2).map((w) => w[0]).join();
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5B4FCF), Color(0xFF7C6FE0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white),
        ),
      ),
    );
  }
}

class _SmallAvatar extends StatelessWidget {
  final String name;
  final bool isActive;
  final bool isAdmin;
  const _SmallAvatar(
      {required this.name, required this.isActive, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final initials =
        name.trim().split(' ').take(2).map((w) => w[0]).join();
    return Stack(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isAdmin
                  ? [const Color(0xFF5B4FCF), const Color(0xFF7C6FE0)]
                  : [const Color(0xFF10B981), const Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initials,
              style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isActive ? AppColors.success : AppColors.textSecondaryLight,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Access Denied View ────────────────────────────────────────────────────────
class _AccessDeniedView extends StatelessWidget {
  final bool isDark;
  const _AccessDeniedView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 44,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'غير مسموح بالوصول',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'هذه الصفحة مخصصة لمدير المؤسسة فقط.\nلا تملك الصلاحية للوصول إلى الإعدادات.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
