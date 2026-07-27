import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:charity_app/shared/providers/app_providers.dart';
import 'package:charity_app/core/permissions/role.dart';
import 'package:charity_app/features/competitions/data/supabase_competitions_repository.dart';
import 'package:charity_app/features/competitions/data/supabase_engagement_repository.dart';
import 'package:charity_app/features/competitions/domain/competition_models.dart';

const _uuid = Uuid();

// ════════════════════════════════════════════════════════════════════════════
//  صلاحية إنشاء المسابقات — المشرف (admin) أو من مُنح صلاحية إدارة المستخدمين.
//  يمكن منح أكثر من حساب هذه الصلاحية عبر نظام الصلاحيات الموجود.
// ════════════════════════════════════════════════════════════════════════════
final canManageCompetitionsProvider = Provider<bool>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return false;
  return user.role == UserRole.admin ||
      user.hasPermission(Permission.managePermissions) ||
      user.hasPermission(Permission.editSettings);
});

// ════════════════════════════════════════════════════════════════════════════
//  حالة المسابقات + مشاركات المستخدم
// ════════════════════════════════════════════════════════════════════════════
class CompetitionsState {
  final List<Competition> competitions;
  final Map<String, CompetitionEntry> entries; // competitionId -> entry

  const CompetitionsState({this.competitions = const [], this.entries = const {}});

  CompetitionEntry entryFor(String id) =>
      entries[id] ?? CompetitionEntry(competitionId: id);

  CompetitionsState copyWith({
    List<Competition>? competitions,
    Map<String, CompetitionEntry>? entries,
  }) {
    return CompetitionsState(
      competitions: competitions ?? this.competitions,
      entries: entries ?? this.entries,
    );
  }
}

/// CompetitionsNotifier — القائمة تُقرأ من Supabase (getCompetitions)، ومشاركات
/// المستخدم (entries/join/leave/submitProof) صارت الآن مدعومة بـ Supabase عبر
/// دوال RPC (join_competition / submit_competition_proof) وقراءة
/// competition_entries + participation_proofs، مع الحفاظ على نفس واجهة الحالة
/// تماماً (competitions + entries + كل الدوال) حتى لا تتغيّر الصفحات:
///  - التحميل الأولي async من Supabase (المسابقات + مشاركات المستخدم).
///  - join/leave/submitProof تبقى بتوقيع متزامن (كما كانت): تحقّق/تحديث تفاؤلي
///    محلي ثم استدعاء RPC في الخلفية وإعادة تحميل المشاركات.
///  - الإنشاء/التعديل/الحذف (مشرف) تبقى محلية تفاؤلية كما كانت (خارج النطاق).
///  - بلا جلسة Supabase: قراءة المشاركات تُرجع فارغاً، وطفرات RPC ترمي داخلياً
///    فنُبقي التحديث التفاؤلي المحلي لإبقاء الواجهة قابلة للتجربة.
class CompetitionsNotifier extends StateNotifier<CompetitionsState> {
  final SupabaseCompetitionsRepository _repo = SupabaseCompetitionsRepository();
  final SupabaseEngagementRepository _engagement =
      SupabaseEngagementRepository();

  CompetitionsNotifier() : super(const CompetitionsState()) {
    _load();
  }

  /// تحميل قائمة المسابقات + مشاركات المستخدم من Supabase (READ فقط).
  Future<void> _load() async {
    try {
      final competitions = await _repo.getCompetitions();
      state = state.copyWith(competitions: competitions);
    } catch (_) {
      // تعذّر الاتصال — نُبقي القائمة الحالية بدل الانهيار.
    }
    await _loadEntries();
  }

