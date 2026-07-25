import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/istikhara/domain/istikhara_models.dart';
import 'package:charity_app/features/istikhara/presentation/pages/quran_istikhara_result_page.dart';
import 'package:charity_app/features/istikhara/presentation/pages/tasbih_istikhara_page.dart';
import 'package:charity_app/features/istikhara/presentation/widgets/istikhara_shared.dart';

/// شاشة النيّة والآداب: تهيّئ المستخدم نفسياً قبل الاستخارة، وفيها عدّاد
/// للصلاة على محمد وآله (ثلاث مرات) لا يُفتح زرّ "استخِر" إلا بعد إتمامها.
class IstikharaAdabPage extends StatefulWidget {
  final IstikharaMethod method;
  const IstikharaAdabPage({super.key, required this.method});

  @override
  State<IstikharaAdabPage> createState() => _IstikharaAdabPageState();
}

class _IstikharaAdabPageState extends State<IstikharaAdabPage> {
  int _salawatCount = 0;
  bool get _ready => _salawatCount >= 3;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('آداب الاستخارة', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          _Intro(method: widget.method, isDark: isDark),
          const SizedBox(height: 18),
          Text('الآداب',
              style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
          const SizedBox(height: 10),
          ...List.generate(istikharaAdabSteps.length, (i) => _AdabTile(index: i + 1, text: istikharaAdabSteps[i], isDark: isDark)),
          const SizedBox(height: 16),
          _SalawatCounter(
            count: _salawatCount,
            isDark: isDark,
            onTap: () => setState(() {
              if (_salawatCount < 3) _salawatCount++;
            }),
          ),
          const SizedBox(height: 16),
          _DuaCard(isDark: isDark),
          const SizedBox(height: 22),
          _StartButton(
            enabled: _ready,
            onTap: _ready ? _start : null,
          ),
          if (!_ready) ...[
            const SizedBox(height: 10),
            Text('أتمّ الصلاة على محمد وآله (٣ مرات) لتفعيل الاستخارة',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 11.5, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight)),
          ],
        ],
      ),
    );
  }

  void _start() {
    final page = widget.method == IstikharaMethod.quran
        ? const QuranIstikharaResultPage()
        : const TasbihIstikharaPage();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }
}

class _Intro extends StatelessWidget {
  final IstikharaMethod method;
  final bool isDark;
  const _Intro({required this.method, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: istikharaAccent.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: istikharaAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.spa_rounded, color: istikharaAccent, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(method.label,
                    style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w900, color: istikharaAccent)),
                const SizedBox(height: 4),
                Text('هيّئ قلبك وأخلِص نيّتك، ثم اتّبع الآداب التالية قبل الاستخارة.',
                    style: GoogleFonts.cairo(
                        fontSize: 12,
                        height: 1.6,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdabTile extends StatelessWidget {
  final int index;
  final String text;
  final bool isDark;
  const _AdabTile({required this.index, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: istikharaAccent.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Center(
              child: Text('$index',
                  style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w800, color: istikharaAccent)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(text,
                  style: GoogleFonts.cairo(
                      fontSize: 13,
                      height: 1.6,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalawatCounter extends StatelessWidget {
  final int count;
  final bool isDark;
  final VoidCallback onTap;
  const _SalawatCounter({required this.count, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final done = count >= 3;
    return Material(
      color: done ? AppColors.success.withValues(alpha: 0.12) : istikharaAccent.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: (done ? AppColors.success : istikharaAccent).withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Text(salawat,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiriQuran(
                      fontSize: 18,
                      height: 1.8,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(done ? Icons.check_circle_rounded : Icons.touch_app_rounded,
                      size: 18, color: done ? AppColors.success : istikharaAccent),
                  const SizedBox(width: 8),
                  Text(done ? 'تمّت الصلاة (٣/٣)' : 'اضغط للصلاة — $count / 3',
                      style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: done ? AppColors.success : istikharaAccent)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DuaCard extends StatelessWidget {
  final bool isDark;
  const _DuaCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('دعاء الإمام الصادق عليه السلام',
              style: GoogleFonts.cairo(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
          const SizedBox(height: 12),
          Text(sadiqIstikharaDua,
              textAlign: TextAlign.justify,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiriQuran(
                  fontSize: 17,
                  height: 2.0,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
        ],
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onTap;
  const _StartButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: istikharaAccent,
          disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.auto_awesome_rounded),
        label: Text('استخِر الآن',
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w900)),
      ),
    );
  }
}
