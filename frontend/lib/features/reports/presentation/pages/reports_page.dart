import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/shared/widgets/section_header.dart';
import 'package:charity_app/shared/widgets/chart_card.dart';
import 'package:charity_app/features/subscribers/data/mock_subscribers_repository.dart';
import 'package:charity_app/features/families/data/mock_families_repository.dart';
import 'package:charity_app/features/aid/data/mock_aid_repository.dart';
import 'package:charity_app/shared/models/aid_model.dart';
import 'package:charity_app/shared/models/subscriber_model.dart';
import 'package:charity_app/shared/models/family_model.dart';

// ── Report Configs ────────────────────────────────────────────────────────────
class _ReportCard {
  final String id, title, subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final Color glow;
  final String kpi1Label, kpi1Value;
  final String kpi2Label, kpi2Value;
  const _ReportCard({
    required this.id, required this.title, required this.subtitle,
    required this.icon, required this.gradient, required this.glow,
    required this.kpi1Label, required this.kpi1Value,
    required this.kpi2Label, required this.kpi2Value,
  });
}

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final subsRepo = MockSubscribersRepository();
    final famRepo = MockFamiliesRepository();
    final aidRepo = MockAidRepository();
    final subs = subsRepo.getAll();
    final families = famRepo.getAll();
    final aids = aidRepo.getAll();

    final activeSubs = subs.where((s) => s.status == SubscriberStatus.active).length;
    final eligibleFam = families.where((f) => f.status == FamilyStatus.eligible).length;
    final totalAidAmount = aidRepo.getTotalAmount();
    final distributedAid = aids.where((a) => a.status == AidStatus.distributed).length;
    final pendingAid = aids.where((a) => a.status == AidStatus.pending).length;
    final totalMembers = families.fold(0, (s, f) => s + f.membersCount);

    final reports = [
      _ReportCard(
        id: 'delegates',
        title: 'المشتركين حسب المندوب',
        subtitle: 'تحليل أداء المندوبين والمشتركين',
        icon: Icons.people_alt_rounded,
        gradient: AppColors.gradientBlue,
        glow: const Color(0xFF3B82F6),
        kpi1Label: 'إجمالي المشتركين', kpi1Value: '${subs.length}',
        kpi2Label: 'نشط', kpi2Value: '$activeSubs',
      ),
      _ReportCard(
        id: 'overdue',
        title: 'المتأخرين في التسديد',
        subtitle: 'المشتركون المتأخرون عن السداد',
        icon: Icons.warning_amber_rounded,
        gradient: AppColors.gradientRed,
        glow: const Color(0xFFEF4444),
        kpi1Label: 'المتأخرون', kpi1Value: '${(activeSubs * 0.3).round()}',
        kpi2Label: 'أكثر من 4 أشهر', kpi2Value: '${(activeSubs * 0.1).round()}',
      ),
      _ReportCard(
        id: 'expenses',
        title: 'الصرفيات الشهرية',
        subtitle: 'تتبع المصاريف الشهرية للمؤسسة',
        icon: Icons.payments_rounded,
        gradient: AppColors.gradientTeal,
        glow: const Color(0xFF00C9A7),
        kpi1Label: 'الصرف الشهري', kpi1Value: '2.4M',
        kpi2Label: 'تم الصرف', kpi2Value: '$distributedAid',
      ),
      _ReportCard(
        id: 'aid',
        title: 'المساعدات العامة',
        subtitle: 'تقرير شامل لجميع المساعدات',
        icon: Icons.volunteer_activism_rounded,
        gradient: AppColors.gradientGreen,
        glow: const Color(0xFF10B981),
        kpi1Label: 'إجمالي المساعدات', kpi1Value: '${aids.length}',
        kpi2Label: 'قيد الانتظار', kpi2Value: '$pendingAid',
      ),
      const _ReportCard(
        id: 'income',
        title: 'الوارد الشهري',
        subtitle: 'الإيرادات الشهرية من الاشتراكات',
        icon: Icons.trending_up_rounded,
        gradient: AppColors.gradientPurple,
        glow: Color(0xFF7C3AED),
        kpi1Label: 'الوارد الشهري', kpi1Value: '3.8M',
        kpi2Label: 'معدل النمو', kpi2Value: '+12%',
      ),
      _ReportCard(
        id: 'funds',
        title: 'تقرير الصناديق',
        subtitle: 'أرصدة وحركة الصناديق المالية',
        icon: Icons.account_balance_rounded,
        gradient: AppColors.gradientIndigo,
        glow: const Color(0xFF6366F1),
        kpi1Label: 'الرصيد الكلي', kpi1Value: '${(totalAidAmount / 1000000).toStringAsFixed(1)}M',
        kpi2Label: 'عدد الأسر', kpi2Value: '${families.length}',
      ),
      _ReportCard(
        id: 'works',
        title: 'أعمال المؤسسة',
        subtitle: 'إحصائيات ومشاريع المؤسسة',
        icon: Icons.apartment_rounded,
        gradient: AppColors.gradientOrange,
        glow: const Color(0xFFF59E0B),
        kpi1Label: 'الأسر المستفيدة', kpi1Value: '$eligibleFam',
        kpi2Label: 'إجمالي الأفراد', kpi2Value: '$totalMembers',
      ),
    ];

    return Column(
      children: [
        Container(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('التقارير',
                            style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w900,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                        Text('تقارير تحليلية شاملة',
                            style: GoogleFonts.cairo(fontSize: 12,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: Row(children: [
                      Icon(Icons.picture_as_pdf_outlined, size: 14,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      const SizedBox(width: 6),
                      Text('تصدير PDF', style: GoogleFonts.cairo(fontSize: 11,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Quick stats row
              Row(
                children: [
                  const _QuickStat(label: 'التقارير', value: '7', color: AppColors.primary),
                  const SizedBox(width: 8),
                  _QuickStat(label: 'المشتركين', value: '${subs.length}', color: const Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  _QuickStat(label: 'المساعدات', value: '${aids.length}', color: const Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  _QuickStat(label: 'الأسر', value: '${families.length}', color: const Color(0xFF06B6D4)),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: (reports.length / 2).ceil(),
            itemBuilder: (ctx, row) {
              final left = reports[row * 2];
              final right = row * 2 + 1 < reports.length ? reports[row * 2 + 1] : null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _ReportCardWidget(
                      report: left, isDark: isDark,
                      subsRepo: subsRepo, famRepo: famRepo, aidRepo: aidRepo,
                      subs: subs, families: families, aids: aids,
                    )),
                    const SizedBox(width: 12),
                    if (right != null)
                      Expanded(child: _ReportCardWidget(
                        report: right, isDark: isDark,
                        subsRepo: subsRepo, famRepo: famRepo, aidRepo: aidRepo,
                        subs: subs, families: families, aids: aids,
                      ))
                    else
                      const Expanded(child: SizedBox()),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Quick Stat ─────────────────────────────────────────────────────────────────
class _QuickStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _QuickStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Text(value, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w900, color: color, height: 1.1)),
          Text(label, style: GoogleFonts.cairo(fontSize: 8, color: color.withValues(alpha: 0.75))),
        ]),
      ),
    );
  }
}

// ── Report Card Widget ─────────────────────────────────────────────────────────
class _ReportCardWidget extends StatelessWidget {
  final _ReportCard report;
  final bool isDark;
  final MockSubscribersRepository subsRepo;
  final MockFamiliesRepository famRepo;
  final MockAidRepository aidRepo;
  final List subs, families, aids;

  const _ReportCardWidget({
    required this.report, required this.isDark,
    required this.subsRepo, required this.famRepo, required this.aidRepo,
    required this.subs, required this.families, required this.aids,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = report.glow;

    return GestureDetector(
      onTap: () => _openReport(context),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withValues(alpha: isDark ? 0.22 : 0.12)),
          boxShadow: [
            BoxShadow(color: accentColor.withValues(alpha: isDark ? 0.28 : 0.15),
                blurRadius: 14, spreadRadius: -4, offset: const Offset(0, 7)),
            BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.07),
                blurRadius: 20, spreadRadius: -5, offset: const Offset(0, 10)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gradient header
              Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                decoration: BoxDecoration(gradient: report.gradient),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: Icon(report.icon, size: 20, color: Colors.white),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.arrow_outward_rounded, size: 14, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(report.title,
                        style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white,
                            shadows: [Shadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)]),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(report.subtitle,
                        style: GoogleFonts.cairo(fontSize: 9, color: Colors.white.withValues(alpha: 0.75)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),

              // Divider shine
              Container(height: 1, decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  accentColor.withValues(alpha: 0.0), accentColor.withValues(alpha: 0.5), accentColor.withValues(alpha: 0.0),
                ]),
              )),

              // KPI body
              Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(child: _KpiMini(
                      label: report.kpi1Label, value: report.kpi1Value,
                      color: accentColor, isDark: isDark,
                    )),
                    Container(width: 1, height: 36,
                        color: (isDark ? AppColors.borderDark : AppColors.borderLight).withValues(alpha: 0.7)),
                    Expanded(child: _KpiMini(
                      label: report.kpi2Label, value: report.kpi2Value,
                      color: accentColor, isDark: isDark,
                    )),
                  ],
                ),
              ),

              // Mini preview chart
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                child: SizedBox(
                  height: 52,
                  child: _MiniBarChart(
                    data: _miniChartData(),
                    color: accentColor,
                    isDark: isDark,
                  ),
                ),
              ),

              // Open button
              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    accentColor.withValues(alpha: isDark ? 0.18 : 0.1),
                    accentColor.withValues(alpha: isDark ? 0.08 : 0.05),
                  ]),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accentColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('عرض التقرير', style: GoogleFonts.cairo(
                        fontSize: 11, fontWeight: FontWeight.w700, color: accentColor)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_left_rounded, size: 14, color: accentColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<double> _miniChartData() {
    switch (report.id) {
      case 'delegates': return [5, 4, 6, 3, 5, 4];
      case 'overdue':   return [60, 25, 15];
      case 'expenses':  return [180, 220, 195, 240, 210, 230];
      case 'aid':
        final p = aids.where((a) => a.status == AidStatus.pending).length.toDouble();
        final ap = aids.where((a) => a.status == AidStatus.approved).length.toDouble();
        final d = aids.where((a) => a.status == AidStatus.distributed).length.toDouble();
        return [p, ap, d];
      case 'income':  return [310, 350, 290, 380, 340, 370];
      case 'funds':   return [45, 25, 20, 10];
      case 'works':   return [85, 70, 60, 45, 30];
      default:        return [1, 2, 3, 4, 5];
    }
  }

  void _openReport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportDetailSheet(
        report: report, isDark: isDark,
        subsRepo: subsRepo, famRepo: famRepo, aidRepo: aidRepo,
        subs: subs, families: families, aids: aids,
      ),
    );
  }
}

