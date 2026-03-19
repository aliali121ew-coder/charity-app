import 'dart:io';
import 'package:postgres/postgres.dart';

class Db {
  Db._(this.conn);

  final Connection conn;

  static Future<Db?> connectFromEnv() async {
    final url = Platform.environment['DATABASE_URL'];
    if (url == null || url.isEmpty) return null;

    // Render provides DATABASE_URL like:
    // postgres://user:pass@host:5432/dbname
    final uri = Uri.parse(url);
    final userInfo = uri.userInfo.split(':');
    final endpoint = Endpoint(
      host: uri.host,
      port: uri.port,
      database: uri.pathSegments.first,
      username: userInfo.isNotEmpty ? userInfo[0] : null,
      password: userInfo.length > 1 ? userInfo[1] : null,
    );
    final connection = await Connection.open(
      endpoint,
      settings: const ConnectionSettings(sslMode: SslMode.require),
    );
    return Db._(connection);
  }

  Future<void> close() => conn.close();

  Future<void> ensureSchema() async {
    await conn.execute('''
CREATE TABLE IF NOT EXISTS payment_intents (
  id TEXT PRIMARY KEY,
  provider TEXT NOT NULL,
  method TEXT NOT NULL,
  amount DOUBLE PRECISION NOT NULL,
  currency TEXT NOT NULL,
  donor_name TEXT NOT NULL,
  donation_id TEXT NOT NULL,
  status TEXT NOT NULL,
  redirect_url TEXT,
  provider_payment_id TEXT,
  provider_invoice_id TEXT,
  provider_txn_id TEXT,
  last_error TEXT,
  created_at TIMESTAMPTZ NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL
);
''');

    await conn.execute('''
CREATE INDEX IF NOT EXISTS payment_intents_status_idx
ON payment_intents(status);
''');

    await conn.execute('''
CREATE TABLE IF NOT EXISTS donations (
  id TEXT PRIMARY KEY,
  donor TEXT NOT NULL,
  amount DOUBLE PRECISION NOT NULL,
  currency TEXT NOT NULL,
  method TEXT NOT NULL,
  status TEXT NOT NULL,
  reference TEXT NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  notes TEXT
);
''');

    await conn.execute('''
CREATE INDEX IF NOT EXISTS donations_date_idx
ON donations(date DESC);
''');

    await conn.execute('''
CREATE INDEX IF NOT EXISTS donations_status_idx
ON donations(status);
''');
  }
}

