import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/shared/providers/app_providers.dart';
import 'package:charity_app/features/competitions/domain/competition_models.dart';
import 'package:charity_app/features/competitions/presentation/providers/competitions_provider.dart';

class CreateCompetitionPage extends ConsumerStatefulWidget {
  final Competition? existing; // null = إنشاء، غير null = تعديل
  const CreateCompetitionPage({super.key, this.existing});

  @override
  ConsumerState<CreateCompetitionPage> createState() => _CreateCompetitionPageState();
}

class _CreateCompetitionPageState extends ConsumerState<CreateCompetitionPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _desc;
  late final TextEditingController _points;
  late final TextEditingController _target;
  late final TextEditingController _winners;
  late final TextEditingController _maxParticipants;
  late final TextEditingController _prizeTitle;
  late final TextEditingController _prizeDesc;
  late final TextEditingController _prizeInstructions;
  final _conditionInput = TextEditingController();
  final _stepInput = TextEditingController();

  late CompetitionCategory _category;
  late PrizeType _prizeType;
  late DateTime _start;
  late DateTime _end;
  late final List<String> _conditions;
  late final List<String> _steps;
  bool _coverPicked = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _desc = TextEditingController(text: e?.description ?? '');
    _points = TextEditingController(text: e?.rewardPoints.toString() ?? '500');
    _target = TextEditingController(text: e?.target.toString() ?? '7');
    _winners = TextEditingController(text: e?.winnerCount.toString() ?? '1');
    _maxParticipants = TextEditingController(text: e?.maxParticipants.toString() ?? '0');
    _prizeTitle = TextEditingController(text: e?.prizeTitle ?? '');
    _prizeDesc = TextEditingController(text: e?.prizeDescription ?? '');
    _prizeInstructions = TextEditingController(text: e?.prizeInstructions ?? '');
    _category = e?.category ?? CompetitionCategory.quran;
    _prizeType = e?.prizeType ?? PrizeType.digital;
    _start = e?.startsAt ?? DateTime.now();
    _end = e?.endsAt ?? DateTime.now().add(const Duration(days: 7));
    _conditions = [...?e?.conditions];
    _steps = [...?e?.steps];
    _coverPicked = e?.coverImagePath != null;
  }

  @override
  void dispose() {
    for (final c in [
      _title, _desc, _points, _target, _winners, _maxParticipants,
      _prizeTitle, _prizeDesc, _prizeInstructions, _conditionInput, _stepInput,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _start : _end;
    // 1) اختيار التاريخ
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null) return;
    // 2) اختيار الوقت (خلال 24 ساعة)
    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    final t = pickedTime ?? TimeOfDay.fromDateTime(initial);
    final combined = DateTime(
        pickedDate.year, pickedDate.month, pickedDate.day, t.hour, t.minute);
    setState(() {
      if (isStart) {
        _start = combined;
        if (!_end.isAfter(_start)) _end = _start.add(const Duration(days: 7));
      } else {
        _end = combined.isAfter(_start) ? combined : _start.add(const Duration(hours: 1));
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_prizeTitle.text.trim().isEmpty) {
      _err('أدخل عنوان الجائزة');
      return;
    }
    final user = ref.read(authProvider).user;
    final notifier = ref.read(competitionsProvider.notifier);
    final instructions = _prizeInstructions.text.trim().isEmpty ? null : _prizeInstructions.text.trim();
    final cover = _coverPicked
        ? (widget.existing?.coverImagePath ?? 'cover_${DateTime.now().millisecondsSinceEpoch}.jpg')
        : null;
    final String title = _title.text.trim();

    if (_isEdit) {
      notifier.updateCompetition(
        widget.existing!.id,
        title: title,
        description: _desc.text.trim(),
        category: _category,
        rewardPoints: int.tryParse(_points.text) ?? 0,
        target: (int.tryParse(_target.text) ?? 1).clamp(1, 1000),
        winnerCount: (int.tryParse(_winners.text) ?? 1).clamp(1, 1000),
        maxParticipants: int.tryParse(_maxParticipants.text) ?? 0,
        startsAt: _start,
        endsAt: _end,
        conditions: _conditions,
        steps: _steps,
        prizeType: _prizeType,
        prizeTitle: _prizeTitle.text.trim(),
        prizeDescription: _prizeDesc.text.trim(),
        prizeInstructions: instructions,
        coverImagePath: cover,
      );
    } else {
      notifier.createCompetition(
        title: title,
        description: _desc.text.trim(),
        category: _category,
        rewardPoints: int.tryParse(_points.text) ?? 0,
        target: (int.tryParse(_target.text) ?? 1).clamp(1, 1000),
        winnerCount: (int.tryParse(_winners.text) ?? 1).clamp(1, 1000),
        maxParticipants: int.tryParse(_maxParticipants.text) ?? 0,
        startsAt: _start,
        endsAt: _end,
        conditions: _conditions,
        steps: _steps,
        prizeType: _prizeType,
        prizeTitle: _prizeTitle.text.trim(),
        prizeDescription: _prizeDesc.text.trim(),
        prizeInstructions: instructions,
        coverImagePath: cover,
        createdBy: user?.name ?? 'مشرف',
      );
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_isEdit ? 'تم تحديث مسابقة "$title" ✓' : 'تم إنشاء مسابقة "$title" بنجاح ✓',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF059669),
    ));
  }

  void _err(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFFEF4444),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final df = DateFormat('yyyy/MM/dd', 'ar');
    final tf = DateFormat('hh:mm a', 'ar');
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(_isEdit ? 'تعديل مسابقة' : 'إنشاء مسابقة', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            // ── صورة الغلاف ──
            _coverPicker(isDark),
            const SizedBox(height: 18),

            _section('المعلومات الأساسية', isDark),
            _field(_title, 'عنوان المسابقة', isDark, validator: _required),
            _field(_desc, 'وصف مختصر', isDark, maxLines: 2, validator: _required),
            const SizedBox(height: 10),
            _categoryPicker(isDark),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _numField(_points, 'النقاط', isDark)),
                const SizedBox(width: 10),
                Expanded(child: _numField(_target, 'الهدف (أيام/مرات)', isDark)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _numField(_winners, 'عدد الفائزين', isDark)),
                const SizedBox(width: 10),
                Expanded(child: _numField(_maxParticipants, 'حد المشاركين (0=∞)', isDark)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _dateTile('تبدأ', df.format(_start), tf.format(_start), () => _pickDate(isStart: true), isDark)),
                const SizedBox(width: 10),
                Expanded(child: _dateTile('تنتهي', df.format(_end), tf.format(_end), () => _pickDate(isStart: false), isDark)),
              ],
            ),
            const SizedBox(height: 22),

            _section('الجائزة', isDark),
            _prizeTypePicker(isDark),
            const SizedBox(height: 12),
            _field(_prizeTitle, 'عنوان الجائزة', isDark),
            _field(_prizeDesc, 'وصف الجائزة', isDark, maxLines: 2),
            if (_prizeType == PrizeType.physical)
              _field(_prizeInstructions, 'تعليمات الاستلام', isDark, maxLines: 2),
            const SizedBox(height: 22),

            _section('الشروط', isDark),
            _chipAdder(
              controller: _conditionInput,
              hint: 'أضف شرطاً…',
              items: _conditions,
              isDark: isDark,
            ),
            const SizedBox(height: 22),

            _section('خطوات المشاركة', isDark),
            _chipAdder(
              controller: _stepInput,
              hint: 'أضف خطوة…',
              items: _steps,
              isDark: isDark,
              numbered: true,
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: Icon(_isEdit ? Icons.save_rounded : Icons.add_task_rounded),
                label: Text(_isEdit ? 'حفظ التعديلات' : 'نشر المسابقة', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _category.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── مكوّنات مساعدة ──────────────────────────────────────────────────────────
  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null;

  Widget _section(String title, bool isDark) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Container(width: 4, height: 16, decoration: BoxDecoration(color: _category.color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w900,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
        ]),
      );

  Widget _field(TextEditingController c, String label, bool isDark,
      {int maxLines = 1, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        validator: validator,
        style: GoogleFonts.cairo(fontSize: 13),
        decoration: _dec(label, isDark),
      ),
    );
  }

  Widget _numField(TextEditingController c, String label, bool isDark) {
    return TextFormField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: GoogleFonts.cairo(fontSize: 13),
      decoration: _dec(label, isDark),
    );
  }

  InputDecoration _dec(String label, bool isDark) => InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondaryLight),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : AppColors.cardLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _category.color, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  Widget _coverPicker(bool isDark) {
    return InkWell(
      onTap: () => setState(() => _coverPicked = !_coverPicked),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: _coverPicked ? _category.gradient : null,
          color: _coverPicked ? null : (isDark ? AppColors.surfaceDark : AppColors.cardLight),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _coverPicked ? Colors.transparent : AppColors.borderLight, width: 1.4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_coverPicked ? Icons.check_circle_rounded : Icons.add_photo_alternate_rounded,
                size: 34, color: _coverPicked ? Colors.white : AppColors.textSecondaryLight),
            const SizedBox(height: 6),
            Text(_coverPicked ? 'تم اختيار صورة الغلاف' : 'إضافة صورة غلاف',
                style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700,
                    color: _coverPicked ? Colors.white : AppColors.textSecondaryLight)),
          ],
        ),
      ),
    );
  }

  Widget _categoryPicker(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CompetitionCategory.values.map((cat) {
        final selected = cat == _category;
        return InkWell(
          onTap: () => setState(() => _category = cat),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? cat.color : cat.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cat.color.withValues(alpha: selected ? 1 : 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(cat.icon, size: 15, color: selected ? Colors.white : cat.color),
                const SizedBox(width: 5),
                Text(cat.label,
                    style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w800,
                        color: selected ? Colors.white : cat.color)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _prizeTypePicker(bool isDark) {
    return Row(
      children: PrizeType.values.map((t) {
        final selected = t == _prizeType;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: t == PrizeType.digital ? 8 : 0),
            child: InkWell(
              onTap: () => setState(() => _prizeType = t),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? _category.color.withValues(alpha: 0.1) : null,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? _category.color : AppColors.borderLight, width: 1.4),
                ),
                child: Column(
                  children: [
                    Icon(t.icon, color: selected ? _category.color : AppColors.textSecondaryLight),
                    const SizedBox(height: 4),
                    Text(t.label,
                        style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w700,
                            color: selected ? _category.color : AppColors.textSecondaryLight)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _dateTile(String label, String date, String time, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Row(
          children: [
            Icon(Icons.event_rounded, size: 15, color: _category.color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.cairo(fontSize: 9, color: AppColors.textSecondaryLight)),
                  Text(date, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 10, color: _category.color),
                      const SizedBox(width: 3),
                      Text(time, style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipAdder({
    required TextEditingController controller,
    required String hint,
    required List<String> items,
    required bool isDark,
    bool numbered = false,
  }) {
    void add() {
      final v = controller.text.trim();
      if (v.isEmpty) return;
      setState(() {
        items.add(v);
        controller.clear();
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: GoogleFonts.cairo(fontSize: 13),
                onSubmitted: (_) => add(),
                decoration: _dec(hint, isDark),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: add,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(color: _category.color, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...items.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 22, height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _category.color.withValues(alpha: 0.12),
                      shape: numbered ? BoxShape.circle : BoxShape.rectangle,
                      borderRadius: numbered ? null : BorderRadius.circular(6),
                    ),
                    child: numbered
                        ? Text('${e.key + 1}', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w800, color: _category.color))
                        : Icon(Icons.check_rounded, size: 14, color: _category.color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(e.value, style: GoogleFonts.cairo(fontSize: 12.5,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                  ),
                  InkWell(
                    onTap: () => setState(() => items.removeAt(e.key)),
                    child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textTertiaryLight),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
