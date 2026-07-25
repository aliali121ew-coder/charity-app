import 'package:equatable/equatable.dart';

enum AttachmentType { image, voiceNote }

class MediaAttachment extends Equatable {
  final String id;
  final AttachmentType type;
  final String name;
  final String? mockPath;
  final int? durationSeconds;
  final DateTime createdAt;

  const MediaAttachment({
    required this.id,
    required this.type,
    required this.name,
    this.mockPath,
    this.durationSeconds,
    required this.createdAt,
  });

  bool get isImage => type == AttachmentType.image;
  bool get isVoiceNote => type == AttachmentType.voiceNote;

  String get durationFormatted {
    if (durationSeconds == null) return '';
    final m = durationSeconds! ~/ 60;
    final s = durationSeconds! % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [id, type, name];
}
