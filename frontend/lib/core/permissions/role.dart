enum UserRole { admin, employee, beneficiary }

enum Permission {
  // Subscribers
  viewSubscribers,
  addSubscriber,
  editSubscriber,
  deleteSubscriber,

  // Families
  viewFamilies,
  addFamily,
  editFamily,
  deleteFamily,

  // Aid
  viewAid,
  addAid,
  editAid,
  deleteAid,
  approveAid,
  distributeAid,

  // Reports
  viewReports,
  exportReports,

  // Logs
  viewLogs,

  // Settings
  viewSettings,
  editSettings,
  manageUsers,
  managePermissions,

  // Dashboard
  viewDashboard,
}

/// Default permission sets per role.
const Map<UserRole, Set<Permission>> defaultPermissions = {
  UserRole.admin: {
    Permission.viewSubscribers,
    Permission.addSubscriber,
    Permission.editSubscriber,
    Permission.deleteSubscriber,
    Permission.viewFamilies,
    Permission.addFamily,
    Permission.editFamily,
    Permission.deleteFamily,
    Permission.viewAid,
    Permission.addAid,
    Permission.editAid,
    Permission.deleteAid,
    Permission.approveAid,
    Permission.distributeAid,
    Permission.viewReports,
    Permission.exportReports,
    Permission.viewLogs,
    Permission.viewSettings,
    Permission.editSettings,
    Permission.manageUsers,
    Permission.managePermissions,
    Permission.viewDashboard,
  },
  UserRole.employee: {
    Permission.viewSubscribers,
    Permission.addSubscriber,
    Permission.editSubscriber,
    Permission.viewFamilies,
    Permission.addFamily,
    Permission.editFamily,
    Permission.viewAid,
    Permission.addAid,
    Permission.editAid,
    Permission.viewReports,
    Permission.viewLogs,
    Permission.viewDashboard,
  },
  UserRole.beneficiary: {},
};
