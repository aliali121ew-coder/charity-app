import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class ReportsRoutes {
  late final Router router;

  ReportsRoutes() {
    router = Router()
      ..get('/summary', _getSummary)
      ..get('/monthly', _getMonthly)
      ..get('/yearly', _getYearly)
      ..get('/aid-by-type', _getAidByType);
  }

  Future<Response> _getSummary(Request req) async => _json({
        'totalSubscribers': 0,
        'totalFamilies': 0,
        'totalAid': 0,
        'totalAmount': 0,
        'activeCases': 0,
        'pendingReviews': 0,
        'message': 'Connect to repositories to get real data',
      });

  Future<Response> _getMonthly(Request req) async =>
      _json({'data': [], 'message': 'Connect to AidRepository.getMonthlyTotals()'});

  Future<Response> _getYearly(Request req) async =>
      _json({'data': [], 'message': 'Connect to AidRepository.getYearlyTotals()'});

  Future<Response> _getAidByType(Request req) async =>
      _json({'data': {}, 'message': 'Connect to AidRepository.getCountByType()'});

  Response _json(dynamic data, {int statusCode = 200}) => Response(
        statusCode,
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      );
}
