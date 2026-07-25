enum RequestType {
  generalHelp,
  doctorBooking,
  treatment,
  foodBasket,
  financial,
  householdMaterials;

  String get labelAr {
    switch (this) {
      case RequestType.generalHelp:
        return 'طلب مساعدة عامة';
      case RequestType.doctorBooking:
        return 'حجز طبيب';
      case RequestType.treatment:
        return 'طلب علاج';
      case RequestType.foodBasket:
        return 'طلب سلة غذائية';
      case RequestType.financial:
        return 'طلب مبلغ مالي';
      case RequestType.householdMaterials:
        return 'طلب مواد منزلية';
    }
  }

  String get labelEn {
    switch (this) {
      case RequestType.generalHelp:
        return 'General Help';
      case RequestType.doctorBooking:
        return 'Doctor Booking';
      case RequestType.treatment:
        return 'Treatment Request';
      case RequestType.foodBasket:
        return 'Food Basket';
      case RequestType.financial:
        return 'Financial Request';
      case RequestType.householdMaterials:
        return 'Household Materials';
    }
  }

  String get descriptionAr {
    switch (this) {
      case RequestType.generalHelp:
        return 'تقديم طلب مساعدة عامة لأي احتياج إنساني';
      case RequestType.doctorBooking:
        return 'حجز موعد مع طبيب متخصص';
      case RequestType.treatment:
        return 'طلب علاج أو دواء أو تغطية تكاليف طبية';
      case RequestType.foodBasket:
        return 'طلب سلة غذائية شهرية للأسرة';
      case RequestType.financial:
        return 'طلب دعم مالي لتغطية احتياجات عاجلة';
      case RequestType.householdMaterials:
        return 'طلب مستلزمات وأثاث منزلي أساسي';
    }
  }
}
