import 'package:equatable/equatable.dart';

enum FamilyStatus { eligible, underReview, inactive, supported }
enum IncomeLevel { none, low, medium, high }

class Family extends Equatable {
  final String id;
  final String headName;
  final int memberCount;
  final String maritalStatus;
  final IncomeLevel incomeLevel;
  final String address;
  final String area;
  final FamilyStatus status;
  final String? notes;
  final int aidCount;
  final double? totalAidAmount;
  final DateTime registrationDate;
  final String? phone;

  const Family({
    required this.id,
    required this.headName,
    required this.memberCount,
    required this.maritalStatus,
    required this.incomeLevel,
    required this.address,
    required this.area,
    required this.status,
    this.notes,
    this.aidCount = 0,
    this.totalAidAmount,
    required this.registrationDate,
    this.phone,
  });

  Family copyWith({
    String? headName,
    int? memberCount,
    String? maritalStatus,
    IncomeLevel? incomeLevel,
    String? address,
    FamilyStatus? status,
    String? notes,
  }) {
    return Family(
      id: id,
      headName: headName ?? this.headName,
      memberCount: memberCount ?? this.memberCount,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      incomeLevel: incomeLevel ?? this.incomeLevel,
      address: address ?? this.address,
      area: area,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      aidCount: aidCount,
      totalAidAmount: totalAidAmount,
      registrationDate: registrationDate,
      phone: phone,
    );
  }

  @override
  List<Object?> get props => [id, headName, status, memberCount];
}
