import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/core/localization/app_localizations.dart';
import 'package:charity_app/core/router/app_router.dart';
import 'package:charity_app/shared/widgets/kpi_stat_card.dart';
import 'package:charity_app/shared/widgets/section_header.dart';
import 'package:charity_app/shared/widgets/chart_card.dart';
import 'package:charity_app/shared/widgets/activity_log_item.dart';
import 'package:charity_app/features/subscribers/data/mock_subscribers_repository.dart';
import 'package:charity_app/features/families/data/mock_families_repository.dart';
import 'package:charity_app/features/aid/data/mock_aid_repository.dart';
import 'package:charity_app/features/logs/data/mock_logs_repository.dart';
import 'package:charity_app/shared/models/subscriber_model.dart';
import 'package:charity_app/shared/models/aid_model.dart';
import 'package:charity_app/shared/models/family_model.dart';
import 'package:charity_app/shared/widgets/status_chip.dart';
import 'package:intl/intl.dart';

// ── Dashboard Lock Provider ────────────────────────────────────────────────────
class _LockedNotifier extends Notifier<bool> {
  @override bool build() => true;
  void set(bool v) => state = v;
}
final _dashboardLockedProvider = NotifierProvider<_LockedNotifier, bool>(_LockedNotifier.new);

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Re-lock each time the page is (re)created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(_dashboardLockedProvider.notifier).set(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(_dashboardLockedProvider);
    if (isLocked) {
      return _PinLockScreen(onUnlock: () {
        ref.read(_dashboardLockedProvider.notifier).set(false);
      });
    }
    return _DashboardContent();
  }
}

class _DashboardContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    final subscribersRepo = MockSubscribersRepository();
    final familiesRepo = MockFamiliesRepository();
    final aidRepo = MockAidRepository();
    final logsRepo = MockLogsRepository();

    final subscribers = subscribersRepo.getAll();
    final families = familiesRepo.getAll();
    final aidRecords = aidRepo.getAll();
    final logs = logsRepo.getAll();

    final activeSubscribers = subscribers.where((s) => s.status == SubscriberStatus.active).length;
    final pendingAid = aidRecords.where((a) => a.status == AidStatus.pending).length;
    final totalAmount = aidRepo.getTotalAmount();
    final eligibleFamilies = families.where((f) => f.status == FamilyStatus.eligible).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page title
          PageHeader(
            title: l10n.tr('dashboard'),
            subtitle: 'نظرة شاملة على أنشطة المنظمة',
            actions: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('dd/MM/yyyy').format(DateTime.now()),
                      style: GoogleFonts.cairo(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── KPI Cards Row 1 ────────────────────────────────────────────────
          _KpiRow(children: [
            KpiStatCard(
              label: l10n.tr('total_subscribers'),
              value: '${subscribers.length}',
              icon: Icons.people_rounded,
              gradientColors: AppColors.kpiBlue,
              changePercent: '+12%',
              isPositiveChange: true,
              subtitle: l10n.tr('this_month'),
            ),
            KpiStatCard(
              label: l10n.tr('total_families'),
              value: '${families.length}',
              icon: Icons.family_restroom_rounded,
              gradientColors: AppColors.kpiPurple,
              changePercent: '+8%',
              isPositiveChange: true,
              subtitle: '$eligibleFamilies مؤهلة',
            ),
            KpiStatCard(
              label: l10n.tr('total_aid'),
              value: '${aidRecords.length}',
              icon: Icons.volunteer_activism_rounded,
              gradientColors: AppColors.kpiGreen,
              changePercent: '+23%',
              isPositiveChange: true,
              subtitle: '${aidRecords.where((a) => a.status == AidStatus.distributed).length} تم صرفها',
            ),
          ]),
          const SizedBox(height: 12),
          _KpiRow(children: [
            KpiStatCard(
              label: l10n.tr('active_cases'),
              value: '$activeSubscribers',
              icon: Icons.verified_user_rounded,
              gradientColors: AppColors.kpiTeal,
              changePercent: '+5%',
              isPositiveChange: true,
            ),
            KpiStatCard(
              label: l10n.tr('monthly_amount'),
              value: '${(totalAmount / 1000000).toStringAsFixed(1)}M',
              icon: Icons.account_balance_wallet_rounded,
              gradientColors: AppColors.kpiOrange,
              changePercent: '+17%',
              isPositiveChange: true,
              subtitle: 'د.ع',
            ),
            KpiStatCard(
              label: l10n.tr('pending_reviews'),
              value: '$pendingAid',
              icon: Icons.pending_actions_rounded,
              gradientColors: AppColors.kpiRose,
              changePercent: '-3',
              isPositiveChange: false,
              subtitle: 'بانتظار الاعتماد',
            ),
          ]),
          const SizedBox(height: 24),

          // ── Charts Row ─────────────────────────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 280,
                        child: _AidTrendChart(aidRepo: aidRepo),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 280,
                        child: _AidCategoriesChart(aidRepo: aidRepo, l10n: l10n),
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  SizedBox(height: 260, child: _AidTrendChart(aidRepo: aidRepo)),
                  const SizedBox(height: 12),
                  SizedBox(height: 260, child: _AidCategoriesChart(aidRepo: aidRepo, l10n: l10n)),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // ── Bottom Row: Recent Subscribers + Recent Aid + Activity ─────────
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _RecentSubscribersCard(subscribers: subscribers.take(5).toList(), l10n: l10n)),
                    const SizedBox(width: 12),
                    Expanded(child: _RecentAidCard(aidRecords: aidRecords.take(4).toList(), l10n: l10n)),
                  ],
                );
              }
              return Column(
                children: [
                  _RecentSubscribersCard(subscribers: subscribers.take(5).toList(), l10n: l10n),
                  const SizedBox(height: 12),
                  _RecentAidCard(aidRecords: aidRecords.take(4).toList(), l10n: l10n),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // ── Recent Activity Log ────────────────────────────────────────────
          SectionHeader(title: l10n.tr('recent_activity'), trailing: TextButton(
            onPressed: () => context.go(AppRoutes.logs),
            child: Text('عرض الكل', style: GoogleFonts.cairo(fontSize: 12, color: AppColors.primary)),
          )),
          ...logs.take(5).toList().asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: ActivityLogItem(log: e.value, isLast: e.key == 4),
          )),
          const SizedBox(height: 24),

          // ── Quick Actions ──────────────────────────────────────────────────
          SectionHeader(title: l10n.tr('quick_actions')),
          _QuickActionsGrid(l10n: l10n),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── KPI Row helper ─────────────────────────────────────────────────────────────
