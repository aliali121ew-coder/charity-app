import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';

class GeneralHelpSection extends StatefulWidget {
  final Map<String, String> data;
  final void Function(Map<String, String>) onChanged;

  const GeneralHelpSection({
    super.key,
    required this.data,
    required this.onChanged,
  });

  @override
  State<GeneralHelpSection> createState() => _GeneralHelpSectionState();
}

class _GeneralHelpSectionState extends State<GeneralHelpSection> {
  static const _categories = [
    ('general', 'مساعدة عامة'),
    ('food', 'غذاء / وجبات'),
    ('clothing', 'ملابس'),
    ('hygiene', 'مستلزمات نظافة'),
    ('other', 'أخرى'),
  ];

  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.data['helpCategory'] ?? 'general';
  }

  void _notify() {
    widget.onChanged({'helpCategory': _selected});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(label: 'نوع المساعدة المطلوبة', isDark: isDark),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((cat) {
            final isSelected = _selected == cat.$1;
            return GestureDetector(
              onTap: () {
                setState(() => _selected = cat.$1);
                _notify();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : isDark
                          ? AppColors.surfaceVariantDark
                          : AppColors.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  cat.$2,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            );
          }).toList(),
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
            gradient: AppColors.gradientPurple,
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
