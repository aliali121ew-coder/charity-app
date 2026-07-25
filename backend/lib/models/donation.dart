enum DonationPaymentMethod { zainCash, visaCard, masterCard, bankTransfer, cash }
enum DonationStatus { completed, processing, rejected }

class Donation {
  final String id;
  final String donor;
  final double amount;
  final String currency;
  final DonationPaymentMethod method;
  final DonationStatus status;
  final String reference;
  final DateTime date;
  final String? notes;

  const Donation({
    required this.id,
    required this.donor,
    required this.amount,
    this.currency = 'IQD',
    required this.method,
    required this.status,
    required this.reference,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'donor': donor,
        'amount': amount,
        'currency': currency,
        'method': method.name,
        'status': status.name,
        'reference': reference,
        'date': date.toIso8601String(),
        'notes': notes,
      };

  factory Donation.fromJson(Map<String, dynamic> json) => Donation(
        id: json['id'] as String,
        donor: json['donor'] as String,
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'IQD',
        method: DonationPaymentMethod.values.byName(json['method'] as String),
        status: DonationStatus.values.byName(json['status'] as String),
        reference: json['reference'] as String,
        date: DateTime.parse(json['date'] as String),
        notes: json['notes'] as String?,
      );

  Donation copyWith({DonationStatus? status, String? notes}) => Donation(
        id: id,
        donor: donor,
        amount: amount,
        currency: currency,
        method: method,
        status: status ?? this.status,
        reference: reference,
        date: date,
        notes: notes ?? this.notes,
      );
}
