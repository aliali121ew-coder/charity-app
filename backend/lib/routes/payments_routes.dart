import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';
import 'package:charity_backend/models/payment.dart';
import 'package:charity_backend/repositories/payments_store.dart';
import 'package:charity_backend/services/myfatoorah_service.dart';
import 'package:charity_backend/services/zaincash_service.dart';

class PaymentsRoutes {
  late final Router router;

  final PaymentsStore _repo;
  final MyFatoorahService _myfatoorah;
  final ZainCashService _zaincash;

  PaymentsRoutes({
    PaymentsStore? repo,
    required MyFatoorahService myfatoorah,
    required ZainCashService zaincash,
  })  : _repo = repo ?? (throw ArgumentError('PaymentsStore repo is required')),
        _myfatoorah = myfatoorah,
        _zaincash = zaincash {
    router = Router()
      ..post('/session', _createSession)
      ..get('/status/<id>', _status)
      ..post('/webhooks/myfatoorah', _myfatoorahWebhook)
      ..get('/redirect/myfatoorah', _myfatoorahRedirect)
      ..get('/redirect/zaincash', _zaincashRedirect);
  }

  // POST /api/payments/session
  // body: {amount, currency, method, donorName, donationId}
  Future<Response> _createSession(Request req) async {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final amount = (body['amount'] as num?)?.toDouble();
    final currency = body['currency']?.toString() ?? 'IQD';
    final methodRaw = body['method']?.toString();
    final donorName = body['donorName']?.toString() ?? 'متبرع';
    final donationId = body['donationId']?.toString() ?? '';

    if (amount == null || methodRaw == null || donationId.isEmpty) {
      return _json(
        {'error': 'amount, method, donationId are required'},
        statusCode: 400,
      );
    }

    final method = PaymentIntentMethod.values
        .cast<PaymentIntentMethod?>()
        .firstWhere((m) => m?.name == methodRaw, orElse: () => null);
    if (method == null) {
      return _json({'error': 'Invalid method'}, statusCode: 400);
    }

    final id = const Uuid().v4();
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(minutes: 15));

    // URLs that providers will redirect to (backend endpoints)
    final publicBase = _publicBaseUrl(req);
    final zainRedirect = publicBase.resolve('/api/payments/redirect/zaincash');
    final myfatoorahRedirect =
        publicBase.resolve('/api/payments/redirect/myfatoorah');

    if (method == PaymentIntentMethod.visa ||
        method == PaymentIntentMethod.mastercard) {
      // MyFatoorah Hosted Payment Page
      // CustomerIdentifier will carry our internal sessionId
      final redirectUrl = myfatoorahRedirect.replace(queryParameters: {
        'sessionId': id,
      });

      final created = await _myfatoorah.createHostedPayment(
        amount: amount,
        currency: currency,
        customerName: donorName,
        customerIdentifier: id,
        redirectionUrl: redirectUrl,
        paymentMethod: 'CARD',
      );

      final intent = PaymentIntent(
        id: id,
        provider: PaymentProvider.myfatoorah,
        method: method,
        amount: amount,
        currency: currency,
        donorName: donorName,
        donationId: donationId,
        status: PaymentIntentStatus.pending,
        createdAt: now,
        expiresAt: expiresAt,
        redirectUrl: created.paymentUrl,
        providerInvoiceId: created.invoiceId,
      );
      await _repo.upsert(intent);
      return _json(intent.toJson(), statusCode: 201);
    }

    // ZainCash / SuperKi (we treat both as ZainCash-style redirect in this demo)
    if (method == PaymentIntentMethod.zaincash ||
        method == PaymentIntentMethod.superki) {
      final redirectUrl = zainRedirect.replace(queryParameters: {
        'sessionId': id,
      });

      final init = await _zaincash.initPayment(
        amountIqd: amount.round(),
        orderId: id,
        redirectUrl: redirectUrl,
      );

      final intent = PaymentIntent(
        id: id,
        provider: PaymentProvider.zaincash,
        method: method,
        amount: amount,
        currency: currency,
        donorName: donorName,
        donationId: donationId,
        status: PaymentIntentStatus.pending,
        createdAt: now,
        expiresAt: expiresAt,
        redirectUrl: init.paymentUrl.toString(),
        providerTxnId: init.transactionId,
      );
      await _repo.upsert(intent);
      return _json(intent.toJson(), statusCode: 201);
    }

