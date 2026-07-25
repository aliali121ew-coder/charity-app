enum AidType { financial, food, medical, seasonal, education, other }
enum AidStatus { pending, approved, rejected, distributed }

class AidModel {
  final String id;
  final String referenceNumber;
  final String beneficiaryName;
  final String? familyId;
  final String? subscriberId;
  final AidType type;
  final double amount;
  final String currency;
  final DateTime date;
  final String responsibleEmployee;
  final AidStatus status;
  final String? notes;
  final DateTime? deliveryDate;

  const AidModel({
    required this.id,
    required this.referenceNumber,
    required this.beneficiaryName,
    this.familyId,
    this.subscriberId,
    required this.type,
    required this.amount,
    this.currency = 'IQD',
    required this.date,
    required this.responsibleEmployee,
    required this.status,
    this.notes,
    this.deliveryDate,
  });

  AidModel copyWith({
    String? beneficiaryName,
    AidType? type,
    double? amount,
    String? currency,
    DateTime? date,
    String? responsibleEmployee,
    AidStatus? status,
    String? notes,
    DateTime? deliveryDate,
  }) {
    return AidModel(
      id: id,
      referenceNumber: referenceNumber,
      beneficiaryName: beneficiaryName ?? this.beneficiaryName,
      familyId: familyId,
      subscriberId: subscriberId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      date: date ?? this.date,
      responsibleEmployee: responsibleEmployee ?? this.responsibleEmployee,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      deliveryDate: deliveryDate ?? this.deliveryDate,
    );
  }
}

extension AidTypeExt on AidType {
  String get labelAr {
    switch (this) {
      case AidType.financial: return 'مالية';
      case AidType.food: return 'غذائية';
      case AidType.medical: return 'طبية';
      case AidType.seasonal: return 'موسمية';
      case AidType.education: return 'تعليمية';
      case AidType.other: return 'أخرى';
    }
  }

  String get labelEn {
    switch (this) {
      case AidType.financial: return 'Financial';
      case AidType.food: return 'Food';
      case AidType.medical: return 'Medical';
      case AidType.seasonal: return 'Seasonal';
      case AidType.education: return 'Education';
      case AidType.other: return 'Other';
    }
  }
}

extension AidStatusExt on AidStatus {
  String get labelAr {
    switch (this) {
      case AidStatus.pending: return 'قيد الانتظار';
      case AidStatus.approved: return 'معتمد';
      case AidStatus.rejected: return 'مرفوض';
      case AidStatus.distributed: return 'تم الصرف';
    }
  }
}
