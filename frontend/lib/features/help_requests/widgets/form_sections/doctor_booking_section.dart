import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';

class DoctorBookingSection extends StatefulWidget {
  final Map<String, String> data;
  final void Function(Map<String, String>) onChanged;

  const DoctorBookingSection({
    super.key,
    required this.data,
    required this.onChanged,
  });

  @override
  State<DoctorBookingSection> createState() => _DoctorBookingSectionState();
}

class _DoctorBookingSectionState extends State<DoctorBookingSection> {
  late final TextEditingController _patientNameCtrl;
  late final TextEditingController _patientAgeCtrl;
  late final TextEditingController _specialtyCtrl;
  late final TextEditingController _hospitalCtrl;
  late final TextEditingController _preferredDateCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _patientNameCtrl = TextEditingController(text: d['patientName'] ?? '');
    _patientAgeCtrl = TextEditingController(text: d['patientAge'] ?? '');
    _specialtyCtrl = TextEditingController(text: d['specialtyNeeded'] ?? '');
    _hospitalCtrl = TextEditingController(text: d['preferredHospital'] ?? '');
    _preferredDateCtrl = TextEditingController(text: d['preferredDate'] ?? '');
  }

  @override
  void dispose() {
    _patientNameCtrl.dispose();
    _patientAgeCtrl.dispose();
    _specialtyCtrl.dispose();
    _hospitalCtrl.dispose();
    _preferredDateCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged({
      'patientName': _patientNameCtrl.text,
      'patientAge': _patientAgeCtrl.text,
      'specialtyNeeded': _specialtyCtrl.text,
      'preferredHospital': _hospitalCtrl.text,
      'preferredDate': _preferredDateCtrl.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(label: 'بيانات الحجز الطبي', isDark: isDark),
        const SizedBox(height: 12),
        _FieldLabel(label: 'اسم المريض', isDark: isDark),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _patientNameCtrl,
          hint: 'الاسم الكامل للمريض',
          icon: Icons.person_outline_rounded,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _FieldLabel(label: 'عمر المريض', isDark: isDark),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _patientAgeCtrl,
          hint: 'مثال: 35',
          icon: Icons.cake_outlined,
          isDark: isDark,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 12),
        _FieldLabel(label: 'التخصص المطلوب', isDark: isDark),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _specialtyCtrl,
          hint: 'مثال: طب الأطفال، قلبية...',
          icon: Icons.medical_services_outlined,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _FieldLabel(label: 'المستشفى المفضّل (اختياري)', isDark: isDark),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _hospitalCtrl,
          hint: 'اسم المستشفى أو المركز الصحي',
          icon: Icons.local_hospital_outlined,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _FieldLabel(label: 'التاريخ المفضل للموعد', isDark: isDark),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: now.add(const Duration(days: 1)),
              firstDate: now,
              lastDate: now.add(const Duration(days: 90)),
              locale: const Locale('ar'),
            );
            if (picked != null) {
              _preferredDateCtrl.text =
                  '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
              _notify();
            }
          },
          child: AbsorbPointer(
            child: _buildTextField(
              controller: _preferredDateCtrl,
              hint: 'اختر التاريخ',
              icon: Icons.calendar_today_outlined,
              isDark: isDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: (_) => _notify(),
      style: GoogleFonts.cairo(
        fontSize: 13,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
      decoration: _inputDecoration(hint: hint, icon: icon, isDark: isDark),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required bool isDark,
  }) {
    return InputDecoration(
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
            gradient: AppColors.gradientTeal,
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

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _FieldLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
    );
  }
}
