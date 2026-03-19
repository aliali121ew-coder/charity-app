import 'package:charity_app/shared/models/subscriber_model.dart';

final List<SubscriberModel> mockSubscribers = [
  SubscriberModel(id: 's001', name: 'أحمد محمد الحسن', phone: '07701234567', address: 'شارع الرشيد، الكرخ', area: 'الكرخ', registrationDate: DateTime(2024, 1, 15), status: SubscriberStatus.active, nationalId: '12345678901', email: 'ahmed@example.com', aidCount: 3, notes: 'أسرة مكونة من 5 أفراد'),
  SubscriberModel(id: 's002', name: 'فاطمة علي الزهراء', phone: '07709876543', address: 'حي الجامعة، الرصافة', area: 'الرصافة', registrationDate: DateTime(2024, 2, 20), status: SubscriberStatus.active, nationalId: '98765432109', aidCount: 2),
  SubscriberModel(id: 's003', name: 'عمر خالد العمري', phone: '07701111222', address: 'المنصور، بغداد', area: 'المنصور', registrationDate: DateTime(2024, 3, 5), status: SubscriberStatus.pending, nationalId: '11122233344', aidCount: 0),
  SubscriberModel(id: 's004', name: 'زينب حسين الموسوي', phone: '07703333444', address: 'الزعفرانية، الرصافة', area: 'الزعفرانية', registrationDate: DateTime(2024, 3, 18), status: SubscriberStatus.active, aidCount: 5),
  SubscriberModel(id: 's005', name: 'حيدر جواد الشمري', phone: '07705555666', address: 'حي العدل، بغداد', area: 'العدل', registrationDate: DateTime(2024, 4, 2), status: SubscriberStatus.inactive, aidCount: 1),
  SubscriberModel(id: 's006', name: 'مريم صادق القيسي', phone: '07707777888', address: 'الدورة، جنوب بغداد', area: 'الدورة', registrationDate: DateTime(2024, 4, 25), status: SubscriberStatus.active, aidCount: 4),
  SubscriberModel(id: 's007', name: 'علي كريم الربيعي', phone: '07709999000', address: 'سيدي الشهداء', area: 'الشهداء', registrationDate: DateTime(2024, 5, 10), status: SubscriberStatus.suspended, aidCount: 0, notes: 'موقوف مؤقتاً'),
  SubscriberModel(id: 's008', name: 'نور الدين عباس', phone: '07701234000', address: 'الكاظمية، بغداد', area: 'الكاظمية', registrationDate: DateTime(2024, 5, 20), status: SubscriberStatus.active, aidCount: 2),
  SubscriberModel(id: 's009', name: 'سارة محمود التميمي', phone: '07703214567', address: 'حي السلام، بغداد', area: 'السلام', registrationDate: DateTime(2024, 6, 8), status: SubscriberStatus.active, aidCount: 3),
  SubscriberModel(id: 's010', name: 'حسن عادل البياتي', phone: '07706543210', address: 'المدينة، الرصافة', area: 'المدينة', registrationDate: DateTime(2024, 6, 22), status: SubscriberStatus.pending, aidCount: 0),
  SubscriberModel(id: 's011', name: 'رنا طارق العاني', phone: '07709870001', address: 'اليرموك، بغداد', area: 'اليرموك', registrationDate: DateTime(2024, 7, 3), status: SubscriberStatus.active, aidCount: 1),
  SubscriberModel(id: 's012', name: 'كريم فاضل الدليمي', phone: '07702345678', address: 'حي الشعب، بغداد', area: 'الشعب', registrationDate: DateTime(2024, 7, 17), status: SubscriberStatus.active, aidCount: 2),
  SubscriberModel(id: 's013', name: 'لمياء صلاح النجار', phone: '07704567890', address: 'الغزالية، بغداد', area: 'الغزالية', registrationDate: DateTime(2024, 8, 5), status: SubscriberStatus.inactive, aidCount: 1),
  SubscriberModel(id: 's014', name: 'أمير يوسف الجابري', phone: '07706789012', address: 'الحارثية، بغداد', area: 'الحارثية', registrationDate: DateTime(2024, 8, 20), status: SubscriberStatus.active, aidCount: 0),
  SubscriberModel(id: 's015', name: 'نادية حمد الجبوري', phone: '07708901234', address: 'الشعلة، الكرخ', area: 'الشعلة', registrationDate: DateTime(2024, 9, 1), status: SubscriberStatus.active, aidCount: 3),
];

class MockSubscribersRepository {
  List<SubscriberModel> getAll() => List.from(mockSubscribers);

  SubscriberModel? getById(String id) =>
      mockSubscribers.cast<SubscriberModel?>().firstWhere(
            (s) => s?.id == id,
            orElse: () => null,
          );

  List<SubscriberModel> search(String query) {
    final q = query.toLowerCase();
    return mockSubscribers
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.phone.contains(q) ||
            s.area.toLowerCase().contains(q))
        .toList();
  }

  List<SubscriberModel> filterByStatus(SubscriberStatus? status) {
    if (status == null) return getAll();
    return mockSubscribers.where((s) => s.status == status).toList();
  }
}
