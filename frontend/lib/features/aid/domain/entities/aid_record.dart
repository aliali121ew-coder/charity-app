import 'package:equatable/equatable.dart';

enum AidType { financial, food, medical, seasonal, education, other }
enum AidStatus { pending, approved, distributed, rejected, cancelled }

class AidRecord extends Equatable {
  final String id;
  final String beneficiaryId;
  final String beneficiaryName;
  final bool isFamilyBeneficiary;
  final AidType aidType;
  final double amount;
  final DateTime date;
  final String employeeId;
  final String employeeName;
  final AidStatus status;
  final String? notes;
  final String referenceNumber;
  final String? area;

  const AidRecord({
    required this.id,
    required this.beneficiaryId,
    required this.beneficiaryName,
    this.isFamilyBeneficiary = false,
    required this.aidType,
    required this.amount,
    required this.date,
    required this.employeeId,
    required this.employeeName,
    required this.status,
    this.notes,
    required this.referenceNumber,
    this.area,
  });

  AidRecord copyWith({
    AidType? aidType,
    double? amount,
    AidStatus? status,
    String? notes,
    String? employeeId,
    String? employeeName,
  }) {
    return AidRecord(
      id: id,
      beneficiaryId: beneficiaryId,
      beneficiaryName: beneficiaryName,
      isFamilyBeneficiary: isFamilyBeneficiary,
      aidType: aidType ?? this.aidType,
      amount: amount ?? this.amount,
      date: date,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      referenceNumber: referenceNumber,
      area: area,
    );
  }

  @override
  List<Object?> get props => [id, beneficiaryId, aidType, status, date];
}
