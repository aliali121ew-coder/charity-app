import 'package:charity_app/shared/models/family_model.dart';

final List<FamilyModel> mockFamilies = [
  FamilyModel(id: 'f001', headName: 'أبو علي الحسيني', membersCount: 6, maritalStatus: MaritalStatus.married, incomeLevel: IncomeLevel.veryLow, address: 'حي الشعب، بغداد', area: 'الشعب', status: FamilyStatus.eligible, registrationDate: DateTime(2024, 1, 10), aidCount: 8, totalAidAmount: 450000, phone: '07701111111'),
  FamilyModel(id: 'f002', headName: 'أم كرار العبودي', membersCount: 4, maritalStatus: MaritalStatus.widowed, incomeLevel: IncomeLevel.veryLow, address: 'الزعفرانية', area: 'الزعفرانية', status: FamilyStatus.eligible, registrationDate: DateTime(2024, 1, 22), aidCount: 12, totalAidAmount: 750000, phone: '07702222222', notes: 'أرملة، تعول أطفالاً'),
  FamilyModel(id: 'f003', headName: 'محمد كاظم الخفاجي', membersCount: 8, maritalStatus: MaritalStatus.married, incomeLevel: IncomeLevel.low, address: 'المدينة، بغداد', area: 'المدينة', status: FamilyStatus.eligible, registrationDate: DateTime(2024, 2, 5), aidCount: 5, totalAidAmount: 300000),
  FamilyModel(id: 'f004', headName: 'سعاد رجب التكريتي', membersCount: 3, maritalStatus: MaritalStatus.divorced, incomeLevel: IncomeLevel.low, address: 'الكاظمية', area: 'الكاظمية', status: FamilyStatus.pending, registrationDate: DateTime(2024, 2, 18), aidCount: 2, totalAidAmount: 120000),
  FamilyModel(id: 'f005', headName: 'حسين علوان الموسوي', membersCount: 5, maritalStatus: MaritalStatus.married, incomeLevel: IncomeLevel.veryLow, address: 'الدورة', area: 'الدورة', status: FamilyStatus.eligible, registrationDate: DateTime(2024, 3, 1), aidCount: 7, totalAidAmount: 420000),
  FamilyModel(id: 'f006', headName: 'أم زينب الأسدي', membersCount: 7, maritalStatus: MaritalStatus.widowed, incomeLevel: IncomeLevel.veryLow, address: 'الحارثية', area: 'الحارثية', status: FamilyStatus.eligible, registrationDate: DateTime(2024, 3, 15), aidCount: 9, totalAidAmount: 600000, notes: 'أرملة بأطفال صغار'),
  FamilyModel(id: 'f007', headName: 'فارس قاسم العزاوي', membersCount: 4, maritalStatus: MaritalStatus.married, incomeLevel: IncomeLevel.medium, address: 'اليرموك', area: 'اليرموك', status: FamilyStatus.ineligible, registrationDate: DateTime(2024, 4, 8), aidCount: 0, totalAidAmount: 0),
  FamilyModel(id: 'f008', headName: 'نجاة طالب الشمري', membersCount: 9, maritalStatus: MaritalStatus.married, incomeLevel: IncomeLevel.veryLow, address: 'الغزالية', area: 'الغزالية', status: FamilyStatus.eligible, registrationDate: DateTime(2024, 4, 20), aidCount: 6, totalAidAmount: 380000),
  FamilyModel(id: 'f009', headName: 'جاسم صبري العاني', membersCount: 5, maritalStatus: MaritalStatus.married, incomeLevel: IncomeLevel.low, address: 'العدل، بغداد', area: 'العدل', status: FamilyStatus.pending, registrationDate: DateTime(2024, 5, 5), aidCount: 1, totalAidAmount: 50000),
  FamilyModel(id: 'f010', headName: 'خديجة محمود السامرائي', membersCount: 3, maritalStatus: MaritalStatus.widowed, incomeLevel: IncomeLevel.veryLow, address: 'سيدي الشهداء', area: 'الشهداء', status: FamilyStatus.eligible, registrationDate: DateTime(2024, 5, 22), aidCount: 4, totalAidAmount: 240000),
  FamilyModel(id: 'f011', headName: 'ليث رياض البيضاني', membersCount: 6, maritalStatus: MaritalStatus.married, incomeLevel: IncomeLevel.low, address: 'الشعلة، الكرخ', area: 'الشعلة', status: FamilyStatus.eligible, registrationDate: DateTime(2024, 6, 10), aidCount: 3, totalAidAmount: 180000),
  FamilyModel(id: 'f012', headName: 'وردة حسن الجبوري', membersCount: 4, maritalStatus: MaritalStatus.divorced, incomeLevel: IncomeLevel.low, address: 'المنصور، بغداد', area: 'المنصور', status: FamilyStatus.suspended, registrationDate: DateTime(2024, 6, 28), aidCount: 0, totalAidAmount: 0, notes: 'موقوف للمراجعة'),
];

class MockFamiliesRepository {
  List<FamilyModel> getAll() => List.from(mockFamilies);

  List<FamilyModel> search(String query) {
    final q = query.toLowerCase();
    return mockFamilies
        .where((f) =>
            f.headName.toLowerCase().contains(q) ||
            f.area.toLowerCase().contains(q) ||
            f.address.toLowerCase().contains(q))
        .toList();
  }

  List<FamilyModel> filterByStatus(FamilyStatus? status) {
    if (status == null) return getAll();
    return mockFamilies.where((f) => f.status == status).toList();
  }

  Map<String, int> getStatusCounts() {
    return {
      'eligible': mockFamilies.where((f) => f.status == FamilyStatus.eligible).length,
      'pending': mockFamilies.where((f) => f.status == FamilyStatus.pending).length,
      'ineligible': mockFamilies.where((f) => f.status == FamilyStatus.ineligible).length,
      'suspended': mockFamilies.where((f) => f.status == FamilyStatus.suspended).length,
    };
  }
}
