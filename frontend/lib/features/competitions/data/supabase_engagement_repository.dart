import 'package:flutter/material.dart';
import 'package:charity_app/core/supabase/supabase_config.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/competitions/domain/competition_models.dart';
import 'package:charity_app/features/competitions/domain/khatma_models.dart';

/// مستودع تفاعل المسابقات عبر Supabase — النقاط + الختمة + الاستبدال +
/// المشاركات/الأدلّة. يكمّل [SupabaseCompetitionsRepository] (قراءة المسابقات
/// والجوائز ولوحة الصدارة) بكل العمليات التي تُغيّر الحالة.
///
/// كل عملية تُغيّر النقاط تمرّ عبر دوال RPC (SECURITY DEFINER) المعرّفة في
/// migration 0017 لأن RLS يمنع الكتابة المباشرة في points_ledger من المستخدم
/// المجتمعي (pl_staff_insert). القراءات تعتمد على سياسات SELECT التي تسمح
/// للمستخدم بقراءة صفوفه (user_id = auth.uid()).
///
/// الهوية: كل العمليات تتطلّب جلسة Supabase auth (supabase.auth.currentUser).
/// عند غياب الجلسة ترمي [AuthRequiredException] للطفرات، وتُرجع القراءات فارغاً.
class SupabaseEngagementRepository {
  // أسماء الجداول
  static const _ledger = 'points_ledger';
  static const _stats = 'user_engagement_stats';
  static const _khatmat = 'khatmat';
  static const _khatmaJuz = 'khatma_juz';
  static const _redemptions = 'store_redemptions';
  static const _entries = 'competition_entries';
  static const _proofs = 'participation_proofs';

  /// معرّف المستخدم الحالي من جلسة Supabase (null إن لا جلسة).
  String? get _uid => supabase.auth.currentUser?.id;

