import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';

class FoodBasketSection extends StatefulWidget {
  final Map<String, String> data;
  final void Function(Map<String, String>) onChanged;

  const FoodBasketSection({
    super.key,
    required this.data,
    required this.onChanged,
  });

  @override
  State<FoodBasketSection> createState() => _FoodBasketSectionState();
}

class _FoodBasketSectionState extends State<FoodBasketSection> {
  static const _basketTypes = [
    ('standard', 'سلة قياسية', 'مواد غذائية أساسية للأسرة'),
    ('large', 'سلة كبيرة', 'لأسرة كبيرة أو احتياج أعلى'),
    ('ramadan', 'سلة رمضانية', 'حصة خاصة بشهر رمضان'),
  ];

  late String _basketType;
  late final TextEditingController _specialRequestsCtrl;

  @override
  void initState() {
    super.initState();
    _basketType = widget.data['basketType'] ?? 'standard';
    _specialRequestsCtrl =
        TextEditingController(text: widget.data['specialRequests'] ?? '');
  }

  @override
  void dispose() {
    _specialRequestsCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged({
      'basketType': _basketType,
      'specialRequests': _specialRequestsCtrl.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(label: 'تفاصيل السلة الغذائية', isDark: isDark),
        const SizedBox(height: 12),
        ...(_basketTypes.map((bt) {
          final isSelected = _basketType == bt.$1;
          return GestureDetector(
            onTap: () {
              setState(() => _basketType = bt.$1);
              _notify();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariantLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.borderLight,
                        width: 2,
                      ),
                      color: isSelected ? AppColors.primary : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bt.$2,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.primary
                                : isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          bt.$3,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        })),
        const SizedBox(height: 4),
        Text(
          'طلبات خاصة (اختياري)',
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _specialRequestsCtrl,
          maxLines: 2,
          onChanged: (_) => _notify(),
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: 'مثال: حساسية من الجلوتين، بدون سكر...',
            hintStyle: GoogleFonts.cairo(
              fontSize: 12,
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
            ),
            filled: true,
            fillColor:
                isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionTitle({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            gradient: AppColors.gradientGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}
