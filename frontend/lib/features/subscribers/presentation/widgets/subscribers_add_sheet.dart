part of '../pages/subscribers_page.dart';

class _AddFamilySheet extends StatefulWidget {
  final bool isDark;

  const _AddFamilySheet({required this.isDark});

  @override
  State<_AddFamilySheet> createState() => _AddFamilySheetState();
}

class _AddFamilySheetState extends State<_AddFamilySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _membersCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _delegateCtrl = TextEditingController();
  FamilyStatus _status = FamilyStatus.pending;
  IncomeLevel _incomeLevel = IncomeLevel.veryLow;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _areaCtrl.dispose();
    _membersCtrl.dispose();
    _phoneCtrl.dispose();
    _delegateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final sheetBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPurple,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'إضافة عائلة جديدة',
                    style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              height: 1,
            ),
            // Form
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FormField(
                        label: 'اسم رب الأسرة',
                        controller: _nameCtrl,
                        hint: 'أدخل الاسم الكامل',
                        icon: Icons.person_rounded,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      _FormField(
                        label: 'اسم المندوب',
                        controller: _delegateCtrl,
                        hint: 'أدخل اسم المندوب المسؤول',
                        icon: Icons.person_outline_rounded,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      _FormField(
                        label: 'المنطقة',
                        controller: _areaCtrl,
                        hint: 'المنطقة السكنية',
                        icon: Icons.location_on_rounded,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      _FormField(
                        label: 'عدد أفراد الأسرة',
                        controller: _membersCtrl,
                        hint: 'العدد الإجمالي',
                        icon: Icons.people_rounded,
                        isDark: isDark,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      _FormField(
                        label: 'رقم الهاتف',
                        controller: _phoneCtrl,
                        hint: '07XX XXXXXXX',
                        icon: Icons.phone_rounded,
                        isDark: isDark,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'مستوى الدخل',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<IncomeLevel>(
                            value: _incomeLevel,
                            isExpanded: true,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                            dropdownColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                            items: IncomeLevel.values
                                .map((l) => DropdownMenuItem(
                                      value: l,
                                      child: Text(l.labelAr, style: GoogleFonts.cairo(fontSize: 13)),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _incomeLevel = v);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'حالة الأسرة',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: FamilyStatus.values.map((s) {
                          final selected = _status == s;
                          final color = _statusHeaderColor(s);
                          return GestureDetector(
                            onTap: () => setState(() => _status = s),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: selected
                                    ? color.withValues(alpha: 0.15)
                                    : (isDark
                                        ? AppColors.surfaceVariantDark
                                        : AppColors.surfaceVariantLight),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected ? color : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Text(
                                s.labelAr,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                  color: selected
                                      ? color
                                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),
                      // Submit button
                      GestureDetector(
                        onTap: () {
                          final name = _nameCtrl.text.trim();
                          final area = _areaCtrl.text.trim();
                          final membersStr = _membersCtrl.text.trim();
                          final phone = _phoneCtrl.text.trim();
                          final delegate = _delegateCtrl.text.trim();

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'يرجى إدخال اسم رب الأسرة',
                                  style: GoogleFonts.cairo(),
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }

                          final members = int.tryParse(membersStr) ?? 1;

                          final newFamily = FamilyModel(
                            id: 'f_${DateTime.now().millisecondsSinceEpoch}',
                            headName: name,
                            membersCount: members,
                            maritalStatus: MaritalStatus.married,
                            incomeLevel: _incomeLevel,
                            address: area,
                            area: area,
                            status: _status,
                            phone: phone.isEmpty ? null : phone,
                            delegateName: delegate.isEmpty ? null : delegate,
                            registrationDate: DateTime.now(),
                          );

                          Navigator.pop(context, newFamily);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientPurple,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'حفظ البيانات',
                              style: GoogleFonts.cairo(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              'إلغاء',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Form Field ────────────────────────────────────────────────────────────────
class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool isDark;
  final TextInputType? keyboardType;

  const _FormField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.isDark,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
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
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.cairo(
                fontSize: 13,
                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
              ),
              prefixIcon: Icon(
                icon,
                size: 18,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
