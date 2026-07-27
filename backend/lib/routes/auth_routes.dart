import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// Legacy auth routes.
///
/// Authentication has moved to Supabase Auth. These endpoints no longer issue
/// or revoke tokens — they respond `410 Gone` so any stale clients fail loudly
/// instead of silently receiving a token from a removed, insecure code path.
class AuthRoutes {
  late final Router router;

  AuthRoutes() {
    router = Router()
      ..post('/login', _gone)
      ..post('/logout', _gone);
  }

  Response _gone(Request req) => Response(
        410,
        body: jsonEncode({'error': 'auth_moved_to_supabase'}),
        headers: {'Content-Type': 'application/json'},
      );
}
