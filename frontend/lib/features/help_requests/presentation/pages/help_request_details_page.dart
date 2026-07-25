import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/help_requests/domain/entities/request_type.dart';
import 'package:charity_app/features/help_requests/providers/help_requests_provider.dart';
import 'package:charity_app/features/help_requests/widgets/request_status_badge.dart';
import 'package:charity_app/features/help_requests/widgets/edit_window_indicator.dart';
import 'package:charity_app/features/help_requests/widgets/location_summary_widget.dart';

class HelpRequestDetailsPage extends ConsumerWidget {
  final String requestId;

  const HelpRequestDetailsPage({super.key, required this.requestId});

  static (LinearGradient, IconData) _typeConfig(RequestType t) {
    switch (t) {
      case RequestType.generalHelp:
        return (AppColors.gradientPurple, Icons.volunteer_activism_rounded);
      case RequestType.doctorBooking:
        return (AppColors.gradientTeal, Icons.medical_services_rounded);
      case RequestType.treatment:
        return (AppColors.gradientBlue, Icons.medication_rounded);
      case RequestType.foodBasket:
        return (AppColors.gradientGreen, Icons.shopping_basket_rounded);
      case RequestType.financial:
        return (AppColors.gradientOrange, Icons.account_balance_wallet_rounded);
      case RequestType.householdMaterials:
        return (AppColors.gradientIndigo, Icons.chair_rounded);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final request =
        ref.watch(helpRequestsProvider.notifier).getById(requestId);

    if (request == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text('الطلب غير موجود', style: GoogleFonts.cairo()),
        ),
      );
    }

    final (gradient, icon) = _typeConfig(request.type);
    final dateStr =
        intl.DateFormat('dd/MM/yyyy  HH:mm').format(request.submittedAt);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // SliverAppBar with gradient header
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor:
                isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded,
                  size: 18,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (request.isEditable)
                TextButton.icon(
                  onPressed: () =>
                      context.push('/help-requests/${request.id}/edit'),
                  icon: const Icon(Icons.edit_outlined,
                      size: 16, color: AppColors.primary),
                  label: Text(
                    'تعديل',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      gradient.colors.first.withValues(alpha: 0.15),
                      gradient.colors.last.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 80, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: gradient.colors.first
                                  .withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.type.labelAr,
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: gradient.colors.first,
                              ),
                            ),
                            Text(
                              request.title,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      RequestStatusBadge(status: request.status),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Edit window
                  EditWindowIndicator(
                    request: request,
                    onEditTap: request.isEditable
                        ? () => context
                            .push('/help-requests/${request.id}/edit')
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Meta chips row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaTag(
                          icon: Icons.access_time_rounded, label: dateStr, isDark: isDark),
                      _MetaTag(
                          icon: Icons.warning_amber_rounded,
                          label: request.urgency.labelAr,
                          isDark: isDark),
                      if (request.familySize != null)
                        _MetaTag(
                            icon: Icons.group_rounded,
                            label: '${request.familySize} أفراد',
                            isDark: isDark),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description card
                  _InfoCard(
                    title: 'وصف الطلب',
                    isDark: isDark,
                    child: Text(
                      request.description,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        height: 1.6,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Personal info card
                  _InfoCard(
                    title: 'بيانات مقدم الطلب',
                    isDark: isDark,
                    child: Column(
                      children: [
                        _InfoRow(
                            label: 'الاسم',
                            value: request.fullName,
                            isDark: isDark),
                        const SizedBox(height: 8),
                        _InfoRow(
                            label: 'الهاتف',
                            value: request.phone,
                            isDark: isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Location card
                  _InfoCard(
                    title: 'الموقع',
                    isDark: isDark,
                    child: LocationSummaryWidget(
                      location: request.location,
                      compact: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Type-specific data
                  if (request.typeData.isNotEmpty) ...[
                    _InfoCard(
                      title: 'بيانات إضافية',
                      isDark: isDark,
                      child: Column(
                        children: request.typeData.entries
                            .where((e) => e.value.isNotEmpty)
                            .map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _InfoRow(
                                    label: _typeDataLabel(e.key),
                                    value: e.value,
                                    isDark: isDark,
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Attachments card
                  if (request.attachments.isNotEmpty) ...[
                    _InfoCard(
                      title: 'المرفقات (${request.attachments.length})',
                      isDark: isDark,
                      child: Column(
                        children: request.attachments.map((a) {
                          final isVoice = a.isVoiceNote;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.backgroundDark
                                  : AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    gradient: isVoice
                                        ? AppColors.gradientPurple
                                        : AppColors.gradientBlue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isVoice
                                        ? Icons.mic_rounded
                                        : Icons.image_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    a.name,
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ),
                                if (isVoice && a.durationSeconds != null)
                                  Text(
                                    a.durationFormatted,
                                    style: GoogleFonts.cairo(
                                      fontSize: 10,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Notes
                  if (request.notes != null && request.notes!.isNotEmpty) ...[
                    _InfoCard(
                      title: 'ملاحظات',
                      isDark: isDark,
                      child: Text(
                        request.notes!,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          height: 1.5,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _typeDataLabel(String key) {
    const labels = {
      'helpCategory': 'فئة المساعدة',
      'patientName': 'اسم المريض',
      'patientAge': 'عمر المريض',
      'specialtyNeeded': 'التخصص',
      'preferredHospital': 'المستشفى',
      'preferredDate': 'تاريخ الموعد',
      'medicationName': 'اسم الدواء',
      'diagnosisDetails': 'التشخيص',
      'requiredQuantity': 'الكمية',
      'basketType': 'نوع السلة',
      'specialRequests': 'طلبات خاصة',
      'requestedAmount': 'المبلغ المطلوب',
      'purposeDetails': 'الغرض',
      'bankName': 'البنك',
      'furnitureCategory': 'الفئة',
      'itemsNeeded': 'المواد المطلوبة',
    };
    return labels[key] ?? key;
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isDark;

  const _InfoCard({
    required this.title,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _MetaTag({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:
            isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
