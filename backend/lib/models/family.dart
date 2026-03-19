enum FamilyStatus { eligible, ineligible, pending, suspended }
enum IncomeLevel { veryLow, low, medium, aboveAverage }
enum MaritalStatus { married, widowed, divorced, single }

class Family {
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

  const Family({
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'headName': headName,
        'membersCount': membersCount,
        'maritalStatus': maritalStatus.name,
        'incomeLevel': incomeLevel.name,
        'address': address,
        'area': area,
        'status': status.name,
        'notes': notes,
        'aidCount': aidCount,
        'totalAidAmount': totalAidAmount,
        'registrationDate': registrationDate.toIso8601String(),
        'phone': phone,
      };

  factory Family.fromJson(Map<String, dynamic> json) => Family(
        id: json['id'] as String,
        headName: json['headName'] as String,
        membersCount: json['membersCount'] as int,
        maritalStatus: MaritalStatus.values.byName(json['maritalStatus'] as String),
        incomeLevel: IncomeLevel.values.byName(json['incomeLevel'] as String),
        address: json['address'] as String,
        area: json['area'] as String,
        status: FamilyStatus.values.byName(json['status'] as String),
        notes: json['notes'] as String?,
        aidCount: json['aidCount'] as int? ?? 0,
        totalAidAmount: (json['totalAidAmount'] as num?)?.toDouble() ?? 0,
        registrationDate: DateTime.parse(json['registrationDate'] as String),
        phone: json['phone'] as String?,
      );
}
