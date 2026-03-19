import 'package:charity_backend/models/payment.dart';

abstract class PaymentsStore {
  Future<PaymentIntent?> getById(String id);
  Future<void> upsert(PaymentIntent intent);
  Future<PaymentIntent?> update(String id, PaymentIntent Function(PaymentIntent) fn);
}

