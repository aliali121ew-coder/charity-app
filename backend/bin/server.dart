// ─────────────────────────────────────────────────────────────────────────────
// Charity Backend API (Dart + Shelf)
//
// This backend is now used ONLY for payment gateway endpoints
// (MyFatoorah / ZainCash). Authentication is delegated to Supabase Auth:
// the Flutter app authenticates directly with Supabase and sends the Supabase
// access token (a JWT signed HS256 with the project's JWT secret) as a
// `Authorization: Bearer <token>` header. This server validates that JWT.
//
// REQUIRED ENVIRONMENT VARIABLE
//   SUPABASE_JWT_SECRET
//     The project's JWT secret, found in the Supabase dashboard under
//     Settings → API → JWT Secret. Used to verify (HS256) the access tokens
//     sent by the Flutter app. If this is unset the server responds 500 to
//     every guarded request (misconfiguration), so it must be set on the
//     Railway deployment before going live.
//
// Optional:
//   PORT              Port to listen on (default 8080).
//   PUBLIC_BASE_URL   Public base URL used to build webhook/redirect URLs.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:charity_backend/routes/auth_routes.dart';
import 'package:charity_backend/routes/subscribers_routes.dart';
import 'package:charity_backend/routes/families_routes.dart';
import 'package:charity_backend/routes/aid_routes.dart';
import 'package:charity_backend/routes/logs_routes.dart';
import 'package:charity_backend/routes/reports_routes.dart';

void main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  // ── Root router ──────────────────────────────────────────────────────────
  final router = Router();

  // Mount sub-routers
  router.mount('/api/auth/', AuthRoutes().router);
  router.mount('/api/subscribers/', SubscribersRoutes().router);
  router.mount('/api/families/', FamiliesRoutes().router);
  router.mount('/api/aid/', AidRoutes().router);
  router.mount('/api/logs/', LogsRoutes().router);
  router.mount('/api/reports/', ReportsRoutes().router);

  // Health check
  router.get('/health', (Request req) => Response.ok('{"status":"ok"}',
      headers: {'Content-Type': 'application/json'}));

  // ── Middleware pipeline ──────────────────────────────────────────────────
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addMiddleware(_rateLimitMiddleware())
      .addMiddleware(_authMiddleware)
      .addHandler(router.call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('✅ Charity Backend API running on http://localhost:${server.port}');
  print('   Routes:');
  print('     GET  /health');
  print('     POST /api/payments/session');
  print('     GET  /api/payments/status/<id>');
}

// ── Auth Middleware (Supabase JWT guard) ─────────────────────────────────────
//
// Verifies the Supabase access token (HS256, signed with SUPABASE_JWT_SECRET).
// On success the `sub` claim (Supabase user id) is placed in
// request.context['userId'].
//
// Unauthenticated paths:
//   * /health
//   * Payment provider webhook/callback endpoints (gateways call these
//     server-to-server and cannot present a user JWT):
//       - POST /api/payments/webhooks/...     (MyFatoorah webhook)
//       - GET  /api/payments/redirect/...     (MyFatoorah / ZainCash redirects)
Middleware get _authMiddleware {
  return (Handler innerHandler) {
    return (Request request) async {
      final path = request.url.path;

      // Public, unauthenticated endpoints.
      if (_isPublicPath(path)) {
        return innerHandler(request);
      }

      final jwtSecret = Platform.environment['SUPABASE_JWT_SECRET'];
      if (jwtSecret == null || jwtSecret.isEmpty) {
        stderr.writeln(
          'CONFIG ERROR: SUPABASE_JWT_SECRET is not set. Cannot verify '
          'Supabase access tokens. Set it in the Railway environment '
          '(Supabase → Settings → API → JWT Secret) and redeploy.',
        );
        return Response.internalServerError(
          body: '{"error":"server_misconfigured"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      final authHeader = request.headers['Authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response.unauthorized(
          '{"error":"missing_token"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      final token = authHeader.substring(7).trim();
      final JWT jwt;
      try {
        jwt = JWT.verify(token, SecretKey(jwtSecret));
      } on JWTExpiredException {
        return Response.unauthorized(
          '{"error":"token_expired"}',
          headers: {'Content-Type': 'application/json'},
        );
      } on JWTException {
        return Response.unauthorized(
          '{"error":"invalid_token"}',
          headers: {'Content-Type': 'application/json'},
        );
      } catch (_) {
        return Response.unauthorized(
          '{"error":"invalid_token"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Extract the Supabase user id from the `sub` claim.
      final payload = jwt.payload;
      final userId =
          (payload is Map) ? payload['sub']?.toString() : null;

      return innerHandler(
        request.change(context: {'userId': userId}),
      );
    };
  };
}

/// Paths that bypass authentication.
///
/// `request.url.path` has no leading slash (e.g. `api/payments/session`).
bool _isPublicPath(String path) {
  if (path == 'health') return true;

  // Payment gateway server-to-server callbacks: webhooks and redirect returns.
  if (path.startsWith('api/payments/webhooks/')) return true;
  if (path.startsWith('api/payments/redirect/')) return true;

  return false;
}

// ── Rate-limit Middleware (in-memory per-IP token bucket) ────────────────────
//
// Dependency-free sliding-window limiter: at most [maxRequests] requests per
// [window] per client IP. Client IP is taken from the first hop of
// `x-forwarded-for` (Railway sits behind a proxy) and falls back to the
// connection's remote address.
Middleware _rateLimitMiddleware({
  int maxRequests = 30,
  Duration window = const Duration(seconds: 60),
}) {
  final hits = <String, List<DateTime>>{};

  return (Handler innerHandler) {
    return (Request request) async {
      final now = DateTime.now();
      final cutoff = now.subtract(window);
      final clientIp = _clientIp(request);

      final timestamps = hits.putIfAbsent(clientIp, () => <DateTime>[]);
      // Prune entries older than the window.
      timestamps.removeWhere((t) => t.isBefore(cutoff));

      if (timestamps.length >= maxRequests) {
        return Response(
          429,
          body: '{"error":"rate_limited"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      timestamps.add(now);

      // Opportunistically drop empty buckets to bound memory growth.
      if (hits.length > 10000) {
        hits.removeWhere((_, v) => v.isEmpty);
      }

      return innerHandler(request);
    };
  };
}

/// Resolve the client IP: first hop of `x-forwarded-for`, else the connection's
/// remote address, else a stable fallback key.
String _clientIp(Request request) {
  final forwarded = request.headers['x-forwarded-for'];
  if (forwarded != null && forwarded.trim().isNotEmpty) {
    return forwarded.split(',').first.trim();
  }
  final connInfo =
      request.context['shelf.io.connection_info'] as HttpConnectionInfo?;
  final remote = connInfo?.remoteAddress.address;
  if (remote != null && remote.isNotEmpty) return remote;
  return 'unknown';
}
