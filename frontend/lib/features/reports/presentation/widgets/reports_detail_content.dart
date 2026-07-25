part of '../pages/reports_page.dart';

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
