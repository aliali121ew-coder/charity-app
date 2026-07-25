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
}

// ── Auth Middleware (JWT guard) ───────────────────────────────────────────────
Middleware get _authMiddleware {
  return (Handler innerHandler) {
    return (Request request) async {
      // Skip auth for login endpoint
      if (request.url.path.startsWith('api/auth/') ||
          request.url.path == 'health') {
        return innerHandler(request);
      }

      final authHeader = request.headers['Authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response.unauthorized(
          '{"error":"Unauthorized","message":"Missing or invalid token"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      // TODO: Validate JWT token here
      // final token = authHeader.substring(7);
      // final payload = JwtService.verify(token);

      return innerHandler(request);
    };
  };
}
