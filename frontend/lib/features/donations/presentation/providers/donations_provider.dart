import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/donations/data/supabase_donations_repository.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum PaymentMethod { zainCash, visaCard, masterCard, bankTransfer, cash }

extension PaymentMethodExt on PaymentMethod {
  String get labelAr {
    switch (this) {
      case PaymentMethod.zainCash:     return 'زين كاش';
      case PaymentMethod.visaCard:     return 'Visa Card';
      case PaymentMethod.masterCard:   return 'MasterCard';
      case PaymentMethod.bankTransfer: return 'تحويل بنكي';
      case PaymentMethod.cash:         return 'نقداً';
    }
  }

  String get number {
    switch (this) {
      case PaymentMethod.zainCash:     return '•••• •••• 4821';
      case PaymentMethod.visaCard:     return '•••• •••• 9043';
      case PaymentMethod.masterCard:   return '•••• •••• 7712';
      case PaymentMethod.bankTransfer: return 'IQ••••••8830';
      case PaymentMethod.cash:         return 'دفع نقدي مباشر';
    }
  }

  String get expiry {
    switch (this) {
      case PaymentMethod.zainCash:     return '12/27';
      case PaymentMethod.visaCard:     return '08/28';
      case PaymentMethod.masterCard:   return '03/26';
      case PaymentMethod.bankTransfer: return 'بنك الرشيد';
      case PaymentMethod.cash:         return 'متاح دائماً';
    }
  }

