import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Premium Animated Splash Screen
// الصورة الأصلية هي القاعدة — الأنيميشن يُضاف فوقها كطبقات
// ─────────────────────────────────────────────────────────────────────────────
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  // ── Controllers ───────────────────────────────────────────────────────────
  late final AnimationController _masterCtrl;   // 0→7 s الرسوم المتتابعة
  late final AnimationController _glowCtrl;     // نبضة الضوء الذهبي
  late final AnimationController _particleCtrl; // جزيئات اللمع المتطايرة
  late final AnimationController _spinnerCtrl;  // دوران مؤشر التحميل
  late final AnimationController _streakCtrl;   // خطوط الضوء المنزلقة

  // ── Master-timeline Animations ────────────────────────────────────────────
  late final Animation<double> _screenFadeIn;   // fade من أسود → الصورة
  late final Animation<double> _glowFade;       // ظهور هالة الشعار
  late final Animation<double> _arabicFade;     // ظهور العنوان العربي
  late final Animation<Offset> _arabicSlide;    // انزلاق العنوان للأعلى
  late final Animation<double> _enFade;         // ظهور النص الإنجليزي
  late final Animation<double> _imageFade;      // ظهور قسم الصور
  late final Animation<double> _bottomFade;     // ظهور النص السفلي
  late final Animation<double> _spinnerFade;    // ظهور المؤشر
  late final Animation<double> _glowPulse;      // تنفس الهالة

  @override
  void initState() {
    super.initState();

    _masterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    );
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();
    _spinnerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _streakCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    // ── Staggered Timeline ────────────────────────────────────────────────
    _screenFadeIn = _interval(0.00, 0.18, Curves.easeIn);
    _glowFade     = _interval(0.12, 0.35, Curves.easeOut);
    _arabicFade   = _interval(0.28, 0.46, Curves.easeOut);
    _arabicSlide  = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.28, 0.46, curve: Curves.easeOut),
    ));
    _enFade      = _interval(0.42, 0.56, Curves.easeOut);
    _imageFade   = _interval(0.50, 0.68, Curves.easeOut);
    _bottomFade  = _interval(0.64, 0.78, Curves.easeOut);
    _spinnerFade = _interval(0.76, 0.90, Curves.easeOut);
    _glowPulse   = Tween<double>(begin: 0.50, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    // شاشة كاملة — إخفاء شريط الحالة والتنقل
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ));

    _masterCtrl.forward();

    // الانتقال للصفحة التالية بعد 7 ثوانٍ
    Future.delayed(const Duration(milliseconds: 7200), () {
      if (mounted) context.go('/login');
    });
  }

  Animation<double> _interval(double t0, double t1, Curve c) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _masterCtrl, curve: Interval(t0, t1, curve: c)),
      );

  @override
  void dispose() {
    // استعادة واجهة النظام الطبيعية بعد الـ Splash
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _masterCtrl.dispose();
    _glowCtrl.dispose();
    _particleCtrl.dispose();
    _spinnerCtrl.dispose();
    _streakCtrl.dispose();
    super.dispose();
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _masterCtrl,
          _glowCtrl,
          _particleCtrl,
          _spinnerCtrl,
          _streakCtrl,
        ]),
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // ── Layer 0: الصورة الأصلية — القاعدة الكاملة ──────────────
              Opacity(
                opacity: _screenFadeIn.value,
                child: Image.asset(
                  'assets/images/Ahbab.png',
                  fit: BoxFit.cover,
                  width: size.width,
                  height: size.height,
                  errorBuilder: (_, __, ___) =>
                      // fallback إذا لم تُضَف الصورة بعد
                      Container(
                        decoration: const BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(0, -0.25),
                            radius: 1.4,
                            colors: [
                              Color(0xFF0D5C28),
                              Color(0xFF093518),
                              Color(0xFF051A0A),
                            ],
                          ),
                        ),
                      ),
                ),
              ),

              // ── Layer 1: طبقة الإظلام الأولي (fade من أسود) ─────────────
              Opacity(
                opacity: (1.0 - _screenFadeIn.value).clamp(0.0, 1.0),
                child: Container(color: Colors.black),
              ),

              // ── Layer 2: جزيئات الذهب المتطايرة ─────────────────────────
              Opacity(
                opacity: (_screenFadeIn.value * 2).clamp(0.0, 1.0),
                child: CustomPaint(
                  size: size,
                  painter: _ParticlesPainter(progress: _particleCtrl.value),
                ),
              ),

              // ── Layer 3: هالة ضوئية ذهبية خلف الشعار ───────────────────
              _buildLogoGlow(size),

              // ── Layer 4: خطوط ضوء متحركة أسفل الصورة ───────────────────
              Positioned(
                bottom: size.height * 0.22,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _bottomFade.value,
                  child: CustomPaint(
                    size: Size(size.width, 3),
                    painter: _LightStreakPainter(progress: _streakCtrl.value),
                  ),
                ),
              ),

              // ── Layer 5: shimmer ذهبي على النص العربي ───────────────────
              _buildArabicShimmerOverlay(size),

              // ── Layer 6: مؤشر التحميل ─────────────────────────────────
              Positioned(
                bottom: 36,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _spinnerFade.value,
                  child: Center(
                    child: CustomPaint(
                      size: const Size(34, 34),
                      painter: _SpinnerPainter(progress: _spinnerCtrl.value),
                    ),
                  ),
                ),
              ),

              // ── Layer 7: وهج أبيض ناعم في النصف العلوي عند البداية ─────
              Opacity(
                opacity: ((0.3 - _masterCtrl.value) * 3).clamp(0.0, 0.25),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [Colors.white, Colors.transparent],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── هالة الشعار الذهبية النابضة ──────────────────────────────────────────
  Widget _buildLogoGlow(Size size) {
    // الشعار في الأعلى تقريباً عند 22% من الارتفاع
    final centerY = size.height * 0.22;
    final centerX = size.width * 0.5;
    final glowR = 110.0 * _glowPulse.value;

    return Positioned(
      top: centerY - glowR,
      left: centerX - glowR,
      width: glowR * 2,
      height: glowR * 2,
      child: Opacity(
        opacity: _glowFade.value * _glowPulse.value * 0.72,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFD4AF37).withAlpha(
                    (180 * _glowPulse.value).round()),
                const Color(0xFFFFD700).withAlpha(
                    (80 * _glowPulse.value).round()),
                Colors.transparent,
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  // ── Shimmer ذهبي يمر على منطقة العنوان العربي ────────────────────────────
  Widget _buildArabicShimmerOverlay(Size size) {
    // منطقة العنوان العربي تقريباً 35–47% من الارتفاع
    final areaTop    = size.height * 0.34;
    final areaHeight = size.height * 0.14;
    final shimmerX   = _streakCtrl.value * (size.width + 200) - 100;

    return Positioned(
      top: areaTop,
      left: 0,
      right: 0,
      height: areaHeight,
      child: Opacity(
        opacity: _arabicFade.value * 0.35,
        child: CustomPaint(
          painter: _HorizontalShimmerPainter(x: shimmerX, width: size.width),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painters
// ─────────────────────────────────────────────────────────────────────────────

/// جزيئات ذهبية متطايرة لامعة
class _ParticlesPainter extends CustomPainter {
  final double progress;

  static final _rng = Random(99);
  static final List<_P> _pts = List.generate(
    70,
    (i) => _P(
      x:      _rng.nextDouble(),
      phase:  _rng.nextDouble(),
      speed:  _rng.nextDouble() * 0.20 + 0.05,
      r:      _rng.nextDouble() * 2.4 + 0.6,
      drift:  _rng.nextDouble() * 0.06 - 0.03,
      bright: _rng.nextBool(),
    ),
  );

  const _ParticlesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _pts) {
      final t  = (p.phase + progress * p.speed) % 1.0;
      final px = (p.x + p.drift * sin(progress * pi)) * size.width;
      final py = (1.0 - t) * size.height;
      final a  = (sin(t * pi) * 200).round().clamp(0, 200);

      // نقطة ضوئية
      canvas.drawCircle(
        Offset(px, py),
        p.r,
        Paint()
          ..color = (p.bright
                  ? const Color(0xFFFFE566)
                  : const Color(0xFFD4AF37))
              .withAlpha(a),
      );

      // وميض صليبي للجسيمات الكبيرة
      if (p.r > 1.9) {
        final sp = Paint()
          ..color = const Color(0xFFFFEC80).withAlpha((a * 0.55).round())
          ..strokeWidth = 0.9;
        final cr = p.r * 2.8;
        canvas.drawLine(Offset(px - cr, py), Offset(px + cr, py), sp);
        canvas.drawLine(Offset(px, py - cr), Offset(px, py + cr), sp);
      }
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter o) => o.progress != progress;
}

class _P {
  final double x, phase, speed, r, drift;
  final bool bright;
  const _P({
    required this.x,
    required this.phase,
    required this.speed,
    required this.r,
    required this.drift,
    required this.bright,
  });
}

/// خط ضوء ذهبي منزلق أفقياً
class _LightStreakPainter extends CustomPainter {
  final double progress;
  const _LightStreakPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 2; i++) {
      final t  = (progress + i * 0.5) % 1.0;
      final cx = t * (size.width + 160) - 80;
      final a  = (sin(t * pi) * 200).round().clamp(0, 200);

      canvas.drawLine(
        Offset(cx - 90, size.height / 2),
        Offset(cx + 90, size.height / 2),
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              const Color(0xFFD4AF37).withAlpha(a),
              const Color(0xFFFFE566).withAlpha(a),
              const Color(0xFFD4AF37).withAlpha(a),
              Colors.transparent,
            ],
          ).createShader(Rect.fromLTWH(cx - 90, 0, 180, size.height))
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );

      // وهج تحت الخط
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset(cx, size.height / 2), width: 160, height: 12),
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFD4AF37).withAlpha((a * 0.3).round()),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCenter(
              center: Offset(cx, size.height / 2), width: 160, height: 12)),
      );
    }
  }

  @override
  bool shouldRepaint(_LightStreakPainter o) => o.progress != progress;
}

