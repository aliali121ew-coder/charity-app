import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/help_requests/domain/entities/media_attachment.dart';
import 'package:uuid/uuid.dart';

/// قسم المرفقات في نموذج طلب المساعدة.
///
/// يلتقط صوراً حقيقيّة من الجهاز عبر image_picker ويحتفظ بالبايتات محليّاً في
/// [_pendingBytes] مفهرسةً بمعرّف المرفق. تُمرَّر هذه البايتات للأعلى عبر
/// [onBytesChanged] ليقوم تدفّق الإرسال برفعها إلى Supabase Storage قبل الحفظ.
///
/// كيان [MediaAttachment] غير قابل للتعديل ولا يحمل حقل بايتات — لذلك نضع اسم
/// الملف الفعليّ في [MediaAttachment.name] ونضع قيمة حارسة (sentinel) في
/// [MediaAttachment.mockPath] للصور المُلتقطة حديثاً (`local:<id>`)، ثمّ
/// يُستبدَل بالمسار الحقيقيّ بعد الرفع في تدفّق الإرسال.
class MediaAttachmentSection extends StatefulWidget {
  final List<MediaAttachment> attachments;
  final void Function(List<MediaAttachment>) onChanged;

  /// يُستدعى عند تغيّر البايتات المُلتقطة محليّاً (إضافة/إزالة صورة).
  /// المفتاح هو معرّف المرفق ([MediaAttachment.id]).
  final void Function(Map<String, Uint8List>)? onBytesChanged;

  const MediaAttachmentSection({
    super.key,
    required this.attachments,
    required this.onChanged,
    this.onBytesChanged,
  });

  @override
  State<MediaAttachmentSection> createState() => _MediaAttachmentSectionState();
}

class _MediaAttachmentSectionState extends State<MediaAttachmentSection> {
  static const _uuid = Uuid();

  /// قيمة حارسة توضع في mockPath للصور المُلتقطة قبل الرفع.
  static const _localSentinelPrefix = 'local:';

  /// بايتات الصور المُلتقطة محليّاً، مفهرسة بمعرّف المرفق.
  final Map<String, Uint8List> _pendingBytes = {};

  final ImagePicker _picker = ImagePicker();

  void _emitBytes() {
    widget.onBytesChanged?.call(Map<String, Uint8List>.from(_pendingBytes));
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked == null) return; // ألغى المستخدم الاختيار

      final Uint8List bytes = await picked.readAsBytes();
      final id = _uuid.v4();
      final name = picked.name.trim().isEmpty
          ? 'صورة_${widget.attachments.where((a) => a.isImage).length + 1}.jpg'
          : picked.name.trim();

      _pendingBytes[id] = bytes;

      final updated = [
        ...widget.attachments,
        MediaAttachment(
          id: id,
          type: AttachmentType.image,
          name: name,
          mockPath: '$_localSentinelPrefix$id',
          createdAt: DateTime.now(),
        ),
      ];
      widget.onChanged(updated);
      _emitBytes();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذّر اختيار الصورة: $e', style: GoogleFonts.cairo()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _addMockVoiceNote() {
    final hasVoice = widget.attachments.any((a) => a.isVoiceNote);
    if (hasVoice) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يمكنك إضافة تسجيل صوتي واحد فقط',
              style: GoogleFonts.cairo()),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final updated = [
      ...widget.attachments,
      MediaAttachment(
        id: _uuid.v4(),
        type: AttachmentType.voiceNote,
        name: 'تسجيل_صوتي.m4a',
        durationSeconds: 30 + (widget.attachments.length * 7),
        createdAt: DateTime.now(),
      ),
    ];
    widget.onChanged(updated);
  }

  void _remove(String id) {
    _pendingBytes.remove(id);
    widget.onChanged(widget.attachments.where((a) => a.id != id).toList());
    _emitBytes();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Text(
          'المرفقات',
          style: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'أضف صوراً أو تسجيلاً صوتياً لتوضيح حالتك',
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 12),

        // Add buttons
        Row(
          children: [
            Expanded(
              child: _AddButton(
                icon: Icons.add_photo_alternate_rounded,
                label: 'إضافة صورة',
                gradient: AppColors.gradientBlue,
                onTap: _pickImage,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AddButton(
                icon: Icons.mic_rounded,
                label: 'تسجيل صوتي',
                gradient: AppColors.gradientPurple,
                onTap: _addMockVoiceNote,
              ),
            ),
          ],
        ),

        // Attachment previews
        if (widget.attachments.isNotEmpty) ...[
          const SizedBox(height: 14),
          ...widget.attachments.map((a) => _AttachmentItem(
                attachment: a,
                previewBytes: _pendingBytes[a.id],
                onRemove: () => _remove(a.id),
              )),
        ],
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _AddButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (b) => gradient.createShader(b),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentItem extends StatelessWidget {
  final MediaAttachment attachment;
  final Uint8List? previewBytes;
  final VoidCallback onRemove;

  const _AttachmentItem({
    required this.attachment,
    required this.onRemove,
    this.previewBytes,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isVoice = attachment.isVoiceNote;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: (!isVoice && previewBytes != null)
                ? Image.memory(
                    previewBytes!,
                    width: 38,
                    height: 38,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient:
                          isVoice ? AppColors.gradientPurple : AppColors.gradientBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isVoice ? Icons.mic_rounded : Icons.image_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (isVoice && attachment.durationSeconds != null)
                  Text(
                    'مدة التسجيل: ${attachment.durationFormatted}',
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                if (!isVoice)
                  Text(
                    'صورة مرفقة',
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppColors.error,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
        ],
      ),
    );
  }
}
