import 'dart:convert';
import 'package:http/http.dart' as http;

class MyFatoorahConfig {
  final String apiKey;
  final Uri baseUrl;
  final String webhookSecret;

  const MyFatoorahConfig({
    required this.apiKey,
    required this.baseUrl,
    required this.webhookSecret,
  });
}

class MyFatoorahCreatePaymentResult {
  final String invoiceId;
  final String paymentUrl;

  const MyFatoorahCreatePaymentResult({
    required this.invoiceId,
    required this.paymentUrl,
  });
}

class MyFatoorahPaymentDetails {
  final String invoiceId;
  final String invoiceStatus; // PAID/PENDING
  final String transactionStatus; // SUCCESS/FAILED/AUTHORIZE/CANCELED
  final String paymentId;

  const MyFatoorahPaymentDetails({
    required this.invoiceId,
    required this.invoiceStatus,
    required this.transactionStatus,
    required this.paymentId,
  });

  bool get isPaid => invoiceStatus == 'PAID' || transactionStatus == 'SUCCESS';
}

class MyFatoorahService {
  final MyFatoorahConfig config;
  const MyFatoorahService(this.config);

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${config.apiKey}',
        'Content-Type': 'application/json',
      };

  /// Create Hosted Payment Page via POST /v3/payments
  /// Docs: https://docs.myfatoorah.com/docs/v3-hosted-payment-page
  Future<MyFatoorahCreatePaymentResult> createHostedPayment({
    required double amount,
    required String currency,
    required String customerName,
    required String customerIdentifier,
    required Uri redirectionUrl,
    String paymentMethod = 'CARD',
  }) async {
    final url = config.baseUrl.resolve('/v3/payments');
    final body = {
      'PaymentMethod': paymentMethod,
      'CustomerIdentifier': customerIdentifier,
      'CustomerName': customerName,
      'Order': {'Amount': amount, 'Currency': currency},
      'IntegrationUrls': {'Redirection': redirectionUrl.toString()},
    };

    final resp = await http.post(url, headers: _headers, body: jsonEncode(body));
    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode < 200 ||
        resp.statusCode >= 300 ||
        decoded['IsSuccess'] != true) {
      throw Exception('MyFatoorah create payment failed: ${resp.body}');
    }

    final data = decoded['Data'] as Map<String, dynamic>;
    return MyFatoorahCreatePaymentResult(
      invoiceId: data['InvoiceId']?.toString() ?? '',
      paymentUrl: data['PaymentURL']?.toString() ?? '',
    );
  }

  /// Verify payment status via GET /v3/payments/{paymentId}
  /// Docs: https://docs.myfatoorah.com/docs/v3-hosted-payment-page
  Future<MyFatoorahPaymentDetails> getPaymentDetails(String paymentId) async {
    final url = config.baseUrl.resolve('/v3/payments/$paymentId');
    final resp = await http.get(url, headers: _headers);
    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode < 200 ||
        resp.statusCode >= 300 ||
        decoded['IsSuccess'] != true) {
      throw Exception('MyFatoorah get payment details failed: ${resp.body}');
    }

    final data = decoded['Data'] as Map<String, dynamic>;
    final invoice = data['Invoice'] as Map<String, dynamic>;
    final txn = data['Transaction'] as Map<String, dynamic>;
    return MyFatoorahPaymentDetails(
      invoiceId: invoice['Id']?.toString() ?? '',
      invoiceStatus: invoice['Status']?.toString() ?? '',
      transactionStatus: txn['Status']?.toString() ?? '',
      paymentId: txn['PaymentId']?.toString() ?? paymentId,
    );
  }
}

