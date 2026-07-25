import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:charity_app/shared/providers/app_providers.dart';

const _kFavoritesPrefsKey = 'devotional_favorites_v1';

/// مفضّلة موحّدة لكل أقسام العبادات (الأدعية/الزيارات/الأعمال)، مفهرسة بمساحة
/// اسم (namespace) فمفتاح العنصر، ومحفوظة بشكل دائم محلياً.
class DevotionalFavoritesNotifier extends StateNotifier<Map<String, Set<String>>> {
  final SharedPreferences _prefs;

  DevotionalFavoritesNotifier(this._prefs) : super(const {}) {
    _load();
  }

  void _load() {
    final raw = _prefs.getString(_kFavoritesPrefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      state = decoded.map((k, v) => MapEntry(k, Set<String>.from(v as List)));
    } catch (_) {
      // بيانات تالفة — نتجاهلها ونبدأ بمفضّلة فارغة.
    }
  }

  void _persist() {
    _prefs.setString(
      _kFavoritesPrefsKey,
      jsonEncode(state.map((k, v) => MapEntry(k, v.toList()))),
    );
  }

  bool isFavorite(String namespace, String itemId) =>
      state[namespace]?.contains(itemId) ?? false;

  void toggle(String namespace, String itemId) {
    final current = Set<String>.from(state[namespace] ?? {});
    if (current.contains(itemId)) {
      current.remove(itemId);
    } else {
      current.add(itemId);
    }
    state = {...state, namespace: current};
    _persist();
  }
}

final devotionalFavoritesProvider =
    StateNotifierProvider<DevotionalFavoritesNotifier, Map<String, Set<String>>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DevotionalFavoritesNotifier(prefs);
});
