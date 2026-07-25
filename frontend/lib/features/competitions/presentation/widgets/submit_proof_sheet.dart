import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/competitions/domain/competition_models.dart';
import 'package:charity_app/features/competitions/presentation/providers/competitions_provider.dart';

/// ورقة سفلية لرفع دليل المشاركة اليومي (نص أو "صورة" — يُحاكى اختيارها).
class SubmitProofSheet extends ConsumerStatefulWidget {
  final Competition competition;
  const SubmitProofSheet({super.key, required this.competition});

  static Future<void> show(BuildContext context, Competition c) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubmitProofSheet(competition: c),
    );
  }

  @override
  ConsumerState<SubmitProofSheet> createState() => _SubmitProofSheetState();
}

class _SubmitProofSheetState extends ConsumerState<SubmitProofSheet> {
  final _controller = TextEditingController();
  String? _imageName; // محاكاة اختيار صورة

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pickImage() {
    // محاكاة منتقي الصور (لا حزمة صور خارجية مطلوبة في النسخة التجريبية).
    setState(() => _imageName = 'proof_${DateTime.now().millisecondsSinceEpoch}.jpg');
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty && _imageName == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('أضف نصاً أو صورة كدليل', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFEF4444),
      ));
      return;
    }
    ref.read(competitionsProvider.notifier).submitProof(
          widget.competition.id,
          text: text.isEmpty ? null : text,
          imagePath: _imageName,
        );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('تم تسجيل دليلك اليومي ✓', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF059669),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = widget.competition;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44, height: 4,
                decoration: BoxDecoration(color: AppColors.textTertiaryLight, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(c.icon, color: c.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('رفع دليل المشاركة',
                      style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('سجّل ما أنجزته اليوم في "${c.title}"',
                style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.textSecondaryLight)),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 3,
              style: GoogleFonts.cairo(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'اكتب وصفاً لما أنجزته (اختياري إن أرفقت صورة)…',
                hintStyle: GoogleFonts.cairo(fontSize: 12, color: AppColors.textTertiaryLight),
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _imageName != null ? c.color : AppColors.borderLight,
                    width: 1.4,
                    style: BorderStyle.solid,
                  ),
                  color: _imageName != null ? c.color.withValues(alpha: 0.06) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_imageName != null ? Icons.check_circle_rounded : Icons.add_photo_alternate_rounded,
                        color: _imageName != null ? c.color : AppColors.textSecondaryLight, size: 20),
                    const SizedBox(width: 8),
                    Text(_imageName != null ? 'تم إرفاق صورة' : 'إرفاق صورة',
                        style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w700,
                            color: _imageName != null ? c.color : AppColors.textSecondaryLight)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('تسجيل الدليل', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
