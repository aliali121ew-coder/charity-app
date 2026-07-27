import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:charity_app/core/supabase/supabase_config.dart';

/// خدمة رفع/جلب ملفات Supabase Storage.
///
/// تُغلّف عمليات الرفع (uploadBinary)، والحصول على رابط عام (getPublicUrl)،
/// ورابط موقّع مؤقّت (createSignedUrl) للـ buckets الخاصّة.
///
/// ملاحظة حول الصلاحيات (RLS على storage.objects):
///  - الـ buckets الخاصّة (help-media / proof-media): الرفع مسموح فقط داخل مجلّد
///    اسمه = معرّف المستخدم (uid). لذا نبني المسار بادئاً بـ `uid/`.
///  - work-media: الرفع مسموح للموظّفين فقط (is_staff())، وليس مقيّداً بمجلّد
///    المستخدم — لذلك path يبدأ بـ `works/`.
///  - جميع العمليات المصادَق عليها تتطلّب جلسة Supabase Auth فعليّة
///    (supabase.auth.currentUser != null). التطبيق حالياً يستخدم مصادقة وهميّة،
///    لذا يجب على مواقع الاستدعاء التقاط StateError والتعامل معه بلطف.
class SupabaseStorageService {
  const SupabaseStorageService();

  /// يُنظّف اسم الملف من المحارف غير الآمنة في مسارات التخزين.
  String _sanitize(String filename) {
    final trimmed = filename.trim().isEmpty ? 'file' : filename.trim();
    // نستبدل أي محرف ليس حرفاً/رقماً لاتينياً أو نقطة أو شرطة/شرطة سفليّة بشرطة سفليّة.
    return trimmed.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  /// يرفع بايتات إلى [bucket] ويعيد المسار المُخزَّن داخل الـ bucket.
  ///
  /// - عند [userScoped] == true يُبنى المسار بادئاً بمعرّف المستخدم:
  ///   `<uid>/<timestamp>_<sanitizedName>` (شرط RLS للـ buckets الخاصّة).
  /// - عند false يُبنى `<timestamp>_<sanitizedName>` (يستخدمه موقع الاستدعاء
  ///   لإضافة بادئة مجلّد خاصّة به مثل `works/`).
  /// - يرمي [StateError] برسالة عربيّة إذا كان [userScoped] ولا يوجد مستخدم
  ///   مسجّل الدخول.
  Future<String> uploadBytes({
    required String bucket,
    required Uint8List bytes,
    required String filename,
    String contentType = 'image/jpeg',
    bool userScoped = true,
  }) async {
    final safeName = _sanitize(filename);
    final ts = DateTime.now().millisecondsSinceEpoch;

    String path;
    if (userScoped) {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) {
        throw StateError('يجب تسجيل الدخول لرفع الملفات');
      }
      path = '$uid/${ts}_$safeName';
    } else {
      path = '${ts}_$safeName';
    }

    final storedPath = await supabase.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: contentType),
        );
    return storedPath;
  }

  /// رابط عام (dead-simple) لملف في bucket عام.
  String publicUrl(String bucket, String path) =>
      supabase.storage.from(bucket).getPublicUrl(path);

  /// رابط موقّع مؤقّت لملف في bucket خاصّ (افتراضياً صالح ساعة).
  Future<String> signedUrl(
    String bucket,
    String path, {
    int expiresSec = 3600,
  }) =>
      supabase.storage.from(bucket).createSignedUrl(path, expiresSec);

  // ── اختصارات ملائمة ─────────────────────────────────────────────────────────

  /// رفع صورة مرفقة بطلب مساعدة إلى bucket خاصّ داخل مجلّد المستخدم.
  Future<String> uploadHelpImage(Uint8List bytes, String filename) =>
      uploadBytes(
        bucket: 'help-media',
        bytes: bytes,
        filename: filename,
        contentType: 'image/jpeg',
        userScoped: true,
      );

  /// رفع صورة دليل مشاركة إلى bucket خاصّ داخل مجلّد المستخدم.
  Future<String> uploadProofImage(Uint8List bytes, String filename) =>
      uploadBytes(
        bucket: 'proof-media',
        bytes: bytes,
        filename: filename,
        contentType: 'image/jpeg',
        userScoped: true,
      );

  /// رفع صورة منشور عمل إلى bucket عام (للموظّفين فقط بحسب RLS).
  /// ليس مقيّداً بمجلّد المستخدم؛ المسار يبدأ بـ `works/`.
  Future<String> uploadWorkImage(Uint8List bytes, String filename) {
    final safeName = _sanitize(filename);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = 'works/${ts}_$safeName';
    return supabase.storage.from('work-media').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
  }
}
