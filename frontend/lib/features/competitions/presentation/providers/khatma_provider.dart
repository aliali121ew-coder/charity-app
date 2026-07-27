import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:charity_app/features/competitions/data/supabase_engagement_repository.dart';
import 'package:charity_app/features/competitions/domain/khatma_models.dart';

// ════════════════════════════════════════════════════════════════════════════
//  حالة الختمة — مدعومة بـ Supabase (khatmat + khatma_juz عبر RPC).
//  • القراءة: getActiveKhatma (الختمة النشطة + أجزاؤها الثلاثون) عند الباني.
//  • الحجز/الإتمام: RPC reserve_juz / complete_juz (الأخير يمنح 10 نقاط).
//  • نفس واجهة الحالة تماماً (KhatmaState + active/completed/
//    totalCompletedKhatmas) ونفس دوال المزوّد المتزامنة (reserve/markCompleted/
//    cancelReservation) حتى لا تتغيّر khatma_page/competitions_page:
//      - تُحدّث الحالة تفاؤلياً ثم تستدعي RPC في الخلفية وتزامن من الخادم.
//  • بلا ختمات في القاعدة: نبدأ بختمة فارغة واحدة (لا انهيار).
//  • بلا جلسة Supabase: القراءة تعمل (khatma_juz مقروء للجميع)، لكن طفرات RPC
//    ترمي داخلياً؛ نُبقي التحديث التفاؤلي المحلي لإبقاء الواجهة قابلة للتجربة.
// ════════════════════════════════════════════════════════════════════════════
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
  final SupabaseEngagementRepository _repo = SupabaseEngagementRepository();

  /// معرّف الختمة النشطة الخام (uuid) — لازم لاستدعاء دوال RPC.
  String? _activeKhatmaId;

  KhatmaNotifier() : super(KhatmaState(khatmas: [KhatmaModel.empty(1)])) {
    _load();
  }

  Future<void> _load() async {
    try {
      _activeKhatmaId = await _repo.getActiveKhatmaId();
      final active = await _repo.getActiveKhatma();
      state = KhatmaState(khatmas: [active ?? KhatmaModel.empty(1)]);
    } catch (_) {
      // تعذّر الاتصال — نُبقي الختمة الفارغة الحالية بدل الانهيار.
    }
  }

  /// إعادة تحميل من الخادم.
  Future<void> reload() => _load();

  // ── تحديث تفاؤلي محلي لجزء داخل الختمة المفتوحة ──────────────────────────────
  void _updateActiveJuz(JuzModel updated) {
    final active = state.active;
    if (active.isComplete) return; // مغلقة — لا تعديل
    final updatedKhatma = active.withJuz(updated);
    final khatmas = state.khatmas
        .map((k) => k.index == updatedKhatma.index ? updatedKhatma : k)
        .toList();
    state = state.copyWith(khatmas: khatmas);
  }

  /// حجز جزء باسم المستخدم — يظهر بعدها "تم حجزه" للبقية.
  /// (متزامن كما كان؛ يستدعي RPC reserve_juz في الخلفية ثم يزامن.)
  void reserve(int juzNumber, String reserverName) {
    final juz = state.active.juz[juzNumber - 1];
    if (!juz.isAvailable) return;
    // تفاؤلياً: نضع اسم الحاجز (يطابق ما تعرضه الصفحة لتمييز "حجزك").
    _updateActiveJuz(
        juz.copyWith(status: JuzStatus.reserved, reservedBy: reserverName));
    _syncReserve(juzNumber);
  }

  /// إلغاء الحجز (يعيد الجزء متاحاً).
  /// ملاحظة: لا توجد دالة RPC لإلغاء الحجز ضمن نطاق هذه المهمة، وسياسة RLS
  /// (kj_reserve) لا تسمح للمستخدم العادي بإرجاعه متاحاً؛ لذا يبقى الإلغاء
  /// تحديثاً تفاؤلياً محلياً فقط (يُزامَن مع الخادم عند إعادة التحميل التالية).
  void cancelReservation(int juzNumber) {
    final juz = state.active.juz[juzNumber - 1];
    if (!juz.isReserved) return;
    _updateActiveJuz(
        juz.copyWith(status: JuzStatus.available, clearReserver: true));
  }

  /// تأكيد إتمام قراءة الجزء.
  /// (متزامن كما كان؛ يستدعي RPC complete_juz في الخلفية — يمنح 10 نقاط.)
  void markCompleted(int juzNumber) {
    final juz = state.active.juz[juzNumber - 1];
    if (juz.isCompleted) return;
    _updateActiveJuz(juz.copyWith(status: JuzStatus.completed));
    _syncComplete(juzNumber);
  }

  // ── مزامنة خلفية عبر RPC ثم إعادة تحميل ──────────────────────────────────────
  Future<void> _syncReserve(int juzNumber) async {
    final id = _activeKhatmaId;
    if (id == null) return; // لا ختمة فعلية في القاعدة — يبقى محلياً
    try {
      await _repo.reserveJuz(id, juzNumber);
      await _load();
    } catch (_) {
      // بلا جلسة/تعارض — نُبقي التحديث التفاؤلي المحلي.
    }
  }

  Future<void> _syncComplete(int juzNumber) async {
    final id = _activeKhatmaId;
    if (id == null) return;
    try {
      await _repo.completeJuz(id, juzNumber);
      await _load();
    } catch (_) {
      // بلا جلسة/تعارض — نُبقي التحديث التفاؤلي المحلي.
    }
  }
}

final khatmaProvider =
    StateNotifierProvider<KhatmaNotifier, KhatmaState>((ref) {
  return KhatmaNotifier();
});
