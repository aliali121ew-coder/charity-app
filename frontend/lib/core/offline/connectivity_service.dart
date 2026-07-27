import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin wrapper over connectivity_plus v6, which reports connectivity as a
/// `List<ConnectivityResult>` for both the one-shot check and the stream.
class ConnectivityService {
  const ConnectivityService();

  static bool _isOnline(List<ConnectivityResult> results) =>
      results.any((x) => x != ConnectivityResult.none);

  /// One-shot online check.
  Future<bool> isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return _isOnline(results);
  }

  /// Stream of `true` (online) / `false` (offline) as connectivity changes.
  Stream<bool> onlineStream() {
    return Connectivity().onConnectivityChanged.map(_isOnline);
  }
}

/// Streams the current online status. Emits `true` when at least one transport
/// (wifi / mobile / ethernet / vpn …) is available, `false` when fully offline.
final connectivityStatusProvider = StreamProvider<bool>((ref) {
  const service = ConnectivityService();
  return service.onlineStream();
});
