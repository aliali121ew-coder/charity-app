import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/shared/providers/app_providers.dart';
import 'package:charity_app/shared/providers/supabase_repository_providers.dart';
import 'package:charity_app/features/competitions/domain/competition_models.dart';
import 'package:charity_app/features/competitions/presentation/providers/competitions_provider.dart';
import 'package:charity_app/features/competitions/presentation/providers/points_provider.dart';
import 'package:charity_app/features/competitions/presentation/pages/claim_card_page.dart';
import 'package:charity_app/features/competitions/presentation/pages/create_competition_page.dart';
import 'package:charity_app/features/competitions/presentation/widgets/submit_proof_sheet.dart';
import 'package:charity_app/features/competitions/presentation/widgets/countdown_text.dart';

/// رتبة المستخدم في مسابقة منتهية (1-based)، أو 0 إن لم يشارك.
int myRankIn(Competition c, CompetitionEntry entry) {
  if (!entry.joined) return 0;
  if (entry.rank > 0) return entry.rank;
  return c.participants > 0 ? c.participants : 1;
}

/// هل المستخدم فائز؟ ضمن أعلى `winnerCount` إنجازاً.
bool isWinnerOf(Competition c, CompetitionEntry entry) {
  final r = myRankIn(c, entry);
  return r >= 1 && r <= c.winnerCount;
}

class CompetitionDetailPage extends ConsumerStatefulWidget {
  final String competitionId;
  const CompetitionDetailPage({super.key, required this.competitionId});

  @override
  ConsumerState<CompetitionDetailPage> createState() => _CompetitionDetailPageState();
}

