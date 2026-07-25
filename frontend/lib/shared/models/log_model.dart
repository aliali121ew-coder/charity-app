enum LogActionType {
  add,
  edit,
  delete,
  approve,
  reject,
  distribute,
  login,
  logout,
  report,
  settings,
  updateFamily,
  updateSubscriber,
}

class LogModel {
  final String id;
  final String actionTitle;
  final String description;
  final String performedBy;
  final String performedById;
  final DateTime timestamp;
  final LogActionType actionType;
  final String? referenceNumber;
  final String? entityType;
  final String? entityId;

  const LogModel({
    required this.id,
    required this.actionTitle,
    required this.description,
    required this.performedBy,
    required this.performedById,
    required this.timestamp,
    required this.actionType,
    this.referenceNumber,
    this.entityType,
    this.entityId,
  });
}

extension LogActionTypeExt on LogActionType {
  String get labelAr {
    switch (this) {
      case LogActionType.add: return 'إضافة';
      case LogActionType.edit: return 'تعديل';
      case LogActionType.delete: return 'حذف';
      case LogActionType.approve: return 'اعتماد';
      case LogActionType.reject: return 'رفض';
      case LogActionType.distribute: return 'صرف';
      case LogActionType.login: return 'تسجيل دخول';
      case LogActionType.logout: return 'تسجيل خروج';
      case LogActionType.report: return 'تقرير';
      case LogActionType.settings: return 'إعدادات';
      case LogActionType.updateFamily: return 'تحديث أسرة';
      case LogActionType.updateSubscriber: return 'تحديث مشترك';
    }
  }
}
