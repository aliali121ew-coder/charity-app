import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

/// Codegen-free offline persistence layer.
///
/// Supabase rows are cached as JSON strings (no Hive typed adapters, so this
/// works without running build_runner). Two boxes are used:
///   - `offline_cache`  : read-through cache keyed by a logical name
///                        (e.g. 'subscribers') → JSON-encoded `List<Map>`.
///   - `offline_outbox` : queued write operations keyed by a generated id,
///                        flushed to Supabase by [SyncService] when online.
class OfflineStore {
  OfflineStore._();

  static final OfflineStore instance = OfflineStore._();

  static const String _cacheBoxName = 'offline_cache';
  static const String _outboxBoxName = 'offline_outbox';

  static const Uuid _uuid = Uuid();

  Box<String>? _cacheBox;
  Box<String>? _outboxBox;

  bool _initialized = false;

  /// Whether [init] has completed. Callers can guard reads/writes against this
  /// so that a missing init never throws.
  bool get isReady => _initialized;

  Box<String> get _cache {
    final box = _cacheBox;
    if (box == null) {
      throw StateError('OfflineStore.init() must be called before use.');
    }
    return box;
  }

  Box<String> get _outbox {
    final box = _outboxBox;
    if (box == null) {
      throw StateError('OfflineStore.init() must be called before use.');
    }
    return box;
  }

  /// Initialize Hive and open the cache + outbox boxes. Safe to call once at
  /// startup (idempotent).
  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _cacheBox = await Hive.openBox<String>(_cacheBoxName);
    _outboxBox = await Hive.openBox<String>(_outboxBoxName);
    _initialized = true;
  }

  // ---------------------------------------------------------------------------
  // Read-through cache
  // ---------------------------------------------------------------------------

  /// Cache a list of Supabase rows under [key] as a JSON string.
  Future<void> cacheRows(String key, List<Map<String, dynamic>> rows) async {
    if (!_initialized) return;
    await _cache.put(key, jsonEncode(rows));
  }

  /// Read cached rows for [key]; returns null when nothing is cached.
  List<Map<String, dynamic>>? readRows(String key) {
    if (!_initialized) return null;
    final raw = _cache.get(key);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! List) return null;
    return decoded
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Write outbox
  // ---------------------------------------------------------------------------

  /// Queue a write operation to be flushed to Supabase later.
  ///
  /// [action] must be one of `insert`, `update`, `delete`. For update/delete
  /// provide [matchColumn] + [matchValue] (typically column 'id').
  Future<void> enqueue({
    required String table,
    required String action,
    Map<String, dynamic>? payload,
    String? matchColumn,
    dynamic matchValue,
  }) async {
    if (!_initialized) return;
    final id = _uuid.v4();
    final op = <String, dynamic>{
      'id': id,
      'table': table,
      'action': action,
      'payload': payload,
      'matchColumn': matchColumn,
      'matchValue': matchValue,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await _outbox.put(id, jsonEncode(op));
  }

  /// Pending operations ordered by their `createdAt` timestamp (oldest first).
  List<Map<String, dynamic>> pendingOps() {
    if (!_initialized) return <Map<String, dynamic>>[];
    final ops = <Map<String, dynamic>>[];
    for (final raw in _outbox.values) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        ops.add(Map<String, dynamic>.from(decoded));
      }
    }
    ops.sort((a, b) {
      final ca = (a['createdAt'] ?? '') as String;
      final cb = (b['createdAt'] ?? '') as String;
      return ca.compareTo(cb);
    });
    return ops;
  }

  /// Remove a single queued operation by its id.
  Future<void> removeOp(String id) async {
    if (!_initialized) return;
    await _outbox.delete(id);
  }

  // ---------------------------------------------------------------------------
  // Error heuristics
  // ---------------------------------------------------------------------------

  /// Heuristic: does [e] look like a connectivity/offline failure (as opposed
  /// to a genuine server-side rejection)?
  static bool isOfflineError(Object e) {
    if (e is SocketException) return true;
    if (e is TimeoutException) return true;
    // http's ClientException is thrown on transport failures. Match by name so
    // we don't need to import `package:http` here.
    if (e.runtimeType.toString() == 'ClientException') return true;
    final msg = e.toString();
    return msg.contains('SocketException') ||
        msg.contains('Failed host lookup') ||
        msg.contains('Connection') ||
        msg.contains('network') ||
        msg.contains('ClientException');
  }
}
