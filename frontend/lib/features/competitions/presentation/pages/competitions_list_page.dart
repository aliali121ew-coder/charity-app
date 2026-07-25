import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/competitions/domain/competition_models.dart';
import 'package:charity_app/features/competitions/presentation/providers/competitions_provider.dart';
import 'package:charity_app/features/competitions/presentation/pages/competition_detail_page.dart';
import 'package:charity_app/features/competitions/presentation/pages/create_competition_page.dart';
import 'package:charity_app/features/competitions/presentation/pages/my_prizes_page.dart';
import 'package:charity_app/features/competitions/presentation/pages/prizes_page.dart';
import 'package:charity_app/features/competitions/presentation/widgets/countdown_text.dart';

class CompetitionsListPage extends ConsumerStatefulWidget {
  const CompetitionsListPage({super.key});

  @override
  ConsumerState<CompetitionsListPage> createState() => _CompetitionsListPageState();
}

class _CompetitionsListPageState extends ConsumerState<CompetitionsListPage> {
  CompetitionStatus? _statusFilter; // null = الكل
  CompetitionCategory? _categoryFilter; // null = كل الفئات

  static const _statusTabs = <(String, CompetitionStatus?)>[
    ('الكل', null),
    ('جارية', CompetitionStatus.active),
    ('قريباً', CompetitionStatus.upcoming),
    ('منتهية', CompetitionStatus.ended),
  ];

  List<Competition> _filter(List<Competition> all) {
    return all.where((c) {
      if (_statusFilter != null && c.status != _statusFilter) return false;
      if (_categoryFilter != null && c.category != _categoryFilter) return false;
      return true;
    }).toList();
  }

  Future<void> _create() async {
    await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CreateCompetitionPage()));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final all = ref.watch(competitionsProvider).competitions;
    final canManage = ref.watch(canManageCompetitionsProvider);
    final list = _filter(all);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('المسابقات', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'متجر الجوائز',
            icon: const Icon(Icons.storefront_rounded),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrizesPage())),
          ),
          IconButton(
            tooltip: 'جوائزي',
            icon: const Icon(Icons.card_giftcard_rounded),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyPrizesPage())),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _create,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text('إنشاء مسابقة',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: Colors.white)),
            )
          : null,
      body: Column(
        children: [
          _StatusTabs(
            tabs: _statusTabs,
            selected: _statusFilter,
            onSelect: (s) => setState(() => _statusFilter = s),
          ),
          _CategoryChips(
            selected: _categoryFilter,
            onSelect: (cat) => setState(() => _categoryFilter = cat),
          ),
          Expanded(
            child: list.isEmpty
                ? _empty(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _CompetitionCard(
                      c: list[i],
                      joined: ref.watch(competitionsProvider).entryFor(list[i].id).joined,
                      isDark: isDark,
                      onExpire: () { if (mounted) setState(() {}); },
                      onOpen: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => CompetitionDetailPage(competitionId: list[i].id))),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _empty(bool isDark) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 56, color: AppColors.textTertiaryLight),
            const SizedBox(height: 12),
            Text('لا توجد مسابقات بهذا التصنيف',
                style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
          ],
        ),
      );
}

// ── تبويبات الحالة ────────────────────────────────────────────────────────────
class _StatusTabs extends StatelessWidget {
  final List<(String, CompetitionStatus?)> tabs;
  final CompetitionStatus? selected;
  final ValueChanged<CompetitionStatus?> onSelect;
  const _StatusTabs({required this.tabs, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: tabs.map((t) {
          final isSel = selected == t.$2;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(t.$2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSel ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(t.$1,
                    style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w800,
                        color: isSel ? Colors.white : AppColors.textSecondaryLight)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── شرائح الفئات ──────────────────────────────────────────────────────────────
class _CategoryChips extends StatelessWidget {
  final CompetitionCategory? selected;
  final ValueChanged<CompetitionCategory?> onSelect;
  const _CategoryChips({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          _chip('الكل', Icons.apps_rounded, AppColors.primary, selected == null, () => onSelect(null)),
          ...CompetitionCategory.values.map((cat) =>
              _chip(cat.label, cat.icon, cat.color, selected == cat, () => onSelect(cat))),
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icon, Color color, bool isSel, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSel ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: isSel ? 1 : 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: isSel ? Colors.white : color),
              const SizedBox(width: 5),
              Text(label,
                  style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w800,
                      color: isSel ? Colors.white : color)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── بطاقة المسابقة (غنية) ──────────────────────────────────────────────────────
class _CompetitionCard extends StatelessWidget {
  final Competition c;
  final bool joined;
  final bool isDark;
  final VoidCallback onOpen;
  final VoidCallback onExpire;
  const _CompetitionCard({
    required this.c,
    required this.joined,
    required this.isDark,
    required this.onOpen,
    required this.onExpire,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: [BoxShadow(color: c.color.withValues(alpha: 0.10), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onOpen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الشريط العلوي المتدرّج
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: c.gradient,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(12)),
                      child: Icon(c.icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  c.statusLabel,
                                  style: GoogleFonts.cairo(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                              if (joined) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                                  child: Text(
                                    'مشترك ✓',
                                    style: GoogleFonts.cairo(fontSize: 8, fontWeight: FontWeight.w900, color: c.color),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            c.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(fontSize: 14.5, height: 1.2, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.88)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // الجسم
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // عدّاد تنازلي حيّ
                          if (c.status == CompetitionStatus.active)
                            CountdownText(target: c.endsAt, color: c.statusColor, endedLabel: 'انتهت', onEnded: onExpire)
                          else if (c.status == CompetitionStatus.upcoming)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.hourglass_top_rounded, size: 13, color: c.statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  'يبدأ بعد',
                                  style: GoogleFonts.cairo(fontSize: 9.5, fontWeight: FontWeight.w700, color: c.statusColor),
                                ),
                                const SizedBox(width: 4),
                                CountdownText(target: c.startsAt, color: c.statusColor, showIcon: false, endedLabel: 'بدأت', onEnded: onExpire),
                              ],
                            )
                          else
                            _meta(Icons.event_busy_rounded, 'انتهت', c.statusColor),
                          _meta(
                            Icons.groups_rounded,
                            c.isUnlimited ? '${c.participants} مشارك' : '${c.participants}/${c.maxParticipants}',
                            AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded, size: 15, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 3),
                        Text(
                          '${c.rewardPoints}',
                          style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFFD97706)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // زر فتح التفاصيل
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: c.color.withValues(alpha: joined ? 0.0 : 1.0),
                    borderRadius: BorderRadius.circular(12),
                    border: joined ? Border.all(color: c.color, width: 1.5) : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        c.status == CompetitionStatus.ended
                            ? Icons.visibility_rounded
                            : joined
                                ? Icons.open_in_new_rounded
                                : Icons.arrow_circle_left_rounded,
                        size: 17,
                        color: joined ? c.color : Colors.white,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        c.status == CompetitionStatus.ended
                            ? 'عرض النتائج'
                            : joined
                                ? 'متابعة المسابقة'
                                : 'عرض التفاصيل والاشتراك',
                        style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w800,
                            color: joined ? c.color : Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.cairo(fontSize: 10.5, fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
        ],
      );
}
