import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:charity_app/features/devotions/domain/devotional_models.dart';

/// يحمّل قسماً دينياً كاملاً من ملف JSON المدمج في الأصول.
/// المفتاح هو مساحة الاسم (duas / ziyarat / amal)، والملف في:
/// assets/data/devotions/<namespace>.json
final devotionalSectionProvider =
    FutureProvider.family<DevotionalSection, String>((ref, namespace) async {
  final raw = await rootBundle.loadString('assets/data/devotions/$namespace.json');
  final map = jsonDecode(raw) as Map<String, dynamic>;
  return DevotionalSection.fromJson(map);
});
