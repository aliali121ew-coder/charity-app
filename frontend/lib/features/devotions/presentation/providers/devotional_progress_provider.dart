import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:charity_app/shared/providers/app_providers.dart';

const _kProgressKey = 'devotional_last_page_v1';

/// يحفظ آخر صفحة وصلها القارئ في كل نصّ ديني (مفهرسة بمعرّف العنصر) محلياً،
/// ليُستأنف من حيث توقّف عند إعادة الفتح.
class DevotionalProgressNotifier extends StateNotifier<Map<String, int>> {
  final SharedPreferences _prefs;

  DevotionalProgressNotifier(this._prefs) : super(const {}) {
    _load();
  }

  void _load() {
    final raw = _prefs.getString(_kProgressKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      state = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      // بيانات تالفة — نتجاهلها.
    }
  }

  void _persist() => _prefs.setString(_kProgressKey, jsonEncode(state));

  int pageFor(String itemId) => state[itemId] ?? 0;

  void setPage(String itemId, int page) {
    if ((state[itemId] ?? 0) == page) return;
    state = {...state, itemId: page};
    _persist();
  }
}

final devotionalProgressProvider =
    StateNotifierProvider<DevotionalProgressNotifier, Map<String, int>>((ref) {
  return DevotionalProgressNotifier(ref.watch(sharedPreferencesProvider));
});
