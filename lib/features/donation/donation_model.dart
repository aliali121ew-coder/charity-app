class Donation {
  final int id;
  final String type;
  final double amount;
  final DateTime date;
  final String description;

  Donation({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.description,
  });

  factory Donation.fromJson(Map<String, dynamic> json) => Donation(
        id: json['id'],
        type: json['type'],
        amount: json['amount'],
        date: DateTime.parse(json['date']),
        description: json['description'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'amount': amount,
        'date': date.toIso8601String(),
        'description': description,
      };
}