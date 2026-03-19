enum SubscriberStatus { active, inactive, pending, suspended }

class SubscriberModel {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String area;
  final DateTime registrationDate;
  final SubscriberStatus status;
  final String? avatarUrl;
  final String? notes;
  final String? nationalId;
  final String? email;
  final int aidCount;

  const SubscriberModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.area,
    required this.registrationDate,
    required this.status,
    this.avatarUrl,
    this.notes,
    this.nationalId,
    this.email,
    this.aidCount = 0,
  });

  SubscriberModel copyWith({
    String? name,
    String? phone,
    String? address,
    String? area,
    DateTime? registrationDate,
    SubscriberStatus? status,
    String? avatarUrl,
    String? notes,
    String? nationalId,
    String? email,
    int? aidCount,
  }) {
    return SubscriberModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      area: area ?? this.area,
      registrationDate: registrationDate ?? this.registrationDate,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      notes: notes ?? this.notes,
      nationalId: nationalId ?? this.nationalId,
      email: email ?? this.email,
      aidCount: aidCount ?? this.aidCount,
    );
  }
}

extension SubscriberStatusExt on SubscriberStatus {
  String get labelAr {
    switch (this) {
      case SubscriberStatus.active: return 'نشط';
      case SubscriberStatus.inactive: return 'غير نشط';
      case SubscriberStatus.pending: return 'قيد الانتظار';
      case SubscriberStatus.suspended: return 'موقوف';
    }
  }

  String get labelEn {
    switch (this) {
      case SubscriberStatus.active: return 'Active';
      case SubscriberStatus.inactive: return 'Inactive';
      case SubscriberStatus.pending: return 'Pending';
      case SubscriberStatus.suspended: return 'Suspended';
    }
  }
}
