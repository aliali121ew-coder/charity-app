import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/istikhara/domain/istikhara_models.dart';
import 'package:charity_app/features/istikhara/presentation/pages/istikhara_adab_page.dart';
import 'package:charity_app/features/istikhara/presentation/widgets/istikhara_shared.dart';

const Color _tasbihColor = Color(0xFFB45309);
const Color _glowColor = Color(0xFFFFC23C);

/// حديث أمير المؤمنين عليّ عليه السلام في الاستخارة (يُعرض كتلميح).
const String _aliHadith = 'ما حارَ مَنِ استخارَ، ولا نَدِمَ مَنِ استشارَ.';

enum _Phase { idle, counting, done }

/// استخارة السبحة على طريقة الإمام المهدي (عج): ينوي المستخدم حاجته ويضغط
/// "نستخير الله"، فيُقبض كفٌّ من الخرز (عدد عشوائي) ويُحسب الباقي بعدّه اثنين
/// اثنين: خرزة (افعل) أو خرزتان (لا تفعل) — وفق معامل باقي القسمة على اثنين.
class TasbihIstikharaPage extends ConsumerStatefulWidget {
  const TasbihIstikharaPage({super.key});

  @override
  ConsumerState<TasbihIstikharaPage> createState() => _TasbihIstikharaPageState();
}

class _TasbihIstikharaPageState extends ConsumerState<TasbihIstikharaPage> {
  _Phase _phase = _Phase.idle;
  int _leftover = 0;

  IstikharaResult get _result => _leftover == 1 ? IstikharaResult.good : IstikharaResult.prohibition;
  // النتيجة وشرحها دون حساب عدّ الخرز.
  String get _detail => _leftover == 1 ? 'النتيجة: افعل' : 'النتيجة: لا تفعل';
  String get _commentary => _leftover == 1
      ? 'خيرة جيدة بالإقدام على الأمر متوكّلاً على الله، فالصلاة على النبي وآل محمد تُطلب في بدايته ونهايته.'
      : 'الأولى ترك هذا الأمر وتفويضه إلى الله.';

  void _grab() {
    final count = 22 + Random().nextInt(10); // كفّ عشوائي من الخرز (22..31)
    HapticFeedback.lightImpact();
    setState(() {
      _leftover = count.isOdd ? 1 : 2;
      _phase = _Phase.counting;
    });
  }

  // إعادة الخيرة تُرجِع إلى آداب الاستخارة لإتمامها قبل كل خيرة جديدة.
  void _restartFromAdab() => Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const IstikharaAdabPage(method: IstikharaMethod.tasbih)),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('استخارة السبحة', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: switch (_phase) {
        _Phase.done => _buildResult(isDark),
        _Phase.counting => _GlowingSageView(
            isDark: isDark,
            onDone: () => setState(() => _phase = _Phase.done),
          ),
        _Phase.idle => _buildIdle(isDark),
      },
    );
  }

  Widget _buildIdle(bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        const _SageImage(height: 360),
        const SizedBox(height: 18),
        _HintCard(isDark: isDark),
        const SizedBox(height: 20),
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: _grab,
            style: FilledButton.styleFrom(
              backgroundColor: _tasbihColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text('نستخير الله', style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }

  Widget _buildResult(bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        IstikharaResultView(result: _result, detail: _detail, commentary: _commentary),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _restartFromAdab,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: istikharaAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.refresh_rounded, color: istikharaAccent),
                label: Text('إعادة', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: istikharaAccent)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => showSaveIstikharaDialog(
                  context,
                  ref,
                  method: IstikharaMethod.tasbih,
                  result: _result,
                  detail: _detail,
                  commentary: _commentary,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: istikharaAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.bookmark_add_rounded),
                label: Text('حفظ', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// تلميح: حديث أمير المؤمنين عليّ عليه السلام في فضل الاستخارة والاستشارة.
class _HintCard extends StatelessWidget {
  final bool isDark;
  const _HintCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _tasbihColor.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _tasbihColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.format_quote_rounded, color: _tasbihColor, size: 20),
              const SizedBox(width: 8),
              Text('تلميح',
                  style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w800, color: _tasbihColor)),
            ],
          ),
          const SizedBox(height: 10),
          Text(_aliHadith,
              textAlign: TextAlign.center,
              style: GoogleFonts.amiriQuran(
                  fontSize: 18,
                  height: 1.9,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
          const SizedBox(height: 8),
          Text('— أمير المؤمنين عليّ عليه السلام',
              style: GoogleFonts.cairo(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
        ],
      ),
    );
  }
}