// ── Mini Bar Chart ────────────────────────────────────────────────────────────
class _MiniBarChart extends StatelessWidget {
  final List<double> data;
  final Color color;
  final bool isDark;
  const _MiniBarChart({required this.data, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.fold(0.0, (a, b) => a > b ? a : b);
    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxVal * 1.25,
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(enabled: false),
      barGroups: data.asMap().entries.map((e) => BarChartGroupData(
        x: e.key,
        barRods: [BarChartRodData(
          toY: e.value,
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.5), color],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 7,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(3),
            topRight: Radius.circular(3),
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxVal * 1.25,
            color: color.withValues(alpha: isDark ? 0.08 : 0.06),
          ),
        )],
      )).toList(),
    ));
  }
}

// ── KPI Mini ──────────────────────────────────────────────────────────────────
class _KpiMini extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isDark;
  const _KpiMini({required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w900, color: color, height: 1.1)),
      const SizedBox(height: 2),
      Text(label, style: GoogleFonts.cairo(fontSize: 8,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
    ]);
  }
}

// ── Report Detail Sheet ───────────────────────────────────────────────────────
class _ReportDetailSheet extends StatelessWidget {
  final _ReportCard report;
  final bool isDark;
  final MockSubscribersRepository subsRepo;
  final MockFamiliesRepository famRepo;
  final MockAidRepository aidRepo;
  final List subs, families, aids;

