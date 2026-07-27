import 'package:charity_app/core/supabase/supabase_config.dart';
import 'package:charity_app/shared/models/family_model.dart';

/// مستودع العائلات عبر Supabase — يحلّ محل MockFamiliesRepository (async).
class SupabaseFamiliesRepository {
  static const _table = 'families';

  FamilyModel _map(Map<String, dynamic> r) => FamilyModel(
        id: r['id'] as String,
        headName: (r['head_name'] ?? '') as String,
        membersCount: (r['members_count'] ?? 0) as int,
        maritalStatus: MaritalStatus.values.byName((r['marital_status'] ?? 'married') as String),
        incomeLevel: IncomeLevel.values.byName((r['income_level'] ?? 'low') as String),
        address: (r['address'] ?? '') as String,
        area: (r['area'] ?? '') as String,
        status: FamilyStatus.values.byName((r['status'] ?? 'pending') as String),
        notes: r['notes'] as String?,
        aidCount: (r['aid_count'] ?? 0) as int,
        totalAidAmount: ((r['total_aid_amount'] ?? 0) as num).toDouble(),
        registrationDate: DateTime.parse(r['registration_date'] as String),
        phone: r['phone'] as String?,
        delegateName: r['delegate_name'] as String?,
      );

  Map<String, dynamic> _toRow(FamilyModel f) => {
        'head_name': f.headName,
        'members_count': f.membersCount,
        'marital_status': f.maritalStatus.name,
        'income_level': f.incomeLevel.name,
        'address': f.address,
        'area': f.area,
        'status': f.status.name,
        'notes': f.notes,
        'aid_count': f.aidCount,
        'total_aid_amount': f.totalAidAmount,
        'registration_date': f.registrationDate.toIso8601String(),
        'phone': f.phone,
        'delegate_name': f.delegateName,
      };

  Future<List<FamilyModel>> getAll() async {
    final rows = await supabase.from(_table).select().order('registration_date', ascending: false);
    return rows.map((e) => _map(e)).toList();
  }

  Future<List<FamilyModel>> search(String query) async {
    final q = query.replaceAll(',', ' ').trim();
    final rows = await supabase
        .from(_table)
        .select()
        .or('head_name.ilike.%$q%,area.ilike.%$q%,address.ilike.%$q%');
    return rows.map((e) => _map(e)).toList();
  }

  Future<List<FamilyModel>> filterByStatus(FamilyStatus? status) async {
    if (status == null) return getAll();
    final rows = await supabase.from(_table).select().eq('status', status.name);
    return rows.map((e) => _map(e)).toList();
  }

  Future<Map<String, int>> getStatusCounts() async {
    final rows = await supabase.from(_table).select('status');
    final counts = {'eligible': 0, 'pending': 0, 'ineligible': 0, 'suspended': 0};
    for (final r in rows) {
      final s = r['status'] as String;
      counts[s] = (counts[s] ?? 0) + 1;
    }
    return counts;
  }

  Future<FamilyModel> create(FamilyModel f) async {
    final row = await supabase.from(_table).insert(_toRow(f)).select().single();
    return _map(row);
  }

  Future<FamilyModel> update(FamilyModel f) async {
    final row = await supabase.from(_table).update(_toRow(f)).eq('id', f.id).select().single();
    return _map(row);
  }

  Future<void> delete(String id) async {
    await supabase.from(_table).delete().eq('id', id);
  }
}
