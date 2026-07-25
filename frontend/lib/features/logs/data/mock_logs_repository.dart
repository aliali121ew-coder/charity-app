import 'package:charity_app/shared/models/log_model.dart';

final List<LogModel> mockLogs = [
  LogModel(id: 'l001', actionTitle: 'إضافة مشترك جديد', description: 'تمت إضافة المشترك أحمد محمد الحسن إلى قاعدة البيانات', performedBy: 'مدير النظام', performedById: 'user_001', timestamp: DateTime.now().subtract(const Duration(minutes: 5)), actionType: LogActionType.add, referenceNumber: 'SUB-001', entityType: 'subscriber', entityId: 's001'),
  LogModel(id: 'l002', actionTitle: 'اعتماد مساعدة', description: 'تم اعتماد المساعدة الطبية لأحمد محمد الحسن', performedBy: 'مدير النظام', performedById: 'user_001', timestamp: DateTime.now().subtract(const Duration(minutes: 30)), actionType: LogActionType.approve, referenceNumber: 'AID-2024-003', entityType: 'aid', entityId: 'a003'),
  LogModel(id: 'l003', actionTitle: 'تعديل بيانات أسرة', description: 'تم تحديث بيانات أسرة أبو علي الحسيني', performedBy: 'أحمد محمد', performedById: 'user_002', timestamp: DateTime.now().subtract(const Duration(hours: 1)), actionType: LogActionType.edit, referenceNumber: 'FAM-001', entityType: 'family', entityId: 'f001'),
  LogModel(id: 'l004', actionTitle: 'صرف مساعدة مالية', description: 'تم صرف المساعدة المالية لحسين علوان الموسوي', performedBy: 'علي كريم', performedById: 'user_003', timestamp: DateTime.now().subtract(const Duration(hours: 2)), actionType: LogActionType.distribute, referenceNumber: 'AID-2024-004', entityType: 'aid', entityId: 'a004'),
  LogModel(id: 'l005', actionTitle: 'تسجيل دخول', description: 'تسجيل دخول ناجح من الجهاز المحمول', performedBy: 'أحمد محمد', performedById: 'user_002', timestamp: DateTime.now().subtract(const Duration(hours: 3)), actionType: LogActionType.login),
  LogModel(id: 'l006', actionTitle: 'إضافة أسرة جديدة', description: 'تمت إضافة أسرة ليث رياض البيضاني', performedBy: 'مدير النظام', performedById: 'user_001', timestamp: DateTime.now().subtract(const Duration(hours: 5)), actionType: LogActionType.add, referenceNumber: 'FAM-011', entityType: 'family', entityId: 'f011'),
  LogModel(id: 'l007', actionTitle: 'رفض طلب مساعدة', description: 'تم رفض طلب المساعدة لخديجة محمود السامرائي - غير مستوفي الشروط', performedBy: 'مدير النظام', performedById: 'user_001', timestamp: DateTime.now().subtract(const Duration(hours: 6)), actionType: LogActionType.reject, referenceNumber: 'AID-2024-008', entityType: 'aid', entityId: 'a008'),
  LogModel(id: 'l008', actionTitle: 'تصدير تقرير شهري', description: 'تم تصدير التقرير الشهري لشهر يونيو 2024', performedBy: 'مدير النظام', performedById: 'user_001', timestamp: DateTime.now().subtract(const Duration(days: 1)), actionType: LogActionType.report, referenceNumber: 'RPT-2024-06'),
  LogModel(id: 'l009', actionTitle: 'حذف مشترك', description: 'تم حذف بيانات المشترك عمر خالد (طلب شخصي)', performedBy: 'مدير النظام', performedById: 'user_001', timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)), actionType: LogActionType.delete, referenceNumber: 'SUB-003', entityType: 'subscriber'),
  LogModel(id: 'l010', actionTitle: 'تعديل إعدادات النظام', description: 'تم تحديث إعدادات المنظمة وبيانات الاتصال', performedBy: 'مدير النظام', performedById: 'user_001', timestamp: DateTime.now().subtract(const Duration(days: 2)), actionType: LogActionType.settings),
  LogModel(id: 'l011', actionTitle: 'إضافة مساعدة تعليمية', description: 'تمت إضافة مساعدة تعليمية لسارة محمود التميمي', performedBy: 'سارة خالد', performedById: 'user_003', timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 4)), actionType: LogActionType.add, referenceNumber: 'AID-2024-012', entityType: 'aid', entityId: 'a012'),
  LogModel(id: 'l012', actionTitle: 'تحديث حالة مشترك', description: 'تم تغيير حالة المشترك علي كريم الربيعي إلى موقوف', performedBy: 'مدير النظام', performedById: 'user_001', timestamp: DateTime.now().subtract(const Duration(days: 3)), actionType: LogActionType.updateSubscriber, referenceNumber: 'SUB-007', entityType: 'subscriber', entityId: 's007'),
  LogModel(id: 'l013', actionTitle: 'صرف مساعدة غذائية', description: 'تم صرف الحصة الغذائية لأسرة محمد كاظم الخفاجي', performedBy: 'علي كريم', performedById: 'user_003', timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 2)), actionType: LogActionType.distribute, referenceNumber: 'AID-2024-007', entityType: 'aid', entityId: 'a007'),
  LogModel(id: 'l014', actionTitle: 'تسجيل دخول', description: 'تسجيل دخول ناجح', performedBy: 'سارة خالد', performedById: 'user_003', timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 8)), actionType: LogActionType.login),
  LogModel(id: 'l015', actionTitle: 'إضافة مشترك', description: 'تمت إضافة المشترك نادية حمد الجبوري', performedBy: 'سارة خالد', performedById: 'user_003', timestamp: DateTime.now().subtract(const Duration(days: 4)), actionType: LogActionType.add, referenceNumber: 'SUB-015', entityType: 'subscriber', entityId: 's015'),
];

class MockLogsRepository {
  List<LogModel> getAll() => List.from(mockLogs);

  List<LogModel> search(String query) {
    final q = query.toLowerCase();
    return mockLogs
        .where((l) =>
            l.actionTitle.toLowerCase().contains(q) ||
            l.description.toLowerCase().contains(q) ||
            l.performedBy.toLowerCase().contains(q) ||
            (l.referenceNumber?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  List<LogModel> filterByActionType(LogActionType? type) {
    if (type == null) return getAll();
    return mockLogs.where((l) => l.actionType == type).toList();
  }

  List<LogModel> filterByUser(String? userId) {
    if (userId == null || userId.isEmpty) return getAll();
    return mockLogs.where((l) => l.performedById == userId).toList();
  }

  Map<LogActionType, int> getCountByType() {
    final map = <LogActionType, int>{};
    for (final l in mockLogs) {
      map[l.actionType] = (map[l.actionType] ?? 0) + 1;
    }
    return map;
  }

  int getTodayCount() {
    final today = DateTime.now();
    return mockLogs
        .where((l) =>
            l.timestamp.day == today.day &&
            l.timestamp.month == today.month &&
            l.timestamp.year == today.year)
        .length;
  }
}