  const _ReportDetailSheet({
    required this.report, required this.isDark,
    required this.subsRepo, required this.famRepo, required this.aidRepo,
    required this.subs, required this.families, required this.aids,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Center(child: Container(margin: const EdgeInsets.only(top: 10),
                width: 40, height: 4, decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2)))),
            // Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(gradient: report.gradient, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                Icon(report.icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(report.title, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text(report.subtitle, style: GoogleFonts.cairo(fontSize: 10, color: Colors.white.withValues(alpha: 0.75))),
                ])),
              ]),
            ),

            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: _reportContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportContent(BuildContext context) {
    switch (report.id) {
      case 'delegates':
        return _DelegatesReportContent(subs: subs, isDark: isDark);
      case 'overdue':
        return _OverdueReportContent(subs: subs, isDark: isDark);
      case 'expenses':
      case 'income':
        return _MonthlyChartContent(aidRepo: aidRepo, isDark: isDark, isIncome: report.id == 'income');
      case 'aid':
        return _AidReportContent(aidRepo: aidRepo, aids: aids, isDark: isDark);
      case 'funds':
        return _FundsReportContent(families: families, isDark: isDark);
      case 'works':
        return _WorksReportContent(families: families, isDark: isDark);
      default:
        return const SizedBox();
    }
  }
}

