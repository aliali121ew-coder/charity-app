import 'package:charity_app/core/supabase/supabase_config.dart';
import 'package:charity_app/shared/models/subscriber_model.dart';

/// مستودع المشتركين عبر Supabase — يحلّ محل MockSubscribersRepository.
/// نفس أسماء الدوال لكنها async (Supabase غير متزامن).
class SupabaseSubscribersRepository {
  static const _table = 'subscribers';

  SubscriberModel _map(Map<String, dynamic> r) => SubscriberModel(
        id: r['id'] as String,
        name: (r['name'] ?? '') as String,
        phone: (r['phone'] ?? '') as String,
        address: (r['address'] ?? '') as String,
        area: (r['area'] ?? '') as String,
        registrationDate: DateTime.parse(r['registration_date'] as String),
        status: SubscriberStatus.values.byName((r['status'] ?? 'pending') as String),
        avatarUrl: r['avatar_url'] as String?,
        notes: r['notes'] as String?,
        nationalId: r['national_id'] as String?,
        email: r['email'] as String?,
        aidCount: (r['aid_count'] ?? 0) as int,
        delegate: r['delegate_name'] as String?,
        subscriptionAmount: ((r['subscription_amount'] ?? 0) as num).toDouble(),
        overdueMonths: (r['overdue_months'] ?? 0) as int,
        subscriptionCategory: r['subscription_category'] as String?,
      );

  Map<String, dynamic> _toRow(SubscriberModel s) => {
        'name': s.name,
        'phone': s.phone,
        'address': s.address,
        'area': s.area,
        'registration_date': s.registrationDate.toIso8601String(),
        'status': s.status.name,
        'avatar_url': s.avatarUrl,
        'notes': s.notes,
        'national_id': s.nationalId,
        'email': s.email,
        'aid_count': s.aidCount,
        'delegate_name': s.delegate,
        'subscription_amount': s.subscriptionAmount,
        'overdue_months': s.overdueMonths,
        'subscription_category': s.subscriptionCategory,
      };

  Future<List<SubscriberModel>> getAll() async {
    final rows = await supabase.from(_table).select().order('registration_date', ascending: false);
    return rows.map((e) => _map(e)).toList();
  }

  Future<SubscriberModel?> getById(String id) async {
    final row = await supabase.from(_table).select().eq('id', id).maybeSingle();
    return row == null ? null : _map(row);
  }

  Future<List<SubscriberModel>> search(String query) async {
    final q = query.replaceAll(',', ' ').trim();
    final rows = await supabase
        .from(_table)
        .select()
        .or('name.ilike.%$q%,phone.ilike.%$q%,area.ilike.%$q%');
    return rows.map((e) => _map(e)).toList();
  }

  Future<List<SubscriberModel>> filterByStatus(SubscriberStatus? status) async {
    if (status == null) return getAll();
    final rows = await supabase.from(_table).select().eq('status', status.name);
    return rows.map((e) => _map(e)).toList();
  }

  Future<List<SubscriberModel>> getOverdueSubscribers() async {
    final rows = await supabase.from(_table).select().gt('overdue_months', 0);
    return rows.map((e) => _map(e)).toList();
  }

  /// إنشاء مشترك — نترك id لتوليده في القاعدة (uuid) ونعيد الصف الناتج.
  Future<SubscriberModel> create(SubscriberModel s) async {
    final row = await supabase.from(_table).insert(_toRow(s)).select().single();
    return _map(row);
  }

  Future<SubscriberModel> update(SubscriberModel s) async {
    final row = await supabase.from(_table).update(_toRow(s)).eq('id', s.id).select().single();
    return _map(row);
  }

  Future<void> delete(String id) async {
    await supabase.from(_table).delete().eq('id', id);
  }
}