/// shimmer أفقي ذهبي ناعم
class _HorizontalShimmerPainter extends CustomPainter {
  final double x;
  final double width;
  const _HorizontalShimmerPainter({required this.x, required this.width});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, size.height),
      Paint()
        ..shader = LinearGradient(
          colors: const [
            Colors.transparent,
            Color(0xFFFFE566),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          transform: _ShiftTransform(x / width),
        ).createShader(Rect.fromLTWH(0, 0, width, size.height)),
    );
  }

  @override
  bool shouldRepaint(_HorizontalShimmerPainter o) => o.x != x;
}

class _ShiftTransform extends GradientTransform {
  final double shift;
  const _ShiftTransform(this.shift);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (shift - 0.5) * 2.5, 0, 0);
}

/// مؤشر التحميل الدائري المجزأ
class _SpinnerPainter extends CustomPainter {
  final double progress;
  const _SpinnerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const segs = 12;
    const gap  = 0.07;
    final r    = size.width / 2 - 2;
    final c    = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < segs; i++) {
      final t = ((progress - i / segs) % 1.0 + 1.0) % 1.0;
      final a = (sin(t * pi) * 255).round().clamp(30, 255);

      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        i * 2 * pi / segs + gap / 2,
        2 * pi / segs - gap,
        false,
        Paint()
          ..color = const Color(0xFFD4AF37).withAlpha(a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_SpinnerPainter o) => o.progress != progress;
}