  LinearGradient get cardGradient {
    switch (this) {
      case PaymentMethod.zainCash:
        return const LinearGradient(colors: [Color(0xFF0F52BA), Color(0xFF003D7A)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case PaymentMethod.visaCard:
        return const LinearGradient(colors: [Color(0xFF1C1C3A), Color(0xFF0D1B4B)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case PaymentMethod.masterCard:
        return const LinearGradient(colors: [Color(0xFF3D1A6E), Color(0xFF0D6E5A)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case PaymentMethod.bankTransfer:
        return const LinearGradient(colors: [Color(0xFF134E5E), Color(0xFF1B6B4A)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case PaymentMethod.cash:
        return const LinearGradient(colors: [Color(0xFF2C3E6B), Color(0xFF1A2A5E)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    }
  }

  Color get accentColor {
    switch (this) {
      case PaymentMethod.zainCash:     return const Color(0xFF4DA6FF);
      case PaymentMethod.visaCard:     return const Color(0xFFFFD700);
      case PaymentMethod.masterCard:   return const Color(0xFFFF6B6B);
      case PaymentMethod.bankTransfer: return const Color(0xFF71B280);
      case PaymentMethod.cash:         return const Color(0xFF7EB6FF);
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.zainCash:     return Icons.phone_android_rounded;
      case PaymentMethod.visaCard:     return Icons.credit_card_rounded;
      case PaymentMethod.masterCard:   return Icons.credit_score_rounded;
      case PaymentMethod.bankTransfer: return Icons.account_balance_rounded;
      case PaymentMethod.cash:         return Icons.payments_rounded;
    }
  }
}

// ── Models ────────────────────────────────────────────────────────────────────

class TransferRecord {
  final String id, donor, status, reference, avatarInitials;
  final double amount;
  final PaymentMethod method;
  final DateTime date;
  final Color statusColor, statusBg, avatarColor;

  const TransferRecord({
    required this.id,
    required this.donor,
    required this.amount,
    required this.method,
    required this.date,
    required this.status,
    required this.reference,
    required this.statusColor,
    required this.statusBg,
    required this.avatarInitials,
    required this.avatarColor,
  });
}

class OperationRecord {
  final String action, description, user;
  final DateTime date;
  final Color color;
  final IconData icon;

  const OperationRecord({
    required this.action,
    required this.description,
    required this.user,
    required this.date,
    required this.color,
    required this.icon,
  });
}

// ── Initial mock data ─────────────────────────────────────────────────────────
// ملاحظة: بيانات التحويلات المبدئية (mock) أُزيلت لأن قائمة التحويلات صارت تُحمّل
// من Supabase عبر SupabaseDonationsRepository (انظر DonationsNotifier أدناه).

final _initialOperations = [
  OperationRecord(action: 'تأكيد تبرع', description: 'تم تأكيد تبرع 1,200,000 د.ع من سارة حسين عبر Visa', user: 'المشرف أحمد', date: DateTime(2026, 3, 14, 9, 20), color: AppColors.logApprove, icon: Icons.check_circle_rounded),
  OperationRecord(action: 'إضافة طريقة دفع', description: 'تمت إضافة حساب تحويل بنكي IBAN: IQ72•••8830', user: 'المشرف أحمد', date: DateTime(2026, 3, 13, 17, 0), color: AppColors.logAdd, icon: Icons.add_card_rounded),
  OperationRecord(action: 'رفض معاملة', description: 'رُفض تحويل TRF-006 لعدم اكتمال البيانات', user: 'المشرف سارة', date: DateTime(2026, 3, 12, 14, 5), color: AppColors.logReject, icon: Icons.cancel_rounded),
  OperationRecord(action: 'تحديث الحد الأدنى', description: 'تم تحديث الحد الأدنى للتبرع من 10,000 إلى 25,000 د.ع', user: 'المشرف أحمد', date: DateTime(2026, 3, 11, 11, 30), color: AppColors.logEdit, icon: Icons.edit_rounded),
  OperationRecord(action: 'صرف تبرعات', description: 'صرف 5,000,000 د.ع لصالح 12 عائلة مستفيدة', user: 'المشرف سارة', date: DateTime(2026, 3, 10, 9, 0), color: AppColors.logDistribute, icon: Icons.volunteer_activism_rounded),
  OperationRecord(action: 'إنشاء تقرير', description: 'تقرير التبرعات الشهري لشهر فبراير 2026', user: 'المشرف أحمد', date: DateTime(2026, 3, 9, 15, 45), color: AppColors.logReport, icon: Icons.description_rounded),
  OperationRecord(action: 'تفعيل MasterCard', description: 'تم تفعيل بوابة الدفع عبر MasterCard بنجاح', user: 'المدير العام', date: DateTime(2026, 3, 8, 10, 0), color: AppColors.logAdd, icon: Icons.credit_card_rounded),
];

// ── Colors helper ─────────────────────────────────────────────────────────────

(Color, Color) statusColors(String status) {
  switch (status) {
    case 'مكتمل':
      return (AppColors.statusActiveText, AppColors.statusActiveBg);
    case 'قيد المعالجة':
      return (AppColors.statusPendingText, AppColors.statusPendingBg);
    case 'مرفوض':
      return (AppColors.statusRejectedText, AppColors.statusRejectedBg);
    default:
      return (AppColors.textSecondaryLight, AppColors.surfaceVariantLight);
  }
}

// ── Donations Notifier ────────────────────────────────────────────────────────

/// DonationsNotifier مدعوم بـ Supabase (جدول donations عبر SupabaseDonationsRepository).
/// نفس الواجهة العامة تماماً (List<TransferRecord> + addTransfer/updateStatus/removeTransfer)
/// حتى لا تتغيّر donations_page/transfer_history_tab/transfer_detail:
///  - التحميل الأولي async من Supabase (getAll)، ويبدأ بقائمة فارغة ثم يملؤها.
///  - addTransfer/updateStatus/removeTransfer تكتب في Supabase ثم تُعيد التحميل (refresh).
///  - الفلترة/البحث تبقى محلية ومتزامنة عبر filteredDonationsProvider (لم تتغيّر).
///  - الملخّص المعروض (الإجمالي/عدد المتبرعين/قيد المعالجة) يُشتقّ محلياً من القائمة،
///    وبذلك يصبح مدعوماً بـ Supabase تلقائياً دون تغيير الصفحات.
class DonationsNotifier extends StateNotifier<List<TransferRecord>> {
  final SupabaseDonationsRepository _repo = SupabaseDonationsRepository();

  DonationsNotifier() : super(const []) {
    _load();
  }

  Future<void> _load() async {
    try {
      state = await _repo.getAll();
    } catch (_) {
      // في حال تعذّر الاتصال نُبقي الحالة الحالية (فارغة) بدل الانهيار.
    }
  }

  /// إعادة تحميل من الخادم (مفيدة للسحب-للتحديث).
  Future<void> reload() => _load();

  Future<void> addTransfer({
    required String donor,
    required double amount,
    required PaymentMethod method,
    String status = 'مكتمل',
  }) async {
    await _repo.create(
      donor: donor,
      amount: amount,
      method: method,
      status: status,
    );
    await _load();
  }

  Future<void> updateStatus(String id, String newStatus) async {
    await _repo.updateStatus(id, newStatus);
    await _load();
  }

  Future<void> removeTransfer(String id) async {
    await _repo.delete(id);
    await _load();
  }
}

final donationsProvider =
    StateNotifierProvider<DonationsNotifier, List<TransferRecord>>((ref) {
  return DonationsNotifier();
});

// ── Operations Notifier ───────────────────────────────────────────────────────
// TODO(supabase): سجل العمليات (operations log) لا يزال محلياً على بيانات مبدئية.
// خارج نطاق هذه المهمة (القائمة/الملخّص فقط) — يمكن ربطه لاحقاً بجدول سجل مخصّص.

class OperationsNotifier extends StateNotifier<List<OperationRecord>> {
  OperationsNotifier() : super(List.from(_initialOperations));

  void addOperation({
    required String action,
    required String description,
    required String user,
    required Color color,
    required IconData icon,
  }) {
    final record = OperationRecord(
      action: action,
      description: description,
      user: user,
      date: DateTime.now(),
      color: color,
      icon: icon,
    );
    state = [record, ...state];
  }
}

final operationsProvider =
    StateNotifierProvider<OperationsNotifier, List<OperationRecord>>((ref) {
  return OperationsNotifier();
});

// ── Filter Providers ──────────────────────────────────────────────────────────

final donationStatusFilterProvider = StateProvider<String?>((ref) => null);
final donationMethodFilterProvider =
    StateProvider<PaymentMethod?>((ref) => null);
final donationSearchProvider = StateProvider<String>((ref) => '');

final filteredDonationsProvider = Provider<List<TransferRecord>>((ref) {
  final all = ref.watch(donationsProvider);
  final status = ref.watch(donationStatusFilterProvider);
  final method = ref.watch(donationMethodFilterProvider);
  final search = ref.watch(donationSearchProvider).trim().toLowerCase();

  return all.where((t) {
    if (status != null && t.status != status) return false;
    if (method != null && t.method != method) return false;
    if (search.isNotEmpty &&
        !t.donor.toLowerCase().contains(search) &&
        !t.reference.toLowerCase().contains(search)) {
      return false;
    }
    return true;
  }).toList();
});

// ── UI Providers (donate flow) ────────────────────────────────────────────────
// TODO(supabase): حالة تدفّق الدفع (اختيار البطاقة/المبلغ) وبوّابات الدفع الفعلية
// (payment_flow_provider + MyFatoorah/ZainCash) تبقى محلية دون تغيير في هذه المهمة.

final selectedMethodIndexProvider = StateProvider<int>((ref) => 0);
final selectedAmountProvider = StateProvider<double?>((ref) => null);
final donationLoadingProvider = StateProvider<bool>((ref) => false);
