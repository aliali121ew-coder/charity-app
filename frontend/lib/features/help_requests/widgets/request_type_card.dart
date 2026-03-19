import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/help_requests/domain/entities/request_type.dart';

class RequestTypeCard extends StatelessWidget {
  final RequestType type;
  final VoidCallback onTap;
  final bool isSelected;

  const RequestTypeCard({
    super.key,
    required this.type,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (gradient, icon) = _config(type);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const Spacer(),
                if (isSelected)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 13),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              type.labelAr,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 4),
            Text(
              type.descriptionAr,
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  static (Gradient gradient, IconData icon) _config(RequestType t) {
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
}