class _CompetitionDetailPageState extends ConsumerState<CompetitionDetailPage> {
  String get competitionId => widget.competitionId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(competitionsProvider);
    final canManage = ref.watch(canManageCompetitionsProvider);
    final c = state.competitions.where((x) => x.id == competitionId).toList();
    if (c.isEmpty) {
      return const Scaffold(body: Center(child: Text('المسابقة غير متاحة')));
    }
    final competition = c.first;
    final entry = state.entryFor(competitionId);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          _CoverHeader(
            c: competition,
            canManage: canManage,
            onEdit: () => _editCompetition(competition),
            onDelete: () => _deleteCompetition(competition),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MetaRow(c: competition, onExpire: () { if (mounted) setState(() {}); }),
                  const SizedBox(height: 16),
                  if (competition.status == CompetitionStatus.ended) ...[
                    _WinnersSection(c: competition, entry: entry),
                    const SizedBox(height: 16),
                  ],
                  if (entry.joined && competition.status == CompetitionStatus.active) ...[
                    _ProgressCard(c: competition, entry: entry),
                    const SizedBox(height: 16),
                  ],
                  _PrizeCard(c: competition),
                  const SizedBox(height: 16),
                  if (competition.conditions.isNotEmpty) ...[
                    _ListSection(title: 'الشروط', icon: Icons.fact_check_rounded, items: competition.conditions, color: competition.color, isDark: isDark, numbered: false),
                    const SizedBox(height: 16),
                  ],
                  if (competition.steps.isNotEmpty) ...[
                    _ListSection(title: 'خطوات المشاركة', icon: Icons.list_alt_rounded, items: competition.steps, color: competition.color, isDark: isDark, numbered: true),
                    const SizedBox(height: 16),
                  ],
                  _InfoGrid(c: competition, isDark: isDark),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _BottomAction(c: competition, entry: entry),
    );
  }

  // ── تحكّم الأدمن ─────────────────────────────────────────────────────────────
  Future<void> _editCompetition(Competition c) async {
    await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CreateCompetitionPage(existing: c)));
    if (mounted) setState(() {});
  }

  Future<void> _deleteCompetition(Competition c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('حذف المسابقة', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        content: Text('هل تريد حذف "${c.title}"؟ لا يمكن التراجع.',
            style: GoogleFonts.cairo()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('إلغاء', style: GoogleFonts.cairo(fontWeight: FontWeight.w700))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: Text('حذف', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      ref.read(competitionsProvider.notifier).deleteCompetition(c.id);
      if (mounted) Navigator.of(context).pop();
    }
  }
}

// ── الغلاف ──────────────────────────────────────────────────────────────────
class _CoverHeader extends StatelessWidget {
  final Competition c;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _CoverHeader({
    required this.c,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 190,
      pinned: true,
      foregroundColor: Colors.white,
      backgroundColor: c.color,
      actions: [
        if (canManage)
          Container(
            margin: const EdgeInsets.only(left: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white),
              tooltip: 'تحكّم الأدمن',
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Row(children: [
                  const Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('تعديل المسابقة', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                ])),
                PopupMenuItem(value: 'delete', child: Row(children: [
                  const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                  const SizedBox(width: 8),
                  Text('حذف المسابقة', style: GoogleFonts.cairo(fontWeight: FontWeight.w700, color: const Color(0xFFEF4444))),
                ])),
              ],
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(c.title,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
        background: Container(
          decoration: BoxDecoration(gradient: c.gradient),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(right: -20, top: -10, child: Icon(c.icon, size: 150, color: Colors.white.withValues(alpha: 0.12))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 54),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _badge(c.category.label, Colors.white.withValues(alpha: 0.25)),
                        const SizedBox(width: 8),
                        _badge(c.statusLabel, c.statusColor),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(c.description,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(fontSize: 12.5, height: 1.5, color: Colors.white.withValues(alpha: 0.92))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
      );
}

// ── صف المعلومات (عدّاد، مشاركون، نقاط) ────────────────────────────────────────
class _MetaRow extends StatelessWidget {
  final Competition c;
  final VoidCallback onExpire;
  const _MetaRow({required this.c, required this.onExpire});

  @override
  Widget build(BuildContext context) {
    // التبويب الأول: عدّاد تنازلي حيّ (للجارية والقادمة) أو "انتهت".
    final Widget timeContent;
    final String timeTitle;
    if (c.status == CompetitionStatus.active) {
      timeTitle = 'ينتهي خلال';
      timeContent = CountdownText(target: c.endsAt, color: c.statusColor, fontSize: 11, showIcon: false, endedLabel: 'انتهت', onEnded: onExpire);
    } else if (c.status == CompetitionStatus.upcoming) {
      timeTitle = 'يبدأ خلال';
      timeContent = CountdownText(target: c.startsAt, color: c.statusColor, fontSize: 11, showIcon: false, endedLabel: 'بدأت', onEnded: onExpire);
    } else {
      timeTitle = 'الحالة';
      timeContent = Text('انتهت', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w800, color: c.statusColor));
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _timeTile(timeTitle, timeContent, c.statusColor)),
          const SizedBox(width: 10),
          Expanded(child: _tile(Icons.groups_rounded,
              c.isUnlimited ? '${c.participants} مشارك' : '${c.participants}/${c.maxParticipants}', AppColors.primary)),
          const SizedBox(width: 10),
          Expanded(child: _tile(Icons.stars_rounded, '${c.rewardPoints} نقطة', const Color(0xFFD97706))),
        ],
      ),
    );
  }

  Widget _timeTile(String title, Widget content, Color color) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined, size: 20, color: color),
            const SizedBox(height: 5),
            Text(title, style: GoogleFonts.cairo(fontSize: 8.5, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.8))),
            const SizedBox(height: 2),
            content,
          ],
        ),
      );

  Widget _tile(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 5),
            Text(label, textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 10.5, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      );
}

// ── تقدّم المستخدم (شريط + نسبة + ترتيب) ───────────────────────────────────────
class _ProgressCard extends StatelessWidget {
  final Competition c;
  final CompetitionEntry entry;
  const _ProgressCard({required this.c, required this.entry});