// ── Report Content Widgets ────────────────────────────────────────────────────
class _DelegatesReportContent extends StatelessWidget {
  final List subs;
  final bool isDark;
  const _DelegatesReportContent({required this.subs, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final delegates = ['أحمد الكريمي', 'سارة الموسوي', 'حسين الجبوري', 'نور الهاشمي', 'علاء فارس', 'ريم العلي'];
    final counts = [5, 4, 6, 3, 5, 4];
    return Column(
      children: [
        _SummaryRow(items: [
          ('الإجمالي', '${subs.length}', const Color(0xFF3B82F6)),
          ('نشط', '${subs.where((s) => s.status == SubscriberStatus.active).length}', const Color(0xFF10B981)),
          ('معلق', '${subs.where((s) => s.status == SubscriberStatus.pending).length}', const Color(0xFFF59E0B)),
        ], isDark: isDark),
        const SizedBox(height: 16),
        _SectionCard(title: 'عدد المشتركين لكل مندوب', isDark: isDark, child: Column(
          children: delegates.asMap().entries.map((e) => _ProgressRow(
            label: e.value, value: counts[e.key], max: 8,
            color: const Color(0xFF3B82F6), isDark: isDark,
          )).toList(),
        )),
      ],
    );
  }
}

class _OverdueReportContent extends StatelessWidget {
  final List subs;
  final bool isDark;
  const _OverdueReportContent({required this.subs, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final total = subs.length;
    return Column(
      children: [
        _SummaryRow(items: [
          ('مسدد', '${(total * 0.6).round()}', const Color(0xFF10B981)),
          ('متأخر <4ش', '${(total * 0.25).round()}', const Color(0xFFF59E0B)),
          ('متأخر >4ش', '${(total * 0.15).round()}', const Color(0xFFEF4444)),
        ], isDark: isDark),
        const SizedBox(height: 16),
        _SectionCard(title: 'توزيع التأخر في التسديد', isDark: isDark, child: Column(
          children: [
            _ProgressRow(label: 'مسدد في الوقت', value: (total * 0.6).round(), max: total, color: const Color(0xFF10B981), isDark: isDark),
            _ProgressRow(label: 'تأخر أقل من شهر', value: (total * 0.15).round(), max: total, color: const Color(0xFF3B82F6), isDark: isDark),
            _ProgressRow(label: 'تأخر 1-4 أشهر', value: (total * 0.15).round(), max: total, color: const Color(0xFFF59E0B), isDark: isDark),
            _ProgressRow(label: 'تأخر أكثر من 4 أشهر', value: (total * 0.1).round(), max: total, color: const Color(0xFFEF4444), isDark: isDark),
          ],
        )),
      ],
    );
  }
}

class _MonthlyChartContent extends StatelessWidget {
  final MockAidRepository aidRepo;
  final bool isDark, isIncome;
  const _MonthlyChartContent({required this.aidRepo, required this.isDark, required this.isIncome});

