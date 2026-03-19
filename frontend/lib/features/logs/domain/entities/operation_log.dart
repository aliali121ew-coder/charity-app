import 'package:equatable/equatable.dart';

enum LogActionType {
  add,
  edit,
  delete,
  approve,
  reject,
  distribute,
  createReport,
  changeSettings,
  login,
  transfer,
  other,
}

class OperationLog extends Equatable {
  final String id;
  final String actionTitle;
  final String actionTitleAr;
  final String description;
  final String descriptionAr;
  final String performedBy;
  final String performedByInitials;
  final DateTime timestamp;
  final String? referenceNumber;
  final LogActionType actionType;
  final String? relatedEntity;
  final String? relatedEntityId;

  const OperationLog({
    required this.id,
    required this.actionTitle,
    required this.actionTitleAr,
    required this.description,
    required this.descriptionAr,
    required this.performedBy,
    required this.performedByInitials,
    required this.timestamp,
    this.referenceNumber,
    required this.actionType,
    this.relatedEntity,
    this.relatedEntityId,
  });

  @override
  List<Object?> get props => [id, actionType, timestamp];
}
