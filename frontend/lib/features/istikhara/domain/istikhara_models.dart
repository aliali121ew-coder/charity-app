import 'package:flutter/material.dart';

/// طريقة الاستخارة المختارة.
enum IstikharaMethod {
  quran('استخارة بالقرآن', 'quran'),
  tasbih('استخارة السبحة', 'tasbih');

  final String label;
  final String key;
  const IstikharaMethod(this.label, this.key);

  static IstikharaMethod fromKey(String? k) =>
      IstikharaMethod.values.firstWhere((m) => m.key == k, orElse: () => IstikharaMethod.quran);
}

/// نوع نتيجة الاستخارة وتقييمها الفقهي المبسّط.
enum IstikharaResult {
  veryGood('خيرة جيدة جداً', 'very_good', Color(0xFF10B981), Icons.verified_rounded),
  good('خيرة جيدة', 'good', Color(0xFF06B6D4), Icons.check_circle_rounded),
  mixed('مخيّر', 'mixed', Color(0xFFF59E0B), Icons.compare_arrows_rounded),
  prohibition('نهي — الأولى الترك', 'prohibition', Color(0xFFEF4444), Icons.do_not_disturb_on_rounded);

  final String label;
  final String key;
  final Color color;
  final IconData icon;
  const IstikharaResult(this.label, this.key, this.color, this.icon);

  static IstikharaResult fromKey(String? k) =>
      IstikharaResult.values.firstWhere((r) => r.key == k, orElse: () => IstikharaResult.mixed);
}

/// مدخل في قاعدة بيانات خيرة القرآن: آية مع تقييمها وشرحها.
class QuranIstikharaEntry {
  final String surahName;
  final int verseNumber;
  final IstikharaResult result;
  final String commentary;

  const QuranIstikharaEntry({
    required this.surahName,
    required this.verseNumber,
    required this.result,
    required this.commentary,
  });

  factory QuranIstikharaEntry.fromJson(Map<String, dynamic> json) => QuranIstikharaEntry(
        surahName: json['surah_name'] as String,
        verseNumber: json['verse_number'] as int,
        result: IstikharaResult.fromKey(json['result_type'] as String?),
        commentary: json['commentary'] as String? ?? '',
      );
}

/// سجلّ استخارة محفوظ ليرجع إليه المستخدم لاحقاً.
class IstikharaRecord {
  final String id;
  final String title;
  final IstikharaMethod method;
  final IstikharaResult result;
  final String detail; // مثل: "سورة البقرة • آية ٥" أو "السبحة: ٤٧ خرزة"
  final String commentary;
  final int timestamp; // ميلي ثانية

  const IstikharaRecord({
    required this.id,
    required this.title,
    required this.method,
    required this.result,
    required this.detail,
    required this.commentary,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'method': method.key,
        'result': result.key,
        'detail': detail,
        'commentary': commentary,
        'timestamp': timestamp,
      };

  factory IstikharaRecord.fromJson(Map<String, dynamic> json) => IstikharaRecord(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        method: IstikharaMethod.fromKey(json['method'] as String?),
        result: IstikharaResult.fromKey(json['result'] as String?),
        detail: json['detail'] as String? ?? '',
        commentary: json['commentary'] as String? ?? '',
        timestamp: json['timestamp'] as int? ?? 0,
      );
}
