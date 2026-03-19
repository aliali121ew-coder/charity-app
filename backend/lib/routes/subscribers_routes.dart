import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:charity_backend/repositories/subscribers_repository.dart';

class SubscribersRoutes {
  final _repo = MockSubscribersRepository();
  late final Router router;

  SubscribersRoutes() {
    router = Router()
      ..get('/', _getAll)
      ..get('/<id>', _getById)
      ..post('/', _create)
      ..put('/<id>', _update)
      ..delete('/<id>', _delete)
      ..get('/count', _count);
  }

  Future<Response> _getAll(Request req) async {
    final params = req.url.queryParameters;
    final subscribers = await _repo.getAll(
      query: params['q'],
      area: params['area'],
    );
    return _json({'data': subscribers.map((s) => s.toJson()).toList(), 'total': subscribers.length});
  }

  Future<Response> _getById(Request req, String id) async {
    final subscriber = await _repo.getById(id);
    if (subscriber == null) return _json({'error': 'Not found'}, statusCode: 404);
    return _json(subscriber.toJson());
  }

  Future<Response> _create(Request req) async {
    try {
      final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
      body['id'] = 'sub_${DateTime.now().millisecondsSinceEpoch}';
      body['registrationDate'] ??= DateTime.now().toIso8601String();
      body['status'] ??= 'pending';
      final subscriber = await _repo.create(SubscriberModel_fromMap(body));
      return _json(subscriber.toJson(), statusCode: 201);
    } catch (e) {
      return _json({'error': 'Invalid data: $e'}, statusCode: 400);
    }
  }

  Future<Response> _update(Request req, String id) async {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final updated = await _repo.update(id, body);
    if (updated == null) return _json({'error': 'Not found'}, statusCode: 404);
    return _json(updated.toJson());
  }

  Future<Response> _delete(Request req, String id) async {
    final deleted = await _repo.delete(id);
    if (!deleted) return _json({'error': 'Not found'}, statusCode: 404);
    return _json({'message': 'Deleted successfully'});
  }

  Future<Response> _count(Request req) async {
    final count = await _repo.count();
    return _json({'count': count});
  }

  Response _json(dynamic data, {int statusCode = 200}) => Response(
        statusCode,
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      );
}

// Helper to avoid import issues (use proper model factory in real code)
dynamic SubscriberModel_fromMap(Map<String, dynamic> map) {
  // This would call Subscriber.fromJson in real code
  return map;
}
