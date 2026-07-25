import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';

class HouseholdMaterialsSection extends StatefulWidget {
  final Map<String, String> data;
  final void Function(Map<String, String>) onChanged;

  const HouseholdMaterialsSection({
    super.key,
    required this.data,
    required this.onChanged,
  });

  @override
  State<HouseholdMaterialsSection> createState() =>
      _HouseholdMaterialsSectionState();
}

class _HouseholdMaterialsSectionState extends State<HouseholdMaterialsSection> {
  static const _categories = [
    ('bedroom', 'غرفة النوم', Icons.bed_outlined),
    ('kitchen', 'المطبخ', Icons.kitchen_outlined),
    ('bathroom', 'الحمام', Icons.bathroom_outlined),
    ('living', 'الصالة', Icons.weekend_outlined),
    ('other', 'أخرى', Icons.more_horiz_rounded),
  ];

  late String _category;
  late final TextEditingController _itemsCtrl;

  @override
  void initState() {
    super.initState();
    _category = widget.data['furnitureCategory'] ?? 'other';
    _itemsCtrl =
        TextEditingController(text: widget.data['itemsNeeded'] ?? '');
  }

  @override
  void dispose() {
    _itemsCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged({
      'furnitureCategory': _category,
      'itemsNeeded': _itemsCtrl.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(label: 'تفاصيل المواد المنزلية', isDark: isDark),
        const SizedBox(height: 12),
        Text(
          'فئة المواد',
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((cat) {
            final isSelected = _category == cat.$1;
            return GestureDetector(
              onTap: () {
                setState(() => _category = cat.$1);
                _notify();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.indigo.withValues(alpha: 0.12)
                      : isDark
                          ? AppColors.surfaceVariantDark
                          : AppColors.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.indigo
                        : isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat.$3,
                      size: 14,
                      color: isSelected
                          ? AppColors.indigo
                          : isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat.$2,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.indigo
                            : isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text(
          'المواد والأثاث المطلوبة',
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _itemsCtrl,
          maxLines: 4,
          onChanged: (_) => _notify(),
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText:
                'اذكر المواد المطلوبة بالتفصيل\nمثال: سرير مفرد، طاولة طعام، ثلاجة...',
            hintStyle: GoogleFonts.cairo(
              fontSize: 12,
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
            ),
            filled: true,
            fillColor: isDark
                ? AppColors.surfaceVariantDark
                : AppColors.surfaceVariantLight,
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
            gradient: AppColors.gradientIndigo,
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
