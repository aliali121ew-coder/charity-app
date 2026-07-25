import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/competitions/data/mock_competitions_data.dart';
import 'package:charity_app/features/competitions/domain/competition_models.dart';
import 'package:charity_app/features/competitions/presentation/pages/engagement_leaderboard_page.dart';

/// مركز "الأكثر تفاعلاً" — يجمع 5 لوحات صدارة مستقلة في تصميم فريد
/// (شرائط أفقية بشريط لون جانبي + معاينة المتصدّر)، مختلف عمداً عن شبكة
/// البطاقات المربّعة المستخدمة في قسم العبادات.
class EngagementHubPage extends StatelessWidget {
  const EngagementHubPage({super.key});

  EngagementEntry? _leaderOf(EngagementCategory c) {
    switch (c) {
      case EngagementCategory.social:
        return mockSocialLeaderboard.isEmpty ? null : mockSocialLeaderboard.first;
      case EngagementCategory.orgSupport:
        return mockOrgSupportLeaderboard.isEmpty ? null : mockOrgSupportLeaderboard.first;
      case EngagementCategory.khatma:
        final list = khatmaEngagementEntries();
        return list.isEmpty ? null : list.first;
      case EngagementCategory.familyDonation:
        return mockFamilyDonationLeaderboard.isEmpty ? null : mockFamilyDonationLeaderboard.first;
      case EngagementCategory.delegates:
        final sorted = [...mockDelegatesActivity]
          ..sort((a, b) => b.activityScore.compareTo(a.activityScore));
        return sorted.isEmpty ? null : sorted.first.toEntry();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('الأكثر تفاعلاً', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const _HubBanner(),
          const SizedBox(height: 20),
          ...EngagementCategory.values.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SpotlightCard(
                  category: c,
                  leader: _leaderOf(c),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => EngagementLeaderboardPage(category: c))),
                ),
              )),
        ],
      ),
    );
  }
}

// ── بانر علوي مموّج بالنقاط ─────────────────────────────────────────────────────
class _HubBanner extends StatelessWidget {
  const _HubBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -18, top: -18,
            child: Icon(Icons.auto_awesome_rounded, size: 90, color: Colors.white.withValues(alpha: 0.06)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.leaderboard_rounded, color: Color(0xFFFBBF24), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('٥ مسارات للتميّز',
                        style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'اختر مجالك وتنافس على القمة — كل مسار له صدارته ونقاطه الخاصة',
                style: GoogleFonts.cairo(fontSize: 11.5, height: 1.6, color: Colors.white.withValues(alpha: 0.75)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── شريط تفاعلي أفقي لكل قسم ────────────────────────────────────────────────────
class _SpotlightCard extends StatelessWidget {
  final EngagementCategory category;
  final EngagementEntry? leader;
  final VoidCallback onTap;
  const _SpotlightCard({required this.category, required this.leader, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // شريط اللون الجانبي المميّز لهذا القسم
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: category.color,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(18)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            gradient: category.gradient,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [BoxShadow(color: category.color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                          ),
                          child: Icon(category.icon, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(category.title,
                                  maxLines: 2, overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(fontSize: 14, height: 1.25, fontWeight: FontWeight.w900,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                              const SizedBox(height: 3),
                              Text(category.subtitle,
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textSecondaryLight)),
                              if (leader != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text('🏆', style: TextStyle(fontSize: 11)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(leader!.name,
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.cairo(fontSize: 10.5, fontWeight: FontWeight.w700,
                                              color: category.color)),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_left_rounded, color: AppColors.textTertiaryLight, size: 22),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
