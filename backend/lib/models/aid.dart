enum AidType { financial, food, medical, seasonal, education, other }
enum AidStatus { pending, approved, rejected, distributed }

class Aid {
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

  const Aid({
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'referenceNumber': referenceNumber,
        'beneficiaryName': beneficiaryName,
        'familyId': familyId,
        'subscriberId': subscriberId,
        'type': type.name,
        'amount': amount,
        'currency': currency,
        'date': date.toIso8601String(),
        'responsibleEmployee': responsibleEmployee,
        'status': status.name,
        'notes': notes,
        'deliveryDate': deliveryDate?.toIso8601String(),
      };

  factory Aid.fromJson(Map<String, dynamic> json) => Aid(
        id: json['id'] as String,
        referenceNumber: json['referenceNumber'] as String,
        beneficiaryName: json['beneficiaryName'] as String,
        familyId: json['familyId'] as String?,
        subscriberId: json['subscriberId'] as String?,
        type: AidType.values.byName(json['type'] as String),
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'IQD',
        date: DateTime.parse(json['date'] as String),
        responsibleEmployee: json['responsibleEmployee'] as String,
        status: AidStatus.values.byName(json['status'] as String),
        notes: json['notes'] as String?,
        deliveryDate: json['deliveryDate'] != null
            ? DateTime.parse(json['deliveryDate'] as String)
            : null,
      );
}
