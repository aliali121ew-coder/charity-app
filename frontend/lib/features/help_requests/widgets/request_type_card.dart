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

    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 360;
    final isLarge = screenWidth > 600;

    final paddingVal = isNarrow
        ? 10.0
        : isLarge
            ? 20.0
            : 16.0;
    final iconContainerSize = isNarrow
        ? 36.0
        : isLarge
            ? 52.0
            : 44.0;
    final iconSizeVal = isNarrow
        ? 18.0
        : isLarge
            ? 26.0
            : 22.0;
    final titleFontSize = isNarrow
        ? 12.0
        : isLarge
            ? 16.5
            : 14.0;
    final descFontSize = isNarrow
        ? 9.5
        : isLarge
            ? 12.5
            : 11.0;
    final gapHeight = isNarrow
        ? 8.0
        : isLarge
            ? 16.0
            : 12.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.all(paddingVal),
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
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(isNarrow ? 8 : 12),
                  ),
                  child: Icon(icon, color: Colors.white, size: iconSizeVal),
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
            SizedBox(height: gapHeight),
            Flexible(
              child: Text(
                type.labelAr,
                style: GoogleFonts.cairo(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                type.descriptionAr,
                style: GoogleFonts.cairo(
                  fontSize: descFontSize,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
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