  @override
  Widget build(BuildContext context) {
    final monthly = aidRepo.getMonthlyTotals();
    final color = isIncome ? const Color(0xFF7C3AED) : const Color(0xFF00C9A7);
    return Column(
      children: [
        _SummaryRow(items: [
          (isIncome ? 'الوارد الكلي' : 'الصرف الكلي', isIncome ? '3.8M' : '2.4M', color),
          ('الشهر الحالي', isIncome ? '380K' : '240K', color.withValues(alpha: 0.7)),
          ('المعدل', isIncome ? '310K' : '200K', color.withValues(alpha: 0.5)),
        ], isDark: isDark),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ChartCard(
            title: isIncome ? 'الوارد الشهري' : 'الصرف الشهري',
            subtitle: 'بالألف دينار',
            chart: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.borderLight, strokeWidth: 1, dashArray: [4, 4])),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                    getTitlesWidget: (v, m) {
                      const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو'];
                      final idx = v.toInt();
                      if (idx < 0 || idx >= months.length) return const SizedBox();
                      return Text(months[idx].substring(0, 3), style: GoogleFonts.cairo(fontSize: 9, color: AppColors.textTertiaryLight));
                    })),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36,
                    getTitlesWidget: (v, _) => Text('${v.toInt()}K', style: GoogleFonts.cairo(fontSize: 9, color: AppColors.textTertiaryLight)))),
              ),
              borderData: FlBorderData(show: false),
              barGroups: monthly.asMap().entries.map((e) {
                final val = (e.value['total'] as double) / 1000;
                return BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(
                    toY: val,
                    gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.6)],
                        begin: Alignment.bottomCenter, end: Alignment.topCenter),
                    width: 18,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                  ),
                ]);
              }).toList(),
            )),
          ),
        ),
      ],
    );
  }
}