  /// تحميل مشاركات المستخدم الحالي + أدلّته وبناء خريطة entries.
  Future<void> _loadEntries() async {
    try {
      final rows = await _engagement.myEntries();
      final entries = <String, CompetitionEntry>{};
      for (final r in rows) {
        final competitionId = r['competition_id'] as String;
        final proofsRows = await _engagement.myProofs(competitionId);
        entries[competitionId] = CompetitionEntry(
          competitionId: competitionId,
          joined: true,
          earnedPoints: (r['earned_points'] ?? 0) as int,
          rank: (r['rank'] ?? 0) as int,
          proofs: proofsRows
              .map((p) => ParticipationProof(
                    id: p['id'] as String,
                    text: p['text'] as String?,
                    imagePath: p['image_url'] as String?,
                    submittedAt: DateTime.parse(p['submitted_at'] as String),
                  ))
              .toList(),
        );
      }
      state = state.copyWith(entries: entries);
    } catch (_) {
      // بلا جلسة/تعذّر الاتصال — نُبقي المشاركات الحالية بدل الانهيار.
    }
  }

  /// إعادة تحميل من الخادم (مفيدة للسحب-للتحديث).
  Future<void> reload() => _load();

  Competition? byId(String id) {
    for (final c in state.competitions) {
      if (c.id == id) return c;
    }
    return null;
  }

  // ── اشتراك / إلغاء ─────────────────────────────────────────────────────────
  /// يُرجع رسالة خطأ إن تعذّر الاشتراك، أو null عند النجاح (تحقّق متزامن كما كان).
  String? join(String id) {
    final c = byId(id);
    if (c == null) return 'المسابقة غير موجودة';
    if (c.status == CompetitionStatus.ended) return 'انتهت هذه المسابقة';
    if (c.status == CompetitionStatus.upcoming) return 'لم تبدأ المسابقة بعد';
    if (c.isFull) return 'اكتمل عدد المشاركين في هذه المسابقة';

    final entry = state.entryFor(id);
    if (entry.joined) return null; // مشترك أصلاً

    // تحديث تفاؤلي محلي (يطابق السلوك السابق) ثم مزامنة عبر RPC.
    _updateCompetition(c.copyWith(participants: c.participants + 1));
    _updateEntry(entry.copyWith(joined: true, rank: c.participants + 1));
    _syncJoin(id);
    return null;
  }

  void leave(String id) {
    final c = byId(id);
    final entry = state.entryFor(id);
    if (c == null || !entry.joined) return;
    _updateCompetition(
        c.copyWith(participants: (c.participants - 1).clamp(0, 1 << 30)));
    _updateEntry(entry.copyWith(joined: false));
    _syncLeave(id);
  }

  // ── رفع دليل المشاركة اليومي ────────────────────────────────────────────────
  void submitProof(String id, {String? text, String? imagePath}) {
    final c = byId(id);
    final entry = state.entryFor(id);
    if (c == null || !entry.joined) return;

    final proof = ParticipationProof(
      id: _uuid.v4(),
      text: text,
      imagePath: imagePath,
      submittedAt: DateTime.now(),
    );
    final proofs = [...entry.proofs, proof];
    // كل دليل = حصة من نقاط المسابقة موزّعة على الهدف (عرض تقديري محلي؛ النقاط
    // الفعلية تُمنح عند اعتماد المشرف للدليل في القاعدة — proof_approved).
    final perProof = c.target > 0 ? (c.rewardPoints / c.target).round() : 0;
    _updateEntry(entry.copyWith(
      proofs: proofs,
      earnedPoints: entry.earnedPoints + perProof,
      rank: _recomputeRank(c, proofs.length),
    ));
    // مزامنة عبر RPC (imagePath هنا اسم/مسار محلي؛ image_url الفعلي يُرفع لاحقاً
    // عبر Storage — نمرّره كما هو للاتساق).
    _syncSubmitProof(id, text: text, imageUrl: imagePath);
  }

  int _recomputeRank(Competition c, int progress) {
    // تقدير بسيط: كلما زاد التقدّم تحسّن الترتيب (لأغراض العرض).
    final base = (c.participants * 0.6).round();
    final rank = (base - progress * 2).clamp(1, c.participants == 0 ? 1 : c.participants);
    return rank;
  }

  // ── مزامنة خلفية عبر RPC ثم إعادة تحميل المشاركات ────────────────────────────
  Future<void> _syncJoin(String id) async {
    try {
      await _engagement.join(id);
      await _loadEntries();
    } catch (_) {
      // بلا جلسة/تعذّر الاتصال — نُبقي التحديث التفاؤلي المحلي.
    }
  }

