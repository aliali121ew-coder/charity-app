part of '../pages/settings_page.dart';

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
