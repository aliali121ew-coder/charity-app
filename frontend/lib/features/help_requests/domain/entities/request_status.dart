enum RequestStatus {
  pending,
  underReview,
  approved,
  rejected,
  completed;

  String get labelAr {
    switch (this) {
      case RequestStatus.pending:
        return 'قيد الانتظار';
      case RequestStatus.underReview:
        return 'قيد المراجعة';
      case RequestStatus.approved:
        return 'تمت الموافقة';
      case RequestStatus.rejected:
        return 'مرفوض';
      case RequestStatus.completed:
        return 'مكتمل';
    }
  }

  String get labelEn {
    switch (this) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.underReview:
        return 'Under Review';
      case RequestStatus.approved:
        return 'Approved';
      case RequestStatus.rejected:
        return 'Rejected';
      case RequestStatus.completed:
        return 'Completed';
    }
  }
}
