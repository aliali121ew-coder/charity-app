import 'package:charity_app/shared/models/aid_model.dart';

final List<AidModel> mockAidRecords = [
  AidModel(id: 'a001', referenceNumber: 'AID-2024-001', beneficiaryName: 'أبو علي الحسيني', familyId: 'f001', type: AidType.financial, amount: 150000, date: DateTime(2024, 1, 20), responsibleEmployee: 'أحمد محمد', status: AidStatus.distributed, notes: 'مساعدة شهرية'),
  AidModel(id: 'a002', referenceNumber: 'AID-2024-002', beneficiaryName: 'أم كرار العبودي', familyId: 'f002', type: AidType.food, amount: 75000, date: DateTime(2024, 2, 5), responsibleEmployee: 'سارة خالد', status: AidStatus.distributed),
  AidModel(id: 'a003', referenceNumber: 'AID-2024-003', beneficiaryName: 'أحمد محمد الحسن', subscriberId: 's001', type: AidType.medical, amount: 200000, date: DateTime(2024, 2, 18), responsibleEmployee: 'أحمد محمد', status: AidStatus.approved, notes: 'علاج طبي عاجل'),
  AidModel(id: 'a004', referenceNumber: 'AID-2024-004', beneficiaryName: 'حسين علوان الموسوي', familyId: 'f005', type: AidType.seasonal, amount: 120000, date: DateTime(2024, 3, 10), responsibleEmployee: 'علي كريم', status: AidStatus.distributed, notes: 'مساعدة رمضان'),
  AidModel(id: 'a005', referenceNumber: 'AID-2024-005', beneficiaryName: 'نجاة طالب الشمري', familyId: 'f008', type: AidType.education, amount: 180000, date: DateTime(2024, 3, 25), responsibleEmployee: 'سارة خالد', status: AidStatus.approved, notes: 'رسوم دراسية'),
  AidModel(id: 'a006', referenceNumber: 'AID-2024-006', beneficiaryName: 'فاطمة علي الزهراء', subscriberId: 's002', type: AidType.financial, amount: 100000, date: DateTime(2024, 4, 8), responsibleEmployee: 'أحمد محمد', status: AidStatus.pending),
  AidModel(id: 'a007', referenceNumber: 'AID-2024-007', beneficiaryName: 'محمد كاظم الخفاجي', familyId: 'f003', type: AidType.food, amount: 60000, date: DateTime(2024, 4, 20), responsibleEmployee: 'علي كريم', status: AidStatus.distributed),
  AidModel(id: 'a008', referenceNumber: 'AID-2024-008', beneficiaryName: 'خديجة محمود السامرائي', familyId: 'f010', type: AidType.financial, amount: 150000, date: DateTime(2024, 5, 5), responsibleEmployee: 'أحمد محمد', status: AidStatus.rejected, notes: 'غير مستوفي الشروط'),
  AidModel(id: 'a009', referenceNumber: 'AID-2024-009', beneficiaryName: 'مريم صادق القيسي', subscriberId: 's006', type: AidType.medical, amount: 250000, date: DateTime(2024, 5, 18), responsibleEmployee: 'سارة خالد', status: AidStatus.approved),
  AidModel(id: 'a010', referenceNumber: 'AID-2024-010', beneficiaryName: 'أم زينب الأسدي', familyId: 'f006', type: AidType.financial, amount: 175000, date: DateTime(2024, 6, 1), responsibleEmployee: 'علي كريم', status: AidStatus.distributed),
  AidModel(id: 'a011', referenceNumber: 'AID-2024-011', beneficiaryName: 'ليث رياض البيضاني', familyId: 'f011', type: AidType.food, amount: 80000, date: DateTime(2024, 6, 15), responsibleEmployee: 'أحمد محمد', status: AidStatus.pending),
  AidModel(id: 'a012', referenceNumber: 'AID-2024-012', beneficiaryName: 'سارة محمود التميمي', subscriberId: 's009', type: AidType.education, amount: 220000, date: DateTime(2024, 7, 3), responsibleEmployee: 'سارة خالد', status: AidStatus.distributed),
  AidModel(id: 'a013', referenceNumber: 'AID-2024-013', beneficiaryName: 'نور الدين عباس', subscriberId: 's008', type: AidType.seasonal, amount: 130000, date: DateTime(2024, 7, 20), responsibleEmployee: 'علي كريم', status: AidStatus.approved, notes: 'مساعدة الأضحى'),
  AidModel(id: 'a014', referenceNumber: 'AID-2024-014', beneficiaryName: 'وردة حسن الجبوري', familyId: 'f012', type: AidType.other, amount: 50000, date: DateTime(2024, 8, 8), responsibleEmployee: 'أحمد محمد', status: AidStatus.pending),
  AidModel(id: 'a015', referenceNumber: 'AID-2024-015', beneficiaryName: 'نادية حمد الجبوري', subscriberId: 's015', type: AidType.financial, amount: 160000, date: DateTime(2024, 8, 25), responsibleEmployee: 'سارة خالد', status: AidStatus.distributed),
];

class MockAidRepository {
  List<AidModel> getAll() => List.from(mockAidRecords);

  List<AidModel> search(String query) {
    final q = query.toLowerCase();
    return mockAidRecords
        .where((a) =>
            a.beneficiaryName.toLowerCase().contains(q) ||
            a.referenceNumber.toLowerCase().contains(q) ||
            a.responsibleEmployee.toLowerCase().contains(q))
        .toList();
  }

  List<AidModel> filterByType(AidType? type) {
    if (type == null) return getAll();
    return mockAidRecords.where((a) => a.type == type).toList();
  }

  List<AidModel> filterByStatus(AidStatus? status) {
    if (status == null) return getAll();
    return mockAidRecords.where((a) => a.status == status).toList();
  }

  Map<AidType, int> getCountByType() {
    final map = <AidType, int>{};
    for (final a in mockAidRecords) {
      map[a.type] = (map[a.type] ?? 0) + 1;
    }
    return map;
  }

  double getTotalAmount() =>
      mockAidRecords.fold(0, (sum, a) => sum + a.amount);

  List<Map<String, dynamic>> getMonthlyTotals() {
    // Returns last 6 months of totals
    final now = DateTime.now();
    return List.generate(6, (i) {
      final month = DateTime(now.year, now.month - (5 - i));
      final total = mockAidRecords
          .where((a) => a.date.month == month.month && a.date.year == month.year)
          .fold(0.0, (sum, a) => sum + a.amount);
      return {'month': month, 'total': total};
    });
  }
}