class _KpiRow extends StatelessWidget {
  final List<Widget> children;
  const _KpiRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 500) {
          // 1-column stacked
          return Column(
            children: children.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: c,
            )).toList(),
          );
        }
        // Horizontal row
        return Row(
          children: children.indexed.map((e) {
            final (i, child) = e;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: i < children.length - 1 ? 10 : 0),
                child: child,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ── Aid Trend Chart ─────────────────────────────────────────────────────────────
class _AidTrendChart extends StatelessWidget {
  final MockAidRepository aidRepo;
  const _AidTrendChart({required this.aidRepo});

  @override
  Widget build(BuildContext context) {
    final monthly = aidRepo.getMonthlyTotals();
    final maxY = monthly.map((m) => m['total'] as double).fold(0.0, (a, b) => a > b ? a : b);

    final spots = monthly.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['total'] as double) / 1000);
    }).toList();

    final monthNames = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];

    return ChartCard(
      title: 'اتجاه المساعدات',
      subtitle: 'آخر 6 أشهر (بالألف دينار)',
      chart: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? (maxY / 1000 / 4) : 50,
            getDrawingHorizontalLine: (v) => const FlLine(
              color: AppColors.borderLight,
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, m) => Text(
                  '${v.toInt()}K',
                  style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textTertiaryLight),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, m) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= monthly.length) return const SizedBox();
                  final month = monthly[idx]['month'] as DateTime;
                  return Text(
                    monthNames[month.month - 1].substring(0, 3),
                    style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textTertiaryLight),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: AppColors.primary,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Aid Categories Donut Chart ─────────────────────────────────────────────────
class _AidCategoriesChart extends StatefulWidget {
  final MockAidRepository aidRepo;
  final AppLocalizations l10n;
  const _AidCategoriesChart({required this.aidRepo, required this.l10n});

  @override
  State<_AidCategoriesChart> createState() => _AidCategoriesChartState();
}

