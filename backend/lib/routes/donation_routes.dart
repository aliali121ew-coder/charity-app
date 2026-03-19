import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:charity_backend/models/donation.dart';
import 'package:charity_backend/repositories/donations_store.dart';

class DonationRoutes {
  late final Router router;
  final DonationsStore _repo;

  DonationRoutes({required DonationsStore repo}) : _repo = repo {
    router = Router()
      ..get('/', _getAll)
      ..get('/summary', _getSummary)
      ..get('/<id>', _getById)
      ..post('/', _create)
      ..put('/<id>/status', _updateStatus)
      ..delete('/<id>', _delete)
      ..put('/goal', _updateGoal);
  }

  // GET /api/donations?status=completed&method=zainCash&search=أحمد
  Future<Response> _getAll(Request req) async {
    final params = req.url.queryParameters;
    final list = await _repo.getAll(
      status: params['status'],
      method: params['method'],
      search: params['search'],
    );
    return _json({'data': list.map((d) => d.toJson()).toList(), 'total': list.length});
  }

  // GET /api/donations/summary
  Future<Response> _getSummary(Request req) async {
    return _json(await _repo.getSummary());
  }

  // GET /api/donations/:id
  Future<Response> _getById(Request req, String id) async {
    final d = await _repo.getById(id);
    if (d == null) return _json({'error': 'Donation not found'}, statusCode: 404);
    return _json(d.toJson());
  }

  // POST /api/donations
  Future<Response> _create(Request req) async {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;

    final donorRaw = body['donor'];
    final amountRaw = body['amount'];
    final methodRaw = body['method'];

    if (donorRaw == null || amountRaw == null || methodRaw == null) {
      return _json({'error': 'donor, amount, method are required'}, statusCode: 400);
    }

    final DonationPaymentMethod method;
    try {
      method = DonationPaymentMethod.values.byName(methodRaw as String);
    } catch (_) {
      return _json({'error': 'Invalid payment method'}, statusCode: 400);
    }

    final DonationStatus status;
    try {
      status = body['status'] != null
          ? DonationStatus.values.byName(body['status'] as String)
          : DonationStatus.processing;
    } catch (_) {
      return _json({'error': 'Invalid status'}, statusCode: 400);
    }

    final donation = await _repo.create(
      donor: donorRaw as String,
      amount: (amountRaw as num).toDouble(),
      method: method,
      status: status,
      notes: body['notes'] as String?,
      currency: body['currency'] as String? ?? 'IQD',
    );

    return _json(donation.toJson(), statusCode: 201);
  }

  // PUT /api/donations/:id/status
  Future<Response> _updateStatus(Request req, String id) async {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final statusRaw = body['status'];
    if (statusRaw == null) {
      return _json({'error': 'status is required'}, statusCode: 400);
    }

    final DonationStatus newStatus;
    try {
      newStatus = DonationStatus.values.byName(statusRaw as String);
    } catch (_) {
      return _json({'error': 'Invalid status'}, statusCode: 400);
    }

    final updated = await _repo.updateStatus(id, newStatus);
    if (updated == null) return _json({'error': 'Donation not found'}, statusCode: 404);
    return _json(updated.toJson());
  }

  // DELETE /api/donations/:id
  Future<Response> _delete(Request req, String id) async {
    final deleted = await _repo.delete(id);
    if (!deleted) return _json({'error': 'Donation not found'}, statusCode: 404);
    return _json({'message': 'Deleted successfully'});
  }

  // PUT /api/donations/goal
  Future<Response> _updateGoal(Request req) async {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final goalRaw = body['goal'];
    if (goalRaw == null) return _json({'error': 'goal is required'}, statusCode: 400);
    await _repo.updateMonthlyGoal((goalRaw as num).toDouble());
    return _json({'message': 'Monthly goal updated', 'goal': goalRaw});
  }

  Response _json(dynamic data, {int statusCode = 200}) => Response(
        statusCode,
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      );
}