  @override
  Widget build(BuildContext context) {
    final progress = c.target > 0 ? (entry.progress / c.target).clamp(0.0, 1.0) : 0.0;
    final pct = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: c.gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: c.color.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('تقدّمك في المسابقة',
                  style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                child: Text('ترتيبك #${entry.rank}',
                    style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('$pct%', style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
              const Spacer(),
              Text('${entry.progress} / ${c.target}',
                  style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.9))),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 5),
              Text('كسبت ${entry.earnedPoints} نقطة حتى الآن',
                  style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.95))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── النتائج / الفائزون + رتبتك ─────────────────────────────────────────────────
class _WinnersSection extends ConsumerWidget {
  final Competition c;
  final CompetitionEntry entry;
  const _WinnersSection({required this.c, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // قائمة الفائزين (أعلى winnerCount إنجازاً) — من لوحة الصدارة عبر Supabase
    // (leaderboardProvider). أثناء التحميل/عند الخطأ نعرض القائمة فارغة بلا انهيار.
    final winners = ref
        .watch(leaderboardProvider)
        .maybeWhen(data: (list) => list.take(c.winnerCount).toList(), orElse: () => const <Participant>[]);
    final myRank = myRankIn(c, entry);
    final won = isWinnerOf(c, entry);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.emoji_events_rounded, size: 18, color: Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            Text('النتائج والفائزون',
                style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            const Spacer(),
            Text('${c.winnerCount} فائز',
                style: GoogleFonts.cairo(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textSecondaryLight)),
          ]),
          const SizedBox(height: 12),
          ...winners.asMap().entries.map((e) => _winnerRow(e.key + 1, e.value.name, e.value.points, isDark)),
          const Divider(height: 20),
          // رتبتك
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: won ? const Color(0xFF10B981).withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: won ? const Color(0xFF10B981) : AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(won ? Icons.celebration_rounded : (entry.joined ? Icons.person_rounded : Icons.info_outline_rounded),
                    color: won ? const Color(0xFF059669) : AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    !entry.joined
                        ? 'لم تشارك في هذه المسابقة'
                        : won
                            ? '🎉 مبروك! أنت من الفائزين (رتبتك #$myRank)'
                            : 'رتبتك #$myRank — لم تفز هذه المرة، وفّقك الله',
                    style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w800,
                        color: won ? const Color(0xFF059669)
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _winnerRow(int rank, String name, int points, bool isDark) {
    final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '🏅';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(medal, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Container(
            width: 22, height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Text('$rank', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
          ),
          const Icon(Icons.stars_rounded, size: 13, color: Color(0xFFF59E0B)),
          const SizedBox(width: 3),
          Text('$points', style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w800, color: const Color(0xFFD97706))),
        ],
      ),
    );
  }
}

// ── الجائزة ─────────────────────────────────────────────────────────────────
class _PrizeCard extends StatelessWidget {
  final Competition c;
  const _PrizeCard({required this.c});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(c.prizeType.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('الجائزة',
                        style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondaryLight)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: c.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(c.prizeType.label,
                          style: GoogleFonts.cairo(fontSize: 8.5, fontWeight: FontWeight.w800, color: c.color)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(c.prizeTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                if (c.prizeDescription.isNotEmpty)
                  Text(c.prizeDescription, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(fontSize: 10.5, color: AppColors.textSecondaryLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── قائمة (شروط/خطوات) ────────────────────────────────────────────────────────
class _ListSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  final Color color;
  final bool isDark;
  final bool numbered;
  const _ListSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.color,
    required this.isDark,
    required this.numbered,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(title, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w900,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
          ]),
          const SizedBox(height: 12),
          ...items.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22, height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: numbered ? BoxShape.circle : BoxShape.rectangle,
                        borderRadius: numbered ? null : BorderRadius.circular(6),
                      ),
                      child: numbered
                          ? Text('${e.key + 1}', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w800, color: color))
                          : Icon(Icons.check_rounded, size: 14, color: color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(e.value,
                          style: GoogleFonts.cairo(fontSize: 12.5, height: 1.4,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── شبكة معلومات إضافية ───────────────────────────────────────────────────────
class _InfoGrid extends StatelessWidget {
  final Competition c;
  final bool isDark;
  const _InfoGrid({required this.c, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy/MM/dd', 'ar');
    final items = [
      ('عدد الفائزين', '${c.winnerCount}', Icons.emoji_events_rounded),
      ('حد المشاركين', c.isUnlimited ? 'غير محدود' : '${c.maxParticipants}', Icons.group_add_rounded),
      ('تبدأ', df.format(c.startsAt), Icons.play_circle_outline_rounded),
      ('تنتهي', df.format(c.endsAt), Icons.flag_rounded),
      ('المنشئ', c.createdBy, Icons.admin_panel_settings_rounded),
      ('الفئة', c.category.label, c.category.icon),
    ];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        children: items.map((it) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
              child: Row(
                children: [
                  Icon(it.$3, size: 17, color: c.color),
                  const SizedBox(width: 10),
                  Text(it.$1, style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondaryLight)),
                  const Spacer(),
                  Text(it.$2, style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                ],
              ),
            )).toList(),
      ),
    );
  }
}

// ── الزر السفلي الثابت ────────────────────────────────────────────────────────
class _BottomAction extends ConsumerWidget {
  final Competition c;
  final CompetitionEntry entry;
  const _BottomAction({required this.c, required this.entry});

  void _snack(BuildContext context, String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? const Color(0xFFEF4444) : const Color(0xFF059669),
    ));
  }

  void _join(BuildContext context, WidgetRef ref) {
    final err = ref.read(competitionsProvider.notifier).join(c.id);
    if (err != null) {
      _snack(context, err, error: true);
    } else {
      _snack(context, 'تم اشتراكك في "${c.title}" 🎉');
    }
  }

  /// محاكاة الفوز (أعلى النقاط — تلقائي): إنشاء بطاقة مطالبة وفتحها.
  void _claim(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    final claims = ref.read(claimsProvider.notifier);
    if (claims.hasClaimFor(c.title)) {
      _snack(context, 'لديك بطاقة مطالبة لهذه المسابقة في "جوائزي"');
    }
    final card = claims.hasClaimFor(c.title)
        ? null
        : claims.createClaim(competition: c, winnerName: user?.name ?? 'الفائز');
    final id = card?.id ?? ref.read(claimsProvider).firstWhere((x) => x.competitionTitle == c.title).id;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ClaimCardPage(claimId: id)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ended = c.status == CompetitionStatus.ended;
    final upcoming = c.status == CompetitionStatus.upcoming;

    Widget button;
    if (ended) {
      // عند الانتهاء: الفائزون فقط (أعلى winnerCount إنجازاً) يمكنهم المطالبة.
      if (isWinnerOf(c, entry)) {
        button = _btn(context, 'مطالبة بالجائزة 🎁', const Color(0xFFF59E0B), () => _claim(context, ref), icon: Icons.card_giftcard_rounded);
      } else if (entry.joined) {
        button = _btn(context, 'لم تفز هذه المرة', Colors.grey, null, icon: Icons.emoji_events_outlined);
      } else {
        button = _btn(context, 'انتهت المسابقة', Colors.grey, null, icon: Icons.lock_outline_rounded);
      }
    } else if (upcoming) {
      button = _btn(context, 'لم تبدأ بعد', Colors.grey, null, icon: Icons.hourglass_top_rounded);
    } else if (!entry.joined) {
      button = _btn(context, c.isFull ? 'اكتمل العدد' : 'اشترك الآن', c.isFull ? Colors.grey : c.color,
          c.isFull ? null : () => _join(context, ref), icon: Icons.add_circle_outline_rounded);
    } else {
      button = Row(
        children: [
          Expanded(
            flex: 2,
            child: _btn(context, 'رفع دليل اليوم', c.color, () => SubmitProofSheet.show(context, c), icon: Icons.upload_file_rounded),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                ref.read(competitionsProvider.notifier).leave(c.id);
                _snack(context, 'تم إلغاء اشتراكك');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: c.color,
                side: BorderSide(color: c.color),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('إلغاء', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: button,
    );
  }

  Widget _btn(BuildContext context, String label, Color color, VoidCallback? onTap, {required IconData icon}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 19),
        label: Text(label, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
