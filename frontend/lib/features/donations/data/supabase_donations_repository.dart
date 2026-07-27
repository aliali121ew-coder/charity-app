import 'package:flutter/material.dart';
import 'package:charity_app/core/supabase/supabase_config.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/donations/presentation/providers/donations_provider.dart';

/// مستودع التبرعات عبر Supabase — يدعم قائمة التحويلات في قسم التبرعات.
///
/// النموذج المستخدم: `TransferRecord` (المعرّف في donations_provider.dart، وهو
/// ما تقرؤه الواجهة فعلياً عبر donationsProvider/filteredDonationsProvider).
///
/// جدول donations: id نصّي (TEXT، بلا توليد تلقائي) → نُرسل id عند الإنشاء.
///
/// تنبيهات على المطابقة (انظر التقرير):
///  • method ↔ عمود method نصّي بقيم PaymentMethod.name (هوية مباشرة).
///  • status في TransferRecord نصّ عربي (مكتمل/قيد المعالجة/مرفوض) بينما القاعدة
///    تخزّنه إنجليزياً (completed/processing/rejected) → نترجم في الاتجاهين.
///  • statusColor/statusBg/avatarInitials/avatarColor حقول واجهة غير مخزّنة في
///    القاعدة → تُشتقّ عند القراءة (نفس منطق DonationsNotifier).
class SupabaseDonationsRepository {
  static const _table = 'donations';

  static const _avatarColors = [
    Color(0xFF6366F1), Color(0xFFEC4899), Color(0xFF10B981),
    Color(0xFFF59E0B), Color(0xFF8B5CF6), Color(0xFFEF4444),
    Color(0xFF06B6D4), Color(0xFFF97316), Color(0xFF14B8A6),
  ];

  // ── ترجمة الحالة بين واجهة (عربي) وقاعدة (إنجليزي) ────────────────────────────
  String _statusToDb(String arStatus) {
    switch (arStatus) {
      case 'مكتمل':
        return 'completed';
      case 'قيد المعالجة':
        return 'processing';
      case 'مرفوض':
        return 'rejected';
      default:
        return arStatus;
    }
  }

  String _statusFromDb(String dbStatus) {
    switch (dbStatus) {
      case 'completed':
        return 'مكتمل';
      case 'processing':
        return 'قيد المعالجة';
      case 'rejected':
        return 'مرفوض';
      default:
        return dbStatus;
    }
  }

  PaymentMethod _methodFromDb(String v) => PaymentMethod.values.byName(v);

  String _avatarInitials(String donor) {
    final initials = donor.trim().split(RegExp(r'\s+')).take(2).map((w) => w.isEmpty ? '' : w[0]).join();
    return initials.isNotEmpty ? initials : (donor.isNotEmpty ? donor[0] : '?');
  }

  Color _avatarColorFor(String id) => _avatarColors[id.hashCode.abs() % _avatarColors.length];

  // ── تحويل صف → TransferRecord (مع اشتقاق حقول الواجهة) ────────────────────────
  TransferRecord _map(Map<String, dynamic> r) {
    final arStatus = _statusFromDb((r['status'] ?? '') as String);
    final colors = statusColors(arStatus);
    final donor = (r['donor'] ?? '') as String;
    final id = r['id'] as String;
    return TransferRecord(
      id: id,
      donor: donor,
      amount: ((r['amount'] ?? 0) as num).toDouble(),
      method: _methodFromDb((r['method'] ?? 'cash') as String),
      date: DateTime.parse(r['date'] as String),
      status: arStatus,
      reference: (r['reference'] ?? '') as String,
      statusColor: colors.$1,
      statusBg: colors.$2,
      avatarInitials: _avatarInitials(donor),
      avatarColor: _avatarColorFor(id),
    );
  }

  Map<String, dynamic> _toRow(TransferRecord t) => {
        'id': t.id, // نصّي بلا توليد تلقائي في القاعدة
        'donor': t.donor,
        'amount': t.amount,
        'currency': 'IQD',
        'method': t.method.name,
        'status': _statusToDb(t.status),
        'reference': t.reference,
        'date': t.date.toIso8601String(),
      };

  Future<List<TransferRecord>> getAll() async {
    final rows = await supabase.from(_table).select().order('date', ascending: false);
    return rows.map((e) => _map(e)).toList();
  }

  /// إنشاء تبرّع. يبني معرّفاً ومرجعاً بنفس نمط DonationsNotifier.addTransfer،
  /// ثم يُدرج الصف ويعيد TransferRecord الناتج.
  Future<TransferRecord> create({
    required String donor,
    required double amount,
    required PaymentMethod method,
    String status = 'مكتمل',
    String? reference,
  }) async {
    final prefix = method == PaymentMethod.zainCash
        ? 'ZC'
        : method == PaymentMethod.visaCard
            ? 'VS'
            : method == PaymentMethod.masterCard
                ? 'MC'
                : method == PaymentMethod.bankTransfer
                    ? 'BNK'
                    : 'CSH';
    final now = DateTime.now();
    final ref = reference ?? '$prefix-${now.millisecondsSinceEpoch % 1000000}';
    final id = 'TRF-${now.microsecondsSinceEpoch.toRadixString(36).toUpperCase()}';

    final row = {
      'id': id,
      'donor': donor,
      'amount': amount,
      'currency': 'IQD',
      'method': method.name,
      'status': _statusToDb(status),
      'reference': ref,
      'date': now.toIso8601String(),
    };
    final inserted = await supabase.from(_table).insert(row).select().single();
    return _map(inserted);
  }

  /// تحديث حالة تبرّع. يقبل الحالة بالعربية (كما تستخدمها الواجهة) ويترجمها.
  Future<void> updateStatus(String id, String newStatus) async {
    await supabase.from(_table).update({'status': _statusToDb(newStatus)}).eq('id', id);
  }

  Future<void> delete(String id) async {
    await supabase.from(_table).delete().eq('id', id);
  }

  /// ملخّص محسوب على العميل: الإجمالي، إجمالي الشهر الحالي، والعدد.
  /// يعتمد فقط على التبرعات المكتملة (completed) في الإجماليات المالية.
  Future<Map<String, dynamic>> getSummary() async {
    final rows = await supabase.from(_table).select('amount, status, date');
    final now = DateTime.now();
    double total = 0;
    double thisMonth = 0;
    for (final r in rows) {
      final status = (r['status'] ?? '') as String;
      if (status != 'completed') continue;
      final amount = ((r['amount'] ?? 0) as num).toDouble();
      total += amount;
      final d = DateTime.parse(r['date'] as String);
      if (d.year == now.year && d.month == now.month) thisMonth += amount;
    }
    return {
      'total': total,
      'thisMonth': thisMonth,
      'count': rows.length,
    };
  }
}
