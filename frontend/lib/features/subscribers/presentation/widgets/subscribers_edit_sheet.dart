part of '../pages/subscribers_page.dart';

class _FamilyEditSheet extends StatefulWidget {
  final FamilyModel family;
  final bool isDark;
  const _FamilyEditSheet({required this.family, required this.isDark});
  @override
  State<_FamilyEditSheet> createState() => _FamilyEditSheetState();
}

class _FamilyEditSheetState extends State<_FamilyEditSheet> with TickerProviderStateMixin {
  late AnimationController _entryCtr;
  late AnimationController _saveCtr;
  late Animation<double> _saveScale;
  bool _saved = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _delegateCtrl;
  late TextEditingController _areaCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _notesCtrl;
  late int _members;
  late MaritalStatus _marital;
  late IncomeLevel _income;
  late FamilyStatus _status;

  @override
  void initState() {
    super.initState();
    final f = widget.family;
    _nameCtrl    = TextEditingController(text: f.headName);
    _phoneCtrl   = TextEditingController(text: f.phone ?? '');
    _delegateCtrl = TextEditingController(text: f.delegateName ?? '');
    _areaCtrl    = TextEditingController(text: f.area);
    _addressCtrl = TextEditingController(text: f.address);
    _notesCtrl   = TextEditingController(text: f.notes ?? '');
    _members = f.membersCount;
    _marital = f.maritalStatus;
    _income  = f.incomeLevel;
    _status  = f.status;

    _entryCtr = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _saveCtr  = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _saveScale = Tween(begin: 1.0, end: 0.92).animate(CurvedAnimation(parent: _saveCtr, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _entryCtr.dispose(); _saveCtr.dispose();
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _delegateCtrl.dispose(); _areaCtrl.dispose();
    _addressCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Animation<Offset> _slideAnim(int index) {
    final start = (index * 0.04).clamp(0.0, 0.8);
    final end = (start + 0.2).clamp(0.0, 1.0);
    return Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtr, curve: Interval(start, end, curve: Curves.easeOutCubic)));
  }

  Animation<double> _fadeAnim(int index) {
    final start = (index * 0.04).clamp(0.0, 0.8);
    final end = (start + 0.2).clamp(0.0, 1.0);
    return Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _entryCtr, curve: Interval(start, end, curve: Curves.easeOut)));
  }

  void _save() async {
    _saveCtr.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    setState(() => _saved = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final updated = widget.family.copyWith(
      headName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      delegateName: _delegateCtrl.text.trim().isEmpty ? null : _delegateCtrl.text.trim(),
      area: _areaCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      membersCount: _members,
      maritalStatus: _marital,
      incomeLevel: _income,
      status: _status,
    );
    Navigator.pop(context, updated);
  }

  Color get _ratingClr => _ratingColor(_income);
  String get _ratingStr => _familyRating(_income);

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(children: [
          // Handle + title
          Center(child: Container(margin: const EdgeInsets.only(top: 10), width: 40, height: 4,
              decoration: BoxDecoration(color: isDark ? AppColors.borderDark : AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF4F46E5)]), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.edit_rounded, size: 20, color: Colors.white)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('تعديل بيانات العائلة', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                Text(widget.family.headName, style: GoogleFonts.cairo(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              ])),
              GestureDetector(onTap: () => Navigator.pop(context),
                child: Container(width: 36, height: 36, decoration: BoxDecoration(color: isDark ? AppColors.cardDark : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.close_rounded, size: 18, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
            ]),
          ),
          Divider(height: 16, color: isDark ? AppColors.borderDark : AppColors.borderLight),

          // Form
          Expanded(child: SingleChildScrollView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Section 1: أساسية
              _animField(0, _EditSectionTitle(title: 'البيانات الأساسية', icon: Icons.person_rounded, isDark: isDark)),
              _animField(1, _EditField(label: 'اسم رب الأسرة', icon: Icons.person_outline_rounded, ctrl: _nameCtrl, isDark: isDark)),
              _animField(2, _EditField(label: 'اسم المندوب', icon: Icons.person_outline_rounded, ctrl: _delegateCtrl, isDark: isDark)),
              _animField(3, _EditField(label: 'رقم الهاتف', icon: Icons.phone_outlined, ctrl: _phoneCtrl, isDark: isDark, keyboardType: TextInputType.phone)),
              _animField(4, _EditField(label: 'المنطقة', icon: Icons.location_on_outlined, ctrl: _areaCtrl, isDark: isDark)),
              _animField(5, _EditField(label: 'العنوان التفصيلي', icon: Icons.home_outlined, ctrl: _addressCtrl, isDark: isDark)),
              const SizedBox(height: 16),

              // Section 2: الأفراد
              _animField(6, _EditSectionTitle(title: 'البيانات الاجتماعية', icon: Icons.people_rounded, isDark: isDark)),
              _animField(7, _MemberCounter(value: _members, onChanged: (v) => setState(() => _members = v), isDark: isDark)),
              const SizedBox(height: 12),
              _animField(8, _EnumSelector<MaritalStatus>(
                label: 'الحالة الاجتماعية',
                values: MaritalStatus.values,
                selected: _marital,
                labelOf: (v) => v.labelAr,
                onChanged: (v) => setState(() => _marital = v),
                isDark: isDark,
              )),
              const SizedBox(height: 12),
              _animField(9, _EnumSelector<IncomeLevel>(
                label: 'مستوى الدخل',
                values: IncomeLevel.values,
                selected: _income,
                labelOf: (v) => v.labelAr,
                onChanged: (v) => setState(() => _income = v),
                isDark: isDark,
                accent: _ratingClr,
              )),
              const SizedBox(height: 8),
              // Live rating preview
              _animField(10, AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: _ratingClr.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: _ratingClr.withValues(alpha: 0.3))),
                child: Row(children: [
                  Icon(Icons.star_rounded, size: 18, color: _ratingClr),
                  const SizedBox(width: 8),
                  Text('تقييم العائلة: $_ratingStr', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: _ratingClr)),
                ]),
              )),
              const SizedBox(height: 16),

              // Section 3: الحالة
              _animField(11, _EditSectionTitle(title: 'حالة العائلة', icon: Icons.verified_rounded, isDark: isDark)),
              _animField(12, _StatusSelector(selected: _status, onChanged: (v) => setState(() => _status = v), isDark: isDark)),
              const SizedBox(height: 16),

              // Section 4: ملاحظات
              _animField(13, _EditSectionTitle(title: 'ملاحظات', icon: Icons.notes_rounded, isDark: isDark)),
              _animField(14, _EditField(label: 'أضف ملاحظة...', icon: Icons.edit_note_rounded, ctrl: _notesCtrl, isDark: isDark, maxLines: 3)),
              const SizedBox(height: 24),
            ]),
          )),

          // Save button
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
            child: ScaleTransition(
              scale: _saveScale,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: _saved
                      ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                      : const LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF4F46E5)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: (_saved ? const Color(0xFF10B981) : const Color(0xFF6D28D9)).withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 5))],
                ),
                child: GestureDetector(
                  onTap: _saved ? null : _save,
                  child: Center(child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _saved
                        ? Row(key: const ValueKey('done'), mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                            const SizedBox(width: 8),
                            Text('تم الحفظ بنجاح', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                          ])
                        : Row(key: const ValueKey('save'), mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.save_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text('حفظ التعديلات', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                          ]),
                  )),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _animField(int i, Widget child) => FadeTransition(
    opacity: _fadeAnim(i),
    child: SlideTransition(position: _slideAnim(i), child: child),
  );
}

