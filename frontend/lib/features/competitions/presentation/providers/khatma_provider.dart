import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:charity_app/shared/providers/app_providers.dart';
import 'package:charity_app/features/competitions/domain/khatma_models.dart';

const _kKhatmaPrefsKey = 'khatma_state_v1';

class KhatmaState {
  final List<KhatmaModel> khatmas;
  const KhatmaState({this.khatmas = const []});

  /// الختمة المفتوحة حالياً = أول ختمة غير مكتملة.
  /// لا تُفتح الختمة التالية إلا بعد إكمال جميع أجزاء الحالية.
  KhatmaModel get active =>
      khatmas.firstWhere((k) => !k.isComplete, orElse: () => khatmas.last);

  /// الختمات المكتملة (للأرشيف).
  List<KhatmaModel> get completed =>
      khatmas.where((k) => k.isComplete).toList();

  int get totalCompletedKhatmas => completed.length;

  KhatmaState copyWith({List<KhatmaModel>? khatmas}) =>
      KhatmaState(khatmas: khatmas ?? this.khatmas);
}

class KhatmaNotifier extends StateNotifier<KhatmaState> {
  final SharedPreferences _prefs;

  KhatmaNotifier(this._prefs) : super(const KhatmaState()) {
    _load();
  }

  void _load() {
    final raw = _prefs.getString(_kKhatmaPrefsKey);
    if (raw == null || raw.isEmpty) {
      state = KhatmaState(khatmas: [KhatmaModel.empty(1)]);
      return;
    }
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => KhatmaModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      state = KhatmaState(khatmas: list.isEmpty ? [KhatmaModel.empty(1)] : list);
    } catch (_) {
      state = KhatmaState(khatmas: [KhatmaModel.empty(1)]);
    }
  }

  void _persist() {
    _prefs.setString(
      _kKhatmaPrefsKey,
      jsonEncode(state.khatmas.map((k) => k.toJson()).toList()),
    );
  }

  /// تحديث جزء داخل الختمة المفتوحة فقط، ثم فتح ختمة جديدة إذا اكتملت.
  void _updateActiveJuz(JuzModel updated) {
    final active = state.active;
    if (active.isComplete) return; // مغلقة — لا تعديل
    final updatedKhatma = active.withJuz(updated);

    final khatmas = state.khatmas
        .map((k) => k.index == updatedKhatma.index ? updatedKhatma : k)
        .toList();

    // إذا اكتملت الختمة الآن، افتح الختمة التالية تلقائياً.
    if (updatedKhatma.isComplete &&
        !khatmas.any((k) => k.index == updatedKhatma.index + 1)) {
      khatmas.add(KhatmaModel.empty(updatedKhatma.index + 1));
    }

    state = state.copyWith(khatmas: khatmas);
    _persist();
  }

  /// حجز جزء باسم المستخدم — يظهر بعدها "تم حجزه" للبقية.
  void reserve(int juzNumber, String reserverName) {
    final juz = state.active.juz[juzNumber - 1];
    if (!juz.isAvailable) return;
    _updateActiveJuz(juz.copyWith(status: JuzStatus.reserved, reservedBy: reserverName));
  }

  /// إلغاء الحجز (يعيد الجزء متاحاً).
  void cancelReservation(int juzNumber) {
    final juz = state.active.juz[juzNumber - 1];
    if (!juz.isReserved) return;
    _updateActiveJuz(juz.copyWith(status: JuzStatus.available, clearReserver: true));
  }

  /// تأكيد إتمام قراءة الجزء.
  void markCompleted(int juzNumber) {
    final juz = state.active.juz[juzNumber - 1];
    if (juz.isCompleted) return;
    _updateActiveJuz(juz.copyWith(status: JuzStatus.completed));
  }
}

final khatmaProvider =
    StateNotifierProvider<KhatmaNotifier, KhatmaState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return KhatmaNotifier(prefs);
});