/// صورة الاستخارة بحواف ناعمة (مع حلٍّ احتياطي إن غاب ملف الصورة).
class _SageImage extends StatelessWidget {
  final double height;
  final double? width;
  const _SageImage({required this.height, this.width});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Image.asset(
          'assets/images/istikhara_sage.png',
          width: width ?? double.infinity,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: width ?? double.infinity,
            height: height,
            color: _tasbihColor.withValues(alpha: 0.12),
            child: const Icon(Icons.auto_stories_rounded, color: _tasbihColor, size: 60),
          ),
        ),
      ),
    );
  }
}

/// مشهد الاستخارة: توهّج شمسيّ يشعّ خلف الصورة لمدّة ٤ ثوانٍ ثم تظهر النتيجة.
class _GlowingSageView extends StatefulWidget {
  final bool isDark;
  final VoidCallback onDone;
  const _GlowingSageView({required this.isDark, required this.onDone});

  @override
  State<_GlowingSageView> createState() => _GlowingSageViewState();
}

class _GlowingSageViewState extends State<_GlowingSageView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 320,
            height: 420,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                final v = _controller.value;
                final intensity = (v / 0.25).clamp(0.0, 1.0); // تصاعد التوهّج في البداية
                final pulse = 0.85 + 0.15 * sin(v * pi * 4); // نبض شمسيّ لطيف
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(320, 420),
                      painter: _SunGlowPainter(rotation: v * pi * 1.5, intensity: intensity * pulse),
                    ),
                    const _SageImage(height: 340, width: 244),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Text('نستخير الله...',
              style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: widget.isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
          const SizedBox(height: 14),
          SizedBox(
            width: 160,
            child: LinearProgressIndicator(
              backgroundColor: widget.isDark ? AppColors.borderDark : AppColors.borderLight,
              color: _glowColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}

/// يرسم توهّجاً شمسيّاً (هالة متدرّجة + أشعّة دوّارة) خلف الصورة.
class _SunGlowPainter extends CustomPainter {
  final double rotation;
  final double intensity;
  _SunGlowPainter({required this.rotation, required this.intensity});

  static const int _rays = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width * 0.62;

    // هالة شمسية متدرّجة.
    final halo = Paint()
      ..shader = RadialGradient(
        colors: [
          _glowColor.withValues(alpha: 0.55 * intensity),
          _glowColor.withValues(alpha: 0.18 * intensity),
          _glowColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxR));
    canvas.drawCircle(center, maxR, halo);

    // أشعّة شمسية دوّارة.
    final rayPaint = Paint()..color = _glowColor.withValues(alpha: 0.40 * intensity);
    final inner = size.width * 0.20;
    final outer = size.width * 0.60;
    const halfWidth = 0.085;
    for (int i = 0; i < _rays; i++) {
      final a = rotation + i * (2 * pi / _rays);
      final p1 = center + Offset(cos(a - halfWidth) * inner, sin(a - halfWidth) * inner);
      final p2 = center + Offset(cos(a) * outer, sin(a) * outer);
      final p3 = center + Offset(cos(a + halfWidth) * inner, sin(a + halfWidth) * inner);
      canvas.drawPath(Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy)..close(), rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SunGlowPainter old) => old.rotation != rotation || old.intensity != intensity;
}
