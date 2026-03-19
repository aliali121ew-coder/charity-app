import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';

class FinancialSection extends StatefulWidget {
  final Map<String, String> data;
  final void Function(Map<String, String>) onChanged;

  const FinancialSection({
    super.key,
    required this.data,
    required this.onChanged,
  });

  @override
  State<FinancialSection> createState() => _FinancialSectionState();
}

class _FinancialSectionState extends State<FinancialSection> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _purposeCtrl;
  late final TextEditingController _bankCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _amountCtrl = TextEditingController(text: d['requestedAmount'] ?? '');
    _purposeCtrl = TextEditingController(text: d['purposeDetails'] ?? '');
    _bankCtrl = TextEditingController(text: d['bankName'] ?? '');
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _purposeCtrl.dispose();
    _bankCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged({
      'requestedAmount': _amountCtrl.text,
      'purposeDetails': _purposeCtrl.text,
      'bankName': _bankCtrl.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(label: 'تفاصيل الطلب المالي', isDark: isDark),
        const SizedBox(height: 12),
        _buildLabel('المبلغ المطلوب (دينار عراقي)', isDark),
        const SizedBox(height: 6),
        TextField(
          controller: _amountCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => _notify(),
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          decoration: _decor(
            hint: 'مثال: 500000',
            icon: Icons.account_balance_wallet_outlined,
            isDark: isDark,
            suffix: Text(
              'د.ع',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildLabel('الغرض من المبلغ', isDark),
        const SizedBox(height: 6),
        TextField(
          controller: _purposeCtrl,
          maxLines: 3,
          onChanged: (_) => _notify(),
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          decoration: _decor(
            hint: 'اشرح الغرض من المبلغ المطلوب بالتفصيل...',
            icon: Icons.info_outline_rounded,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 12),
        _buildLabel('البنك / الجهة المحوّلة إليها (اختياري)', isDark),
        const SizedBox(height: 6),
        TextField(
          controller: _bankCtrl,
          onChanged: (_) => _notify(),
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          decoration: _decor(
            hint: 'اسم البنك أو رقم الحساب',
            icon: Icons.account_balance_outlined,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 16, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'سيتم التحقق من الطلب قبل الموافقة عليه. قد يستغرق المراجعة 3-5 أيام عمل.',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: AppColors.warning,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
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

  InputDecoration _decor({
    required String hint,
    required IconData icon,
    required bool isDark,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.cairo(
        fontSize: 12,
        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
      ),
      prefixIcon: Icon(icon, size: 18,
          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
      suffixIcon: suffix != null
          ? Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: suffix,
            )
          : null,
      filled: true,
      fillColor:
          isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
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
            gradient: AppColors.gradientOrange,
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
