import 'package:charity_backend/models/payment.dart';

class PaymentsRepository {
  // In-memory storage. Replace with DB (and unique constraints) in production.
  final Map<String, PaymentIntent> _byId = {};

  PaymentIntent? getById(String id) => _byId[id];

  void put(PaymentIntent intent) {
    _byId[intent.id] = intent;
  }

  PaymentIntent? update(String id, PaymentIntent Function(PaymentIntent) fn) {
    final cur = _byId[id];
    if (cur == null) return null;
    final next = fn(cur);
    _byId[id] = next;
    return next;
  }
}

