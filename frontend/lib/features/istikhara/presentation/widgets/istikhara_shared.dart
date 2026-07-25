import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/istikhara/domain/istikhara_models.dart';
import 'package:charity_app/features/istikhara/presentation/providers/istikhara_providers.dart';

/// اللون المميّز لقسم الاستخارة.
const Color istikharaAccent = Color(0xFF6366F1);

/// دعاء الإمام الصادق عليه السلام للاستخارة.
const String sadiqIstikharaDua =
    'اللّهُمَّ إِنِّي أَسْتَخِيرُكَ بِعِلْمِكَ، فَصَلِّ عَلَى مُحَمَّدٍ وَآلِهِ، وَاقْضِ لِي '
    'بِالْخِيَرَةِ، وَأَلْهِمْنِي مَعْرِفَةَ الاخْتِيَارِ، وَامْنُنْ عَلَيَّ بِالنَّجَاحِ بِقُدْرَتِكَ '
    'فِيمَا أَسْتَخِيرُكَ فِيهِ، يَا أَرْحَمَ الرَّاحِمِينَ.';

const String salawat = 'اللّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَآلِ مُحَمَّدٍ';

/// خطوات آداب الاستخارة (نفسها لكل أنواع الاستخارة).
const List<String> istikharaAdabSteps = [
  'استحضر النيّة واعقد القلب على طلب الخير من الله في حاجتك.',
  'صلِّ على محمد وآل محمد (ثلاث مرات).',
  'اقرأ سورة الحمد (الفاتحة) مرّة واحدة.',
  'قل: يا مَنْ يَعْلَمُ اهدِ مَنْ لا يَعْلَمُ.',
  'اقرأ دعاء الإمام الصادق عليه السلام للاستخارة.',
];

/// بطاقة عرض نتيجة الاستخارة (تُستخدم في القرآن والسبحة معاً).
class IstikharaResultView extends StatelessWidget {
  final IstikharaResult result;
  final String detail;
  final String commentary;
  const IstikharaResultView({super.key, required this.result, required this.detail, required this.commentary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [result.color, result.color.withValues(alpha: 0.72)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: result.color.withValues(alpha: 0.32), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Column(
            children: [
              Icon(result.icon, color: Colors.white, size: 52),
              const SizedBox(height: 12),
              Text(result.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
              if (detail.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(detail,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(fontSize: 13, color: Colors.white.withValues(alpha: 0.9))),
              ],
            ],
          ),
        ),
        if (commentary.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.menu_book_rounded, size: 18, color: result.color),
                    const SizedBox(width: 8),
                    Text('الشرح',
                        style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(commentary,
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        height: 1.9,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: istikharaAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: istikharaAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'الاستخارة تُستخار عند التحيّر، وتُختتم بالصلاة على محمد وآل محمد، والأمر بعدها إلى الله.',
                  style: GoogleFonts.cairo(fontSize: 11.5, height: 1.6, color: istikharaAccent),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// حوار حفظ نتيجة الاستخارة في السجلّ بعنوان يختاره المستخدم.
Future<void> showSaveIstikharaDialog(
  BuildContext context,
  WidgetRef ref, {
  required IstikharaMethod method,
  required IstikharaResult result,
  required String detail,
  required String commentary,
}) async {
  final controller = TextEditingController();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('حفظ الاستخارة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16)),
      content: TextField(
        controller: controller,
        textAlign: TextAlign.right,
        style: GoogleFonts.cairo(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'عنوان (مثال: استخارة السفر)',
          hintStyle: GoogleFonts.cairo(fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: istikharaAccent, width: 2),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text('إلغاء', style: GoogleFonts.cairo(fontWeight: FontWeight.w700, color: Colors.grey)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: istikharaAccent),
          onPressed: () {
            final title = controller.text.trim().isEmpty ? 'استخارة' : controller.text.trim();
            ref.read(istikharaHistoryProvider.notifier).add(IstikharaRecord(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: title,
                  method: method,
                  result: result,
                  detail: detail,
                  commentary: commentary,
                  timestamp: DateTime.now().millisecondsSinceEpoch,
                ));
            Navigator.of(ctx).pop();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('تم حفظ الاستخارة', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              behavior: SnackBarBehavior.floating,
              backgroundColor: istikharaAccent,
            ));
          },
          child: Text('حفظ', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}
