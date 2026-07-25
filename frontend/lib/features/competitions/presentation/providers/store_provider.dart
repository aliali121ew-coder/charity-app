import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:charity_app/features/competitions/data/mock_competitions_data.dart';
import 'package:charity_app/features/competitions/domain/competition_models.dart';
import 'package:charity_app/features/competitions/presentation/providers/points_provider.dart';

const _uuid = Uuid();

// ════════════════════════════════════════════════════════════════════════════
//  جوائز المتجر — يديرها المشرف (إضافة/تعديل/حذف).
// ════════════════════════════════════════════════════════════════════════════
class StorePrizesNotifier extends StateNotifier<List<Prize>> {
  StorePrizesNotifier() : super(seedStorePrizes());

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
//  سجل الاستبدال — منفصل عن "جوائزي".
//  • المادية: تُولّد كود + QR، الحالة "بانتظار الاستلام"، وتُخصم النقاط عند
//    تأكيد المشرف.
//  • الرقمية: تُمنح فوراً وتُخصم النقاط مباشرة (لا استلام فعلي).
// ════════════════════════════════════════════════════════════════════════════
class StoreRedemptionsNotifier extends StateNotifier<List<StoreRedemption>> {
  final Ref _ref;
  StoreRedemptionsNotifier(this._ref) : super(const []);

  /// يُرجع رسالة خطأ أو null عند النجاح.
  String? redeem(Prize prize) {
    if (prize.stock <= 0) return 'نفدت كمية هذه الجائزة';

    final pointsNotifier = _ref.read(userPointsProvider.notifier);
    final balance = _ref.read(userPointsProvider);

    if (prize.type == PrizeType.digital) {
      // خصم فوري ومنح مباشر.
      if (!pointsNotifier.deduct(prize.pointsCost)) {
        return 'نقاطك غير كافية لاستبدال هذه الجائزة';
      }
      _ref.read(storePrizesProvider.notifier)._decrementStock(prize.id);
      state = [_build(prize, ClaimStatus.received), ...state];
      return null;
    }

    // مادية: لا خصم الآن — يجب أن يكون الرصيد كافياً وقت الاستبدال.
    if (balance < prize.pointsCost) {
      return 'نقاطك غير كافية لاستبدال هذه الجائزة';
    }
    _ref.read(storePrizesProvider.notifier)._decrementStock(prize.id);
    state = [_build(prize, ClaimStatus.pending), ...state];
    return null;
  }

  /// تأكيد الاستلام (مشرف) للجائزة المادية — يخصم النقاط.
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

  StoreRedemption _build(Prize prize, ClaimStatus status) {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase();
    return StoreRedemption(
      id: _uuid.v4(),
      prizeTitle: prize.title,
      type: prize.type,
      pointsCost: prize.pointsCost,
      claimCode: 'RDM-$ts-${_uuid.v4().substring(0, 4).toUpperCase()}',
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
