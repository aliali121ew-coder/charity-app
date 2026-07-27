import 'package:flutter/material.dart';
import 'package:charity_app/core/supabase/supabase_config.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/competitions/domain/competition_models.dart';

/// مستودع المسابقات والتفاعل عبر Supabase — بديل عملي عن البيانات الوهمية
/// (mock_competitions_data) لأقسام المسابقات + الجوائز + لوحة الصدارة.
///
/// الجداول: competitions, competition_entries, participation_proofs, prizes,
/// points_ledger, user_engagement_stats.
///
/// تنبيهات على الفقد (lossy) — انظر التقرير:
///  • Prize يتطلّب IconData/Color (أنواع واجهة غير موجودة في القاعدة)؛ نستخدم
///    قيماً افتراضية عند البناء من صف القاعدة.
///  • Competition.createdBy اسم نصّي، بينما created_by في القاعدة uuid FK؛
///    عند القراءة نضع الاسم الافتراضي 'إدارة التطبيق'، وعند الإنشاء نترك
///    created_by = null.
class SupabaseCompetitionsRepository {
  static const _competitions = 'competitions';
  static const _entries = 'competition_entries';
  static const _proofs = 'participation_proofs';
  static const _prizes = 'prizes';
  static const _ledger = 'points_ledger';
  static const _stats = 'user_engagement_stats';

  // ── تحويل مسابقة ────────────────────────────────────────────────────────────
  Competition _mapCompetition(Map<String, dynamic> r) => Competition(
        id: r['id'] as String,
        title: (r['title'] ?? '') as String,
        description: (r['description'] ?? '') as String,
        category: CompetitionCategory.values.byName((r['category'] ?? 'charity') as String),
        participants: (r['participants_count'] ?? 0) as int,
        maxParticipants: (r['max_participants'] ?? 0) as int,
        rewardPoints: (r['reward_points'] ?? 0) as int,
        target: (r['target'] ?? 7) as int,
        winnerCount: (r['winner_count'] ?? 1) as int,
        startsAt: DateTime.parse(r['starts_at'] as String),
        endsAt: DateTime.parse(r['ends_at'] as String),
        conditions: ((r['conditions'] ?? const []) as List).map((e) => e as String).toList(),
        steps: ((r['steps'] ?? const []) as List).map((e) => e as String).toList(),
        prizeType: PrizeType.values.byName((r['prize_type'] ?? 'digital') as String),
        prizeTitle: (r['prize_title'] ?? '') as String,
        prizeDescription: (r['prize_description'] ?? '') as String,
        prizeInstructions: r['prize_instructions'] as String?,
        coverImagePath: r['cover_image_url'] as String?,
        createdBy: 'إدارة التطبيق',
      );

  /// لا نُرسل id (تولّده القاعدة) ولا created_by (uuid FK؛ الاسم النصّي لا يوضع فيه).
  Map<String, dynamic> _competitionToRow(Competition c) => {
        'title': c.title,
        'description': c.description,
        'category': c.category.name,
        'max_participants': c.maxParticipants,
        'reward_points': c.rewardPoints,
        'target': c.target,
        'winner_count': c.winnerCount,
        'conditions': c.conditions,
        'steps': c.steps,
        'prize_type': c.prizeType.name,
        'prize_title': c.prizeTitle,
        'prize_description': c.prizeDescription,
        'prize_instructions': c.prizeInstructions,
        'cover_image_url': c.coverImagePath,
        'starts_at': c.startsAt.toIso8601String(),
        'ends_at': c.endsAt.toIso8601String(),
      };

  // ── تحويل جائزة (مع القيم الافتراضية لأنواع الواجهة) ──────────────────────────
  Prize _mapPrize(Map<String, dynamic> r) => Prize(
        id: r['id'] as String,
        title: (r['title'] ?? '') as String,
        description: (r['description'] ?? '') as String,
        pointsCost: (r['points_cost'] ?? 0) as int,
        icon: Icons.card_giftcard_rounded, // القاعدة تخزّن icon_key فقط؛ افتراضي هنا
        color: AppColors.pink, // اللون غير مخزّن في القاعدة؛ افتراضي هنا
        stock: (r['stock'] ?? 0) as int,
        type: PrizeType.values.byName((r['type'] ?? 'physical') as String),
        instructions: (r['instructions'] ?? '') as String,
      );

  // ── مسابقات ─────────────────────────────────────────────────────────────────
  Future<List<Competition>> getCompetitions() async {
    final rows = await supabase
        .from(_competitions)
        .select()
        .eq('is_published', true)
        .order('starts_at', ascending: false);
    return rows.map((e) => _mapCompetition(e)).toList();
  }

  Future<Competition?> getCompetitionById(String id) async {
    final row = await supabase.from(_competitions).select().eq('id', id).maybeSingle();
    return row == null ? null : _mapCompetition(row);
  }

  // ── جوائز المتجر ────────────────────────────────────────────────────────────
  Future<List<Prize>> getPrizes() async {
    final rows = await supabase
        .from(_prizes)
        .select()
        .eq('is_active', true)
        .order('points_cost', ascending: true);
    return rows.map((e) => _mapPrize(e)).toList();
  }

  // ── الانضمام لمسابقة ────────────────────────────────────────────────────────
  /// يُدرج صفاً في competition_entries. المُشغّلات في القاعدة تتكفّل بزيادة
  /// participants_count و competitions_joined تلقائياً.
  Future<void> joinCompetition(String competitionId, String userId) async {
    await supabase.from(_entries).insert({
      'competition_id': competitionId,
      'user_id': userId,
    });
  }

  // ── رفع دليل مشاركة ─────────────────────────────────────────────────────────
  /// يجلب أولاً entry الخاص بالمستخدم في المسابقة (مطلوب entry_id)، ثم يُدرج الدليل.
  Future<void> submitProof(
    String competitionId,
    String userId, {
    String? text,
    String? imageUrl,
  }) async {
    final entry = await supabase
        .from(_entries)
        .select('id')
        .eq('competition_id', competitionId)
        .eq('user_id', userId)
        .maybeSingle();
    if (entry == null) return; // غير مشترك — لا يمكن رفع دليل
    await supabase.from(_proofs).insert({
      'entry_id': entry['id'],
      'competition_id': competitionId,
      'user_id': userId,
      'text': text,
      'image_url': imageUrl,
    });
  }

  // ── لوحة الصدارة ────────────────────────────────────────────────────────────
  /// تُبنى من user_engagement_stats مع ربط أجنبي بجدول profiles للاسم.
  Future<List<Participant>> getLeaderboard({int limit = 50}) async {
    final rows = await supabase
        .from(_stats)
        .select('total_points,khatma_juz_completed,competitions_joined,area, profiles(full_name)')
        .order('total_points', ascending: false)
        .limit(limit);
    return rows.map((r) {
      final profile = r['profiles'] as Map<String, dynamic>?;
      return Participant(
        name: (profile?['full_name'] ?? '') as String,
        points: (r['total_points'] ?? 0) as int,
        khatmaJuz: (r['khatma_juz_completed'] ?? 0) as int,
        competitions: (r['competitions_joined'] ?? 0) as int,
        area: (r['area'] ?? '') as String,
      );
    }).toList();
  }

  // ── إنشاء مسابقة (مشرف) — عملية إضافية مفيدة، بدون id/created_by ──────────────
  Future<Competition> createCompetition(Competition competition) async {
    final row =
        await supabase.from(_competitions).insert(_competitionToRow(competition)).select().single();
    return _mapCompetition(row);
  }
}
