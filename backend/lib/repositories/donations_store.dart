import 'package:charity_backend/models/donation.dart';

abstract class DonationsStore {
  Future<List<Donation>> getAll({String? status, String? method, String? search});
  Future<Donation?> getById(String id);
  Future<Donation> create({
    required String donor,
    required double amount,
    required DonationPaymentMethod method,
    DonationStatus status,
    String? notes,
    String currency,
  });
  Future<Donation?> updateStatus(String id, DonationStatus newStatus);
  Future<bool> delete(String id);
  Future<Map<String, dynamic>> getSummary();
  Future<void> updateMonthlyGoal(double goal);
}

