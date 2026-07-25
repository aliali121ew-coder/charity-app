import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:charity_app/shared/models/work_post_model.dart';
import 'package:charity_app/shared/providers/app_providers.dart';
import 'package:charity_app/features/works/presentation/providers/works_provider.dart';

class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({super.key});

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _beneficiaryCtrl = TextEditingController();

  WorkCategory _selectedCategory = WorkCategory.general;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _imageUrlCtrl.dispose();
    _tagsCtrl.dispose();
    _beneficiaryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    HapticFeedback.lightImpact();

    final user = ref.read(authProvider).user;
    final tags = _tagsCtrl.text
        .split(RegExp(r'[,،\s]+'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    ref.read(worksProvider.notifier).createPost(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          category: _selectedCategory,
          location: _locationCtrl.text.trim(),
          tags: tags,
          imageUrl: _imageUrlCtrl.text.trim().isNotEmpty
              ? _imageUrlCtrl.text.trim()
              : null,
          authorName: user?.name ?? 'مؤسسة النور الخيرية',
          authorRole: user?.role.name == 'admin' ? 'مدير النظام' : 'موظف',
          beneficiaryCount: int.tryParse(_beneficiaryCtrl.text) ?? 0,
        );

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isSubmitting = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: isDark ? Colors.white : const Color(0xFF111111),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'منشور جديد',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF111111),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF7C3AED),
                    ),
                  )
                : GestureDetector(
                    onTap: _submit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF4C3BC5)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'نشر',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Image URL Field ──────────────────────────────────────────
            _SectionCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('رابط الصورة (اختياري)', isDark: isDark),
                  _buildTextField(
                    controller: _imageUrlCtrl,
                    hint: 'https://example.com/image.jpg',
                    isDark: isDark,
                    prefixIcon: Icons.image_rounded,
                    keyboardType: TextInputType.url,
                  ),
                  if (_imageUrlCtrl.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _imageUrlCtrl.text,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.broken_image_rounded,
                                      color: Colors.red),
                                  SizedBox(width: 6),
                                  Text('رابط الصورة غير صحيح',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Category ─────────────────────────────────────────────────
            _SectionCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('التصنيف', isDark: isDark),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: WorkCategory.values
                        .where((c) => c != WorkCategory.all)
                        .map((cat) => _CategoryChip(
                              category: cat,
                              selected: _selectedCategory == cat,
                              onTap: () =>
                                  setState(() => _selectedCategory = cat),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Main Fields ───────────────────────────────────────────────
            _SectionCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('عنوان المنشور *', isDark: isDark),
                  _buildTextField(
                    controller: _titleCtrl,
                    hint: 'مثال: توزيع السلال الغذائية على 100 أسرة',
                    isDark: isDark,
                    prefixIcon: Icons.title_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'العنوان مطلوب'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _FieldLabel('الوصف التفصيلي *', isDark: isDark),
                  _buildTextField(
                    controller: _descCtrl,
                    hint:
                        'اكتب تفاصيل العمل الخيري، ما الذي تم، من استفاد، وكيف...',
                    isDark: isDark,
                    prefixIcon: Icons.description_rounded,
                    maxLines: 5,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'الوصف مطلوب'
                        : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Location & Beneficiaries ──────────────────────────────────
            _SectionCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('الموقع *', isDark: isDark),
                  _buildTextField(
                    controller: _locationCtrl,
                    hint: 'مثال: الرياض - حي العزيزية',
                    isDark: isDark,
                    prefixIcon: Icons.location_on_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'الموقع مطلوب'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _FieldLabel('عدد المستفيدين', isDark: isDark),
                  _buildTextField(
                    controller: _beneficiaryCtrl,
                    hint: '0',
                    isDark: isDark,
                    prefixIcon: Icons.people_alt_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Tags ──────────────────────────────────────────────────────
            _SectionCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('الوسوم (الهاشتاقات)', isDark: isDark),
                  _buildTextField(
                    controller: _tagsCtrl,
                    hint: 'مثال: رمضان، غذاء، أسر محتاجة',
                    isDark: isDark,
                    prefixIcon: Icons.tag_rounded,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'افصل بين الكلمات بفاصلة أو مسافة',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF666666)
                          : const Color(0xFFAAAAAA),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Submit Button ─────────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 52,
              decoration: BoxDecoration(
                gradient: _isSubmitting
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF4C3BC5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: _isSubmitting ? Colors.grey : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _isSubmitting
                    ? null
                    : [
                        BoxShadow(
                          color:
                              const Color(0xFF7C3AED).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _isSubmitting ? null : _submit,
                  child: Center(
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.publish_rounded,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'نشر الآن',
                                style: GoogleFonts.cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    required IconData prefixIcon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      textDirection: TextDirection.rtl,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.cairo(
        fontSize: 13.5,
        color: isDark ? Colors.white : const Color(0xFF111111),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.cairo(
          fontSize: 12.5,
          color:
              isDark ? const Color(0xFF666666) : const Color(0xFFBBBBBB),
        ),
        prefixIcon: Icon(prefixIcon,
            size: 20,
            color: isDark
                ? const Color(0xFF888888)
                : const Color(0xFFAAAAAA)),
        filled: true,
        fillColor: isDark
            ? const Color(0xFF2A2A2A)
            : const Color(0xFFF8F8F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFF333333)
                : const Color(0xFFEEEEEE),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
      ),
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _SectionCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
        ),
      ),
      child: child,
    );
  }
}

// ── Field Label ───────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _FieldLabel(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF555555),
        ),
      ),
    );
  }
}

// ── Category Chip ─────────────────────────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  final WorkCategory category;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip(
      {required this.category,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? category.color
              : category.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? category.color
                : category.color.withValues(alpha: 0.3),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: category.color.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: 14,
              color: selected ? Colors.white : category.color,
            ),
            const SizedBox(width: 5),
            Text(
              category.labelAr,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : category.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