  /// يضمن وجود جلسة أو يرمي خطأً عربياً واضحاً (للطفرات فقط).
  String _requireUid() {
    final id = _uid;
    if (id == null) throw AuthRequiredException();
    return id;
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  النقاط
  // ══════════════════════════════════════════════════════════════════════════

  /// رصيد النقاط الحالي عبر RPC get_points_balance (0 إن لا جلسة/لا صف).
  Future<int> getBalance() async {
    if (_uid == null) return 0;
    final res = await supabase.rpc('get_points_balance');
    return (res as num?)?.toInt() ?? 0;
  }

  /// إضافة/خصم نقاط عبر RPC award_points؛ يُرجع الرصيد الجديد.
  Future<int> award(
    int delta, {
    String reason = 'adjustment',
    String? refType,
    String? refId,
  }) async {
    _requireUid();
    final res = await supabase.rpc('award_points', params: {
      'p_delta': delta,
      'p_reason': reason,
      'p_ref_type': refType,
      'p_ref_id': refId,
    });
    return (res as num?)?.toInt() ?? 0;
  }

  /// سجل حركات النقاط للمستخدم الحالي (الأحدث أولاً). فارغ إن لا جلسة.
  Future<List<Map<String, dynamic>>> pointsHistory({int limit = 100}) async {
    final id = _uid;
    if (id == null) return const [];
    final rows = await supabase
        .from(_ledger)
        .select()
        .eq('user_id', id)
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  الختمة
  // ══════════════════════════════════════════════════════════════════════════

  /// أول ختمة نشطة (is_active) مع أجزائها الثلاثين، أو null إن لا ختمات.
  Future<KhatmaModel?> getActiveKhatma() async {
    final khatma = await supabase
        .from(_khatmat)
        .select('id')
        .eq('is_active', true)
        .order('created_at', ascending: true)
        .limit(1)
        .maybeSingle();
    if (khatma == null) return null;
    final khatmaId = khatma['id'] as String;
    final juz = await _juzFor(khatmaId);
    return KhatmaModel(index: 1, juz: juz);
  }

  /// جميع الختمات (نشطة أو لا) مع أجزائها، مرتّبة بالأقدم أولاً.
  /// فارغة إن لا ختمات (لا انهيار).
  Future<List<KhatmaModel>> getKhatmat() async {
    final khatmat = await supabase
        .from(_khatmat)
        .select('id')
        .order('created_at', ascending: true);
    final list = <KhatmaModel>[];
    var index = 1;
    for (final k in khatmat) {
      final juz = await _juzFor(k['id'] as String);
      list.add(KhatmaModel(index: index, juz: juz));
      index++;
    }
    return list;
  }

  /// معرّف الختمة النشطة الخام (uuid) — يحتاجه المزوّد لاستدعاء RPC الحجز/الإتمام.
  Future<String?> getActiveKhatmaId() async {
    final khatma = await supabase
        .from(_khatmat)
        .select('id')
        .eq('is_active', true)
        .order('created_at', ascending: true)
        .limit(1)
        .maybeSingle();
    return khatma?['id'] as String?;
  }

  /// يجلب أجزاء ختمة ويحوّلها إلى List<JuzModel> (يملأ الغائب كمتاح).
  Future<List<JuzModel>> _juzFor(String khatmaId) async {
    final rows = await supabase
        .from(_khatmaJuz)
        .select('juz_number,status,reserved_by, profiles:reserved_by(full_name)')
        .eq('khatma_id', khatmaId)
        .order('juz_number', ascending: true);

    // خريطة رقم الجزء -> JuzModel من القاعدة.
    final byNumber = <int, JuzModel>{};
    for (final r in rows) {
      final n = (r['juz_number'] as num).toInt();
      final profile = r['profiles'] as Map<String, dynamic>?;
      byNumber[n] = JuzModel(
        number: n,
        status: JuzStatus.values.byName((r['status'] ?? 'available') as String),
        reservedBy: profile?['full_name'] as String?,
      );
    }

    // نضمن 30 جزءاً دائماً (أي جزء غير موجود في القاعدة = متاح).
    return List.generate(
      30,
      (i) => byNumber[i + 1] ?? JuzModel(number: i + 1),
    );
  }

  /// حجز جزء عبر RPC reserve_juz.
  Future<void> reserveJuz(String khatmaId, int juz) async {
    _requireUid();
    await supabase.rpc('reserve_juz', params: {
      'p_khatma_id': khatmaId,
      'p_juz': juz,
    });
  }

  /// تأكيد إتمام جزء عبر RPC complete_juz (يمنح 10 نقاط في القاعدة).
  Future<void> completeJuz(String khatmaId, int juz) async {
    _requireUid();
    await supabase.rpc('complete_juz', params: {
      'p_khatma_id': khatmaId,
      'p_juz': juz,
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  الاستبدال (المتجر)
  // ══════════════════════════════════════════════════════════════════════════

  /// استبدال جائزة عبر RPC redeem_store_prize (ذرّي: مخزون + نقاط + كود).
  /// يُرجع صف الاستبدال المُنشأ محوّلاً إلى [StoreRedemption].
  Future<StoreRedemption> redeem(String prizeId) async {
    _requireUid();
    final row = await supabase.rpc('redeem_store_prize', params: {
      'p_prize_id': prizeId,
    });
    return _mapRedemption(Map<String, dynamic>.from(row as Map));
  }

  /// سجل استبدالات المستخدم الحالي (الأحدث أولاً). فارغ إن لا جلسة.
  Future<List<StoreRedemption>> myRedemptions() async {
    final id = _uid;
    if (id == null) return const [];
    final rows = await supabase
        .from(_redemptions)
        .select()
        .eq('user_id', id)
        .order('redeemed_at', ascending: false);
    return rows.map((e) => _mapRedemption(Map<String, dynamic>.from(e))).toList();
  }

  StoreRedemption _mapRedemption(Map<String, dynamic> r) {
    final type = PrizeType.values.byName((r['type'] ?? 'physical') as String);
    return StoreRedemption(
      id: r['id'] as String,
      prizeTitle: (r['prize_title'] ?? '') as String,
      type: type,
      pointsCost: (r['points_cost'] ?? 0) as int,
      claimCode: (r['claim_code'] ?? '') as String,
      status: ClaimStatus.values.byName((r['status'] ?? 'pending') as String),
      redeemedAt: DateTime.parse(r['redeemed_at'] as String),
      deadline: DateTime.parse(r['deadline'] as String),
      instructions: (r['instructions'] ?? '') as String,
      // اللون/الأيقونة أنواع واجهة غير مخزّنة في القاعدة — قيم افتراضية.
      color: AppColors.pink,
      icon: type == PrizeType.digital
          ? Icons.workspace_premium_rounded
          : Icons.card_giftcard_rounded,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  المشاركات + الأدلّة
  // ══════════════════════════════════════════════════════════════════════════

  /// الانضمام لمسابقة عبر RPC join_competition. يُرجع الصف دائماً.
  Future<Map<String, dynamic>> join(String competitionId) async {
    _requireUid();
    final row = await supabase.rpc('join_competition', params: {
      'p_competition_id': competitionId,
    });
    return Map<String, dynamic>.from(row as Map);
  }

  /// إلغاء المشاركة — حذف صف competition_entries (مسموح بـ RLS: ce_delete).
  Future<void> leave(String competitionId) async {
    final id = _uid;
    if (id == null) throw AuthRequiredException();
    await supabase
        .from(_entries)
        .delete()
        .eq('competition_id', competitionId)
        .eq('user_id', id);
  }

  /// رفع دليل مشاركة عبر RPC submit_competition_proof (يضمن وجود entry).
  Future<Map<String, dynamic>> submitProof(
    String competitionId, {
    String? text,
    String? imageUrl,
  }) async {
    _requireUid();
    final row = await supabase.rpc('submit_competition_proof', params: {
      'p_competition_id': competitionId,
      'p_text': text,
      'p_image_url': imageUrl,
    });
    return Map<String, dynamic>.from(row as Map);
  }

  /// مشاركات المستخدم الحالي (كل الصفوف). فارغ إن لا جلسة.
  Future<List<Map<String, dynamic>>> myEntries() async {
    final id = _uid;
    if (id == null) return const [];
    final rows = await supabase
        .from(_entries)
        .select()
        .eq('user_id', id)
        .order('joined_at', ascending: false);
    return rows.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// أدلّة المستخدم الحالي في مسابقة محدّدة (الأحدث أولاً). فارغ إن لا جلسة.
  Future<List<Map<String, dynamic>>> myProofs(String competitionId) async {
    final id = _uid;
    if (id == null) return const [];
    final rows = await supabase
        .from(_proofs)
        .select()
        .eq('user_id', id)
        .eq('competition_id', competitionId)
        .order('submitted_at', ascending: false);
    return rows.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  إحصاءات المستخدم (تفيد المزوّدات لعرض عدّادات جاهزة)
  // ══════════════════════════════════════════════════════════════════════════

  /// صف إحصاءات المستخدم الحالي، أو null إن لا جلسة/لا صف.
  Future<Map<String, dynamic>?> myStats() async {
    final id = _uid;
    if (id == null) return null;
    final row =
        await supabase.from(_stats).select().eq('user_id', id).maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }
}

/// خطأ يُرمى عند محاولة عملية تتطلّب تسجيل الدخول دون جلسة Supabase.
class AuthRequiredException implements Exception {
  final String message;
  AuthRequiredException([this.message = 'يجب تسجيل الدخول أولاً']);

  @override
  String toString() => message;
}
