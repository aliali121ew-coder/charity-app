import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/competitions/presentation/providers/khatma_provider.dart';
import 'package:charity_app/features/competitions/presentation/pages/khatma_page.dart';
import 'package:charity_app/features/competitions/presentation/pages/engagement_hub_page.dart';
import 'package:charity_app/features/competitions/presentation/pages/prizes_page.dart';
import 'package:charity_app/features/competitions/presentation/pages/competitions_list_page.dart';

class CompetitionsPage extends ConsumerWidget {
  const CompetitionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final khatma = ref.watch(khatmaProvider);
    final active = khatma.active;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _Header(isDark: isDark, completedKhatmas: khatma.totalCompletedKhatmas),
        const SizedBox(height: 18),

        // ── البطاقة المميّزة: الختمة القرآنية ─────────────────────────
        _KhatmaFeatureCard(
          khatmaIndex: active.index,
          completed: active.completedCount,
          reserved: active.reservedCount,
          progress: active.progress,
          onOpen: () => _push(context, const KhatmaPage()),
        ),
        const SizedBox(height: 20),

        _SectionTitle(title: 'الأقسام', isDark: isDark),
        const SizedBox(height: 12),

        // ── شبكة الأقسام ──────────────────────────────────────────────
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.82,
          children: [
            _SectionCard(
              title: 'الأكثر تفاعلاً',
              subtitle: 'هذا الأسبوع',
              icon: Icons.emoji_events_rounded,
              gradient: AppColors.gradientOrange,
              onTap: () => _push(context, const EngagementHubPage()),
            ),
            _SectionCard(
              title: 'الجوائز',
              subtitle: 'استبدل نقاطك',
              icon: Icons.card_giftcard_rounded,
              gradient: AppColors.gradientPink,
              onTap: () => _push(context, const PrizesPage()),
            ),
            _SectionCard(
              title: 'المسابقات',
              subtitle: 'تحديات وجوائز',
              icon: Icons.workspace_premium_rounded,
              gradient: AppColors.gradientPurple,
              onTap: () => _push(context, const CompetitionsListPage()),
            ),
            _SectionCard(
              title: 'الختمة القرآنية',
              subtitle: '30 جزءاً',
              icon: Icons.menu_book_rounded,
              gradient: AppColors.gradientGreen,
              onTap: () => _push(context, const KhatmaPage()),
            ),
          ],
        ),
      ],
    );
  }

  static void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final bool isDark;
  final int completedKhatmas;
  const _Header({required this.isDark, required this.completedKhatmas});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4C3BC5), Color(0xFF2D1FA3), Color(0xFF1A1266)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF2D1FA3).withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFBBF24), size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('المسابقات والجوائز',
                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 3),
                Text('شارك، تنافس، واكسب الأجر والجوائز',
                    style: GoogleFonts.cairo(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text('$completedKhatmas',
                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFFFBBF24))),
                Text('ختمة مكتملة',
                    style: GoogleFonts.cairo(fontSize: 8, color: Colors.white.withValues(alpha: 0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Khatma Feature Card ─────────────────────────────────────────────────────────
class _KhatmaFeatureCard extends StatelessWidget {
  final int khatmaIndex;
  final int completed;
  final int reserved;
  final double progress;
  final VoidCallback onOpen;
  const _KhatmaFeatureCard({
    required this.khatmaIndex,
    required this.completed,
    required this.reserved,
    required this.progress,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppColors.gradientGreen,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: Colors.white, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الختمة القرآنية الجماعية',
                            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                        Text('الختمة رقم $khatmaIndex • احجز جزءك وشارك في الأجر',
                            style: GoogleFonts.cairo(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.85))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('$completed/30',
                        style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 9,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _MiniInfo(label: 'تمت قراءته', value: '$completed جزء'),
                  const SizedBox(width: 18),
                  _MiniInfo(label: 'محجوز', value: '$reserved جزء'),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text('احجز جزءك',
                            style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF059669))),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF059669)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String label, value;
  const _MiniInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
        Text(label, style: GoogleFonts.cairo(fontSize: 9, color: Colors.white.withValues(alpha: 0.8))),
      ],
    );
  }
}

// ── Section Card ────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: gradient.colors.first.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(fontSize: 14.5, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(fontSize: 10.0, color: Colors.white.withValues(alpha: 0.85))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Title ───────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4, height: 18,
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w900,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
      ],
    );
  }
}
