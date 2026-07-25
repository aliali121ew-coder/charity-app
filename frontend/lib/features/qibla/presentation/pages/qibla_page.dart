import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';

/// إحداثيات الكعبة المشرّفة (مكة المكرمة).
const double _kaabaLat = 21.4225;
const double _kaabaLng = 39.8262;
const Color _qiblaColor = Color(0xFFEF4444);

/// مراحل تجهيز البوصلة، لعرض الحالة المناسبة للمستخدم.
enum _QiblaPhase { loading, ready, error, noSensor }

/// صفحة اتجاه القبلة: بوصلة حقيقية تعتمد على مستشعر المغناطيس في الجهاز
/// مع تحديد الموقع عبر الـ GPS لحساب زاوية القبلة بدقّة.
class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  StreamSubscription<CompassEvent>? _compassSub;

  _QiblaPhase _phase = _QiblaPhase.loading;
  String? _errorMessage;

  double? _heading; // اتجاه الجهاز عن الشمال المغناطيسي (درجات)
  double? _qiblaBearing; // زاوية القبلة عن الشمال (درجات)
  Position? _position;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() {
      _phase = _QiblaPhase.loading;
      _errorMessage = null;
    });

    // 1) التحقق من توفّر مستشعر البوصلة.
    final events = FlutterCompass.events;
    if (events == null) {
      setState(() {
        _phase = _QiblaPhase.noSensor;
        _errorMessage = 'جهازك لا يحتوي على مستشعر بوصلة (مغناطيس).';
      });
      return;
    }

    // 2) تحديد الموقع لحساب زاوية القبلة.
    final located = await _resolveLocation();
    if (!located || !mounted) return;

    // 3) الاشتراك في تدفّق قراءات البوصلة.
    _compassSub = events.listen((event) {
      if (!mounted) return;
      setState(() => _heading = event.heading);
    });

    setState(() => _phase = _QiblaPhase.ready);
  }

  /// يطلب الإذن ويجلب الإحداثيات ثم يحسب زاوية القبلة. يعيد false عند الفشل.
  Future<bool> _resolveLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _fail('خدمة الموقع معطّلة. يرجى تفعيلها من الإعدادات.');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _fail('تم رفض إذن الموقع.');
        return false;
      }
      if (permission == LocationPermission.deniedForever) {
        _fail('إذن الموقع مرفوض نهائياً. افتح الإعدادات لتفعيله.');
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      _position = position;
      _qiblaBearing = _computeQiblaBearing(position.latitude, position.longitude);
      return true;
    } catch (e) {
      _fail('تعذّر تحديد الموقع: $e');
      return false;
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _phase = _QiblaPhase.error;
      _errorMessage = message;
    });
  }

  /// حساب زاوية القبلة (الاتجاه نحو الكعبة) عن الشمال الجغرافي بدرجات.
  static double _computeQiblaBearing(double lat, double lng) {
    final phi1 = _deg2rad(lat);
    final phi2 = _deg2rad(_kaabaLat);
    final deltaLng = _deg2rad(_kaabaLng - lng);

    final y = math.sin(deltaLng);
    final x = math.cos(phi1) * math.tan(phi2) - math.sin(phi1) * math.cos(deltaLng);
    final bearing = _rad2deg(math.atan2(y, x));
    return (bearing + 360) % 360;
  }

  static double _deg2rad(double d) => d * math.pi / 180.0;
  static double _rad2deg(double r) => r * 180.0 / math.pi;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('اتجاه القبلة', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'إعادة المحاولة',
            onPressed: _init,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: switch (_phase) {
        _QiblaPhase.loading => _StatusView(
            isDark: isDark,
            icon: Icons.explore_rounded,
            title: 'جارٍ تحديد القبلة...',
            message: 'نقوم بقراءة موقعك واتجاه البوصلة.',
            showSpinner: true,
          ),
        _QiblaPhase.error => _StatusView(
            isDark: isDark,
            icon: Icons.location_off_rounded,
            title: 'تعذّر تحديد القبلة',
            message: _errorMessage ?? 'حدث خطأ غير متوقع.',
            onRetry: _init,
          ),
        _QiblaPhase.noSensor => _StatusView(
            isDark: isDark,
            icon: Icons.sensors_off_rounded,
            title: 'لا يوجد مستشعر بوصلة',
            message: _errorMessage ?? 'جهازك لا يدعم تحديد الاتجاه.',
          ),
        _QiblaPhase.ready => _CompassView(
            isDark: isDark,
            heading: _heading,
            qiblaBearing: _qiblaBearing!,
            position: _position,
          ),
      },
    );
  }
}

