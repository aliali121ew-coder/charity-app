import 'dart:convert';

enum SubscriberStatus { active, inactive, pending, suspended }

class Subscriber {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String area;
  final DateTime registrationDate;
  final SubscriberStatus status;
  final String? nationalId;
  final String? email;
  final String? notes;
  final int aidCount;

  const Subscriber({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.area,
    required this.registrationDate,
    required this.status,
    this.nationalId,
    this.email,
    this.notes,
    this.aidCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'area': area,
        'registrationDate': registrationDate.toIso8601String(),
        'status': status.name,
        'nationalId': nationalId,
        'email': email,
        'notes': notes,
        'aidCount': aidCount,
      };

  factory Subscriber.fromJson(Map<String, dynamic> json) => Subscriber(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        address: json['address'] as String,
        area: json['area'] as String,
        registrationDate: DateTime.parse(json['registrationDate'] as String),
        status: SubscriberStatus.values.byName(json['status'] as String),
        nationalId: json['nationalId'] as String?,
        email: json['email'] as String?,
        notes: json['notes'] as String?,
        aidCount: json['aidCount'] as int? ?? 0,
      );

  String toJsonString() => jsonEncode(toJson());
}
