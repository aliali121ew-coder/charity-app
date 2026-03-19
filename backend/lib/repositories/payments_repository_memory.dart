import 'package:charity_backend/models/payment.dart';
import 'package:charity_backend/repositories/payments_store.dart';

class PaymentsRepositoryMemory implements PaymentsStore {
  final Map<String, PaymentIntent> _byId = {};

  @override
  Future<PaymentIntent?> getById(String id) async => _byId[id];

  @override
  Future<void> upsert(PaymentIntent intent) async {
    _byId[intent.id] = intent;
  }

  @override
  Future<PaymentIntent?> update(
    String id,
    PaymentIntent Function(PaymentIntent) fn,
  ) async {
    final cur = _byId[id];
    if (cur == null) return null;
    final next = fn(cur);
    _byId[id] = next;
    return next;
  }
}

