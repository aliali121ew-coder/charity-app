import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/shared/widgets/section_header.dart';
import 'package:charity_app/shared/widgets/chart_card.dart';
import 'package:charity_app/shared/providers/supabase_repository_providers.dart';
import 'package:charity_app/shared/models/aid_model.dart';
import 'package:charity_app/shared/models/subscriber_model.dart';
import 'package:charity_app/shared/models/family_model.dart';
import 'overdue_table_page.dart';

part '../widgets/reports_widgets.dart';
part '../widgets/reports_detail_content.dart';

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

    // ── Data sources (Supabase via FutureProviders) ──────────────────────────
    final asyncSubs = ref.watch(subscribersListProvider);
    final asyncFamilies = ref.watch(familiesListProvider);
    final asyncAids = ref.watch(aidListProvider);

    // Single spinner/error until all three sources resolve.
    final asyncs = [asyncSubs, asyncFamilies, asyncAids];
    if (asyncs.any((a) => a.isLoading)) {
      return const Center(child: CircularProgressIndicator());
    }
    if (asyncs.any((a) => a.hasError)) {
      return _ReportsError(
        onRetry: () {
          ref.invalidate(subscribersListProvider);
          ref.invalidate(familiesListProvider);
          ref.invalidate(aidListProvider);
        },
      );
    }

    final subs = asyncSubs.value ?? const <SubscriberModel>[];
    final families = asyncFamilies.value ?? const <FamilyModel>[];
    final aids = asyncAids.value ?? const <AidModel>[];

    final activeSubs = subs.where((s) => s.status == SubscriberStatus.active).length;
    final eligibleFam = families.where((f) => f.status == FamilyStatus.eligible).length;
    final totalAidAmount = aids.fold<double>(0, (sum, a) => sum + a.amount);
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
                      subs: subs, families: families, aids: aids,
                    )),
                    const SizedBox(width: 12),
                    if (right != null)
                      Expanded(child: _ReportCardWidget(
                        report: right, isDark: isDark,
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

// ── Error State ────────────────────────────────────────────────────────────────
class _ReportsError extends StatelessWidget {
  final VoidCallback onRetry;
  const _ReportsError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              'تعذّر تحميل البيانات',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Stat ─────────────────────────────────────────────────────────────────
