enum FamilyStatus { eligible, ineligible, pending, suspended }
enum IncomeLevel { veryLow, low, medium, aboveAverage }
enum MaritalStatus { married, widowed, divorced, single }

class FamilyModel {
  final String id;
  final String headName;
  final int membersCount;
  final MaritalStatus maritalStatus;
  final IncomeLevel incomeLevel;
  final String address;
  final String area;
  final FamilyStatus status;
  final String? notes;
  final int aidCount;
  final double totalAidAmount;
  final DateTime registrationDate;
  final String? phone;

  const FamilyModel({
    required this.id,
    required this.headName,
    required this.membersCount,
    required this.maritalStatus,
    required this.incomeLevel,
    required this.address,
    required this.area,
    required this.status,
    this.notes,
    this.aidCount = 0,
    this.totalAidAmount = 0,
    required this.registrationDate,
    this.phone,
  });

  FamilyModel copyWith({
    String? headName,
    int? membersCount,
    MaritalStatus? maritalStatus,
    IncomeLevel? incomeLevel,
    String? address,
    String? area,
    FamilyStatus? status,
    String? notes,
    int? aidCount,
    double? totalAidAmount,
    DateTime? registrationDate,
    String? phone,
  }) {
    return FamilyModel(
      id: id,
      headName: headName ?? this.headName,
      membersCount: membersCount ?? this.membersCount,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      incomeLevel: incomeLevel ?? this.incomeLevel,
      address: address ?? this.address,
      area: area ?? this.area,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      aidCount: aidCount ?? this.aidCount,
      totalAidAmount: totalAidAmount ?? this.totalAidAmount,
      registrationDate: registrationDate ?? this.registrationDate,
      phone: phone ?? this.phone,
    );
  }
}

extension FamilyStatusExt on FamilyStatus {
  String get labelAr {
    switch (this) {
      case FamilyStatus.eligible: return 'مؤهلة';
      case FamilyStatus.ineligible: return 'غير مؤهلة';
      case FamilyStatus.pending: return 'قيد المراجعة';
      case FamilyStatus.suspended: return 'موقوفة';
    }
  }
}

extension IncomeLevelExt on IncomeLevel {
  String get labelAr {
    switch (this) {
      case IncomeLevel.veryLow: return 'منخفض جداً';
      case IncomeLevel.low: return 'منخفض';
      case IncomeLevel.medium: return 'متوسط';
      case IncomeLevel.aboveAverage: return 'فوق المتوسط';
    }
  }
}

extension MaritalStatusExt on MaritalStatus {
  String get labelAr {
    switch (this) {
      case MaritalStatus.married: return 'متزوج';
      case MaritalStatus.widowed: return 'أرمل/ة';
      case MaritalStatus.divorced: return 'مطلق/ة';
      case MaritalStatus.single: return 'أعزب';
    }
  }
}
