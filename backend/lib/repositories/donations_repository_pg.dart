import 'package:charity_backend/models/donation.dart';
import 'package:charity_backend/repositories/donations_store.dart';
import 'package:charity_backend/services/db.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

class DonationsRepositoryPg implements DonationsStore {
  DonationsRepositoryPg(this._db);
  final Db _db;

  double _monthlyGoal = 15000000;

  @override
  Future<List<Donation>> getAll({String? status, String? method, String? search}) async {
    final where = <String>[];
    final params = <String, dynamic>{};
    if (status != null && status.isNotEmpty) {
      where.add('status=@status');
      params['status'] = status;
    }
    if (method != null && method.isNotEmpty) {
      where.add('method=@method');
      params['method'] = method;
    }
    if (search != null && search.isNotEmpty) {
      where.add('(LOWER(donor) LIKE @q OR LOWER(reference) LIKE @q)');
      params['q'] = '%${search.toLowerCase()}%';
    }

    final sql = '''
SELECT * FROM donations
${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
ORDER BY date DESC
''';

    final rs = await _db.conn.execute(Sql.named(sql), parameters: params);
    return rs.map((r) => _rowToDonation(r.toColumnMap())).toList();
  }

  @override
  Future<Donation?> getById(String id) async {
    final rs = await _db.conn.execute(
      Sql.named('SELECT * FROM donations WHERE id=@id'),
      parameters: {'id': id},
    );
    if (rs.isEmpty) return null;
    return _rowToDonation(rs.first.toColumnMap());
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

    await _db.conn.execute(
      Sql.named('''
INSERT INTO donations (
  id, donor, amount, currency, method, status, reference, date, notes
) VALUES (
  @id, @donor, @amount, @currency, @method, @status, @reference, @date, @notes
)
'''),
      parameters: {
        'id': donation.id,
        'donor': donation.donor,
        'amount': donation.amount,
        'currency': donation.currency,
        'method': donation.method.name,
        'status': donation.status.name,
        'reference': donation.reference,
        'date': donation.date.toUtc(),
        'notes': donation.notes,
      },
    );

    return donation;
  }

  @override
  Future<Donation?> updateStatus(String id, DonationStatus newStatus) async {
    final cur = await getById(id);
    if (cur == null) return null;
    await _db.conn.execute(
      Sql.named('UPDATE donations SET status=@status WHERE id=@id'),
      parameters: {'status': newStatus.name, 'id': id},
    );
    return cur.copyWith(status: newStatus);
  }

  @override
  Future<bool> delete(String id) async {
    final rs = await _db.conn.execute(
      Sql.named('DELETE FROM donations WHERE id=@id'),
      parameters: {'id': id},
    );
    return rs.affectedRows > 0;
  }

  @override
  Future<Map<String, dynamic>> getSummary() async {
    // Fetch recent items and calculate summary in app for simplicity.
    final list = await getAll();
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfDay = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final completed = list.where((d) => d.status == DonationStatus.completed);

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

    final newDonors = list
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
      'donorsCount': list.map((d) => d.donor).toSet().length,
      'pendingCount': list.where((d) => d.status == DonationStatus.processing).length,
      'transfersCount': list.length,
      'newDonors': newDonors,
    };
  }

  @override
  Future<void> updateMonthlyGoal(double goal) async {
    // Keep in-memory for now; add settings table later if needed.
    _monthlyGoal = goal;
  }

  Donation _rowToDonation(Map<String, dynamic> r) {
    return Donation(
      id: r['id'] as String,
      donor: r['donor'] as String,
      amount: (r['amount'] as num).toDouble(),
      currency: r['currency'] as String,
      method: DonationPaymentMethod.values.byName(r['method'] as String),
      status: DonationStatus.values.byName(r['status'] as String),
      reference: r['reference'] as String,
      date: (r['date'] as DateTime).toLocal(),
      notes: r['notes'] as String?,
    );
  }
}