// ── Edit Helper Widgets ────────────────────────────────────────────────────────
class _EditSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  const _EditSectionTitle({required this.title, required this.icon, required this.isDark});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(width: 28, height: 28, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF4F46E5)]), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: Colors.white)),
      const SizedBox(width: 8),
      Text(title, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
    ]),
  );
}

class _EditField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController ctrl;
  final bool isDark;
  final TextInputType? keyboardType;
  final int maxLines;
  const _EditField({required this.label, required this.icon, required this.ctrl, required this.isDark, this.keyboardType, this.maxLines = 1});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.cairo(fontSize: 13, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(fontSize: 12, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF6D28D9)),
        filled: true,
        fillColor: isDark ? AppColors.cardDark : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6D28D9), width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    ),
  );
}

class _MemberCounter extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final bool isDark;
  const _MemberCounter({required this.value, required this.onChanged, required this.isDark});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(children: [
        const Icon(Icons.people_outline_rounded, size: 18, color: Color(0xFF6D28D9)),
        const SizedBox(width: 10),
        Expanded(child: Text('عدد أفراد الأسرة', style: GoogleFonts.cairo(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
        _CounterBtn(icon: Icons.remove_rounded, onTap: value > 1 ? () => onChanged(value - 1) : null),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('$value', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF6D28D9)))),
        _CounterBtn(icon: Icons.add_rounded, onTap: value < 20 ? () => onChanged(value + 1) : null),
      ]),
    ),
  );
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CounterBtn({required this.icon, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: onTap == null ? Colors.grey.withValues(alpha: 0.12) : const Color(0xFF6D28D9).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: onTap == null ? Colors.grey.withValues(alpha: 0.2) : const Color(0xFF6D28D9).withValues(alpha: 0.3)),
      ),
      child: Icon(icon, size: 16, color: onTap == null ? Colors.grey : const Color(0xFF6D28D9)),
    ),
  );
}

class _EnumSelector<T> extends StatelessWidget {
  final String label;
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final bool isDark;
  final Color? accent;
  const _EnumSelector({required this.label, required this.values, required this.selected, required this.labelOf, required this.onChanged, required this.isDark, this.accent});
  @override
  Widget build(BuildContext context) {
    final color = accent ?? const Color(0xFF6D28D9);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.cairo(fontSize: 11, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight)),
      const SizedBox(height: 6),
      Wrap(spacing: 8, runSpacing: 8, children: values.map((v) {
        final isSelected = v == selected;
        return GestureDetector(
          onTap: () => onChanged(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color : (isDark ? AppColors.cardDark : Colors.white),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? color : (isDark ? AppColors.borderDark : AppColors.borderLight), width: isSelected ? 1.5 : 1),
              boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))] : null,
            ),
            child: Text(labelOf(v), style: GoogleFonts.cairo(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
          ),
        );
      }).toList()),
    ]);
  }
}

class _StatusSelector extends StatelessWidget {
  final FamilyStatus selected;
  final ValueChanged<FamilyStatus> onChanged;
  final bool isDark;
  const _StatusSelector({required this.selected, required this.onChanged, required this.isDark});
  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8,
    children: FamilyStatus.values.map((s) {
      final color = _statusHeaderColor(s);
      final isSelected = s == selected;
      return GestureDetector(
        onTap: () => onChanged(s),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : (isDark ? AppColors.cardDark : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : (isDark ? AppColors.borderDark : AppColors.borderLight), width: isSelected ? 2 : 1),
            boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))] : null,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (isSelected) ...[const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white), const SizedBox(width: 5)],
            Text(s.labelAr, style: GoogleFonts.cairo(fontSize: 12, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
          ]),
        ),
      );
    }).toList(),
  );
}

// ── Add Family Bottom Sheet ───────────────────────────────────────────────────
