import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/shared/models/subscriber_model.dart';
import 'package:charity_app/shared/models/family_model.dart';
import 'package:charity_app/shared/models/aid_model.dart';
import 'package:charity_app/shared/models/log_model.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final bool dot;

  const StatusChip({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
    this.dot = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: textColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ] else if (icon != null) ...[
            Icon(icon, size: 11, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Factory constructors by model status ──────────────────────────────────

  factory StatusChip.subscriber(SubscriberStatus status, bool isArabic) {
    final label = isArabic ? status.labelAr : status.labelEn;
    switch (status) {
      case SubscriberStatus.active:
        return StatusChip(
          label: label,
          backgroundColor: AppColors.statusActiveBg,
          textColor: AppColors.statusActiveText,
        );
      case SubscriberStatus.inactive:
        return StatusChip(
          label: label,
          backgroundColor: AppColors.statusInactiveBg,
          textColor: AppColors.statusInactiveText,
        );
      case SubscriberStatus.pending:
        return StatusChip(
          label: label,
          backgroundColor: AppColors.statusPendingBg,
          textColor: AppColors.statusPendingText,
        );
      case SubscriberStatus.suspended:
        return StatusChip(
          label: label,
          backgroundColor: AppColors.statusRejectedBg,
          textColor: AppColors.statusRejectedText,
        );
    }
  }

  factory StatusChip.family(FamilyStatus status) {
    switch (status) {
      case FamilyStatus.eligible:
        return StatusChip(
          label: status.labelAr,
          backgroundColor: AppColors.statusActiveBg,
          textColor: AppColors.statusActiveText,
        );
      case FamilyStatus.ineligible:
        return StatusChip(
          label: status.labelAr,
          backgroundColor: AppColors.statusRejectedBg,
          textColor: AppColors.statusRejectedText,
        );
      case FamilyStatus.pending:
        return StatusChip(
          label: status.labelAr,
          backgroundColor: AppColors.statusPendingBg,
          textColor: AppColors.statusPendingText,
        );
      case FamilyStatus.suspended:
        return StatusChip(
          label: status.labelAr,
          backgroundColor: AppColors.statusInactiveBg,
          textColor: AppColors.statusInactiveText,
        );
    }
  }

  factory StatusChip.aid(AidStatus status) {
    switch (status) {
      case AidStatus.pending:
        return StatusChip(
          label: status.labelAr,
          backgroundColor: AppColors.statusPendingBg,
          textColor: AppColors.statusPendingText,
        );
      case AidStatus.approved:
        return StatusChip(
          label: status.labelAr,
          backgroundColor: AppColors.statusApprovedBg,
          textColor: AppColors.statusApprovedText,
        );
      case AidStatus.rejected:
        return StatusChip(
          label: status.labelAr,
          backgroundColor: AppColors.statusRejectedBg,
          textColor: AppColors.statusRejectedText,
        );
      case AidStatus.distributed:
        return StatusChip(
          label: status.labelAr,
          backgroundColor: AppColors.statusActiveBg,
          textColor: AppColors.statusActiveText,
        );
    }
  }

  factory StatusChip.logAction(LogActionType type) {
    final color = _actionColor(type);
    return StatusChip(
      label: type.labelAr,
      backgroundColor: color.withValues(alpha: 0.12),
      textColor: color,
      dot: false,
    );
  }

  static Color _actionColor(LogActionType type) {
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
}
