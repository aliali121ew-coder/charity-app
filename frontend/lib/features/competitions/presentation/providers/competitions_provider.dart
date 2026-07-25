import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:charity_app/shared/providers/app_providers.dart';
import 'package:charity_app/core/permissions/role.dart';
import 'package:charity_app/features/competitions/data/mock_competitions_data.dart';
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

class CompetitionsNotifier extends StateNotifier<CompetitionsState> {
  CompetitionsNotifier()
      : super(CompetitionsState(
          competitions: seedCompetitions(),
          // مشاركة تجريبية: المستخدم فائز (#1) في مسابقة ختمة رمضان المنتهية،
          // ليكون مسار المطالبة بالجائزة (بطاقة + QR) قابلاً للتجربة مباشرة.
          entries: {
            'c_seasonal_ramadan': const CompetitionEntry(
              competitionId: 'c_seasonal_ramadan',
              joined: true,
              earnedPoints: 1200,
              rank: 1,
            ),
          },
        ));

  Competition? byId(String id) {
    for (final c in state.competitions) {
      if (c.id == id) return c;
    }
    return null;
  }

  // ── اشتراك / إلغاء ─────────────────────────────────────────────────────────
  /// يُرجع رسالة خطأ إن تعذّر الاشتراك، أو null عند النجاح.
  String? join(String id) {
    final c = byId(id);
    if (c == null) return 'المسابقة غير موجودة';
    if (c.status == CompetitionStatus.ended) return 'انتهت هذه المسابقة';
    if (c.status == CompetitionStatus.upcoming) return 'لم تبدأ المسابقة بعد';
    if (c.isFull) return 'اكتمل عدد المشاركين في هذه المسابقة';

    final entry = state.entryFor(id);
    if (entry.joined) return null; // مشترك أصلاً

    _updateCompetition(c.copyWith(participants: c.participants + 1));
    _updateEntry(entry.copyWith(joined: true, rank: c.participants + 1));
    return null;
  }

  void leave(String id) {
    final c = byId(id);
    final entry = state.entryFor(id);
    if (c == null || !entry.joined) return;
    _updateCompetition(
        c.copyWith(participants: (c.participants - 1).clamp(0, 1 << 30)));
    _updateEntry(entry.copyWith(joined: false));
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
    // كل دليل = حصة من نقاط المسابقة موزّعة على الهدف.
    final perProof = c.target > 0 ? (c.rewardPoints / c.target).round() : 0;
    _updateEntry(entry.copyWith(
      proofs: proofs,
      earnedPoints: entry.earnedPoints + perProof,
      rank: _recomputeRank(c, proofs.length),
    ));
  }

  int _recomputeRank(Competition c, int progress) {
    // تقدير بسيط: كلما زاد التقدّم تحسّن الترتيب (لأغراض العرض).
    final base = (c.participants * 0.6).round();
    final rank = (base - progress * 2).clamp(1, c.participants == 0 ? 1 : c.participants);
    return rank;
  }

  // ── إنشاء مسابقة (مشرف) ─────────────────────────────────────────────────────
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
