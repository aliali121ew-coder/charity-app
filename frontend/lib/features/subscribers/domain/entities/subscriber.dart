import 'package:equatable/equatable.dart';

enum SubscriberStatus { active, inactive, pending, suspended }

class Subscriber extends Equatable {
  final String id;
  final String fullName;
  final String phone;
  final String address;
  final String area;
  final DateTime registrationDate;
  final SubscriberStatus status;
  final String? notes;
  final String? avatarUrl;
  final String idNumber;
  final String? email;
  final int? aidCount;
  final double? totalAidAmount;

  const Subscriber({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.address,
    required this.area,
    required this.registrationDate,
    required this.status,
    this.notes,
    this.avatarUrl,
    required this.idNumber,
    this.email,
    this.aidCount,
    this.totalAidAmount,
  });

  Subscriber copyWith({
    String? fullName,
    String? phone,
    String? address,
    String? area,
    SubscriberStatus? status,
    String? notes,
    String? email,
  }) {
    return Subscriber(
      id: id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      area: area ?? this.area,
      registrationDate: registrationDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      avatarUrl: avatarUrl,
      idNumber: idNumber,
      email: email ?? this.email,
      aidCount: aidCount,
      totalAidAmount: totalAidAmount,
    );
  }

  @override
  List<Object?> get props => [id, fullName, phone, status];
}
