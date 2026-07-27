import 'package:charity_app/core/supabase/supabase_config.dart';
import 'package:charity_app/features/help_requests/domain/entities/help_request.dart';
import 'package:charity_app/features/help_requests/domain/entities/location_info.dart';
import 'package:charity_app/features/help_requests/domain/entities/media_attachment.dart';
import 'package:charity_app/features/help_requests/domain/entities/request_status.dart';
import 'package:charity_app/features/help_requests/domain/entities/request_type.dart';
import 'package:charity_app/features/help_requests/domain/entities/urgency_level.dart';

/// مستودع طلبات المساعدة عبر Supabase — يحلّ محل MockHelpRequestsRepository.
///
/// ملاحظة مهمّة حول العقد: واجهة `HelpRequestsRepository` متزامنة
/// (List/HelpRequest?/bool)، بينما Supabase غير متزامن بطبيعته. لذلك لا يمكن
/// استخدام `implements HelpRequestsRepository` حرفياً؛ بدلاً من ذلك نطابق
/// أسماء الدوال ووسائطها بدقّة مع إعادة نسخ `Future<...>` منها (نفس ما فعلته
/// مستودعات Supabase الأخرى مع الـ mocks). على مواقع الاستدعاء التعامل معها
/// عبر await / FutureProvider.
///
/// الجداول: help_requests + help_request_attachments.
class SupabaseHelpRequestsRepository {
  static const _table = 'help_requests';
  static const _attachmentsTable = 'help_request_attachments';

  // ── تحويل مرفق ──────────────────────────────────────────────────────────────
  MediaAttachment _mapAttachment(Map<String, dynamic> r) => MediaAttachment(
        id: r['id'] as String,
        type: AttachmentType.values.byName((r['type'] ?? 'image') as String),
        name: (r['name'] ?? '') as String,
        mockPath: r['storage_path'] as String?,
        durationSeconds: r['duration_seconds'] as int?,
        createdAt: DateTime.parse(r['created_at'] as String),
      );

  Map<String, dynamic> _attachmentToRow(String requestId, MediaAttachment a) => {
        'help_request_id': requestId,
        'type': a.type.name,
        'name': a.name,
        'storage_path': a.mockPath ?? '',
        'duration_seconds': a.durationSeconds,
        'created_at': a.createdAt.toIso8601String(),
      };

  // ── تحويل طلب ───────────────────────────────────────────────────────────────
  HelpRequest _map(Map<String, dynamic> r, {List<MediaAttachment> attachments = const []}) {
    return HelpRequest(
      id: r['id'] as String,
      type: RequestType.values.byName((r['type'] ?? 'generalHelp') as String),
      status: RequestStatus.values.byName((r['status'] ?? 'pending') as String),
      submittedAt: DateTime.parse(r['submitted_at'] as String),
      fullName: (r['full_name'] ?? '') as String,
      phone: (r['phone'] ?? '') as String,
      governorate: (r['governorate'] ?? '') as String,
      area: (r['area'] ?? '') as String,
      fullAddress: (r['full_address'] ?? '') as String,
      title: (r['title'] ?? '') as String,
      description: (r['description'] ?? '') as String,
      urgency: UrgencyLevel.values.byName((r['urgency'] ?? 'medium') as String),
      familySize: r['family_size'] as int?,
      notes: r['notes'] as String?,
      location: LocationInfo(
        latitude: (r['latitude'] as num?)?.toDouble(),
        longitude: (r['longitude'] as num?)?.toDouble(),
        address: (r['location_address'] ?? '') as String,
        governorate: (r['governorate'] ?? '') as String,
        area: (r['area'] ?? '') as String,
      ),
      attachments: attachments,
      typeData: ((r['type_data'] ?? const <String, dynamic>{}) as Map)
          .map((k, v) => MapEntry(k.toString(), (v ?? '').toString())),
    );
  }

  /// لا نُرسل id (تولّده القاعدة). المرفقات تُدرَج في جدول منفصل.
  /// type_data يُمرَّر كـ Map مباشرةً (عمود jsonb).
  Map<String, dynamic> _toRow(HelpRequest h) => {
        'type': h.type.name,
        'status': h.status.name,
        'urgency': h.urgency.name,
        'submitted_at': h.submittedAt.toIso8601String(),
        'full_name': h.fullName,
        'phone': h.phone,
        'governorate': h.governorate,
        'area': h.area,
        'full_address': h.fullAddress,
        'title': h.title,
        'description': h.description,
        'family_size': h.familySize,
        'notes': h.notes,
        'latitude': h.location.latitude,
        'longitude': h.location.longitude,
        'location_address': h.location.address,
        'type_data': h.typeData,
      };

  // ── مرفقات ──────────────────────────────────────────────────────────────────
  Future<List<MediaAttachment>> getAttachments(String requestId) async {
    final rows = await supabase
        .from(_attachmentsTable)
        .select()
        .eq('help_request_id', requestId)
        .order('created_at', ascending: true);
    return rows.map((e) => _mapAttachment(e)).toList();
  }

  // ── قراءة ───────────────────────────────────────────────────────────────────
  /// قوائم: تُعاد الطلبات دون جلب المرفقات لكل عنصر (attachments فارغة) — تُجلب
  /// التفاصيل الكاملة (بالمرفقات) عبر getById، مطابقةً لعقد الواجهة الذي يعيد
  /// نفس نوع الكيان.
  Future<List<HelpRequest>> getAll() async {
    final rows = await supabase.from(_table).select().order('submitted_at', ascending: false);
    return rows.map((e) => _map(e)).toList();
  }

  Future<HelpRequest?> getById(String id) async {
    final row = await supabase.from(_table).select().eq('id', id).maybeSingle();
    if (row == null) return null;
    final attachments = await getAttachments(id);
    return _map(row, attachments: attachments);
  }

  // ── كتابة ───────────────────────────────────────────────────────────────────
  /// إنشاء الطلب (بدون id) ثمّ إدراج مرفقاته مع ربطها بالـ id الجديد.
  Future<HelpRequest> add(HelpRequest request) async {
    final row = await supabase.from(_table).insert(_toRow(request)).select().single();
    final newId = row['id'] as String;

    if (request.attachments.isNotEmpty) {
      await supabase
          .from(_attachmentsTable)
          .insert(request.attachments.map((a) => _attachmentToRow(newId, a)).toList());
    }
    final attachments = await getAttachments(newId);
    return _map(row, attachments: attachments);
  }

  Future<HelpRequest?> update(HelpRequest request) async {
    final existing = await getById(request.id);
    if (existing == null) return null;
    if (!existing.isEditable) return null;
    final row =
        await supabase.from(_table).update(_toRow(request)).eq('id', request.id).select().single();
    final attachments = await getAttachments(request.id);
    return _map(row, attachments: attachments);
  }

  Future<bool> delete(String id) async {
    final existing = await supabase.from(_table).select('id').eq('id', id).maybeSingle();
    if (existing == null) return false;
    // المرفقات تُحذف تلقائياً عبر on delete cascade في القاعدة.
    await supabase.from(_table).delete().eq('id', id);
    return true;
  }
}