class _AidReportContent extends StatelessWidget {
  final MockAidRepository aidRepo;
  final List aids;
  final bool isDark;
  const _AidReportContent({required this.aidRepo, required this.aids, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final pending = aids.where((a) => a.status == AidStatus.pending).length;
    final approved = aids.where((a) => a.status == AidStatus.approved).length;
    final distributed = aids.where((a) => a.status == AidStatus.distributed).length;
    final total = aids.length;
    return Column(
      children: [
        _SummaryRow(items: [
          ('الإجمالي', '$total', const Color(0xFF10B981)),
          ('معتمد', '$approved', const Color(0xFF3B82F6)),
          ('تم الصرف', '$distributed', const Color(0xFF00C9A7)),
        ], isDark: isDark),
        const SizedBox(height: 16),
        _SectionCard(title: 'حالات المساعدات', isDark: isDark, child: Column(children: [
          _ProgressRow(label: 'قيد الانتظار', value: pending, max: total, color: const Color(0xFFF59E0B), isDark: isDark),
          _ProgressRow(label: 'معتمد', value: approved, max: total, color: const Color(0xFF3B82F6), isDark: isDark),
          _ProgressRow(label: 'تم الصرف', value: distributed, max: total, color: const Color(0xFF10B981), isDark: isDark),
        ])),
      ],
    );
  }
}

class _FundsReportContent extends StatelessWidget {
  final List families;
  final bool isDark;
  const _FundsReportContent({required this.families, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fam = families.cast<FamilyModel>();
    final eligible = fam.where((f) => f.status == FamilyStatus.eligible).length;
    final totalAid = fam.fold(0.0, (s, f) => s + f.totalAidAmount);
    return Column(
      children: [
        _SummaryRow(items: [
          ('الرصيد الكلي', '${(totalAid / 1000000).toStringAsFixed(1)}M', const Color(0xFF6366F1)),
          ('الأسر المستفيدة', '$eligible', const Color(0xFF10B981)),
          ('متوسط الصرف', '${(totalAid / eligible / 1000).toStringAsFixed(0)}K', const Color(0xFF3B82F6)),
        ], isDark: isDark),
        const SizedBox(height: 16),
        _SectionCard(title: 'توزيع الصناديق حسب الحالة', isDark: isDark, child: Column(children: [
          _ProgressRow(label: 'صندوق المساعدات', value: 45, max: 100, color: const Color(0xFF6366F1), isDark: isDark),
          _ProgressRow(label: 'صندوق الطوارئ', value: 25, max: 100, color: const Color(0xFFEF4444), isDark: isDark),
          _ProgressRow(label: 'صندوق التطوير', value: 20, max: 100, color: const Color(0xFF10B981), isDark: isDark),
          _ProgressRow(label: 'الاحتياطي', value: 10, max: 100, color: const Color(0xFFF59E0B), isDark: isDark),
        ])),
      ],
    );
  }
}

class _WorksReportContent extends StatelessWidget {
  final List families;
  final bool isDark;
  const _WorksReportContent({required this.families, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fam = families.cast<FamilyModel>();
    final totalMembers = fam.fold(0, (s, f) => s + f.membersCount);
    return Column(
      children: [
        _SummaryRow(items: [
          ('المشاريع', '15', const Color(0xFFF59E0B)),
          ('الأسر المستفيدة', '${fam.length}', const Color(0xFF10B981)),
          ('الأفراد', '$totalMembers', const Color(0xFF3B82F6)),
        ], isDark: isDark),
        const SizedBox(height: 16),
        _SectionCard(title: 'مشاريع المؤسسة', isDark: isDark, child: Column(children: [
          _ProgressRow(label: 'توزيع المواد الغذائية', value: 85, max: 100, color: const Color(0xFF10B981), isDark: isDark),
          _ProgressRow(label: 'الرعاية الطبية', value: 70, max: 100, color: const Color(0xFF3B82F6), isDark: isDark),
          _ProgressRow(label: 'دعم التعليم', value: 60, max: 100, color: const Color(0xFF7C3AED), isDark: isDark),
          _ProgressRow(label: 'مشاريع البنية التحتية', value: 45, max: 100, color: const Color(0xFFF59E0B), isDark: isDark),
          _ProgressRow(label: 'التدريب المهني', value: 30, max: 100, color: const Color(0xFF06B6D4), isDark: isDark),
        ])),
      ],
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final List<(String, String, Color)> items;
  final bool isDark;
  const _SummaryRow({required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items.asMap().entries.expand((e) {
        final (label, value, color) = e.value;
        return [
          if (e.key > 0) const SizedBox(width: 8),
          Expanded(child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(children: [
              Text(value, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w900, color: color, height: 1.1)),
              Text(label, style: GoogleFonts.cairo(fontSize: 9, color: color.withValues(alpha: 0.8)), textAlign: TextAlign.center),
            ]),
          )),
        ];
      }).toList(),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isDark;
  const _SectionCard({required this.title, required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title, padding: const EdgeInsets.only(bottom: 12)),
          child,
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int value, max;
  final Color color;
  final bool isDark;
  const _ProgressRow({required this.label, required this.value, required this.max, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? value / max : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.cairo(fontSize: 12,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              Text('$value (${(pct * 100).toStringAsFixed(0)}%)',
                  style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
