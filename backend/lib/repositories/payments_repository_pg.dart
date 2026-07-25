import 'package:charity_backend/models/payment.dart';
import 'package:charity_backend/repositories/payments_store.dart';
import 'package:charity_backend/services/db.dart';
import 'package:postgres/postgres.dart';

class PaymentsRepositoryPg implements PaymentsStore {
  PaymentsRepositoryPg(this._db);

  final Db _db;

  @override
  Future<PaymentIntent?> getById(String id) async {
    final rs = await _db.conn.execute(
      Sql.named('SELECT * FROM payment_intents WHERE id=@id'),
      parameters: {'id': id},
    );
    if (rs.isEmpty) return null;
    return _rowToIntent(rs.first.toColumnMap());
  }

  @override
  Future<void> upsert(PaymentIntent intent) async {
    await _db.conn.execute(
      Sql.named('''
INSERT INTO payment_intents (
  id, provider, method, amount, currency, donor_name, donation_id, status,
  redirect_url, provider_payment_id, provider_invoice_id, provider_txn_id,
  last_error, created_at, expires_at
) VALUES (
  @id, @provider, @method, @amount, @currency, @donor_name, @donation_id, @status,
  @redirect_url, @provider_payment_id, @provider_invoice_id, @provider_txn_id,
  @last_error, @created_at, @expires_at
)
ON CONFLICT (id) DO UPDATE SET
  provider=EXCLUDED.provider,
  method=EXCLUDED.method,
  amount=EXCLUDED.amount,
  currency=EXCLUDED.currency,
  donor_name=EXCLUDED.donor_name,
  donation_id=EXCLUDED.donation_id,
  status=EXCLUDED.status,
  redirect_url=EXCLUDED.redirect_url,
  provider_payment_id=EXCLUDED.provider_payment_id,
  provider_invoice_id=EXCLUDED.provider_invoice_id,
  provider_txn_id=EXCLUDED.provider_txn_id,
  last_error=EXCLUDED.last_error,
  created_at=EXCLUDED.created_at,
  expires_at=EXCLUDED.expires_at
'''),
      parameters: {
        'id': intent.id,
        'provider': intent.provider.name,
        'method': intent.method.name,
        'amount': intent.amount,
        'currency': intent.currency,
        'donor_name': intent.donorName,
        'donation_id': intent.donationId,
        'status': intent.status.name,
        'redirect_url': intent.redirectUrl,
        'provider_payment_id': intent.providerPaymentId,
        'provider_invoice_id': intent.providerInvoiceId,
        'provider_txn_id': intent.providerTxnId,
        'last_error': intent.lastError,
        'created_at': intent.createdAt.toUtc(),
        'expires_at': intent.expiresAt.toUtc(),
      },
    );
  }

  @override
  Future<PaymentIntent?> update(
    String id,
    PaymentIntent Function(PaymentIntent) fn,
  ) async {
    final cur = await getById(id);
    if (cur == null) return null;
    final next = fn(cur);
    await upsert(next);
    return next;
  }

  PaymentIntent _rowToIntent(Map<String, dynamic> r) {
    PaymentProvider provider =
        PaymentProvider.values.byName(r['provider'] as String);
    PaymentIntentMethod method =
        PaymentIntentMethod.values.byName(r['method'] as String);
    PaymentIntentStatus status =
        PaymentIntentStatus.values.byName(r['status'] as String);
    return PaymentIntent(
      id: r['id'] as String,
      provider: provider,
      method: method,
      amount: (r['amount'] as num).toDouble(),
      currency: r['currency'] as String,
      donorName: r['donor_name'] as String,
      donationId: r['donation_id'] as String,
      status: status,
      redirectUrl: r['redirect_url'] as String?,
      providerPaymentId: r['provider_payment_id'] as String?,
      providerInvoiceId: r['provider_invoice_id'] as String?,
      providerTxnId: r['provider_txn_id'] as String?,
      lastError: r['last_error'] as String?,
      createdAt: (r['created_at'] as DateTime).toLocal(),
      expiresAt: (r['expires_at'] as DateTime).toLocal(),
    );
  }
}

