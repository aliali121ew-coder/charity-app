import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';

class TreatmentSection extends StatefulWidget {
  final Map<String, String> data;
  final void Function(Map<String, String>) onChanged;

  const TreatmentSection({
    super.key,
    required this.data,
    required this.onChanged,
  });

  @override
  State<TreatmentSection> createState() => _TreatmentSectionState();
}

class _TreatmentSectionState extends State<TreatmentSection> {
  late final TextEditingController _medicationCtrl;
  late final TextEditingController _diagnosisCtrl;
  late final TextEditingController _quantityCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _medicationCtrl = TextEditingController(text: d['medicationName'] ?? '');
    _diagnosisCtrl = TextEditingController(text: d['diagnosisDetails'] ?? '');
    _quantityCtrl = TextEditingController(text: d['requiredQuantity'] ?? '');
  }

  @override
  void dispose() {
    _medicationCtrl.dispose();
    _diagnosisCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged({
      'medicationName': _medicationCtrl.text,
      'diagnosisDetails': _diagnosisCtrl.text,
      'requiredQuantity': _quantityCtrl.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(label: 'بيانات طلب العلاج', isDark: isDark),
        const SizedBox(height: 12),
        _buildLabel('اسم الدواء / العلاج', isDark),
        const SizedBox(height: 6),
        _buildField(
          controller: _medicationCtrl,
          hint: 'اسم الدواء أو نوع العلاج المطلوب',
          icon: Icons.medication_outlined,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildLabel('تفاصيل التشخيص', isDark),
        const SizedBox(height: 6),
        _buildField(
          controller: _diagnosisCtrl,
          hint: 'اذكر التشخيص الطبي أو تقرير الطبيب...',
          icon: Icons.health_and_safety_outlined,
          isDark: isDark,
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        _buildLabel('الكمية المطلوبة (اختياري)', isDark),
        const SizedBox(height: 6),
        _buildField(
          controller: _quantityCtrl,
          hint: 'مثال: 3 علب، دورة كاملة...',
          icon: Icons.inventory_2_outlined,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildLabel(String label, bool isDark) {
    return Text(
      label,
      style: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: (_) => _notify(),
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
        prefixIcon: maxLines == 1
            ? Icon(icon, size: 18,
                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight)
            : null,
        filled: true,
        fillColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
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
            gradient: AppColors.gradientBlue,
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
