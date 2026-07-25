import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:charity_app/shared/providers/app_providers.dart';
import 'package:charity_app/features/istikhara/domain/istikhara_models.dart';

/// تحميل قاعدة بيانات خيرة القرآن من الأصول.
final quranIstikharaDataProvider = FutureProvider<List<QuranIstikharaEntry>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/istikhara/quran_istikhara.json');
  final map = jsonDecode(raw) as Map<String, dynamic>;
  return (map['entries'] as List)
      .map((e) => QuranIstikharaEntry.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});

/// اختيار عشوائي ذكي لمدخل خيرة من قاعدة البيانات.
QuranIstikharaEntry pickRandomEntry(List<QuranIstikharaEntry> entries) {
  return entries[Random().nextInt(entries.length)];
}

// ── سجلّ الاستخارات المحفوظة ──────────────────────────────────────────────────
const _kHistoryKey = 'istikhara_history_v1';

class IstikharaHistoryNotifier extends StateNotifier<List<IstikharaRecord>> {
  final SharedPreferences _prefs;

  IstikharaHistoryNotifier(this._prefs) : super(const []) {
    _load();
  }

  void _load() {
    final raw = _prefs.getString(_kHistoryKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List;
      state = list.map((e) => IstikharaRecord.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      // بيانات تالفة — نبدأ بسجلّ فارغ.
    }
  }

  void _persist() {
    _prefs.setString(_kHistoryKey, jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  void add(IstikharaRecord record) {
    state = [record, ...state];
    _persist();
  }

  void remove(String id) {
    state = state.where((r) => r.id != id).toList();
    _persist();
  }

  void clear() {
    state = const [];
    _persist();
  }
}

final istikharaHistoryProvider =
    StateNotifierProvider<IstikharaHistoryNotifier, List<IstikharaRecord>>((ref) {
  return IstikharaHistoryNotifier(ref.watch(sharedPreferencesProvider));
});