  Future<void> _syncLeave(String id) async {
    try {
      await _engagement.leave(id);
      await _loadEntries();
    } catch (_) {
      // بلا جلسة/تعذّر الاتصال — نُبقي التحديث التفاؤلي المحلي.
    }
  }

  Future<void> _syncSubmitProof(String id, {String? text, String? imageUrl}) async {
    try {
      await _engagement.submitProof(id, text: text, imageUrl: imageUrl);
      await _loadEntries();
    } catch (_) {
      // بلا جلسة/تعذّر الاتصال — نُبقي التحديث التفاؤلي المحلي.
    }
  }

  // ── إنشاء مسابقة (مشرف) ─────────────────────────────────────────────────────
  // TODO(supabase): الإنشاء/التعديل/الحذف تبقى محلية (تفاؤلية) في هذه المهمة التي
  // تنقل تفاعل المستخدم (النقاط/المشاركات/الاستبدال). المستودع يوفّر
  // createCompetition لكن ليس تعديلاً/حذفاً؛ يمكن لاحقاً استدعاء
  // repo.createCompetition ثم reload() لإبقاء القائمة متزامنة.
  Competition createCompetition({
    required String title,
    required String description,
    required CompetitionCategory category,
    required int rewardPoints,
    required int target,
    required int winnerCount,
    required int maxParticipants,
    required DateTime startsAt,
    required DateTime endsAt,
    required List<String> conditions,
    required List<String> steps,
    required PrizeType prizeType,
    required String prizeTitle,
    required String prizeDescription,
    String? prizeInstructions,
    String? coverImagePath,
    required String createdBy,
  }) {
    final c = Competition(
      id: 'c_${_uuid.v4()}',
      title: title,
      description: description,
      category: category,
      participants: 0,
      maxParticipants: maxParticipants,
      rewardPoints: rewardPoints,
      target: target,
      winnerCount: winnerCount,
      startsAt: startsAt,
      endsAt: endsAt,
      conditions: conditions,
      steps: steps,
      prizeType: prizeType,
      prizeTitle: prizeTitle,
      prizeDescription: prizeDescription,
      prizeInstructions: prizeInstructions,
      coverImagePath: coverImagePath,
      createdBy: createdBy,
    );
    state = state.copyWith(competitions: [c, ...state.competitions]);
    return c;
  }

  /// تعديل مسابقة قائمة (مشرف).
  void updateCompetition(
    String id, {
    required String title,
    required String description,
    required CompetitionCategory category,
    required int rewardPoints,
    required int target,
    required int winnerCount,
    required int maxParticipants,
    required DateTime startsAt,
    required DateTime endsAt,
    required List<String> conditions,
    required List<String> steps,
    required PrizeType prizeType,
    required String prizeTitle,
    required String prizeDescription,
    String? prizeInstructions,
    String? coverImagePath,
  }) {
    final c = byId(id);
    if (c == null) return;
    _updateCompetition(c.copyWith(
      title: title,
      description: description,
      category: category,
      rewardPoints: rewardPoints,
      target: target,
      winnerCount: winnerCount,
      maxParticipants: maxParticipants,
      startsAt: startsAt,
      endsAt: endsAt,
      conditions: conditions,
      steps: steps,
      prizeType: prizeType,
      prizeTitle: prizeTitle,
      prizeDescription: prizeDescription,
      prizeInstructions: prizeInstructions,
      coverImagePath: coverImagePath,
    ));
  }

  void deleteCompetition(String id) {
    state = state.copyWith(
      competitions: state.competitions.where((c) => c.id != id).toList(),
    );
  }

  // ── أدوات داخلية ────────────────────────────────────────────────────────────
  void _updateCompetition(Competition updated) {
    state = state.copyWith(
      competitions: state.competitions
          .map((c) => c.id == updated.id ? updated : c)
          .toList(),
    );
  }

  void _updateEntry(CompetitionEntry updated) {
    final entries = Map<String, CompetitionEntry>.from(state.entries);
    entries[updated.competitionId] = updated;
    state = state.copyWith(entries: entries);
  }
}

final competitionsProvider =
    StateNotifierProvider<CompetitionsNotifier, CompetitionsState>(
        (ref) => CompetitionsNotifier());