class _AidCategoriesChartState extends State<_AidCategoriesChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final counts = widget.aidRepo.getCountByType();
    final total = counts.values.fold(0, (a, b) => a + b);

    final chartData = [
      (AidType.financial, AppColors.kpiBlue.first),
      (AidType.food, AppColors.kpiGreen.first),
      (AidType.medical, AppColors.kpiRose.first),
      (AidType.seasonal, AppColors.kpiOrange.first),
      (AidType.education, AppColors.kpiPurple.first),
      (AidType.other, AppColors.kpiTeal.first),
    ];

    return ChartCard(
      title: widget.l10n.tr('aid_by_category'),
      chart: Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (e, r) {
                    setState(() {
                      touchedIndex = r?.touchedSection?.touchedSectionIndex ?? -1;
                    });
                  },
                ),
                centerSpaceRadius: 42,
                sections: chartData.asMap().entries.map((e) {
                  final (type, color) = e.value;
                  final count = counts[type] ?? 0;
                  final pct = total > 0 ? (count / total * 100) : 0.0;
                  final isTouched = e.key == touchedIndex;
                  return PieChartSectionData(
                    color: color,
                    value: count.toDouble(),
                    title: isTouched ? '${pct.toStringAsFixed(0)}%' : '',
                    radius: isTouched ? 52 : 45,
                    titleStyle: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: chartData.map((e) {
              final (type, color) = e;
              return ChartLegendItem(
                color: color,
                label: type.labelAr,
                value: '${counts[type] ?? 0}',
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Recent Subscribers Card ────────────────────────────────────────────────────
class _RecentSubscribersCard extends StatelessWidget {
  final List<SubscriberModel> subscribers;
  final AppLocalizations l10n;

  const _RecentSubscribersCard({required this.subscribers, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SectionHeader(
              title: l10n.tr('recent_subscribers'),
              padding: EdgeInsets.zero,
              trailing: TextButton(
                onPressed: () => context.go(AppRoutes.subscribers),
                child: Text('عرض الكل', style: GoogleFonts.cairo(fontSize: 11, color: AppColors.primary)),
              ),
            ),
          ),
          ...subscribers.map((s) => _SubscriberListTile(subscriber: s, l10n: l10n)),
        ],
      ),
    );
  }
}

class _SubscriberListTile extends StatelessWidget {
  final SubscriberModel subscriber;
  final AppLocalizations l10n;
  const _SubscriberListTile({required this.subscriber, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          _Avatar(name: subscriber.name),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subscriber.name,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subscriber.area,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          StatusChip.subscriber(subscriber.status, l10n.isArabic),
        ],
      ),
    );
  }
}

// ── Recent Aid Card ───────────────────────────────────────────────────────────
class _RecentAidCard extends StatelessWidget {
  final List<AidModel> aidRecords;
  final AppLocalizations l10n;
  const _RecentAidCard({required this.aidRecords, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SectionHeader(
              title: l10n.tr('recent_aid'),
              padding: EdgeInsets.zero,
              trailing: TextButton(
                onPressed: () => context.go(AppRoutes.aid),
                child: Text('عرض الكل', style: GoogleFonts.cairo(fontSize: 11, color: AppColors.primary)),
              ),
            ),
          ),
          ...aidRecords.map((a) => _AidListTile(aid: a)),
        ],
      ),
    );
  }
}

class _AidListTile extends StatelessWidget {
  final AidModel aid;
  const _AidListTile({required this.aid});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _typeColor(aid.type).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_typeIcon(aid.type), size: 18, color: _typeColor(aid.type)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aid.beneficiaryName,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  aid.type.labelAr,
                  style: GoogleFonts.cairo(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(aid.amount / 1000).toStringAsFixed(0)}K',
                style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
              StatusChip.aid(aid.status),
            ],
          ),
        ],
      ),
    );
  }

  Color _typeColor(AidType type) {
    switch (type) {
      case AidType.financial: return AppColors.kpiBlue.first;
      case AidType.food: return AppColors.kpiGreen.first;
      case AidType.medical: return AppColors.kpiRose.first;
      case AidType.seasonal: return AppColors.kpiOrange.first;
      case AidType.education: return AppColors.kpiPurple.first;
      case AidType.other: return AppColors.kpiTeal.first;
    }
  }

  IconData _typeIcon(AidType type) {
    switch (type) {
      case AidType.financial: return Icons.attach_money_rounded;
      case AidType.food: return Icons.restaurant_rounded;
      case AidType.medical: return Icons.medical_services_rounded;
      case AidType.seasonal: return Icons.calendar_month_rounded;
      case AidType.education: return Icons.school_rounded;
      case AidType.other: return Icons.category_rounded;
    }
  }
}

