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

part '../widgets/settings_users_sheets.dart';
part '../widgets/settings_permissions.dart';
part '../widgets/settings_tiles.dart';

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

