import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class LogsRoutes {
  late final Router router;

  LogsRoutes() {
    router = Router()
      ..get('/', _getAll)
      ..get('/summary', _getSummary);
  }

  Future<Response> _getAll(Request req) async =>
      _json({'data': [], 'total': 0, 'message': 'Connect to LogsRepository'});

  Future<Response> _getSummary(Request req) async =>
      _json({'total': 0, 'today': 0, 'byType': {}});

  Response _json(dynamic data, {int statusCode = 200}) => Response(
        statusCode,
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      );
}
