import 'package:charity_app/core/supabase/supabase_config.dart';
import 'package:charity_app/shared/models/aid_model.dart';

/// مستودع المساعدات عبر Supabase — يحلّ محل MockAidRepository (async).
class SupabaseAidRepository {
  static const _table = 'aid_records';

  AidModel _map(Map<String, dynamic> r) => AidModel(
        id: r['id'] as String,
        referenceNumber: (r['reference_number'] ?? '') as String,
        beneficiaryName: (r['beneficiary_name'] ?? '') as String,
        familyId: r['family_id'] as String?,
        subscriberId: r['subscriber_id'] as String?,
        type: AidType.values.byName((r['type'] ?? 'other') as String),
        amount: ((r['amount'] ?? 0) as num).toDouble(),
        currency: (r['currency'] ?? 'IQD') as String,
        date: DateTime.parse(r['aid_date'] as String),
        responsibleEmployee: (r['responsible_employee'] ?? '') as String,
        status: AidStatus.values.byName((r['status'] ?? 'pending') as String),
        notes: r['notes'] as String?,
        deliveryDate: r['delivery_date'] == null ? null : DateTime.parse(r['delivery_date'] as String),
      );

  Map<String, dynamic> _toRow(AidModel a) => {
        'reference_number': a.referenceNumber,
        'beneficiary_name': a.beneficiaryName,
        'family_id': a.familyId,
        'subscriber_id': a.subscriberId,
        'type': a.type.name,
        'amount': a.amount,
        'currency': a.currency,
        'aid_date': a.date.toIso8601String(),
        'responsible_employee': a.responsibleEmployee,
        'status': a.status.name,
        'notes': a.notes,
        'delivery_date': a.deliveryDate?.toIso8601String(),
      };

  Future<List<AidModel>> getAll() async {
    final rows = await supabase.from(_table).select().order('aid_date', ascending: false);
    return rows.map((e) => _map(e)).toList();
  }

  Future<AidModel> create(AidModel record) async {
    final row = await supabase.from(_table).insert(_toRow(record)).select().single();
    return _map(row);
  }

  /// نفس اسم دالة الـ mock (add) لكن async وتُعيد الصف المُنشأ.
  Future<AidModel> add(AidModel record) => create(record);

  Future<List<AidModel>> search(String query) async {
    final q = query.replaceAll(',', ' ').trim();
    final rows = await supabase
        .from(_table)
        .select()
        .or('beneficiary_name.ilike.%$q%,reference_number.ilike.%$q%,responsible_employee.ilike.%$q%');
    return rows.map((e) => _map(e)).toList();
  }

  Future<List<AidModel>> filterByType(AidType? type) async {
    if (type == null) return getAll();
    final rows = await supabase.from(_table).select().eq('type', type.name);
    return rows.map((e) => _map(e)).toList();
  }

  Future<List<AidModel>> filterByStatus(AidStatus? status) async {
    if (status == null) return getAll();
    final rows = await supabase.from(_table).select().eq('status', status.name);
    return rows.map((e) => _map(e)).toList();
  }

  Future<Map<AidType, int>> getCountByType() async {
    final rows = await supabase.from(_table).select('type');
    final map = <AidType, int>{};
    for (final r in rows) {
      final t = AidType.values.byName(r['type'] as String);
      map[t] = (map[t] ?? 0) + 1;
    }
    return map;
  }

  Future<double> getTotalAmount() async {
    final rows = await supabase.from(_table).select('amount');
    return rows.fold<double>(0, (sum, r) => sum + ((r['amount'] ?? 0) as num).toDouble());
  }

  /// إجماليات آخر 6 أشهر (نفس منطق الـ mock، محسوبة على العميل).
  Future<List<Map<String, dynamic>>> getMonthlyTotals() async {
    final rows = await supabase.from(_table).select('amount, aid_date');
    final now = DateTime.now();
    return List.generate(6, (i) {
      final month = DateTime(now.year, now.month - (5 - i));
      final total = rows.where((r) {
        final d = DateTime.parse(r['aid_date'] as String);
        return d.month == month.month && d.year == month.year;
      }).fold<double>(0, (sum, r) => sum + ((r['amount'] ?? 0) as num).toDouble());
      return {'month': month, 'total': total};
    });
  }

  Future<void> updateStatus(String id, AidStatus status) async {
    await supabase.from(_table).update({'status': status.name}).eq('id', id);
  }

  Future<void> delete(String id) async {
    await supabase.from(_table).delete().eq('id', id);
  }
}
