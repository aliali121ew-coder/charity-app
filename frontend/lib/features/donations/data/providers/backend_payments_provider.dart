import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:charity_app/core/constants/app_constants.dart';
import 'package:charity_app/shared/providers/app_providers.dart';
import '../../domain/interfaces/payment_provider_interface.dart';
import '../../domain/models/payment_models.dart';

class BackendPaymentsProvider implements PaymentProviderInterface {
  BackendPaymentsProvider(this._ref);

  final Ref _ref;

  Uri get _apiBase => Uri.parse(const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8080',
      ));

  Future<String?> _token() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    return prefs.getString(AppConstants.prefAuthToken);
  }

  @override
  String get providerId => 'backend';

  @override
  String get providerName => 'Backend Hosted Payments';

  @override
  List<PaymentMethodType> get supportedMethods => const [
        PaymentMethodType.visa,
        PaymentMethodType.mastercard,
        PaymentMethodType.zaincash,
        PaymentMethodType.superki,
      ];

  @override
  bool get isAvailable => true;

  static String _methodName(PaymentMethodType m) {
    switch (m) {
      case PaymentMethodType.visa:
        return 'visa';
      case PaymentMethodType.mastercard:
        return 'mastercard';
      case PaymentMethodType.zaincash:
        return 'zaincash';
      case PaymentMethodType.superki:
        return 'superki';
      default:
        return m.name;
    }
  }

  static PaymentSessionStatus _mapStatus(String s) {
    switch (s) {
      case 'paid':
        return PaymentSessionStatus.completed;
      case 'failed':
        return PaymentSessionStatus.failed;
      case 'cancelled':
        return PaymentSessionStatus.cancelled;
      case 'expired':
        return PaymentSessionStatus.expired;
      case 'pending':
      case 'created':
      default:
        return PaymentSessionStatus.pending;
    }
  }

  static PaymentMethodType _mapMethod(String s) {
    switch (s) {
      case 'visa':
        return PaymentMethodType.visa;
      case 'mastercard':
        return PaymentMethodType.mastercard;
      case 'zaincash':
        return PaymentMethodType.zaincash;
      case 'superki':
        return PaymentMethodType.superki;
      default:
        return PaymentMethodType.cash;
    }
  }

  @override
  Future<PaymentSession> createSession({
    required double amount,
    required PaymentCurrency currency,
    required PaymentMethodType method,
    required String donorName,
    required String donationId,
    Map<String, dynamic>? metadata,
  }) async {
    final token = await _token();
    if (token == null || token.isEmpty) {
      throw const PaymentException(
        code: 'UNAUTHORIZED',
        message: 'Missing auth token',
        messageAr: 'يرجى تسجيل الدخول أولاً.',
      );
    }

    final url = _apiBase.resolve('/api/payments/session');
    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'amount': amount,
        'currency': currency.code,
        'method': _methodName(method),
        'donorName': donorName,
        'donationId': donationId,
        'metadata': metadata,
      }),
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw PaymentException(
        code: 'CREATE_SESSION_FAILED',
        message: 'Backend session creation failed',
        messageAr: 'تعذر إنشاء جلسة الدفع. يرجى المحاولة لاحقاً.',
      );
    }

    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    final sessionId = decoded['id']?.toString() ?? '';
    final redirectUrl = decoded['redirectUrl']?.toString();
    final expiresAt = DateTime.tryParse(decoded['expiresAt']?.toString() ?? '');
    final createdAt = DateTime.tryParse(decoded['createdAt']?.toString() ?? '');

    return PaymentSession(
      sessionId: sessionId,
      providerId: decoded['provider']?.toString() ?? providerId,
      amount: (decoded['amount'] as num?)?.toDouble() ?? amount,
      currency: PaymentCurrency.values.firstWhere(
        (c) => c.code == (decoded['currency']?.toString() ?? currency.code),
        orElse: () => currency,
      ),
      method: _mapMethod(decoded['method']?.toString() ?? method.name),
      status: _mapStatus(decoded['status']?.toString() ?? 'pending'),
      verificationRequired: method.requires3DS
          ? VerificationType.threeDSecure
          : method.requiresOtp
              ? VerificationType.otp
              : VerificationType.redirect,
      createdAt: createdAt ?? DateTime.now(),
      expiresAt: expiresAt ?? DateTime.now().add(const Duration(minutes: 15)),
      redirectUrl: redirectUrl,
      providerData: decoded,
    );
  }

  @override
  Future<PaymentInitiationResult> initiatePayment({
    required PaymentSession session,
    required PaymentInput input,
  }) async {
    // We use Hosted Payment Pages; initiation happens in WebView.
    return PaymentInitiationResult(
      requiresVerification: true,
      verificationType: VerificationType.redirect,
      session: session,
      messageAr: 'أكمل الدفع داخل صفحة البوابة.',
    );
  }

  @override
  Future<PaymentResult> verifyPayment({
    required PaymentSession session,
    required String verificationCode,
  }) async {
    throw const PaymentException(
      code: 'UNSUPPORTED',
      message: 'Verification is handled by hosted payment page',
      messageAr: 'التحقق يتم داخل بوابة الدفع.',
    );
  }

  @override
  Future<PaymentSession> checkStatus(String sessionId) async {
    final token = await _token();
    if (token == null || token.isEmpty) {
      throw const PaymentException(
        code: 'UNAUTHORIZED',
        message: 'Missing auth token',
        messageAr: 'يرجى تسجيل الدخول أولاً.',
      );
    }
    final url = _apiBase.resolve('/api/payments/status/$sessionId');
    final resp = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw const PaymentException(
        code: 'STATUS_FAILED',
        message: 'Failed to fetch status',
        messageAr: 'تعذر جلب حالة الدفع.',
      );
    }
    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    return PaymentSession(
      sessionId: decoded['id']?.toString() ?? sessionId,
      providerId: decoded['provider']?.toString() ?? providerId,
      amount: (decoded['amount'] as num?)?.toDouble() ?? 0.0,
      currency: PaymentCurrency.values.firstWhere(
        (c) => c.code == (decoded['currency']?.toString() ?? 'IQD'),
        orElse: () => PaymentCurrency.iqd,
      ),
      method: _mapMethod(decoded['method']?.toString() ?? 'cash'),
      status: _mapStatus(decoded['status']?.toString() ?? 'pending'),
      verificationRequired: VerificationType.redirect,
      createdAt: DateTime.tryParse(decoded['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      expiresAt: DateTime.tryParse(decoded['expiresAt']?.toString() ?? '') ??
          DateTime.now().add(const Duration(minutes: 15)),
      redirectUrl: decoded['redirectUrl']?.toString(),
      providerData: decoded,
    );
  }

  @override
  Future<bool> cancelSession(String sessionId) async {
    // Not implemented in backend yet.
    return false;
  }

  @override
  Future<void> resendOtp(String sessionId) async {
    // Hosted payment pages handle OTP internally. No-op.
  }
}

