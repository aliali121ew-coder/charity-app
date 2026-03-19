import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:charity_backend/routes/auth_routes.dart';
import 'package:charity_backend/routes/subscribers_routes.dart';
import 'package:charity_backend/routes/families_routes.dart';
import 'package:charity_backend/routes/aid_routes.dart';
import 'package:charity_backend/routes/logs_routes.dart';
import 'package:charity_backend/routes/reports_routes.dart';
import 'package:charity_backend/routes/donation_routes.dart';
import 'package:charity_backend/routes/payments_routes.dart';
import 'package:charity_backend/repositories/donations_repository_memory.dart';
import 'package:charity_backend/repositories/donations_repository_pg.dart';
import 'package:charity_backend/repositories/donations_store.dart';
import 'package:charity_backend/repositories/payments_repository_memory.dart';
import 'package:charity_backend/repositories/payments_repository_pg.dart';
import 'package:charity_backend/repositories/payments_store.dart';
import 'package:charity_backend/services/auth_service.dart';
import 'package:charity_backend/services/db.dart';
import 'package:charity_backend/services/myfatoorah_service.dart';
import 'package:charity_backend/services/zaincash_service.dart';

final _authService = AuthService();

// ── CORS: allowed origins (add your frontend URL in production) ───────────────
const _allowedOrigins = ['http://localhost:3000', 'http://localhost:8080'];

void main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  // ── Database (optional) ───────────────────────────────────────────────────
  final db = await Db.connectFromEnv();
  PaymentsStore paymentsStore;
  DonationsStore donationsStore;
  if (db != null) {
    await db.ensureSchema();
    paymentsStore = PaymentsRepositoryPg(db);
    donationsStore = DonationsRepositoryPg(db);
    print('✅ Payments DB connected');
  } else {
    paymentsStore = PaymentsRepositoryMemory();
    donationsStore = DonationsRepositoryMemory();
    print('⚠️  Payments DB not configured; using in-memory store');
  }

  // ── Payment provider configs (env) ────────────────────────────────────────
  final myFatoorahApiKey = Platform.environment['MYFATOORAH_API_KEY'] ?? '';
  final myFatoorahBaseUrl = Uri.parse(
    Platform.environment['MYFATOORAH_BASE_URL'] ??
        'https://apitest.myfatoorah.com',
  );
  final myFatoorahWebhookSecret =
      Platform.environment['MYFATOORAH_WEBHOOK_SECRET'] ?? '';

  final zaincashProduction =
      (Platform.environment['ZAINCASH_PRODUCTION'] ?? 'false') == 'true';
  final zaincashMsisdn = Platform.environment['ZAINCASH_MSISDN'] ?? '';
  final zaincashMerchantId = Platform.environment['ZAINCASH_MERCHANT_ID'] ?? '';
  final zaincashSecret = Platform.environment['ZAINCASH_SECRET'] ?? '';
  final zaincashServiceType =
      Platform.environment['ZAINCASH_SERVICE_TYPE'] ?? 'Charity App';
  final zaincashLang = Platform.environment['ZAINCASH_LANG'] ?? 'ar';

  final myfatoorah = MyFatoorahService(MyFatoorahConfig(
    apiKey: myFatoorahApiKey,
    baseUrl: myFatoorahBaseUrl,
    webhookSecret: myFatoorahWebhookSecret,
  ));
  final zaincash = ZainCashService(ZainCashConfig(
    production: zaincashProduction,
    msisdn: zaincashMsisdn,
    merchantId: zaincashMerchantId,
    secret: zaincashSecret,
    serviceType: zaincashServiceType,
    lang: zaincashLang,
  ));

  // ── Root router ──────────────────────────────────────────────────────────
  final router = Router();

  // Mount sub-routers
  router.mount('/api/auth/', AuthRoutes().router);
  router.mount('/api/subscribers/', SubscribersRoutes().router);
  router.mount('/api/families/', FamiliesRoutes().router);
  router.mount('/api/aid/', AidRoutes().router);
  router.mount('/api/logs/', LogsRoutes().router);
  router.mount('/api/reports/', ReportsRoutes().router);
  router.mount('/api/donations/', DonationRoutes(repo: donationsStore).router);
  router.mount(
    '/api/payments/',
    PaymentsRoutes(
      repo: paymentsStore,
      myfatoorah: myfatoorah,
      zaincash: zaincash,
    ).router,
  );

  // Health check
  router.get('/health', (Request req) => Response.ok('{"status":"ok"}',
      headers: {'Content-Type': 'application/json'}));

  // Payment landing pages (used for WebView success/cancel detection)
  router.get('/payment/success', (Request req) {
    final sessionId = req.url.queryParameters['sessionId'] ?? '';
    return Response.ok(
      '''
<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Payment Success</title></head>
<body style="font-family:system-ui,Segoe UI,Roboto,Arial,sans-serif;padding:20px">
<h2>تم الدفع بنجاح</h2>
<p>يمكنك إغلاق هذه الصفحة والعودة للتطبيق.</p>
<small>sessionId: ${_escapeHtml(sessionId)}</small>
</body></html>
''',
      headers: {'Content-Type': 'text/html; charset=utf-8'},
    );
  });

  router.get('/payment/cancel', (Request req) {
    final sessionId = req.url.queryParameters['sessionId'] ?? '';
    return Response.ok(
      '''
<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Payment Cancelled</title></head>
<body style="font-family:system-ui,Segoe UI,Roboto,Arial,sans-serif;padding:20px">
<h2>لم يكتمل الدفع</h2>
<p>يمكنك إغلاق هذه الصفحة والعودة للتطبيق.</p>
<small>sessionId: ${_escapeHtml(sessionId)}</small>
</body></html>
''',
      headers: {'Content-Type': 'text/html; charset=utf-8'},
    );
  });

  // ── Middleware pipeline ──────────────────────────────────────────────────
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders(headers: {
        'Access-Control-Allow-Origin': _allowedOrigins.join(','),
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Authorization, Content-Type',
      }))
      .addMiddleware(_authMiddleware)
      .addHandler(router.call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('✅ Charity Backend API running on http://localhost:${server.port}');
  print('   Routes:');
  print('     POST /api/auth/login');
  print('     GET  /api/subscribers');
  print('     GET  /api/families');
  print('     GET  /api/aid');
  print('     GET  /api/logs');
  print('     GET  /api/reports/summary');
  print('     GET  /api/donations');
  print('     GET  /api/donations/summary');
  print('     POST /api/donations');
}

// ── Auth Middleware (Token guard) ────────────────────────────────────────────
Middleware get _authMiddleware {
  return (Handler innerHandler) {
    return (Request request) async {
      // Skip auth for login and health endpoints
      if (request.url.path.startsWith('api/auth/') ||
          request.url.path.startsWith('api/payments/webhooks/') ||
          request.url.path.startsWith('api/payments/redirect/') ||
          request.url.path == 'health' ||
          request.method == 'OPTIONS') {
        return innerHandler(request);
      }

      final authHeader = request.headers['Authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response.unauthorized(
          '{"error":"Unauthorized","message":"Missing or invalid token"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      final token = authHeader.substring(7);
      final userId = _authService.validateToken(token);
      if (userId == null) {
        return Response.unauthorized(
          '{"error":"Unauthorized","message":"Invalid or expired token"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      return innerHandler(request);
    };
  };
}

String _escapeHtml(String v) {
  return v
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}
