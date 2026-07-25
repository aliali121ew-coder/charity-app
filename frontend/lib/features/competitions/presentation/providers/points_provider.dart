import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:charity_app/shared/providers/app_providers.dart';
import 'package:charity_app/features/competitions/domain/competition_models.dart';

const _uuid = Uuid();
const _kPointsKey = 'user_points_v1';

// ════════════════════════════════════════════════════════════════════════════
//  رصيد نقاط المستخدم — يُحفظ ويُسترجع.
// ════════════════════════════════════════════════════════════════════════════
class UserPointsNotifier extends StateNotifier<int> {
  final SharedPreferences _prefs;
  UserPointsNotifier(this._prefs) : super(_prefs.getInt(_kPointsKey) ?? 2840);

  void add(int amount) {
    state = (state + amount).clamp(0, 1 << 30);
    _prefs.setInt(_kPointsKey, state);
  }

  /// خصم النقاط — يُرجع true إن نجح (الرصيد كافٍ).
  bool deduct(int amount) {
    if (state < amount) return false;
    state = state - amount;
    _prefs.setInt(_kPointsKey, state);
    return true;
  }
}

final userPointsProvider =
    StateNotifierProvider<UserPointsNotifier, int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UserPointsNotifier(prefs);
});

// ════════════════════════════════════════════════════════════════════════════
//  بطاقات المطالبة بالجوائز ("جوائزي")
//  - تُنشأ عند فوز المستخدم (أعلى النقاط — تلقائي).
//  - تُخصم النقاط فقط عند تأكيد الاستلام الفعلي من المشرف.
// ════════════════════════════════════════════════════════════════════════════
class ClaimsNotifier extends StateNotifier<List<ClaimCard>> {
  final Ref _ref;
  ClaimsNotifier(this._ref) : super(const []);

  bool hasClaimFor(String competitionTitle) =>
      state.any((c) => c.competitionTitle == competitionTitle);

  /// إنشاء بطاقة مطالبة عند الفوز.
  ClaimCard createClaim({
    required Competition competition,
    required String winnerName,
  }) {
    final code = _generateCode();
    final card = ClaimCard(
      id: _uuid.v4(),
      competitionTitle: competition.title,
      winnerName: winnerName,
      prizeTitle: competition.prizeTitle,
      prizeType: competition.prizeType,
      claimCode: code,
      status: ClaimStatus.pending,
      wonAt: DateTime.now(),
      deadline: DateTime.now().add(const Duration(days: 14)),
      instructions: competition.prizeInstructions ??
          'أبرز كود المطالبة أو رمز QR لاستلام جائزتك.',
      pointsCost: competition.rewardPoints,
      color: competition.color,
    );
    state = [card, ...state];
    return card;
  }

  /// تأكيد الاستلام (المشرف) — يخصم النقاط ويحدّث الحالة.
  /// يُرجع رسالة خطأ أو null عند النجاح.
  String? confirmReceipt(String claimId) {
    final idx = state.indexWhere((c) => c.id == claimId);
    if (idx < 0) return 'البطاقة غير موجودة';
    final card = state[idx];
    if (card.status == ClaimStatus.received) return null;

    final ok = _ref.read(userPointsProvider.notifier).deduct(card.pointsCost);
    if (!ok) return 'رصيد النقاط غير كافٍ لإتمام الاستلام';

    final updated = card.copyWith(status: ClaimStatus.received);
    state = [...state]..[idx] = updated;
    return null;
  }

  String _generateCode() {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase();
    final rand = _uuid.v4().substring(0, 4).toUpperCase();
    return 'CLM-$ts-$rand';
  }
}

final claimsProvider =
    StateNotifierProvider<ClaimsNotifier, List<ClaimCard>>(
        (ref) => ClaimsNotifier(ref));
