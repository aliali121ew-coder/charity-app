import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:charity_app/features/competitions/data/supabase_competitions_repository.dart';
import 'package:charity_app/features/competitions/data/supabase_engagement_repository.dart';
import 'package:charity_app/features/competitions/domain/competition_models.dart';
import 'package:charity_app/features/competitions/presentation/providers/points_provider.dart';

// ════════════════════════════════════════════════════════════════════════════
//  جوائز المتجر — القائمة تُقرأ من Supabase (getPrizes)، والإدارة (إضافة/تعديل/
//  حذف) تبقى محلية تفاؤلية كما كانت. نفس واجهة الـ notifier تماماً
//  (List<Prize> + upsert/remove) حتى لا تتغيّر prizes_page/create_store_prize_page.
//  (تُترك كما هي حسب نطاق المهمة — هذا الجزء مربوط بـ Supabase مسبقاً.)
// ════════════════════════════════════════════════════════════════════════════
class StorePrizesNotifier extends StateNotifier<List<Prize>> {
  final SupabaseCompetitionsRepository _repo = SupabaseCompetitionsRepository();

  StorePrizesNotifier() : super(const []) {
    _load();
  }

  /// تحميل جوائز المتجر من Supabase (READ فقط) — يبدأ فارغاً ثم يملأ الحالة.
  Future<void> _load() async {
    try {
      state = await _repo.getPrizes();
    } catch (_) {
      // تعذّر الاتصال — نُبقي القائمة الحالية (فارغة) بدل الانهيار.
    }
  }

  /// إعادة تحميل من الخادم (مفيدة للسحب-للتحديث).
  Future<void> reload() => _load();

  // TODO(supabase): upsert/remove/_decrementStock تبقى محلية (تفاؤلية) في هذه
  // المهمة التي تُعيد ربط تفاعل النقاط/الاستبدال؛ إدارة الجوائز (كتابة prizes)
  // خارج نطاقها.
  void upsert(Prize prize) {
    final idx = state.indexWhere((p) => p.id == prize.id);
    if (idx < 0) {
      state = [prize, ...state];
    } else {
      state = [...state]..[idx] = prize;
    }
  }

  void remove(String id) => state = state.where((p) => p.id != id).toList();

  void _decrementStock(String id) {
    state = state
        .map((p) => p.id == id ? p.copyWith(stock: (p.stock - 1).clamp(0, 1 << 30)) : p)
        .toList();
  }
}

final storePrizesProvider =
    StateNotifierProvider<StorePrizesNotifier, List<Prize>>(
        (ref) => StorePrizesNotifier());

// ════════════════════════════════════════════════════════════════════════════
//  سجل الاستبدال — مدعوم بـ Supabase.
//  • القراءة: myRedemptions (سجل استبدالات المستخدم) عند الباني.
//  • الاستبدال: RPC redeem_store_prize (عملية ذرّية في القاعدة: تحقّق المخزون +
//    خصم النقاط + توليد كود + إدراج الصف). نفس التوقيع المتزامن redeem(Prize)
//    الذي يُرجع String? (رسالة خطأ أو null) حتى لا تتغيّر prizes_page:
//      - تحقّق أوّلي متزامن (مخزون/رصيد) لإرجاع الخطأ فوراً كما كان،
//      - ثم استدعاء RPC في الخلفية مع تحديث تفاؤلي وإعادة تحميل.
//  • confirmReceipt يبقى كما كان (خصم النقاط عبر userPointsProvider المدعوم
//    بـ Supabase). تأكيد الاستلام الفعلي (status=received) عملية إدارية في
//    القاعدة (سياسة sr_staff_update) خارج نطاق المستخدم المجتمعي.
//  • بلا جلسة Supabase: القراءة تُرجع فارغاً؛ الاستبدال يبقى تحديثاً تفاؤلياً
//    محلياً (RPC يرمي داخلياً) لإبقاء الواجهة قابلة للتجربة.
// ════════════════════════════════════════════════════════════════════════════
class StoreRedemptionsNotifier extends StateNotifier<List<StoreRedemption>> {
  final Ref _ref;
  final SupabaseEngagementRepository _repo = SupabaseEngagementRepository();

