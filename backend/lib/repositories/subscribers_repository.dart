import 'package:charity_backend/models/subscriber.dart';

/// Abstract repository interface for subscribers.
/// Swap this implementation with a database-backed one when ready.
abstract class ISubscribersRepository {
  Future<List<Subscriber>> getAll({String? query, SubscriberStatus? status, String? area});
  Future<Subscriber?> getById(String id);
  Future<Subscriber> create(Subscriber subscriber);
  Future<Subscriber?> update(String id, Map<String, dynamic> fields);
  Future<bool> delete(String id);
  Future<int> count();
}

/// In-memory mock implementation — replace with database (PostgreSQL/SQLite) later
class MockSubscribersRepository implements ISubscribersRepository {
  final List<Subscriber> _data = [
    Subscriber(id: 's001', name: 'أحمد محمد الحسن', phone: '07701234567', address: 'شارع الرشيد، الكرخ', area: 'الكرخ', registrationDate: DateTime(2024, 1, 15), status: SubscriberStatus.active, nationalId: '12345678901', aidCount: 3),
    Subscriber(id: 's002', name: 'فاطمة علي الزهراء', phone: '07709876543', address: 'حي الجامعة، الرصافة', area: 'الرصافة', registrationDate: DateTime(2024, 2, 20), status: SubscriberStatus.active, aidCount: 2),
    Subscriber(id: 's003', name: 'عمر خالد العمري', phone: '07701111222', address: 'المنصور، بغداد', area: 'المنصور', registrationDate: DateTime(2024, 3, 5), status: SubscriberStatus.pending, aidCount: 0),
    Subscriber(id: 's004', name: 'زينب حسين الموسوي', phone: '07703333444', address: 'الزعفرانية', area: 'الزعفرانية', registrationDate: DateTime(2024, 3, 18), status: SubscriberStatus.active, aidCount: 5),
    Subscriber(id: 's005', name: 'حيدر جواد الشمري', phone: '07705555666', address: 'حي العدل', area: 'العدل', registrationDate: DateTime(2024, 4, 2), status: SubscriberStatus.inactive, aidCount: 1),
  ];

  @override
  Future<List<Subscriber>> getAll({String? query, SubscriberStatus? status, String? area}) async {
    var result = List<Subscriber>.from(_data);
    if (status != null) result = result.where((s) => s.status == status).toList();
    if (area != null && area.isNotEmpty) result = result.where((s) => s.area.contains(area)).toList();
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where((s) => s.name.toLowerCase().contains(q) || s.phone.contains(q)).toList();
    }
    return result;
  }

  @override
  Future<Subscriber?> getById(String id) async =>
      _data.cast<Subscriber?>().firstWhere((s) => s?.id == id, orElse: () => null);

  @override
  Future<Subscriber> create(Subscriber subscriber) async {
    _data.add(subscriber);
    return subscriber;
  }

  @override
  Future<Subscriber?> update(String id, Map<String, dynamic> fields) async {
    final idx = _data.indexWhere((s) => s.id == id);
    if (idx == -1) return null;
    // In real impl: update fields and return updated model
    return _data[idx];
  }

  @override
  Future<bool> delete(String id) async {
    final len = _data.length;
    _data.removeWhere((s) => s.id == id);
    return _data.length < len;
  }

  @override
  Future<int> count() async => _data.length;
}
