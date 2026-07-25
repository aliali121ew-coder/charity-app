import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/competitions/domain/competition_models.dart';
import 'package:charity_app/features/competitions/presentation/providers/store_provider.dart';

const _uuid = Uuid();

class CreateStorePrizePage extends ConsumerStatefulWidget {
  final Prize? existing; // null = إنشاء، غير null = تعديل
  const CreateStorePrizePage({super.key, this.existing});

  @override
  ConsumerState<CreateStorePrizePage> createState() => _CreateStorePrizePageState();
}

class _CreateStorePrizePageState extends ConsumerState<CreateStorePrizePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _desc;
  late final TextEditingController _cost;
  late final TextEditingController _stock;
  late final TextEditingController _instructions;

  late PrizeType _type;
  late Color _color;
  late IconData _icon;

  static const _colors = [
    Color(0xFF10B981), Color(0xFF7C3AED), Color(0xFFF59E0B),
    Color(0xFF06B6D4), Color(0xFFEC4899), Color(0xFF3B82F6), Color(0xFFEF4444),
  ];
  static const _icons = [
    Icons.card_giftcard_rounded, Icons.shopping_basket_rounded, Icons.menu_book_rounded,
    Icons.workspace_premium_rounded, Icons.mosque_rounded, Icons.volunteer_activism_rounded,
    Icons.backpack_rounded, Icons.redeem_rounded, Icons.emoji_events_rounded,
  ];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _desc = TextEditingController(text: e?.description ?? '');
    _cost = TextEditingController(text: e?.pointsCost.toString() ?? '500');
    _stock = TextEditingController(text: e?.stock.toString() ?? '10');
    _instructions = TextEditingController(text: e?.instructions ?? '');
    _type = e?.type ?? PrizeType.physical;
    _color = e?.color ?? _colors.first;
    _icon = e?.icon ?? _icons.first;
  }

  @override
  void dispose() {
    for (final c in [_title, _desc, _cost, _stock, _instructions]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final prize = Prize(
      id: widget.existing?.id ?? 'p_${_uuid.v4()}',
      title: _title.text.trim(),
      description: _desc.text.trim(),
      pointsCost: int.tryParse(_cost.text) ?? 0,
      icon: _icon,
      color: _color,
      stock: int.tryParse(_stock.text) ?? 0,
      type: _type,
      instructions: _type == PrizeType.physical ? _instructions.text.trim() : '',
    );
    ref.read(storePrizesProvider.notifier).upsert(prize);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_isEdit ? 'تم تحديث الجائزة ✓' : 'تمت إضافة الجائزة ✓',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF059669),
    ));
  }

  void _delete() {
    ref.read(storePrizesProvider.notifier).remove(widget.existing!.id);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('تم حذف الجائزة', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF64748B),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(_isEdit ? 'تعديل جائزة' : 'إضافة جائزة', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            // معاينة
            Container(
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_color, _color.withValues(alpha: 0.7)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: Icon(_icon, color: Colors.white, size: 44)),
            ),
            const SizedBox(height: 18),
            _field(_title, 'عنوان الجائزة', isDark, validator: _required),
            _field(_desc, 'وصف الجائزة', isDark, maxLines: 2),
            Row(
              children: [
                Expanded(child: _numField(_cost, 'تكلفة النقاط', isDark)),
                const SizedBox(width: 10),
                Expanded(child: _numField(_stock, 'المخزون', isDark)),
              ],
            ),
            const SizedBox(height: 16),
            _label('نوع الجائزة', isDark),
            const SizedBox(height: 8),
            _typePicker(isDark),
            if (_type == PrizeType.physical) ...[
              const SizedBox(height: 12),
              _field(_instructions, 'تعليمات الاستلام', isDark, maxLines: 2),
            ],
            const SizedBox(height: 16),
            _label('اللون', isDark),
            const SizedBox(height: 8),
            _colorPicker(),
            const SizedBox(height: 16),
            _label('الأيقونة', isDark),
            const SizedBox(height: 8),
            _iconPicker(isDark),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: Icon(_isEdit ? Icons.save_rounded : Icons.add_task_rounded),
                label: Text(_isEdit ? 'حفظ التعديلات' : 'إضافة الجائزة',
                    style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _color,
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

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null;

  Widget _label(String t, bool isDark) => Row(children: [
        Container(width: 4, height: 15, decoration: BoxDecoration(color: _color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(t, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
      ]);

  Widget _field(TextEditingController c, String label, bool isDark, {int maxLines = 1, String? Function(String?)? validator}) {
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
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _color, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  Widget _typePicker(bool isDark) {
    return Row(
      children: PrizeType.values.map((t) {
        final sel = t == _type;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: t == PrizeType.digital ? 8 : 0),
            child: InkWell(
              onTap: () => setState(() => _type = t),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: sel ? _color.withValues(alpha: 0.1) : null,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? _color : AppColors.borderLight, width: 1.4),
                ),
                child: Column(
                  children: [
                    Icon(t.icon, color: sel ? _color : AppColors.textSecondaryLight),
                    const SizedBox(height: 4),
                    Text(t.label, style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w700,
                        color: sel ? _color : AppColors.textSecondaryLight)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _colorPicker() {
    return Wrap(
      spacing: 10,
      children: _colors.map((c) {
        final sel = c == _color;
        return GestureDetector(
          onTap: () => setState(() => _color = c),
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(color: sel ? Colors.white : Colors.transparent, width: 3),
              boxShadow: sel ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 8)] : null,
            ),
            child: sel ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _iconPicker(bool isDark) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _icons.map((ic) {
        final sel = ic == _icon;
        return GestureDetector(
          onTap: () => setState(() => _icon = ic),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: sel ? _color : _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _color.withValues(alpha: sel ? 1 : 0.3)),
            ),
            child: Icon(ic, color: sel ? Colors.white : _color, size: 22),
          ),
        );
      }).toList(),
    );
  }
}
