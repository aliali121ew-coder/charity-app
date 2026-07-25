import 'dart:convert';

enum PaymentProvider { myfatoorah, zaincash }

enum PaymentIntentStatus { created, pending, paid, failed, cancelled, expired }

enum PaymentIntentMethod { visa, mastercard, zaincash, superki }

class PaymentIntent {
  final String id; // internal session id
  final PaymentProvider provider;
  final PaymentIntentMethod method;
  final double amount;
  final String currency; // ISO, e.g. IQD
  final String donorName;
  final String donationId;
  final PaymentIntentStatus status;
  final String? redirectUrl; // hosted payment page
  final String? providerPaymentId; // e.g. MyFatoorah paymentId
  final String? providerInvoiceId; // e.g. MyFatoorah invoiceId
  final String? providerTxnId; // e.g. ZainCash transaction id
  final String? lastError;
  final DateTime createdAt;
  final DateTime expiresAt;

  const PaymentIntent({
    required this.id,
    required this.provider,
    required this.method,
    required this.amount,
    required this.currency,
    required this.donorName,
    required this.donationId,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.redirectUrl,
    this.providerPaymentId,
    this.providerInvoiceId,
    this.providerTxnId,
    this.lastError,
  });

  bool get isTerminal =>
      status == PaymentIntentStatus.paid ||
      status == PaymentIntentStatus.failed ||
      status == PaymentIntentStatus.cancelled ||
      status == PaymentIntentStatus.expired;

  PaymentIntent copyWith({
    PaymentIntentStatus? status,
    String? redirectUrl,
    String? providerPaymentId,
    String? providerInvoiceId,
    String? providerTxnId,
    String? lastError,
    DateTime? expiresAt,
  }) {
    return PaymentIntent(
      id: id,
      provider: provider,
      method: method,
      amount: amount,
      currency: currency,
      donorName: donorName,
      donationId: donationId,
      status: status ?? this.status,
      createdAt: createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      redirectUrl: redirectUrl ?? this.redirectUrl,
      providerPaymentId: providerPaymentId ?? this.providerPaymentId,
      providerInvoiceId: providerInvoiceId ?? this.providerInvoiceId,
      providerTxnId: providerTxnId ?? this.providerTxnId,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'provider': provider.name,
        'method': method.name,
        'amount': amount,
        'currency': currency,
        'donorName': donorName,
        'donationId': donationId,
        'status': status.name,
        'redirectUrl': redirectUrl,
        'providerPaymentId': providerPaymentId,
        'providerInvoiceId': providerInvoiceId,
        'providerTxnId': providerTxnId,
        'lastError': lastError,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      };

  @override
  String toString() => jsonEncode(toJson());
}

