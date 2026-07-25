import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/competitions/data/mock_competitions_data.dart';
import 'package:charity_app/features/competitions/domain/competition_models.dart';
import 'package:charity_app/features/competitions/presentation/providers/competitions_provider.dart';
import 'package:charity_app/features/competitions/presentation/providers/engagement_provider.dart';
import 'package:charity_app/features/competitions/presentation/providers/khatma_provider.dart';

final _numberFmt = NumberFormat('#,###');

/// لوحة صدارة عامة تُغذّى بأي من الأقسام الخمسة عبر [EngagementCategory].
class EngagementLeaderboardPage extends ConsumerWidget {
  final EngagementCategory category;
  const EngagementLeaderboardPage({super.key, required this.category});

  List<EngagementEntry> _entries() {
    switch (category) {
      case EngagementCategory.social:
        return mockSocialLeaderboard;
      case EngagementCategory.orgSupport:
        return mockOrgSupportLeaderboard;
      case EngagementCategory.khatma:
        return khatmaEngagementEntries();
      case EngagementCategory.familyDonation:
        return mockFamilyDonationLeaderboard;
      case EngagementCategory.delegates:
        final sorted = [...mockDelegatesActivity]
          ..sort((a, b) => b.activityScore.compareTo(a.activityScore));
        return sorted.map((d) => d.toEntry()).toList();
    }
  }

  String _formatValue(num v) {
    if (category == EngagementCategory.orgSupport) return _numberFmt.format(v);
    return '$v';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entries = _entries();
    final top3 = entries.take(3).toList();
    final rest = entries.skip(3).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(category.title, style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(category.icon, color: category.color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(category.subtitle,
                      style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                ),
              ],
            ),
          ),
          if (category == EngagementCategory.social) ...[
            const _SocialActionPanel(),
            const SizedBox(height: 18),
          ],
          if (top3.isNotEmpty) ...[
            _Podium(top3: top3, category: category, formatValue: _formatValue),
            const SizedBox(height: 18),
          ],
          ...rest.asMap().entries.map((e) => _RankRow(
                rank: e.key + 4,
                entry: e.value,
                category: category,
                isDark: isDark,
                formatValue: _formatValue,
              )),
          if (category.showsMyPosition) ...[
            const SizedBox(height: 8),
            _MyPositionCard(category: category, entries: entries, formatValue: _formatValue),
          ],
        ],
      ),
    );
  }
}

// ── لوحة المنصّة (المراكز الثلاثة الأولى) ───────────────────────────────────────
class _Podium extends StatelessWidget {
  final List<EngagementEntry> top3;
  final EngagementCategory category;
  final String Function(num) formatValue;
  const _Podium({required this.top3, required this.category, required this.formatValue});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (top3.length > 1)
          Expanded(child: _PodiumPillar(rank: 2, entry: top3[1], height: 128, category: category, formatValue: formatValue)),
        if (top3.isNotEmpty)
          Expanded(child: _PodiumPillar(rank: 1, entry: top3[0], height: 160, category: category, formatValue: formatValue)),
        if (top3.length > 2)
          Expanded(child: _PodiumPillar(rank: 3, entry: top3[2], height: 108, category: category, formatValue: formatValue)),
      ],
    );
  }
}

class _PodiumPillar extends StatelessWidget {
  final int rank;
  final EngagementEntry entry;
  final double height;
  final EngagementCategory category;
  final String Function(num) formatValue;
  const _PodiumPillar({
    required this.rank,
    required this.entry,
    required this.height,
    required this.category,
    required this.formatValue,
  });

  Color get _color => switch (rank) {
        1 => const Color(0xFFFBBF24),
        2 => const Color(0xFF94A3B8),
        _ => const Color(0xFFB45309),
      };

  String get _medal => switch (rank) { 1 => '🥇', 2 => '🥈', _ => '🥉' };

  @override
  Widget build(BuildContext context) {
    final parts = entry.name.trim().split(' ');
    final initials = parts.take(2).map((w) => w.isNotEmpty ? w[0] : '').join();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_medal, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Container(
            width: rank == 1 ? 58 : 48, height: rank == 1 ? 58 : 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_color, _color.withValues(alpha: 0.7)]),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: _color.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Center(child: Text(initials,
                style: GoogleFonts.cairo(fontSize: rank == 1 ? 18 : 15, fontWeight: FontWeight.w900, color: Colors.white))),
          ),
          const SizedBox(height: 6),
          Text(parts.isNotEmpty ? parts.first : entry.name,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w800)),
          Text('${formatValue(entry.value)} ${category.unit}',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(fontSize: 9.5, fontWeight: FontWeight.w700, color: _color)),
          const SizedBox(height: 6),
          Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_color.withValues(alpha: 0.85), _color.withValues(alpha: 0.45)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Center(child: Text('$rank',
                style: GoogleFonts.cairo(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.9)))),
          ),
        ],
      ),
    );
  }
}

// ── صف ترتيب عادي (المركز الرابع فما بعد) ──────────────────────────────────────
class _RankRow extends StatelessWidget {
  final int rank;
  final EngagementEntry entry;
  final EngagementCategory category;
  final bool isDark;
  final String Function(num) formatValue;
  const _RankRow({
    required this.rank,
    required this.entry,
    required this.category,
    required this.isDark,
    required this.formatValue,
  });

