enum UrgencyLevel {
  low,
  medium,
  high,
  critical;

  String get labelAr {
    switch (this) {
      case UrgencyLevel.low:
        return 'منخفضة';
      case UrgencyLevel.medium:
        return 'متوسطة';
      case UrgencyLevel.high:
        return 'عالية';
      case UrgencyLevel.critical:
        return 'حرجة / عاجلة';
    }
  }

  String get labelEn {
    switch (this) {
      case UrgencyLevel.low:
        return 'Low';
      case UrgencyLevel.medium:
        return 'Medium';
      case UrgencyLevel.high:
        return 'High';
      case UrgencyLevel.critical:
        return 'Critical';
    }
  }
}
