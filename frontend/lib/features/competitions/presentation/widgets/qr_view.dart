import 'package:flutter/material.dart';

/// رمز QR مُنمّط (deterministic) يُرسم من بيانات الكود بدون أي حزمة خارجية،
/// ليبقى التطبيق يعمل دون اتصال. مناسب لعرض كود المطالبة (تُؤكَّد المطالبة
/// داخل التطبيق من المشرف، لا بالمسح الخارجي).
class QrView extends StatelessWidget {
  final String data;
  final double size;
  final Color foreground;
  final Color background;

  const QrView({
    super.key,
    required this.data,
    this.size = 160,
    this.foreground = const Color(0xFF0F172A),
    this.background = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.06),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: CustomPaint(
        painter: _QrPainter(data: data, foreground: foreground),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  final String data;
  final Color foreground;
  static const int _modules = 25; // أبعاد الشبكة

  _QrPainter({required this.data, required this.foreground});

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _modules;
    final paint = Paint()..color = foreground;
    final matrix = _buildMatrix();

    for (var r = 0; r < _modules; r++) {
      for (var c = 0; c < _modules; c++) {
        if (!matrix[r][c]) continue;
        final rect = Rect.fromLTWH(c * cell, r * cell, cell, cell);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(cell * 0.08), Radius.circular(cell * 0.25)),
          paint,
        );
      }
    }
  }

  List<List<bool>> _buildMatrix() {
    final m = List.generate(_modules, (_) => List.filled(_modules, false));

    // نقش التحديد (finder patterns) في ثلاث زوايا.
    void finder(int top, int left) {
      for (var r = 0; r < 7; r++) {
        for (var c = 0; c < 7; c++) {
          final border = r == 0 || r == 6 || c == 0 || c == 6;
          final core = r >= 2 && r <= 4 && c >= 2 && c <= 4;
          m[top + r][left + c] = border || core;
        }
      }
    }

    finder(0, 0);
    finder(0, _modules - 7);
    finder(_modules - 7, 0);

    // ملء بقية الوحدات بشكل حتمي من هاش البيانات.
    int seed = 0;
    for (final code in data.codeUnits) {
      seed = (seed * 31 + code) & 0x7fffffff;
    }
    int next() {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return seed;
    }

    bool inFinder(int r, int c) {
      final tl = r < 8 && c < 8;
      final tr = r < 8 && c >= _modules - 8;
      final bl = r >= _modules - 8 && c < 8;
      return tl || tr || bl;
    }

    for (var r = 0; r < _modules; r++) {
      for (var c = 0; c < _modules; c++) {
        if (inFinder(r, c)) continue;
        m[r][c] = next() % 100 < 48;
      }
    }
    return m;
  }

  @override
  bool shouldRepaint(covariant _QrPainter old) => old.data != data;
}
