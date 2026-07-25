part of '../pages/reports_page.dart';

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
                        maxLines: 2, overflow: TextOverflow.fade),
                    Text(report.subtitle,
                        style: GoogleFonts.cairo(fontSize: 9, color: Colors.white.withValues(alpha: 0.75)),
                        maxLines: 2, overflow: TextOverflow.fade),
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
    if (report.id == 'overdue') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OverdueTablePage()),
      );
      return;
    }
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
          textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.fade),
    ]);
  }
}

// ── Report Detail Sheet ───────────────────────────────────────────────────────
