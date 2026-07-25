import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:charity_app/shared/providers/app_providers.dart';
import 'package:charity_app/features/quran/domain/quran_models.dart';

/// تحميل كامل القرآن من الأصل المدمج (مرة واحدة، عند فتح المصحف).
final quranDataProvider = FutureProvider<List<Surah>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/quran.json');
  final map = jsonDecode(raw) as Map<String, dynamic>;
  return (map['surahs'] as List)
      .map((e) => Surah.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});

// ── إعدادات القارئ (حجم الخط + آخر موضع + الإشارات المرجعية) ──────────────────────
const _kFontSizeKey = 'quran_font_size';
const _kLastReadKey = 'quran_last_read'; // "surah:ayah"
const _kBookmarksKey = 'quran_bookmarks';

class QuranSettings {
  final double fontSize;
  final String? lastRead; // "surah:ayah"
  final Set<String> bookmarks; // "surah:ayah"

  const QuranSettings({
    this.fontSize = 26,
    this.lastRead,
    this.bookmarks = const {},
  });

  int? get lastReadSurah =>
      lastRead == null ? null : int.tryParse(lastRead!.split(':').first);
  int? get lastReadAyah =>
      lastRead == null ? null : int.tryParse(lastRead!.split(':').last);

  QuranSettings copyWith({double? fontSize, String? lastRead, Set<String>? bookmarks}) =>
      QuranSettings(
        fontSize: fontSize ?? this.fontSize,
        lastRead: lastRead ?? this.lastRead,
        bookmarks: bookmarks ?? this.bookmarks,
      );
}

class QuranSettingsNotifier extends StateNotifier<QuranSettings> {
  final SharedPreferences _prefs;

  QuranSettingsNotifier(this._prefs)
      : super(QuranSettings(
          fontSize: _prefs.getDouble(_kFontSizeKey) ?? 26,
          lastRead: _prefs.getString(_kLastReadKey),
          bookmarks: (_prefs.getStringList(_kBookmarksKey) ?? const []).toSet(),
        ));

  void setFontSize(double size) {
    final clamped = size.clamp(18.0, 44.0);
    state = state.copyWith(fontSize: clamped);
    _prefs.setDouble(_kFontSizeKey, clamped);
  }

  void increaseFont() => setFontSize(state.fontSize + 2);
  void decreaseFont() => setFontSize(state.fontSize - 2);

  void setLastRead(int surah, int ayah) {
    final value = '$surah:$ayah';
    state = state.copyWith(lastRead: value);
    _prefs.setString(_kLastReadKey, value);
  }

  bool isBookmarked(int surah, int ayah) => state.bookmarks.contains('$surah:$ayah');

  void toggleBookmark(int surah, int ayah) {
    final key = '$surah:$ayah';
    final next = Set<String>.from(state.bookmarks);
    if (!next.add(key)) next.remove(key);
    state = state.copyWith(bookmarks: next);
    _prefs.setStringList(_kBookmarksKey, next.toList());
  }
}

final quranSettingsProvider =
    StateNotifierProvider<QuranSettingsNotifier, QuranSettings>((ref) {
  return QuranSettingsNotifier(ref.watch(sharedPreferencesProvider));
});
