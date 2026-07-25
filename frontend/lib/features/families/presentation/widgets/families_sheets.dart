part of '../pages/families_page.dart';

class _PaymentSheet extends StatefulWidget {
  final _Delegate delegate;
  const _PaymentSheet({required this.delegate});

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  _Subscriber? _selected;
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('تسديد اشتراك', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            Text('مندوب: ${widget.delegate.name}',
                style: GoogleFonts.cairo(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
            const SizedBox(height: 16),
            Text('اختر المشترك', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: DropdownButtonFormField<_Subscriber>(
                initialValue: _selected,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                ),
                hint: Text('اختر مشتركاً', style: GoogleFonts.cairo(fontSize: 12)),
                items: widget.delegate.subscribers.map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.name, style: GoogleFonts.cairo(fontSize: 12)),
                )).toList(),
                onChanged: (s) {
                  setState(() {
                    _selected = s;
                    if (s != null) _amountCtrl.text = s.monthlyAmount.toStringAsFixed(0);
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            Text('المبلغ', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.cairo(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'المبلغ بالدينار العراقي',
                hintStyle: GoogleFonts.cairo(fontSize: 12),
                suffixText: 'د.ع',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selected == null ? null : () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('✓ تم تسجيل تسديد ${_selected!.name}',
                        style: GoogleFonts.cairo(color: Colors.white)),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                },
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: Text('تأكيد التسديد', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Add Subscriber Sheet ───────────────────────────────────────────────────────
void _showAddSubscriberSheet(BuildContext context, _Delegate delegate) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddSubscriberSheet(delegate: delegate),
  );
}

class _AddSubscriberSheet extends StatefulWidget {
  final _Delegate delegate;
  const _AddSubscriberSheet({required this.delegate});

  @override
  State<_AddSubscriberSheet> createState() => _AddSubscriberSheetState();
}

class _AddSubscriberSheetState extends State<_AddSubscriberSheet> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  double _selectedTier = 5000;

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('إضافة مشترك جديد', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            Text('مندوب: ${widget.delegate.name}',
                style: GoogleFonts.cairo(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
            const SizedBox(height: 16),
            _FormField(label: 'الاسم الكامل', controller: nameCtrl, hint: 'اسم المشترك', isDark: isDark, icon: Icons.person_rounded),
            const SizedBox(height: 10),
            _FormField(label: 'رقم الهاتف', controller: phoneCtrl, hint: '07X XXXX XXXX', isDark: isDark,
                icon: Icons.phone_rounded, inputType: TextInputType.phone),
            const SizedBox(height: 10),
            Text('القسط الشهري (د.ع)', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            const SizedBox(height: 5),
            SizedBox(
              height: 48,
              child: DropdownButtonFormField<double>(
                initialValue: _selectedTier,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                ),
                hint: Text('اختر فئة الاشتراك', style: GoogleFonts.cairo(fontSize: 12)),
                items: const [
                  DropdownMenuItem(value: 1000, child: Text('1,000 د.ع')),
                  DropdownMenuItem(value: 5000, child: Text('5,000 د.ع')),
                  DropdownMenuItem(value: 10000, child: Text('10,000 د.ع')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedTier = val;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('✓ تمت إضافة المشترك بنجاح', style: GoogleFonts.cairo(color: Colors.white)),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                },
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: Text('إضافة المشترك', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final bool isDark;
  final IconData icon;
  final TextInputType inputType;
  const _FormField({required this.label, required this.hint, required this.controller,
      required this.isDark, required this.icon, this.inputType = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: inputType,
          style: GoogleFonts.cairo(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.cairo(fontSize: 12),
            prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}

// ── Add Delegate Sheet ─────────────────────────────────────────────────────────
class _AddDelegateSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddDelegateSheet({required this.onSaved});

  @override
  State<_AddDelegateSheet> createState() => _AddDelegateSheetState();
}

class _AddDelegateSheetState extends State<_AddDelegateSheet> {
  final nameCtrl = TextEditingController();
  final areaCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final specialtyCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  DateTime _selectedJoinDate = DateTime.now();

  @override
  void dispose() {
    nameCtrl.dispose();
    areaCtrl.dispose();
    phoneCtrl.dispose();
    specialtyCtrl.dispose();
    addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(children: [
                Container(padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(gradient: AppColors.gradientPurple, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.badge_rounded, color: Colors.white, size: 20)),
                const SizedBox(width: 12),
                Text('إضافة مندوب جديد', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              ]),
              const SizedBox(height: 20),
              _FormField(label: 'الاسم الكامل', controller: nameCtrl, hint: 'اسم المندوب', isDark: isDark, icon: Icons.person_rounded),
              const SizedBox(height: 10),
              _FormField(label: 'المنطقة', controller: areaCtrl, hint: 'المنطقة المسؤول عنها', isDark: isDark, icon: Icons.location_on_rounded),
              const SizedBox(height: 10),
              _FormField(label: 'رقم الهاتف', controller: phoneCtrl, hint: '07X XXXX XXXX', isDark: isDark,
                  icon: Icons.phone_rounded, inputType: TextInputType.phone),
              const SizedBox(height: 10),
              _FormField(label: 'المسمى الوظيفي', controller: specialtyCtrl, hint: 'مثال: مشرف اشتراكات', isDark: isDark, icon: Icons.work_rounded),
              const SizedBox(height: 10),
              
              Text('تاريخ الاشتراك', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              const SizedBox(height: 5),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedJoinDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    locale: const Locale('ar'),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedJoinDate = date;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('yyyy/MM/dd').format(_selectedJoinDate),
                        style: GoogleFonts.cairo(fontSize: 13, color: isDark ? Colors.white : Colors.black),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down_rounded, color: isDark ? Colors.white54 : Colors.black54),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _FormField(label: 'العنوان', controller: addressCtrl, hint: 'العنوان بالتفصيل للمندوب', isDark: isDark, icon: Icons.home_rounded),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (nameCtrl.text.isEmpty) return;
                    HapticFeedback.mediumImpact();
                    
                    final newDelegate = _Delegate(
                      id: 'd${_mockDelegates.length + 1}',
                      name: nameCtrl.text,
                      area: areaCtrl.text,
                      phone: phoneCtrl.text,
                      isFemale: false,
                      specialty: specialtyCtrl.text.isNotEmpty ? specialtyCtrl.text : 'مشرف',
                      joinDate: _selectedJoinDate,
                      address: addressCtrl.text.isNotEmpty ? addressCtrl.text : areaCtrl.text,
                      subscribers: [],
                    );
                    _mockDelegates.add(newDelegate);
                    
                    widget.onSaved();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('✓ تمت إضافة المندوب بنجاح', style: GoogleFonts.cairo(color: Colors.white)),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ));
                  },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text('حفظ المندوب', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Edit Delegate Sheet ────────────────────────────────────────────────────────
void _showEditDelegateSheet(BuildContext context, _Delegate delegate, VoidCallback onSaved) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditDelegateSheet(delegate: delegate, onSaved: onSaved),
  );
}

class _EditDelegateSheet extends StatefulWidget {
  final _Delegate delegate;
  final VoidCallback onSaved;
  const _EditDelegateSheet({required this.delegate, required this.onSaved});

  @override
  State<_EditDelegateSheet> createState() => _EditDelegateSheetState();
}

class _EditDelegateSheetState extends State<_EditDelegateSheet> {
  late final TextEditingController nameCtrl;
  late final TextEditingController areaCtrl;
  late final TextEditingController phoneCtrl;
  late final TextEditingController addressCtrl;
  late DateTime _selectedJoinDate;
  double _selectedTier = 5000;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.delegate.name);
    areaCtrl = TextEditingController(text: widget.delegate.area);
    phoneCtrl = TextEditingController(text: widget.delegate.phone);
    addressCtrl = TextEditingController(text: widget.delegate.address);
    _selectedJoinDate = widget.delegate.joinDate;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    areaCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(children: [
                Container(padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(gradient: AppColors.gradientPurple, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20)),
                const SizedBox(width: 12),
                Text('تعديل بيانات المندوب', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              ]),
              const SizedBox(height: 20),
              _FormField(label: 'الاسم الكامل للمندوب', controller: nameCtrl, hint: 'اسم المندوب', isDark: isDark, icon: Icons.person_rounded),
              const SizedBox(height: 10),
              _FormField(label: 'رقم الهاتف', controller: phoneCtrl, hint: '07X XXXX XXXX', isDark: isDark,
                  icon: Icons.phone_rounded, inputType: TextInputType.phone),
              const SizedBox(height: 10),
              _FormField(label: 'المنطقة', controller: areaCtrl, hint: 'المنطقة المسؤول عنها', isDark: isDark, icon: Icons.location_on_rounded),
              const SizedBox(height: 10),
              Text('فئة الاشتراك الافتراضية', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              const SizedBox(height: 5),
              SizedBox(
                height: 48,
                child: DropdownButtonFormField<double>(
                  initialValue: _selectedTier,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                  ),
                  hint: Text('اختر فئة الاشتراك', style: GoogleFonts.cairo(fontSize: 12)),
                  items: const [
                    DropdownMenuItem(value: 1000, child: Text('1,000 د.ع')),
                    DropdownMenuItem(value: 5000, child: Text('5,000 د.ع')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedTier = val;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),
              Text('تاريخ الاشتراك', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              const SizedBox(height: 5),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedJoinDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    locale: const Locale('ar'),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedJoinDate = date;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('yyyy/MM/dd').format(_selectedJoinDate),
                        style: GoogleFonts.cairo(fontSize: 13, color: isDark ? Colors.white : Colors.black),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down_rounded, color: isDark ? Colors.white54 : Colors.black54),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _FormField(label: 'العنوان بالتفصيل', controller: addressCtrl, hint: 'العنوان بالتفصيل للمندوب', isDark: isDark, icon: Icons.home_rounded),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final idx = _mockDelegates.indexWhere((d) => d.id == widget.delegate.id);
                    if (idx != -1) {
                      _mockDelegates[idx] = _Delegate(
                        id: widget.delegate.id,
                        name: nameCtrl.text,
                        area: areaCtrl.text,
                        phone: phoneCtrl.text,
                        isFemale: widget.delegate.isFemale,
                        specialty: widget.delegate.specialty,
                        joinDate: _selectedJoinDate,
                        address: addressCtrl.text,
                        subscribers: widget.delegate.subscribers,
                      );
                    }
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context);
                    widget.onSaved();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('✓ تم تعديل بيانات المندوب بنجاح', style: GoogleFonts.cairo(color: Colors.white)),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ));
                  },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text('حفظ التعديلات', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Edit Subscriber Sheet ──────────────────────────────────────────────────────
void _showEditSubscriberSheet(BuildContext context, _Delegate delegate) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditSubscriberSheet(delegate: delegate),
  );
}

class _EditSubscriberSheet extends StatefulWidget {
  final _Delegate delegate;
  const _EditSubscriberSheet({required this.delegate});

  @override
  State<_EditSubscriberSheet> createState() => _EditSubscriberSheetState();
}

class _EditSubscriberSheetState extends State<_EditSubscriberSheet> {
  _Subscriber? _selectedSub;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  double _selectedTier = 5000;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(gradient: AppColors.gradientGreen, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.manage_accounts_rounded, color: Colors.white, size: 20)),
              const SizedBox(width: 12),
              Text('تعديل بيانات المشترك', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            ]),
            Text('مندوب: ${widget.delegate.name}',
                style: GoogleFonts.cairo(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
            const SizedBox(height: 16),
            Text('اختر المشترك المراد تعديله', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: DropdownButtonFormField<_Subscriber>(
                initialValue: _selectedSub,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                ),
                hint: Text('اختر مشتركاً', style: GoogleFonts.cairo(fontSize: 12)),
                items: widget.delegate.subscribers.map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.name, style: GoogleFonts.cairo(fontSize: 12)),
                )).toList(),
                onChanged: (s) {
                  setState(() {
                    _selectedSub = s;
                    if (s != null) {
                      _nameCtrl.text = s.name;
                      _phoneCtrl.text = '07701112223'; // prefilled placeholder phone for subscriber
                      final amount = s.monthlyAmount;
                      _selectedTier = (amount == 1000 || amount == 5000) ? amount : 5000;
                      _addressCtrl.text = widget.delegate.area; // default to delegate's area/address
                    } else {
                      _nameCtrl.clear();
                      _phoneCtrl.clear();
                      _addressCtrl.clear();
                      _selectedTier = 5000;
                    }
                  });
                },
              ),
            ),
            if (_selectedSub != null) ...[
              const SizedBox(height: 14),
              _FormField(label: 'الاسم الكامل للمشترك', controller: _nameCtrl, hint: 'اسم المشترك', isDark: isDark, icon: Icons.person_rounded),
              const SizedBox(height: 10),
              _FormField(label: 'رقم الهاتف', controller: _phoneCtrl, hint: '07X XXXX XXXX', isDark: isDark, icon: Icons.phone_rounded, inputType: TextInputType.phone),
              const SizedBox(height: 10),
              Text('فئة الاشتراك (د.ع)', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              const SizedBox(height: 5),
              SizedBox(
                height: 48,
                child: DropdownButtonFormField<double>(
                  initialValue: _selectedTier,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                  ),
                  hint: Text('اختر فئة الاشتراك', style: GoogleFonts.cairo(fontSize: 12)),
                  items: const [
                    DropdownMenuItem(value: 1000, child: Text('1,000 د.ع')),
                    DropdownMenuItem(value: 5000, child: Text('5,000 د.ع')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedTier = val;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),
              _FormField(label: 'العنوان / المنطقة', controller: _addressCtrl, hint: 'العنوان بالتفصيل للمشترك', isDark: isDark, icon: Icons.location_on_rounded),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedSub == null ? null : () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('✓ تم تعديل بيانات المشترك بنجاح', style: GoogleFonts.cairo(color: Colors.white)),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                },
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text('حفظ التعديلات', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Subscriber Detail Page ───────────────────────────────────────────────────