/// عرض البوصلة الدوّارة مع إبرة القبلة والمعلومات النصية.
class _CompassView extends StatelessWidget {
  final bool isDark;
  final double? heading;
  final double qiblaBearing;
  final Position? position;
  const _CompassView({
    required this.isDark,
    required this.heading,
    required this.qiblaBearing,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final h = heading;
    // فرق الزاوية بين اتجاه الجهاز والقبلة (موجب = القبلة على اليمين).
    final double? diff = h == null ? null : ((qiblaBearing - h + 360) % 360);
    final bool aligned = diff != null && (diff < 5 || diff > 355);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        _InfoBanner(isDark: isDark, aligned: aligned, qiblaBearing: qiblaBearing),
        const SizedBox(height: 24),
        Center(
          child: SizedBox(
            width: 280,
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // قرص البوصلة يدور عكس اتجاه الجهاز ليبقى الشمال ثابتاً جغرافياً.
                Transform.rotate(
                  angle: h == null ? 0 : -h * math.pi / 180.0,
                  child: CustomPaint(
                    size: const Size(280, 280),
                    painter: _CompassDialPainter(isDark: isDark),
                  ),
                ),
                // إبرة القبلة تشير نحو الكعبة بالنسبة لاتجاه الجهاز الحالي.
                Transform.rotate(
                  angle: diff == null ? 0 : diff * math.pi / 180.0,
                  child: _QiblaNeedle(aligned: aligned),
                ),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _qiblaColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        _ReadingRow(
          isDark: isDark,
          label: 'زاوية القبلة',
          value: '${qiblaBearing.toStringAsFixed(0)}°',
          icon: Icons.navigation_rounded,
        ),
        const SizedBox(height: 10),
        _ReadingRow(
          isDark: isDark,
          label: 'اتجاه الجهاز',
          value: h == null ? '—' : '${h.toStringAsFixed(0)}°',
          icon: Icons.smartphone_rounded,
        ),
        if (position != null) ...[
          const SizedBox(height: 10),
          _ReadingRow(
            isDark: isDark,
            label: 'موقعك',
            value:
                '${position!.latitude.toStringAsFixed(3)}, ${position!.longitude.toStringAsFixed(3)}',
            icon: Icons.my_location_rounded,
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'أمسك الجهاز أفقياً وابتعد عن المعادن والأجهزة الكهربائية لقراءة أدق.',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 11.5,
            height: 1.6,
            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
          ),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final bool isDark;
  final bool aligned;
  final double qiblaBearing;
  const _InfoBanner({required this.isDark, required this.aligned, required this.qiblaBearing});

  @override
  Widget build(BuildContext context) {
    final color = aligned ? AppColors.success : _qiblaColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.72)]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 7))],
      ),
      child: Row(
        children: [
          Icon(aligned ? Icons.check_circle_rounded : Icons.explore_rounded, color: Colors.white, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aligned ? 'أنت تواجه القبلة الآن' : 'وجّه الجهاز نحو الإبرة الحمراء',
                  style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 3),
                Text(
                  'الكعبة المشرّفة — مكة المكرمة',
                  style: GoogleFonts.cairo(fontSize: 11, color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QiblaNeedle extends StatelessWidget {
  final bool aligned;
  const _QiblaNeedle({required this.aligned});

  @override
  Widget build(BuildContext context) {
    final color = aligned ? AppColors.success : _qiblaColor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)],
          ),
          child: const Icon(Icons.mosque_rounded, color: Colors.white, size: 22),
        ),
        Container(width: 4, height: 96, color: color),
        const SizedBox(height: 120),
      ],
    );
  }
}

class _ReadingRow extends StatelessWidget {
  final bool isDark;
  final String label;
  final String value;
  final IconData icon;
  const _ReadingRow({required this.isDark, required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _qiblaColor),
          const SizedBox(width: 12),
          Text(label,
              style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
        ],
      ),
    );
  }
}

/// يرسم قرص البوصلة: الدائرة والعلامات والاتجاهات الأربعة.
class _CompassDialPainter extends CustomPainter {
  final bool isDark;
  _CompassDialPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = isDark ? AppColors.borderDark : AppColors.borderLight;
    canvas.drawCircle(center, radius - 2, ringPaint);
    canvas.drawCircle(center, radius - 26, ringPaint..color = (isDark ? AppColors.borderDark : AppColors.borderLight).withValues(alpha: 0.5));

    // علامات كل 30 درجة.
    final tickPaint = Paint()..color = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
    for (int i = 0; i < 360; i += 6) {
      final isMajor = i % 30 == 0;
      final angle = _deg2rad(i.toDouble());
      final outer = radius - 6;
      final inner = radius - (isMajor ? 18 : 12);
      final p1 = center + Offset(math.sin(angle) * outer, -math.cos(angle) * outer);
      final p2 = center + Offset(math.sin(angle) * inner, -math.cos(angle) * inner);
      canvas.drawLine(p1, p2, tickPaint..strokeWidth = isMajor ? 2 : 1);
    }

    // حروف الاتجاهات.
    const labels = {0: 'ش', 90: 'ق', 180: 'ج', 270: 'غ'};
    labels.forEach((deg, text) {
      final angle = _deg2rad(deg.toDouble());
      final pos = center + Offset(math.sin(angle) * (radius - 44), -math.cos(angle) * (radius - 44));
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: deg == 0
                ? _qiblaColor
                : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    });
  }

  static double _deg2rad(double d) => d * math.pi / 180.0;

  @override
  bool shouldRepaint(covariant _CompassDialPainter oldDelegate) => oldDelegate.isDark != isDark;
}

/// عرض موحّد لحالات التحميل/الخطأ/عدم توفّر المستشعر.
class _StatusView extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String message;
  final bool showSpinner;
  final VoidCallback? onRetry;
  const _StatusView({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.message,
    this.showSpinner = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: _qiblaColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: showSpinner
                  ? const Padding(
                      padding: EdgeInsets.all(28),
                      child: CircularProgressIndicator(color: _qiblaColor, strokeWidth: 3),
                    )
                  : Icon(icon, size: 44, color: _qiblaColor),
            ),
            const SizedBox(height: 22),
            Text(title,
                style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    fontSize: 13,
                    height: 1.6,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
            if (onRetry != null) ...[
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onRetry,
                style: FilledButton.styleFrom(backgroundColor: _qiblaColor),
                icon: const Icon(Icons.refresh_rounded),
                label: Text('إعادة المحاولة', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
