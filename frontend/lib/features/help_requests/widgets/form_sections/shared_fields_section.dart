import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/help_requests/domain/entities/urgency_level.dart';

/// Keys used in the data map
class SharedFieldKeys {
  static const fullName = 'fullName';
  static const phone = 'phone';
  static const title = 'title';
  static const description = 'description';
  static const urgency = 'urgency';
  static const familySize = 'familySize';
  static const notes = 'notes';
}

class SharedFieldsSection extends StatefulWidget {
  final Map<String, String> data;
  final void Function(Map<String, String>) onChanged;

  const SharedFieldsSection({
    super.key,
    required this.data,
    required this.onChanged,
  });

  @override
  State<SharedFieldsSection> createState() => _SharedFieldsSectionState();
}

class _SharedFieldsSectionState extends State<SharedFieldsSection> {
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _familySizeCtrl;
  late final TextEditingController _notesCtrl;
  late UrgencyLevel _urgency;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _fullNameCtrl = TextEditingController(text: d[SharedFieldKeys.fullName] ?? '');
    _phoneCtrl = TextEditingController(text: d[SharedFieldKeys.phone] ?? '');
    _titleCtrl = TextEditingController(text: d[SharedFieldKeys.title] ?? '');
    _descriptionCtrl = TextEditingController(text: d[SharedFieldKeys.description] ?? '');
    _familySizeCtrl = TextEditingController(text: d[SharedFieldKeys.familySize] ?? '');
    _notesCtrl = TextEditingController(text: d[SharedFieldKeys.notes] ?? '');
    _urgency = UrgencyLevel.values.firstWhere(
      (u) => u.name == (d[SharedFieldKeys.urgency] ?? ''),
      orElse: () => UrgencyLevel.medium,
    );
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _familySizeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged({
      SharedFieldKeys.fullName: _fullNameCtrl.text,
      SharedFieldKeys.phone: _phoneCtrl.text,
      SharedFieldKeys.title: _titleCtrl.text,
      SharedFieldKeys.description: _descriptionCtrl.text,
      SharedFieldKeys.urgency: _urgency.name,
      SharedFieldKeys.familySize: _familySizeCtrl.text,
      SharedFieldKeys.notes: _notesCtrl.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(label: 'المعلومات الشخصية', isDark: isDark),
        const SizedBox(height: 12),
        _FormField(
          controller: _fullNameCtrl,
          label: 'الاسم الكامل',
          hint: 'أدخل اسمك الكامل',
          icon: Icons.person_outline_rounded,
          onChanged: (_) => _notify(),
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _FormField(
          controller: _phoneCtrl,
          label: 'رقم الهاتف',
          hint: '07xxxxxxxxx',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => _notify(),
          isDark: isDark,
        ),
        const SizedBox(height: 20),
        _SectionHeader(label: 'تفاصيل الطلب', isDark: isDark),
        const SizedBox(height: 12),
        _FormField(
          controller: _titleCtrl,
          label: 'عنوان الطلب',
          hint: 'وصف موجز للطلب',
          icon: Icons.title_rounded,
          onChanged: (_) => _notify(),
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _FormField(
          controller: _descriptionCtrl,
          label: 'وصف تفصيلي',
          hint: 'اشرح حالتك بالتفصيل...',
          icon: Icons.description_outlined,
          maxLines: 4,
          onChanged: (_) => _notify(),
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _UrgencyDropdown(
          value: _urgency,
          isDark: isDark,
          onChanged: (val) {
            if (val != null) {
              setState(() => _urgency = val);
              _notify();
            }
          },
        ),
        const SizedBox(height: 12),
        _FormField(
          controller: _familySizeCtrl,
          label: 'عدد أفراد الأسرة (اختياري)',
          hint: 'مثال: 5',
          icon: Icons.group_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => _notify(),
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _FormField(
          controller: _notesCtrl,
          label: 'ملاحظات إضافية (اختياري)',
          hint: 'أي معلومات إضافية...',
          icon: Icons.notes_rounded,
          maxLines: 2,
          onChanged: (_) => _notify(),
          isDark: isDark,
        ),
      ],
    );
  }
}

// ── Internal helpers ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionHeader({required this.label, required this.isDark});

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

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String) onChanged;
  final bool isDark;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.cairo(
              fontSize: 12,
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
            ),
            prefixIcon: Icon(icon, size: 18,
                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
            filled: true,
            fillColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _UrgencyDropdown extends StatelessWidget {
  final UrgencyLevel value;
  final bool isDark;
  final void Function(UrgencyLevel?) onChanged;

  const _UrgencyDropdown({
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  Color _urgencyColor(UrgencyLevel level) {
    switch (level) {
      case UrgencyLevel.low: return AppColors.success;
      case UrgencyLevel.medium: return AppColors.warning;
      case UrgencyLevel.high: return AppColors.error;
      case UrgencyLevel.critical: return const Color(0xFF7C0000);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'درجة الأولوية',
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<UrgencyLevel>(
              value: value,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              borderRadius: BorderRadius.circular(12),
              dropdownColor: isDark ? AppColors.cardDark : AppColors.surfaceLight,
              onChanged: onChanged,
              items: UrgencyLevel.values.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _urgencyColor(level),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        level.labelAr,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

