import 'package:equatable/equatable.dart';
import 'request_type.dart';
import 'request_status.dart';
import 'urgency_level.dart';
import 'location_info.dart';
import 'media_attachment.dart';

class HelpRequest extends Equatable {
  final String id;
  final RequestType type;
  final RequestStatus status;
  final DateTime submittedAt;

  // Owner
  final String? submittedByUserId;

  // Personal info
  final String fullName;
  final String phone;
  final String governorate;
  final String area;
  final String fullAddress;

  // Request info
  final String title;
  final String description;
  final UrgencyLevel urgency;
  final int? familySize;
  final String? notes;

  // Location
  final LocationInfo location;

  // Media
  final List<MediaAttachment> attachments;

  // Type-specific fields stored as flat map
  final Map<String, String> typeData;

  const HelpRequest({
    required this.id,
    required this.type,
    required this.status,
    required this.submittedAt,
    this.submittedByUserId,
    required this.fullName,
    required this.phone,
    required this.governorate,
    required this.area,
    required this.fullAddress,
    required this.title,
    required this.description,
    required this.urgency,
    this.familySize,
    this.notes,
    required this.location,
    required this.attachments,
    required this.typeData,
  });

  static const editWindowMinutes = 10;

  bool get isEditable {
    return DateTime.now().difference(submittedAt).inMinutes < editWindowMinutes;
  }

  Duration get editTimeRemaining {
    final elapsed = DateTime.now().difference(submittedAt);
    const window = Duration(minutes: editWindowMinutes);
    if (elapsed >= window) return Duration.zero;
    return window - elapsed;
  }

  int get editSecondsRemaining => editTimeRemaining.inSeconds;

  HelpRequest copyWith({
    RequestStatus? status,
    String? submittedByUserId,
    String? fullName,
    String? phone,
    String? governorate,
    String? area,
    String? fullAddress,
    String? title,
    String? description,
    UrgencyLevel? urgency,
    int? familySize,
    String? notes,
    LocationInfo? location,
    List<MediaAttachment>? attachments,
    Map<String, String>? typeData,
  }) {
    return HelpRequest(
      id: id,
      type: type,
      status: status ?? this.status,
      submittedAt: submittedAt,
      submittedByUserId: submittedByUserId ?? this.submittedByUserId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      governorate: governorate ?? this.governorate,
      area: area ?? this.area,
      fullAddress: fullAddress ?? this.fullAddress,
      title: title ?? this.title,
      description: description ?? this.description,
      urgency: urgency ?? this.urgency,
      familySize: familySize ?? this.familySize,
      notes: notes ?? this.notes,
      location: location ?? this.location,
      attachments: attachments ?? this.attachments,
      typeData: typeData ?? this.typeData,
    );
  }

  @override
  List<Object?> get props => [id, type, status, submittedAt, title];
}
