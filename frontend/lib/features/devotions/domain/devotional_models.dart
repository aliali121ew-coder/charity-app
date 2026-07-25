import 'package:flutter/material.dart';

/// نص ديني واحد (دعاء / زيارة / عمل) داخل تصنيف.
class DevotionalItem {
  final String id; // مفتاح ثابت يُستخدم للمفضّلة والحفظ
  final String title;
  final String? occasion; // مناسبة الاستخدام (متى يُقرأ)
  final String body; // النص الكامل أو المختصر
  final bool isExcerpt; // true إذا كان النص مقتطفاً وليس كاملاً

  const DevotionalItem({
    required this.id,
    required this.title,
    this.occasion,
    required this.body,
    this.isExcerpt = false,
  });

  factory DevotionalItem.fromJson(Map<String, dynamic> json) => DevotionalItem(
        id: json['id'] as String,
        title: json['title'] as String,
        occasion: json['occasion'] as String?,
        body: json['body'] as String,
        isExcerpt: json['isExcerpt'] as bool? ?? false,
      );
}

/// تصنيف يجمع مجموعة من النصوص الدينية المتقاربة (مثل "أدعية الصباح").
class DevotionalCategory {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<DevotionalItem> items;

  const DevotionalCategory({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.items,
  });

  factory DevotionalCategory.fromJson(Map<String, dynamic> json) => DevotionalCategory(
        title: json['title'] as String,
        subtitle: json['subtitle'] as String? ?? '',
        icon: devotionalIconByName(json['icon'] as String?),
        items: (json['items'] as List)
            .map((e) => DevotionalItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

/// تجميعة كاملة لقسم ديني (الأدعية / الزيارات / الأعمال) مع هويته البصرية.
class DevotionalSection {
  final String namespace; // مفتاح فريد لتخزين المفضّلة (duas / ziyarat / amal)
  final String title;
  final String tagline;
  final IconData icon;
  final Color color;
  final List<DevotionalCategory> categories;

  const DevotionalSection({
    required this.namespace,
    required this.title,
    required this.tagline,
    required this.icon,
    required this.color,
    required this.categories,
  });

  factory DevotionalSection.fromJson(Map<String, dynamic> json) => DevotionalSection(
        namespace: json['namespace'] as String,
        title: json['title'] as String,
        tagline: json['tagline'] as String? ?? '',
        icon: devotionalIconByName(json['icon'] as String?),
        color: _parseColor(json['color'] as String?),
        categories: (json['categories'] as List)
            .map((e) => DevotionalCategory.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  int get totalItems => categories.fold(0, (sum, c) => sum + c.items.length);
}

/// يحوّل لون hex نصّي (مثل "0xFF7C3AED" أو "#7C3AED") إلى [Color].
Color _parseColor(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFF7C3AED);
  var value = hex.replaceAll('#', '').replaceAll('0x', '');
  if (value.length == 6) value = 'FF$value';
  return Color(int.tryParse(value, radix: 16) ?? 0xFF7C3AED);
}

/// يربط اسم أيقونة نصّي (في ملفات JSON) بأيقونة Material حقيقية.
/// إضافة أيقونة جديدة: أضِف سطراً هنا فقط.
IconData devotionalIconByName(String? name) {
  switch (name) {
    case 'front_hand':
      return Icons.front_hand_rounded;
    case 'mosque':
      return Icons.mosque_rounded;
    case 'auto_awesome':
      return Icons.auto_awesome_rounded;
    case 'wb_sunny':
      return Icons.wb_sunny_rounded;
    case 'nightlight':
      return Icons.nightlight_round;
    case 'auto_stories':
      return Icons.auto_stories_rounded;
    case 'healing':
      return Icons.healing_rounded;
    case 'favorite':
      return Icons.favorite_rounded;
    case 'shield':
      return Icons.shield_rounded;
    case 'groups':
      return Icons.groups_rounded;
    case 'dark_mode':
      return Icons.dark_mode_rounded;
    case 'star':
      return Icons.star_rounded;
    case 'repeat':
      return Icons.repeat_rounded;
    case 'calendar_week':
      return Icons.calendar_view_week_rounded;
    case 'event':
      return Icons.event_rounded;
    case 'menu_book':
      return Icons.menu_book_rounded;
    case 'water_drop':
      return Icons.water_drop_rounded;
    case 'wb_twilight':
      return Icons.wb_twilight_rounded;
    case 'brightness_3':
      return Icons.brightness_3_rounded;
    default:
      return Icons.bookmark_rounded;
  }
}
