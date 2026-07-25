import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:charity_backend/services/auth_service.dart';

class AuthRoutes {
  final _authService = AuthService();
  late final Router router;

  AuthRoutes() {
    router = Router()
      ..post('/login', _login)
      ..post('/logout', _logout);
  }

  Future<Response> _login(Request req) async {
    try {
      final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
      final email = body['email'] as String?;
      final password = body['password'] as String?;

      if (email == null || password == null) {
        return _json({'error': 'email and password are required'}, statusCode: 400);
      }

      final result = await _authService.login(email, password);
      if (result == null) {
        return _json({'error': 'Invalid credentials'}, statusCode: 401);
      }

      return _json(result);
    } catch (e) {
      return _json({'error': 'Invalid request body'}, statusCode: 400);
    }
  }

  Future<Response> _logout(Request req) async {
    final token = req.headers['Authorization']?.substring(7);
    if (token != null) _authService.logout(token);
    return _json({'message': 'Logged out successfully'});
  }

  Response _json(dynamic data, {int statusCode = 200}) => Response(
        statusCode,
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      );
}