    return _json({'error': 'Unsupported method'}, statusCode: 400);
  }

  // GET /api/payments/status/:id
  Future<Response> _status(Request req, String id) async {
    final intent = await _repo.getById(id);
    if (intent == null) {
      return _json({'error': 'Not found'}, statusCode: 404);
    }

    // If MyFatoorah and we have a paymentId (from redirect/webhook), verify status
    if (intent.provider == PaymentProvider.myfatoorah &&
        intent.providerPaymentId != null &&
        intent.providerPaymentId!.isNotEmpty &&
        !intent.isTerminal) {
      try {
        final details =
            await _myfatoorah.getPaymentDetails(intent.providerPaymentId!);
        await _repo.update(id, (cur) {
          final nextStatus = details.isPaid
              ? PaymentIntentStatus.paid
              : PaymentIntentStatus.pending;
          return cur.copyWith(status: nextStatus);
        });
      } catch (_) {
        // best effort
      }
    }

    final updated = (await _repo.getById(id))!;
    return _json(updated.toJson());
  }

  // GET /api/payments/redirect/zaincash?sessionId=...&token=...
  Future<Response> _zaincashRedirect(Request req) async {
    final sessionId = req.url.queryParameters['sessionId'];
    final token = req.url.queryParameters['token'];
    if (sessionId == null || token == null) {
      return Response.badRequest(body: 'missing sessionId/token');
    }
    final intent = await _repo.getById(sessionId);
    if (intent == null) return Response.notFound('session not found');

    try {
      final res = _zaincash.verifyRedirectToken(token);
      await _repo.update(sessionId, (cur) {
        return cur.copyWith(
          status: res.isSuccess ? PaymentIntentStatus.paid : PaymentIntentStatus.failed,
          providerTxnId: res.transactionId.isNotEmpty ? res.transactionId : cur.providerTxnId,
          lastError: res.isSuccess ? null : (res.msg ?? 'ZainCash failed'),
        );
      });
    } catch (e) {
      await _repo.update(sessionId, (cur) => cur.copyWith(
            status: PaymentIntentStatus.failed,
            lastError: 'Invalid token',
          ));
    }

    // Redirect user back to app success/cancel landing (WebView will detect)
    final publicBase = _publicBaseUrl(req);
    final success = publicBase
        .resolve('/payment/success')
        .replace(queryParameters: {'sessionId': sessionId});
    final cancel = publicBase
        .resolve('/payment/cancel')
        .replace(queryParameters: {'sessionId': sessionId});

    final finalIntent = (await _repo.getById(sessionId))!;
    return Response.found(finalIntent.status == PaymentIntentStatus.paid
        ? success.toString()
        : cancel.toString());
  }

  // GET /api/payments/redirect/myfatoorah?sessionId=...&paymentId=...
  Future<Response> _myfatoorahRedirect(Request req) async {
    final sessionId = req.url.queryParameters['sessionId'];
    final paymentId = req.url.queryParameters['paymentId'];
    if (sessionId == null || paymentId == null) {
      return Response.badRequest(body: 'missing sessionId/paymentId');
    }
    final intent = await _repo.getById(sessionId);
    if (intent == null) return Response.notFound('session not found');

    // Store paymentId then verify immediately (best-effort) and redirect.
    await _repo.update(sessionId, (cur) => cur.copyWith(providerPaymentId: paymentId));
    try {
      final details = await _myfatoorah.getPaymentDetails(paymentId);
      await _repo.update(sessionId, (cur) => cur.copyWith(
            status: details.isPaid ? PaymentIntentStatus.paid : PaymentIntentStatus.pending,
            providerInvoiceId: details.invoiceId,
          ));
    } catch (_) {
      // ignore; webhook will update later
    }

    final publicBase = _publicBaseUrl(req);
    final success = publicBase
        .resolve('/payment/success')
        .replace(queryParameters: {'sessionId': sessionId});
    final cancel = publicBase
        .resolve('/payment/cancel')
        .replace(queryParameters: {'sessionId': sessionId});

    final finalIntent = (await _repo.getById(sessionId))!;
    return Response.found(finalIntent.status == PaymentIntentStatus.paid
        ? success.toString()
        : cancel.toString());
  }

  // POST /api/payments/webhooks/myfatoorah
  Future<Response> _myfatoorahWebhook(Request req) async {
    final signature = req.headers['myfatoorah-signature'] ??
        req.headers['MyFatoorah-Signature'];
    final raw = await req.readAsString();
    final payload = jsonDecode(raw) as Map<String, dynamic>;

    // Validate signature for PAYMENT_STATUS_CHANGED:
    // Invoice.Id=...,Invoice.Status=...,Transaction.Status=...,Transaction.PaymentId=...,Invoice.ExternalIdentifier=...
    // Docs: https://docs.myfatoorah.com/docs/webhook-v2-payment-status-data-model
    final event = (payload['Event'] as Map?)?.cast<String, dynamic>() ?? {};
    final data = (payload['Data'] as Map?)?.cast<String, dynamic>() ?? {};
    if (event['Name']?.toString() != 'PAYMENT_STATUS_CHANGED') {
      return _json({'ok': true}); // ignore other events
    }

    final invoice = (data['Invoice'] as Map?)?.cast<String, dynamic>() ?? {};
    final txn = (data['Transaction'] as Map?)?.cast<String, dynamic>() ?? {};

    final ordered = [
      'Invoice.Id=${invoice['Id'] ?? ''}',
      'Invoice.Status=${invoice['Status'] ?? ''}',
      'Transaction.Status=${txn['Status'] ?? ''}',
      'Transaction.PaymentId=${txn['PaymentId'] ?? ''}',
      'Invoice.ExternalIdentifier=${invoice['ExternalIdentifier'] ?? ''}',
    ].join(',');

    final expected = base64Encode(
      Hmac(sha256, utf8.encode(_myfatoorah.config.webhookSecret))
          .convert(utf8.encode(ordered))
          .bytes,
    );

    if (signature == null || signature.trim() != expected.trim()) {
      return Response.forbidden('invalid signature');
    }

    final sessionId = invoice['ExternalIdentifier']?.toString();
    final paymentId = txn['PaymentId']?.toString();
    if (sessionId == null || paymentId == null) return _json({'ok': true});

    final intent = await _repo.getById(sessionId);
    if (intent == null) return _json({'ok': true});

    final txnStatus = txn['Status']?.toString() ?? '';
    final invStatus = invoice['Status']?.toString() ?? '';
    final isPaid = invStatus == 'PAID' || txnStatus == 'SUCCESS';
    final isCancelled = txnStatus == 'CANCELED';
    final isFailed = txnStatus == 'FAILED';

    await _repo.update(sessionId, (cur) {
      final next = isPaid
          ? PaymentIntentStatus.paid
          : isCancelled
              ? PaymentIntentStatus.cancelled
              : isFailed
                  ? PaymentIntentStatus.failed
                  : PaymentIntentStatus.pending;
      return cur.copyWith(
        status: next,
        providerPaymentId: paymentId,
        providerInvoiceId: invoice['Id']?.toString(),
        lastError: isFailed ? (txn['Error']?['Message']?.toString() ?? 'Failed') : null,
      );
    });

    return _json({'ok': true});
  }

  // Public base URL: set PUBLIC_BASE_URL env in production (required for webhooks/redirects)
  Uri _publicBaseUrl(Request req) {
    final env = Platform.environment['PUBLIC_BASE_URL'];
    if (env != null && env.isNotEmpty) return Uri.parse(env);
    final fromEnv = req.headers['x-forwarded-host'];
    final proto = req.headers['x-forwarded-proto'] ?? 'http';
    if (fromEnv != null && fromEnv.isNotEmpty) {
      return Uri.parse('$proto://$fromEnv');
    }
    return Uri.parse('${req.requestedUri.scheme}://${req.requestedUri.authority}');
  }

  Response _json(dynamic data, {int statusCode = 200}) => Response(
        statusCode,
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      );
}

