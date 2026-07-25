import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// خطوط القراءة المتاحة (كلها خطوط عربية مناسبة للنصوص الدينية).
enum ReadingFont {
  amiriQuran('أميري قرآن', 'amiriQuran'),
  amiri('أميري', 'amiri'),
  scheherazade('شهرزاد', 'scheherazade'),
  lateef('لطيف', 'lateef'),
  notoNaskh('نسخ', 'notoNaskh'),
  cairo('القاهرة', 'cairo'),
  tajawal('تجوال', 'tajawal');

  final String label;
  final String key;
  const ReadingFont(this.label, this.key);

  static ReadingFont fromKey(String? key) =>
      ReadingFont.values.firstWhere((f) => f.key == key, orElse: () => ReadingFont.amiriQuran);

  /// يبني نمط النص بالخط المختار عبر google_fonts.
  TextStyle style({required double fontSize, required double height, required Color color}) {
    switch (this) {
      case ReadingFont.amiriQuran:
        return GoogleFonts.amiriQuran(fontSize: fontSize, height: height, color: color);
      case ReadingFont.amiri:
        return GoogleFonts.amiri(fontSize: fontSize, height: height, color: color);
      case ReadingFont.scheherazade:
        return GoogleFonts.scheherazadeNew(fontSize: fontSize, height: height, color: color);
      case ReadingFont.lateef:
        return GoogleFonts.lateef(fontSize: fontSize, height: height, color: color);
      case ReadingFont.notoNaskh:
        return GoogleFonts.notoNaskhArabic(fontSize: fontSize, height: height, color: color);
      case ReadingFont.cairo:
        return GoogleFonts.cairo(fontSize: fontSize, height: height, color: color);
      case ReadingFont.tajawal:
        return GoogleFonts.tajawal(fontSize: fontSize, height: height, color: color);
    }
  }
}

/// خلفيات شاشة القراءة (لون الورقة + لون النص المناسب لها).
enum ReadingBackground {
  parchment('ورقي', 'parchment', Color(0xFFF6ECD6), Color(0xFF3B2F1C), false),
  white('أبيض', 'white', Color(0xFFFFFFFF), Color(0xFF1A2030), false),
  sepia('بنّي فاتح', 'sepia', Color(0xFFEFE0C9), Color(0xFF4A3826), false),
  green('أخضر المصحف', 'green', Color(0xFFEAF3EC), Color(0xFF173A28), false),
  gray('رمادي', 'gray', Color(0xFFE8EBEF), Color(0xFF22272E), false),
  night('ليلي', 'night', Color(0xFF12100C), Color(0xFFE8DFCB), true),
  black('أسود', 'black', Color(0xFF000000), Color(0xFFD9D2C5), true);

  final String label;
  final String key;
  final Color pageColor;
  final Color textColor;
  final bool isDark;
  const ReadingBackground(this.label, this.key, this.pageColor, this.textColor, this.isDark);

  /// لون ثانوي مشتقّ للنصوص الإرشادية (المناسبة، الحواشي).
  Color get secondaryTextColor => textColor.withValues(alpha: 0.62);

  /// لون حدود البطاقات فوق الخلفية.
  Color get borderColor =>
      isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08);

  static ReadingBackground fromKey(String? key) =>
      ReadingBackground.values.firstWhere((b) => b.key == key, orElse: () => ReadingBackground.white);
}

/// طريقة تصفّح النص: تمرير عمودي أو قلب صفحات كالكتاب.
enum ReadingMode {
  scroll('تمرير', 'scroll'),
  flip('قلب الصفحات', 'flip');

  final String label;
  final String key;
  const ReadingMode(this.label, this.key);

  static ReadingMode fromKey(String? key) =>
      ReadingMode.values.firstWhere((m) => m.key == key, orElse: () => ReadingMode.flip);
}

/// تفضيلات القراءة الموحّدة لكل الأقسام التي بها قراءة (القرآن/الأدعية/الزيارات/الأعمال).
class ReadingPreferences {
  final double fontSize;
  final ReadingFont font;
  final ReadingBackground background;
  final ReadingMode mode;

  const ReadingPreferences({
    this.fontSize = 22,
    this.font = ReadingFont.amiriQuran,
    this.background = ReadingBackground.white,
    this.mode = ReadingMode.flip,
  });

  static const double minFontSize = 16;
  static const double maxFontSize = 40;

  ReadingPreferences copyWith({
    double? fontSize,
    ReadingFont? font,
    ReadingBackground? background,
    ReadingMode? mode,
  }) =>
      ReadingPreferences(
        fontSize: fontSize ?? this.fontSize,
        font: font ?? this.font,
        background: background ?? this.background,
        mode: mode ?? this.mode,
      );

  TextStyle bodyStyle({double height = 2.1, Color? color}) =>
      font.style(fontSize: fontSize, height: height, color: color ?? background.textColor);
}
