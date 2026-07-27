import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:charity_app/core/supabase/supabase_config.dart';
import 'package:charity_app/core/offline/offline_store.dart';
import 'package:charity_app/core/offline/connectivity_service.dart';

/// Flushes the offline write-outbox to Supabase when connectivity returns.
class SyncService {
  const SyncService();

  /// Apply every pending op (oldest first) to Supabase.
  ///
  /// On success the op is removed. On a transient/offline failure we stop and
  /// keep the remaining ops for the next flush. On a non-transient 4xx
  /// [PostgrestException] we drop the op to avoid a poison-pill loop.
  ///
  /// Returns the number of ops successfully synced.
  Future<int> flush() async {
    if (!OfflineStore.instance.isReady) return 0;

    var synced = 0;
    final ops = OfflineStore.instance.pendingOps();

    for (final op in ops) {
      final id = op['id'] as String;
      final table = op['table'] as String;
      final action = op['action'] as String;
      final payload = op['payload'] as Map<String, dynamic>?;
      final matchColumn = op['matchColumn'] as String?;
      final matchValue = op['matchValue'];

      try {
        switch (action) {
          case 'insert':
            await supabase.from(table).insert(payload ?? <String, dynamic>{});
            break;
          case 'update':
            if (matchColumn == null) {
              // Malformed op — nothing to match on; drop it.
              await OfflineStore.instance.removeOp(id);
              continue;
            }
            await supabase
                .from(table)
                .update(payload ?? <String, dynamic>{})
                .eq(matchColumn, matchValue);
            break;
          case 'delete':
            if (matchColumn == null) {
              await OfflineStore.instance.removeOp(id);
              continue;
            }
            await supabase.from(table).delete().eq(matchColumn, matchValue);
            break;
          default:
            // Unknown action — drop it so it can't block the queue.
            await OfflineStore.instance.removeOp(id);
            continue;
        }

        await OfflineStore.instance.removeOp(id);
        synced++;
      } catch (e) {
        if (_isPermanentError(e)) {
          // Server rejected the write (validation/permission/etc.). Remove so
          // it doesn't wedge the queue forever.
          await OfflineStore.instance.removeOp(id);
          continue;
        }
        // Transient/offline failure — keep this op and everything after it,
        // stop flushing and retry on the next connectivity flip.
        break;
      }
    }

    return synced;
  }

  /// A permanent error is a Postgrest 4xx (client-side) rejection. Anything
  /// that looks like an offline/transport error is treated as transient.
  bool _isPermanentError(Object e) {
    if (OfflineStore.isOfflineError(e)) return false;
    if (e is PostgrestException) {
      final code = int.tryParse(e.code ?? '');
      if (code != null && code >= 400 && code < 500) return true;
    }
    return false;
  }
}

/// Convenience provider for the [SyncService].
final syncServiceProvider = Provider<SyncService>((ref) => const SyncService());

/// Drives outbox flushing off connectivity changes.
///
/// This provider watches [connectivityStatusProvider] and, whenever the status
/// flips to online, calls [SyncService.flush]. It holds no meaningful value —
/// keep it *alive* so the listener runs.
///
/// ## How to start it
/// It must be observed for the `ref.listen` to fire. Watch it once high in the
/// widget tree (e.g. in your root widget's `build`):
///
/// ```dart
/// class CharityApp extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     ref.watch(syncTriggerProvider); // starts offline→online outbox sync
///     ...
///   }
/// }
/// ```
///
/// Alternatively, call `SyncService().flush()` manually after a successful
/// reconnect or on app resume.
final syncTriggerProvider = Provider<void>((ref) {
  final sync = ref.watch(syncServiceProvider);

  // Flush once at startup in case we launched already-online with a backlog.
  Future.microtask(sync.flush);

  ref.listen<AsyncValue<bool>>(connectivityStatusProvider, (prev, next) {
    final wasOnline = prev?.valueOrNull ?? false;
    final isOnline = next.valueOrNull ?? false;
    if (!wasOnline && isOnline) {
      // Fire-and-forget; flush() is internally safe against partial failures.
      sync.flush();
    }
  });
});