  @override
  Widget build(BuildContext context) {
    final parts = entry.name.trim().split(' ');
    final initials = parts.take(2).map((w) => w.isNotEmpty ? w[0] : '').join();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          SizedBox(width: 26, child: Text('$rank',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
          const SizedBox(width: 6),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(gradient: category.gradient, shape: BoxShape.circle),
            child: Center(child: Text(initials,
                style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                if (entry.subtitle.isNotEmpty)
                  Text(entry.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(fontSize: 9.5,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            constraints: const BoxConstraints(maxWidth: 112),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${formatValue(entry.value)} ${category.unit}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w900, color: category.color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── بطاقة "موقعي الحالي" الثابتة أسفل القائمة ───────────────────────────────────
class _MyPositionCard extends ConsumerWidget {
  final EngagementCategory category;
  final List<EngagementEntry> entries;
  final String Function(num) formatValue;
  const _MyPositionCard({required this.category, required this.entries, required this.formatValue});

  num _myValue(WidgetRef ref) {
    switch (category) {
      case EngagementCategory.social:
        return ref.watch(socialShareProvider.notifier).myPoints;
      case EngagementCategory.orgSupport:
        return ref.watch(myEngagementStatsProvider).orgSupport;
      case EngagementCategory.familyDonation:
        return ref.watch(myEngagementStatsProvider).familyDonations;
      case EngagementCategory.khatma:
        return ref.watch(khatmaProvider).active.completedCount;
      case EngagementCategory.delegates:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myValue = _myValue(ref);
    final rank = entries.where((e) => e.value > myValue).length + 1;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: category.gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: category.color.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('موقعي الحالي',
                    style: GoogleFonts.cairo(fontSize: 11, color: Colors.white.withValues(alpha: 0.85))),
                Text('المرتبة #$rank',
                    style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${formatValue(myValue)} ${category.unit}',
                  style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 6),
              _actionButton(context, ref),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context, WidgetRef ref) {
    if (category == EngagementCategory.familyDonation) {
      return _pill(context, 'تسجيل تبرّع', () {
        ref.read(myEngagementStatsProvider.notifier).addFamilyDonation();
      });
    }
    if (category == EngagementCategory.orgSupport) {
      return _pill(context, 'دعم المؤسسة', () => _showSupportDialog(context, ref));
    }
    return const SizedBox.shrink();
  }

  Widget _pill(BuildContext context, String label, VoidCallback onTap) {
    return Material(
      color: Colors.white.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(label, style: GoogleFonts.cairo(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
      ),
    );
  }

  void _showSupportDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: '25000');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('دعم المؤسسة', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'المبلغ (د.ع)', labelStyle: GoogleFonts.cairo(fontSize: 12)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: GoogleFonts.cairo(fontWeight: FontWeight.w700))),
          ElevatedButton(
            onPressed: () {
              final amount = int.tryParse(controller.text) ?? 0;
              if (amount > 0) ref.read(myEngagementStatsProvider.notifier).addOrgSupport(amount);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: Text('تأكيد', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

// ── لوحة إجراء "تواصل اجتماعي" (مشاركة فيسبوك + اعتماد الأدمن) ─────────────────
class _SocialActionPanel extends ConsumerWidget {
  const _SocialActionPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final requests = ref.watch(socialShareProvider);
    final canManage = ref.watch(canManageCompetitionsProvider);
    final hasPending = ref.watch(socialShareProvider.notifier).hasPending;
    final pendingList = requests.where((r) => r.status == ShareRequestStatus.pending).toList();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.facebook_rounded, color: Color(0xFF3B82F6), size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('شاركت منشوراً للمؤسسة على فيسبوك؟',
                        style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('أبلغنا بمشاركتك، وسيمنحك المشرف النقاط بعد المراجعة.',
                  style: GoogleFonts.cairo(fontSize: 10.5, color: AppColors.textSecondaryLight)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: hasPending ? null : () => ref.read(socialShareProvider.notifier).submitShare(),
                  icon: Icon(hasPending ? Icons.hourglass_top_rounded : Icons.check_circle_outline_rounded, size: 18),
                  label: Text(hasPending ? 'بانتظار اعتماد المشرف ⏳' : 'شاركت المنشور ✓',
                      style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasPending ? Colors.grey.withValues(alpha: 0.4) : const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (canManage && pendingList.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...pendingList.map((r) => _PendingShareTile(request: r)),
        ],
      ],
    );
  }
}

class _PendingShareTile extends ConsumerStatefulWidget {
  final SocialShareRequest request;
  const _PendingShareTile({required this.request});

  @override
  ConsumerState<_PendingShareTile> createState() => _PendingShareTileState();
}

class _PendingShareTileState extends ConsumerState<_PendingShareTile> {
  late final TextEditingController _points = TextEditingController(text: '50');

  @override
  void dispose() {
    _points.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.pending_actions_rounded, color: Color(0xFFD97706), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text('طلب اعتماد مشاركة (مشرف)',
                style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
          ),
          SizedBox(
            width: 56,
            child: TextField(
              controller: _points,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 6)),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: const Color(0xFF10B981),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                final pts = int.tryParse(_points.text) ?? 0;
                ref.read(socialShareProvider.notifier).approve(widget.request.id, pts);
              },
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.check_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
