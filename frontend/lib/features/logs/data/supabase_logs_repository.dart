import 'package:charity_app/core/supabase/supabase_config.dart';
import 'package:charity_app/shared/models/log_model.dart';

/// مستودع سجلّ العمليات عبر Supabase — يحلّ محل MockLogsRepository (async).
/// جدول activity_logs: id عبارة عن bigint identity، و action_type نصّي (بعد 0016)
/// ليقبل كل قيم LogActionType. actor_user_id لا يُستخدم لأنّ performedById
/// نصّي وليس بالضرورة uuid.
class SupabaseLogsRepository {
  static const _table = 'activity_logs';

  LogModel _map(Map<String, dynamic> r) => LogModel(
        id: r['id'].toString(),
        actionTitle: (r['action_title'] ?? '') as String,
        description: (r['description'] ?? '') as String,
        performedBy: (r['actor_name'] ?? '') as String,
        performedById: (r['actor_user_id']?.toString() ?? ''),
        timestamp: DateTime.parse(r['created_at'] as String),
        actionType: LogActionType.values.byName((r['action_type'] ?? 'other') as String),
        referenceNumber: r['reference_number'] as String?,
        entityType: r['related_entity'] as String?,
        entityId: r['related_entity_id'] as String?,
      );

  /// تحويل النموذج لصف للإدراج — بدون id (تولّده القاعدة) وبدون actor_user_id
  /// (performedById نصّي وليس uuid، لذا نتركه null لتفادي خرق قيد الـ FK).
  Map<String, dynamic> _toRow(LogModel l) => {
        'action_title': l.actionTitle,
        'description': l.description,
        'actor_name': l.performedBy,
        'action_type': l.actionType.name,
        'reference_number': l.referenceNumber,
        'related_entity': l.entityType,
        'related_entity_id': l.entityId,
        'created_at': l.timestamp.toIso8601String(),
      };

  Future<List<LogModel>> getAll() async {
    final rows = await supabase.from(_table).select().order('created_at', ascending: false);
    return rows.map((e) => _map(e)).toList();
  }

  Future<List<LogModel>> search(String query) async {
    final q = query.replaceAll(',', ' ').trim();
    final rows = await supabase
        .from(_table)
        .select()
        .or('action_title.ilike.%$q%,description.ilike.%$q%,actor_name.ilike.%$q%,reference_number.ilike.%$q%')
        .order('created_at', ascending: false);
    return rows.map((e) => _map(e)).toList();
  }

  Future<List<LogModel>> filterByActionType(LogActionType? type) async {
    if (type == null) return getAll();
    final rows = await supabase
        .from(_table)
        .select()
        .eq('action_type', type.name)
        .order('created_at', ascending: false);
    return rows.map((e) => _map(e)).toList();
  }

  Future<List<LogModel>> filterByUser(String? userId) async {
    if (userId == null || userId.isEmpty) return getAll();
    final rows = await supabase
        .from(_table)
        .select()
        .eq('actor_user_id', userId)
        .order('created_at', ascending: false);
    return rows.map((e) => _map(e)).toList();
  }

  Future<Map<LogActionType, int>> getCountByType() async {
    final rows = await supabase.from(_table).select('action_type');
    final map = <LogActionType, int>{};
    for (final r in rows) {
      final t = LogActionType.values.byName((r['action_type'] ?? 'other') as String);
      map[t] = (map[t] ?? 0) + 1;
    }
    return map;
  }

  Future<int> getTodayCount() async {
    final start = DateTime.now();
    final dayStart = DateTime(start.year, start.month, start.day);
    final rows = await supabase
        .from(_table)
        .select('id')
        .gte('created_at', dayStart.toIso8601String());
    return rows.length;
  }

  /// إضافة سطر في السجلّ — نترك id لتوليده في القاعدة ونعيد الصف الناتج.
  Future<LogModel> add(LogModel log) async {
    final row = await supabase.from(_table).insert(_toRow(log)).select().single();
    return _map(row);
  }
}