// ── Quick Actions Grid ────────────────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  final AppLocalizations l10n;
  const _QuickActionsGrid({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.person_add_rounded, l10n.tr('add_subscriber'), AppColors.kpiBlue.first, AppRoutes.subscribers),
      (Icons.family_restroom_rounded, l10n.tr('add_family'), AppColors.kpiPurple.first, AppRoutes.families),
      (Icons.volunteer_activism_rounded, l10n.tr('add_aid'), AppColors.kpiGreen.first, AppRoutes.aid),
      (Icons.bar_chart_rounded, l10n.tr('reports'), AppColors.kpiOrange.first, AppRoutes.reports),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.8,
      children: actions.map((a) {
        final (icon, label, color, path) = a;
        return _QuickActionCard(icon: icon, label: label, color: color, onTap: () => context.go(path));
      }).toList(),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Avatar helper ─────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.kpiBlue.first,
      AppColors.kpiPurple.first,
      AppColors.kpiGreen.first,
      AppColors.kpiOrange.first,
      AppColors.kpiRose.first,
    ];
    final color = colors[name.hashCode.abs() % colors.length];
    final initials = name.trim().split(' ').take(2).map((w) => w[0]).join();
    return CircleAvatar(
      radius: 18,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Text(
        initials,
        style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

// ── PIN Lock Screen ────────────────────────────────────────────────────────────
class _PinLockScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  const _PinLockScreen({required this.onUnlock});

  @override
  State<_PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<_PinLockScreen>
    with SingleTickerProviderStateMixin {
  static const _correctPin = '1234';
  String _pin = '';
  bool _wrong = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(_shakeCtrl);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onKey(String key) {
    if (_pin.length >= 4) return;
    setState(() => _pin += key);
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        if (_pin == _correctPin) {
          widget.onUnlock();
        } else {
          setState(() { _wrong = true; });
          _shakeCtrl.forward(from: 0).then((_) {
            if (mounted) setState(() { _pin = ''; _wrong = false; });
          });
        }
      });
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? const Color(0xFF0A0F1E)
        : const Color(0xFF1A1040);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lock icon
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
                        blurRadius: 24, spreadRadius: 2)],
                  ),
                  child: const Icon(Icons.lock_rounded, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text('لوحة التحكم',
                    style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w900,
                        color: Colors.white)),
                const SizedBox(height: 6),
                Text('أدخل رمز PIN للوصول',
                    style: GoogleFonts.cairo(fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.55))),
                const SizedBox(height: 40),

                // PIN dots
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(_shakeAnim.value, 0),
                    child: child,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      final filled = i < _pin.length;
                      final color = _wrong ? const Color(0xFFEF4444)
                          : filled ? const Color(0xFF7C3AED) : Colors.white.withValues(alpha: 0.25);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: filled ? 18 : 16,
                        height: filled ? 18 : 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          boxShadow: filled ? [BoxShadow(color: color.withValues(alpha: 0.5),
                              blurRadius: 8, spreadRadius: 1)] : null,
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedOpacity(
                  opacity: _wrong ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text('رمز PIN غير صحيح',
                      style: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFFEF4444))),
                ),
                const SizedBox(height: 32),

                // Keypad
                _Keypad(onKey: _onKey, onDelete: _onDelete),
                const SizedBox(height: 24),
                Text('الرمز الافتراضي: 1234',
                    style: GoogleFonts.cairo(fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.3))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final void Function(String) onKey;
  final VoidCallback onDelete;
  const _Keypad({required this.onKey, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1','2','3'],
      ['4','5','6'],
      ['7','8','9'],
      ['','0','⌫'],
    ];
    return Column(
      children: keys.map((row) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((k) {
            if (k.isEmpty) return const SizedBox(width: 72, height: 64);
            final isDelete = k == '⌫';
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _KeyButton(
                label: k,
                isDelete: isDelete,
                onTap: () => isDelete ? onDelete() : onKey(k),
              ),
            );
          }).toList(),
        ),
      )).toList(),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final bool isDelete;
  final VoidCallback onTap;
  const _KeyButton({required this.label, required this.isDelete, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(36),
        splashColor: const Color(0xFF7C3AED).withValues(alpha: 0.3),
        child: Container(
          width: 72, height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            color: isDelete
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.1),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          alignment: Alignment.center,
          child: isDelete
              ? Icon(Icons.backspace_outlined, color: Colors.white.withValues(alpha: 0.7), size: 22)
              : Text(label, style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ),
      ),
    );
  }
}
