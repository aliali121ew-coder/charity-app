import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:charity_app/shared/providers/app_providers.dart';
import 'package:charity_app/features/reading/domain/reading_preferences.dart';

const _kFontSize = 'reading_font_size_v1';
const _kFont = 'reading_font_v1';
const _kBackground = 'reading_background_v1';
const _kMode = 'reading_mode_v1';

/// يدير تفضيلات القراءة الموحّدة ويحفظها محلياً ليبقى الاختيار بين الجلسات.
class ReadingPreferencesNotifier extends StateNotifier<ReadingPreferences> {
  final SharedPreferences _prefs;

  ReadingPreferencesNotifier(this._prefs)
      : super(ReadingPreferences(
          fontSize: _prefs.getDouble(_kFontSize) ?? 22,
          font: ReadingFont.fromKey(_prefs.getString(_kFont)),
          background: ReadingBackground.fromKey(_prefs.getString(_kBackground)),
          mode: ReadingMode.fromKey(_prefs.getString(_kMode)),
        ));

  void setFontSize(double size) {
    final clamped = size.clamp(ReadingPreferences.minFontSize, ReadingPreferences.maxFontSize);
    state = state.copyWith(fontSize: clamped);
    _prefs.setDouble(_kFontSize, clamped);
  }

  void increaseFont() => setFontSize(state.fontSize + 2);
  void decreaseFont() => setFontSize(state.fontSize - 2);

  void setFont(ReadingFont font) {
    state = state.copyWith(font: font);
    _prefs.setString(_kFont, font.key);
  }

  void setBackground(ReadingBackground background) {
    state = state.copyWith(background: background);
    _prefs.setString(_kBackground, background.key);
  }

  void setMode(ReadingMode mode) {
    state = state.copyWith(mode: mode);
    _prefs.setString(_kMode, mode.key);
  }
}

final readingPreferencesProvider =
    StateNotifierProvider<ReadingPreferencesNotifier, ReadingPreferences>((ref) {
  return ReadingPreferencesNotifier(ref.watch(sharedPreferencesProvider));
});
