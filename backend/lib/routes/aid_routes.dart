import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class AidRoutes {
  late final Router router;

  AidRoutes() {
    router = Router()
      ..get('/', _getAll)
      ..get('/<id>', _getById)
      ..post('/', _create)
      ..put('/<id>', _update)
      ..post('/<id>/approve', _approve)
      ..post('/<id>/distribute', _distribute)
      ..delete('/<id>', _delete);
  }

  Future<Response> _getAll(Request req) async =>
      _json({'data': [], 'total': 0, 'message': 'Connect to AidRepository'});

  Future<Response> _getById(Request req, String id) async =>
      _json({'error': 'Not implemented'}, statusCode: 501);

  Future<Response> _create(Request req) async =>
      _json({'error': 'Not implemented'}, statusCode: 501);

  Future<Response> _update(Request req, String id) async =>
      _json({'error': 'Not implemented'}, statusCode: 501);

  Future<Response> _approve(Request req, String id) async =>
      _json({'message': 'Aid $id approved'});

  Future<Response> _distribute(Request req, String id) async =>
      _json({'message': 'Aid $id distributed'});

  Future<Response> _delete(Request req, String id) async =>
      _json({'error': 'Not implemented'}, statusCode: 501);

  Response _json(dynamic data, {int statusCode = 200}) => Response(
        statusCode,
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      );
}
