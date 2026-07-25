import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class FamiliesRoutes {
  late final Router router;

  FamiliesRoutes() {
    router = Router()
      ..get('/', _getAll)
      ..get('/<id>', _getById)
      ..post('/', _create)
      ..put('/<id>', _update)
      ..delete('/<id>', _delete);
  }

  // TODO: Inject FamiliesRepository and implement handlers (mirrors SubscribersRoutes pattern)
  Future<Response> _getAll(Request req) async =>
      _json({'data': [], 'total': 0, 'message': 'Connect to FamiliesRepository'});

  Future<Response> _getById(Request req, String id) async =>
      _json({'error': 'Not implemented'}, statusCode: 501);

  Future<Response> _create(Request req) async =>
      _json({'error': 'Not implemented'}, statusCode: 501);

  Future<Response> _update(Request req, String id) async =>
      _json({'error': 'Not implemented'}, statusCode: 501);

  Future<Response> _delete(Request req, String id) async =>
      _json({'error': 'Not implemented'}, statusCode: 501);

  Response _json(dynamic data, {int statusCode = 200}) => Response(
        statusCode,
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      );
}
