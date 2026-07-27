import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:charity_app/features/competitions/data/supabase_engagement_repository.dart';
import 'package:charity_app/features/competitions/domain/competition_models.dart';

const _uuid = Uuid();

// ════════════════════════════════════════════════════════════════════════════
//  رصيد نقاط المستخدم — مدعوم بـ Supabase.
//  • مصدر الحقيقة هو points_ledger/user_engagement_stats عبر دوال RPC
//    (get_points_balance / award_points) لأن RLS يمنع الكتابة المباشرة.
//  • نفس الواجهة العامة تماماً (StateNotifier<int> + add/deduct) حتى لا تتغيّر
//    الصفحات: الحالة هي رصيد int، تُحمّل async في الباني.
//  • add/deduct تبقيان بتوقيع متزامن (كما كانتا): تُحدّثان الحالة تفاؤلياً ثم
//    تستدعيان RPC في الخلفية وتزامنان الرصيد الحقيقي بعدها.
//  • بلا جلسة Supabase (auth.uid == null): القراءة تُرجع 0، وطفرات RPC ترمي
//    داخلياً فنُبقي التحديث التفاؤلي المحلي لإبقاء الواجهة قابلة للتجربة.
// ════════════════════════════════════════════════════════════════════════════
class UserPointsNotifier extends StateNotifier<int> {
  final SupabaseEngagementRepository _repo = SupabaseEngagementRepository();

  UserPointsNotifier() : super(0) {
    _load();
  }

  Future<void> _load() async {
    try {
      state = await _repo.getBalance();
    } catch (_) {
      // تعذّر الاتصال/لا جلسة — نُبقي الرصيد الحالي بدل الانهيار.
    }
  }

  /// إعادة تحميل الرصيد من الخادم.
  Future<void> reload() => _load();

  void add(int amount) {
    state = (state + amount).clamp(0, 1 << 30);
    _syncAward(amount);
  }

  /// خصم النقاط — يُرجع true إن نجح (الرصيد المعروف كافٍ).
  bool deduct(int amount) {
    if (state < amount) return false;
    state = state - amount;
    _syncAward(-amount);
    return true;
  }

  /// تعديل تفاؤلي محلي للرصيد فقط دون استدعاء RPC — يُستخدم عندما تكون حركة
  /// النقاط قد تمّت أصلاً في القاعدة داخل RPC آخر (مثل redeem_store_prize)،
  /// فنتجنّب الخصم المزدوج على الخادم ونكتفي بمزامنة العرض محلياً.
  void applyLocalDelta(int delta) {
    state = (state + delta).clamp(0, 1 << 30);
  }

  /// يرسل الحركة إلى القاعدة عبر award_points ثم يزامن الرصيد الحقيقي.
  Future<void> _syncAward(int delta) async {
    try {
      final balance = await _repo.award(delta, reason: 'adjustment');
      state = balance;
    } catch (_) {
      // بلا جلسة أو تعذّر الاتصال — نُبقي التحديث التفاؤلي المحلي.
    }
  }
}

final userPointsProvider =
    StateNotifierProvider<UserPointsNotifier, int>((ref) {
  return UserPointsNotifier();
});

// ════════════════════════════════════════════════════════════════════════════
//  بطاقات المطالبة بالجوائز ("جوائزي")
//  - تُنشأ عند فوز المستخدم (أعلى النقاط — تلقائي).
//  - تُخصم النقاط فقط عند تأكيد الاستلام الفعلي من المشرف.
//  ملاحظة: جدول claim_cards خارج نطاق هذه المهمة (النقاط/الختمة/الاستبدال/
//  المشاركات)، ولا توجد له دالة RPC؛ لذا تبقى هذه الحالة محلية كما كانت،
//  لكن خصم النقاط عند تأكيد الاستلام يمرّ الآن عبر userPointsProvider المدعوم
//  بـ Supabase (award_points).
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
