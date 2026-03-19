import 'dart:convert';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;

class ZainCashConfig {
  final bool production;
  final String msisdn;
  final String merchantId;
  final String secret;
  final String serviceType;
  final String lang; // ar/en/ku

  const ZainCashConfig({
    required this.production,
    required this.msisdn,
    required this.merchantId,
    required this.secret,
    required this.serviceType,
    required this.lang,
  });

  Uri get initUrl => Uri.parse(production
      ? 'https://api.zaincash.iq/transaction/init'
      : 'https://test.zaincash.iq/transaction/init');

  Uri payUrl(String transactionId) => Uri.parse(production
      ? 'https://api.zaincash.iq/transaction/pay?id=$transactionId'
      : 'https://test.zaincash.iq/transaction/pay?id=$transactionId');
}

class ZainCashInitResult {
  final String transactionId;
  final Uri paymentUrl;

  const ZainCashInitResult({
    required this.transactionId,
    required this.paymentUrl,
  });
}

class ZainCashRedirectResult {
  final String status; // success/failed
  final String orderId;
  final String transactionId;
  final String? msg;

  const ZainCashRedirectResult({
    required this.status,
    required this.orderId,
    required this.transactionId,
    this.msg,
  });

  bool get isSuccess => status == 'success';
}

class ZainCashService {
  final ZainCashConfig config;
  const ZainCashService(this.config);

  Future<ZainCashInitResult> initPayment({
    required int amountIqd,
    required String orderId,
    required Uri redirectUrl,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final jwt = JWT({
      'amount': amountIqd,
      'serviceType': config.serviceType,
      'msisdn': config.msisdn,
      'orderId': orderId,
      'redirectUrl': redirectUrl.toString(),
      'iat': now,
      'exp': now + 60 * 60 * 4,
    });

    final token = jwt.sign(SecretKey(config.secret));
    final postData = {
      'token': token,
      'merchantId': config.merchantId,
      'lang': config.lang,
    };

    final resp = await http.post(
      config.initUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(postData),
    );

    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    final id = decoded['id']?.toString();
    if (resp.statusCode < 200 || resp.statusCode >= 300 || id == null) {
      throw Exception('ZainCash init failed: ${resp.body}');
    }
    return ZainCashInitResult(transactionId: id, paymentUrl: config.payUrl(id));
  }

  ZainCashRedirectResult verifyRedirectToken(String token) {
    final decoded = JWT.verify(token, SecretKey(config.secret));
    final p = decoded.payload as Map<String, dynamic>;
    return ZainCashRedirectResult(
      status: p['status']?.toString() ?? 'failed',
      orderId: p['orderId']?.toString() ?? '',
      transactionId: p['id']?.toString() ?? '',
      msg: p['msg']?.toString(),
    );
  }
}