  StoreRedemptionsNotifier(this._ref) : super(const []) {
    _load();
  }

  Future<void> _load() async {
    try {
      state = await _repo.myRedemptions();
    } catch (_) {
      // تعذّر الاتصال/لا جلسة — نُبقي القائمة الحالية بدل الانهيار.
    }
  }

  /// إعادة تحميل سجل الاستبدال من الخادم.
  Future<void> reload() => _load();

  /// يُرجع رسالة خطأ أو null عند النجاح (تحقّق أوّلي متزامن كما كان).
  String? redeem(Prize prize) {
    if (prize.stock <= 0) return 'نفدت كمية هذه الجائزة';

    final balance = _ref.read(userPointsProvider);
    if (balance < prize.pointsCost) {
      return 'نقاطك غير كافية لاستبدال هذه الجائزة';
    }

    // تحديث تفاؤلي فوري (يطابق سلوك الواجهة السابق) ثم مزامنة عبر RPC.
    _ref.read(storePrizesProvider.notifier)._decrementStock(prize.id);
    // الرقمية تُمنح فوراً (received)، المادية بانتظار الاستلام (pending).
    final status =
        prize.type == PrizeType.digital ? ClaimStatus.received : ClaimStatus.pending;
    state = [_buildOptimistic(prize, status), ...state];
    // الخصم يمرّ عبر القاعدة داخل redeem_store_prize (award_points بداخله)؛ لذا
    // نُطبّق خصماً محلياً للعرض فقط دون RPC ثانٍ لتفادي الخصم المزدوج على الخادم،
    // ثم نزامن الرصيد الحقيقي بعد نجاح RPC الاستبدال في _syncRedeem.
    _ref.read(userPointsProvider.notifier).applyLocalDelta(-prize.pointsCost);
    _syncRedeem(prize.id);
    return null;
  }

  /// تأكيد الاستلام (مشرف) للجائزة المادية — يخصم النقاط محلياً/في القاعدة.
  String? confirmReceipt(String redemptionId) {
    final idx = state.indexWhere((r) => r.id == redemptionId);
    if (idx < 0) return 'السجل غير موجود';
    final r = state[idx];
    if (r.status == ClaimStatus.received) return null;

    if (!_ref.read(userPointsProvider.notifier).deduct(r.pointsCost)) {
      return 'رصيد النقاط غير كافٍ لإتمام الاستلام';
    }
    state = [...state]..[idx] = r.copyWith(status: ClaimStatus.received);
    return null;
  }

  /// استدعاء RPC الاستبدال في الخلفية ثم إعادة تحميل السجل الحقيقي والرصيد.
  Future<void> _syncRedeem(String prizeId) async {
    try {
      await _repo.redeem(prizeId);
      await _load();
      await _ref.read(userPointsProvider.notifier).reload();
    } catch (_) {
      // بلا جلسة أو نفاد المخزون على الخادم — نُبقي التحديث التفاؤلي المحلي.
    }
  }

  /// بناء صف استبدال تفاؤلي محلي (يُستبدل بصف القاعدة بعد إعادة التحميل).
  StoreRedemption _buildOptimistic(Prize prize, ClaimStatus status) {
    final ts =
        DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase();
    return StoreRedemption(
      id: 'local-$ts',
      prizeTitle: prize.title,
      type: prize.type,
      pointsCost: prize.pointsCost,
      claimCode:
          'ST-${_ref.hashCode.toRadixString(16).toUpperCase()}$ts'.substring(0, 11),
      status: status,
      redeemedAt: DateTime.now(),
      deadline: DateTime.now().add(const Duration(days: 14)),
      instructions: prize.instructions.isEmpty
          ? 'أبرز كود الاستلام أو رمز QR لاستلام جائزتك.'
          : prize.instructions,
      color: prize.color,
      icon: prize.icon,
    );
  }
}

final storeRedemptionsProvider =
    StateNotifierProvider<StoreRedemptionsNotifier, List<StoreRedemption>>(
        (ref) => StoreRedemptionsNotifier(ref));
