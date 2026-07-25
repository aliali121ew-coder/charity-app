import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:charity_app/core/theme/app_colors.dart';

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

final _initialTransfers = [
  TransferRecord(id: 'TRF-001', donor: 'أحمد محمد علي', amount: 500000,
      method: PaymentMethod.zainCash, date: DateTime(2026, 3, 15, 14, 30),
      status: 'مكتمل', reference: 'ZC-884712',
      statusColor: AppColors.statusActiveText, statusBg: AppColors.statusActiveBg,
      avatarInitials: 'أم', avatarColor: const Color(0xFF6366F1)),
  TransferRecord(id: 'TRF-002', donor: 'سارة حسين الكريم', amount: 1200000,
      method: PaymentMethod.visaCard, date: DateTime(2026, 3, 14, 9, 15),
      status: 'مكتمل', reference: 'VS-229041',
      statusColor: AppColors.statusActiveText, statusBg: AppColors.statusActiveBg,
      avatarInitials: 'سح', avatarColor: const Color(0xFFEC4899)),
  TransferRecord(id: 'TRF-003', donor: 'محمد عبد الرحمن', amount: 250000,
      method: PaymentMethod.cash, date: DateTime(2026, 3, 14, 11, 0),
      status: 'مكتمل', reference: 'CSH-004',
      statusColor: AppColors.statusActiveText, statusBg: AppColors.statusActiveBg,
      avatarInitials: 'مع', avatarColor: const Color(0xFF10B981)),
  TransferRecord(id: 'TRF-004', donor: 'فاطمة القاسم', amount: 3000000,
      method: PaymentMethod.bankTransfer, date: DateTime(2026, 3, 13, 16, 45),
      status: 'قيد المعالجة', reference: 'BNK-IQ44128',
      statusColor: AppColors.statusPendingText, statusBg: AppColors.statusPendingBg,
      avatarInitials: 'فق', avatarColor: const Color(0xFFF59E0B)),
  TransferRecord(id: 'TRF-005', donor: 'علي جعفر مهدي', amount: 750000,
      method: PaymentMethod.masterCard, date: DateTime(2026, 3, 13, 8, 30),
      status: 'مكتمل', reference: 'MC-774920',
      statusColor: AppColors.statusActiveText, statusBg: AppColors.statusActiveBg,
      avatarInitials: 'عج', avatarColor: const Color(0xFF8B5CF6)),
  TransferRecord(id: 'TRF-006', donor: 'نور الهدى سالم', amount: 100000,
      method: PaymentMethod.zainCash, date: DateTime(2026, 3, 12, 13, 20),
      status: 'مرفوض', reference: 'ZC-998821',
      statusColor: AppColors.statusRejectedText, statusBg: AppColors.statusRejectedBg,
      avatarInitials: 'نس', avatarColor: const Color(0xFFEF4444)),
  TransferRecord(id: 'TRF-007', donor: 'خالد عمر البصري', amount: 2500000,
      method: PaymentMethod.bankTransfer, date: DateTime(2026, 3, 11, 10, 0),
      status: 'مكتمل', reference: 'BNK-IQ77531',
      statusColor: AppColors.statusActiveText, statusBg: AppColors.statusActiveBg,
      avatarInitials: 'خع', avatarColor: const Color(0xFF06B6D4)),
  TransferRecord(id: 'TRF-008', donor: 'رنا حميد الجبوري', amount: 500000,
      method: PaymentMethod.visaCard, date: DateTime(2026, 3, 10, 15, 10),
      status: 'مكتمل', reference: 'VS-662341',
      statusColor: AppColors.statusActiveText, statusBg: AppColors.statusActiveBg,
      avatarInitials: 'رح', avatarColor: const Color(0xFFF97316)),
];

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

const _avatarColors = [
  Color(0xFF6366F1), Color(0xFFEC4899), Color(0xFF10B981),
  Color(0xFFF59E0B), Color(0xFF8B5CF6), Color(0xFFEF4444),
  Color(0xFF06B6D4), Color(0xFFF97316), Color(0xFF14B8A6),
];

// ── Donations Notifier ────────────────────────────────────────────────────────

class DonationsNotifier extends StateNotifier<List<TransferRecord>> {
  DonationsNotifier() : super(List.from(_initialTransfers));

  void addTransfer({
    required String donor,
    required double amount,
    required PaymentMethod method,
    String status = 'مكتمل',
  }) {
    const uuid = Uuid();
    final prefix = method == PaymentMethod.zainCash
        ? 'ZC'
        : method == PaymentMethod.visaCard
            ? 'VS'
            : method == PaymentMethod.masterCard
                ? 'MC'
                : method == PaymentMethod.bankTransfer
                    ? 'BNK'
                    : 'CSH';
    final ref = '$prefix-${(DateTime.now().millisecondsSinceEpoch % 1000000)}';
    final initials = donor.trim().split(' ').take(2).map((w) => w[0]).join();
    final colorIndex = state.length % _avatarColors.length;
    final colors = statusColors(status);

    final record = TransferRecord(
      id: 'TRF-${uuid.v4().substring(0, 6).toUpperCase()}',
      donor: donor,
      amount: amount,
      method: method,
      date: DateTime.now(),
      status: status,
      reference: ref,
      statusColor: colors.$1,
      statusBg: colors.$2,
      avatarInitials: initials.isNotEmpty ? initials : donor[0],
      avatarColor: _avatarColors[colorIndex],
    );

    state = [record, ...state];
  }

  void updateStatus(String id, String newStatus) {
    final colors = statusColors(newStatus);
    state = state.map((t) {
      if (t.id != id) return t;
      return TransferRecord(
        id: t.id, donor: t.donor, amount: t.amount,
        method: t.method, date: t.date, reference: t.reference,
        avatarInitials: t.avatarInitials, avatarColor: t.avatarColor,
        status: newStatus,
        statusColor: colors.$1,
        statusBg: colors.$2,
      );
    }).toList();
  }

  void removeTransfer(String id) {
    state = state.where((t) => t.id != id).toList();
  }
}

final donationsProvider =
    StateNotifierProvider<DonationsNotifier, List<TransferRecord>>((ref) {
  return DonationsNotifier();
});

// ── Operations Notifier ───────────────────────────────────────────────────────

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

final selectedMethodIndexProvider = StateProvider<int>((ref) => 0);
final selectedAmountProvider = StateProvider<double?>((ref) => null);
final donationLoadingProvider = StateProvider<bool>((ref) => false);
