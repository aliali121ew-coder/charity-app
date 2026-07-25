import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/shared/models/log_model.dart';
import 'package:charity_app/shared/widgets/status_chip.dart';
import 'package:intl/intl.dart';

class ActivityLogItem extends StatelessWidget {
  final LogModel log;
  final bool isLast;

  const ActivityLogItem({
    super.key,
    required this.log,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _actionColor(log.actionType);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_actionIcon(log.actionType), size: 17, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            log.actionTitle,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip.logAction(log.actionType),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      log.description,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 13,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          log.performedBy,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _formatTime(log.timestamp),
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                      ],
                    ),
                    if (log.referenceNumber != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.tag_rounded,
                            size: 12,
                            color: AppColors.primary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            log.referenceNumber!,
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: AppColors.primary.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  Color _actionColor(LogActionType type) {
    switch (type) {
      case LogActionType.add: return AppColors.logAdd;
      case LogActionType.edit: return AppColors.logEdit;
      case LogActionType.delete: return AppColors.logDelete;
      case LogActionType.approve: return AppColors.logApprove;
      case LogActionType.reject: return AppColors.logReject;
      case LogActionType.distribute: return AppColors.logDistribute;
      case LogActionType.login: return AppColors.logLogin;
      case LogActionType.logout: return AppColors.logSettings;
      case LogActionType.report: return AppColors.logReport;
      case LogActionType.settings: return AppColors.logSettings;
      case LogActionType.updateFamily: return AppColors.logEdit;
      case LogActionType.updateSubscriber: return AppColors.logEdit;
    }
  }

  IconData _actionIcon(LogActionType type) {
    switch (type) {
      case LogActionType.add: return Icons.add_circle_outline_rounded;
      case LogActionType.edit: return Icons.edit_outlined;
      case LogActionType.delete: return Icons.delete_outline_rounded;
      case LogActionType.approve: return Icons.check_circle_outline_rounded;
      case LogActionType.reject: return Icons.cancel_outlined;
      case LogActionType.distribute: return Icons.volunteer_activism_outlined;
      case LogActionType.login: return Icons.login_rounded;
      case LogActionType.logout: return Icons.logout_rounded;
      case LogActionType.report: return Icons.assessment_outlined;
      case LogActionType.settings: return Icons.settings_outlined;
      case LogActionType.updateFamily: return Icons.family_restroom_outlined;
      case LogActionType.updateSubscriber: return Icons.person_outline_rounded;
    }
  }
}
