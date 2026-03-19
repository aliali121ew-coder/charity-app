import 'package:charity_backend/models/donation.dart';
import 'package:charity_backend/repositories/donations_store.dart';
import 'package:uuid/uuid.dart';

class DonationsRepositoryMemory implements DonationsStore {
  final List<Donation> _donations = [
    Donation(
        id: 'TRF-001',
        donor: 'أحمد محمد علي',
        amount: 500000,
        method: DonationPaymentMethod.zainCash,
        status: DonationStatus.completed,
        reference: 'ZC-884712',
        date: DateTime(2026, 3, 15, 14, 30)),
  ];

  double _monthlyGoal = 15000000;

  @override
  Future<List<Donation>> getAll({String? status, String? method, String? search}) async {
    return _donations.where((d) {
      if (status != null && d.status.name != status) return false;
      if (method != null && d.method.name != method) return false;
      if (search != null && search.isNotEmpty) {
        final q = search.toLowerCase();
        if (!d.donor.toLowerCase().contains(q) &&
            !d.reference.toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<Donation?> getById(String id) async {
    try {
      return _donations.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Donation> create({
    required String donor,
    required double amount,
    required DonationPaymentMethod method,
    DonationStatus status = DonationStatus.processing,
    String? notes,
    String currency = 'IQD',
  }) async {
    const uuid = Uuid();
    final prefix = switch (method) {
      DonationPaymentMethod.zainCash => 'ZC',
      DonationPaymentMethod.visaCard => 'VS',
      DonationPaymentMethod.masterCard => 'MC',
      DonationPaymentMethod.bankTransfer => 'BNK',
      DonationPaymentMethod.cash => 'CSH',
    };
    final ref = '$prefix-${DateTime.now().millisecondsSinceEpoch % 1000000}';
    final donation = Donation(
      id: 'TRF-${uuid.v4().substring(0, 6).toUpperCase()}',
      donor: donor,
      amount: amount,
      currency: currency,
      method: method,
      status: status,
      reference: ref,
      date: DateTime.now(),
      notes: notes,
    );
    _donations.insert(0, donation);
    return donation;
  }

  @override
  Future<Donation?> updateStatus(String id, DonationStatus newStatus) async {
    final index = _donations.indexWhere((d) => d.id == id);
    if (index == -1) return null;
    _donations[index] = _donations[index].copyWith(status: newStatus);
    return _donations[index];
  }

  @override
  Future<bool> delete(String id) async {
    final before = _donations.length;
    _donations.removeWhere((d) => d.id == id);
    return _donations.length < before;
  }

  @override
  Future<Map<String, dynamic>> getSummary() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfDay = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final completed = _donations.where((d) => d.status == DonationStatus.completed);

    double totalAll = completed.fold(0.0, (s, d) => s + d.amount);
    double thisMonth = completed
        .where((d) => d.date.isAfter(startOfMonth))
        .fold(0.0, (s, d) => s + d.amount);
    double thisWeek = completed
        .where((d) => d.date.isAfter(startOfWeek))
        .fold(0.0, (s, d) => s + d.amount);
    double today = completed
        .where((d) => d.date.isAfter(startOfDay))
        .fold(0.0, (s, d) => s + d.amount);

    final newDonors = _donations
        .where((d) => d.date.isAfter(sevenDaysAgo))
        .map((d) => d.donor)
        .toSet()
        .length;

    return {
      'totalAll': totalAll,
      'thisMonth': thisMonth,
      'thisWeek': thisWeek,
      'today': today,
      'monthlyGoal': _monthlyGoal,
      'donorsCount': _donations.map((d) => d.donor).toSet().length,
      'pendingCount': _donations.where((d) => d.status == DonationStatus.processing).length,
      'transfersCount': _donations.length,
      'newDonors': newDonors,
    };
  }

  @override
  Future<void> updateMonthlyGoal(double goal) async => _monthlyGoal = goal;
}

