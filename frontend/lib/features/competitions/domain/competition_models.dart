import 'package:flutter/material.dart';
import 'package:charity_app/core/theme/app_colors.dart';

// ════════════════════════════════════════════════════════════════════════════
//  فئات المسابقات الخيرية/الإسلامية
// ════════════════════════════════════════════════════════════════════════════
enum CompetitionCategory { quran, worship, charity, volunteer, knowledge, seasonal }

extension CompetitionCategoryX on CompetitionCategory {
  String get label {
    switch (this) {
      case CompetitionCategory.quran:
        return 'قرآن';
      case CompetitionCategory.worship:
        return 'عبادة';
      case CompetitionCategory.charity:
        return 'صدقة وإحسان';
      case CompetitionCategory.volunteer:
        return 'تطوّع';
      case CompetitionCategory.knowledge:
        return 'علم ودعوة';
      case CompetitionCategory.seasonal:
        return 'موسمية';
    }
  }

  IconData get icon {
    switch (this) {
      case CompetitionCategory.quran:
        return Icons.auto_stories_rounded;
      case CompetitionCategory.worship:
        return Icons.mosque_rounded;
      case CompetitionCategory.charity:
        return Icons.favorite_rounded;
      case CompetitionCategory.volunteer:
        return Icons.volunteer_activism_rounded;
      case CompetitionCategory.knowledge:
        return Icons.menu_book_rounded;
      case CompetitionCategory.seasonal:
        return Icons.nightlight_round;
    }
  }

  Color get color {
    switch (this) {
      case CompetitionCategory.quran:
        return const Color(0xFF7C3AED); // بنفسجي
      case CompetitionCategory.worship:
        return const Color(0xFF10B981); // أخضر
      case CompetitionCategory.charity:
        return const Color(0xFFEC4899); // وردي
      case CompetitionCategory.volunteer:
        return const Color(0xFF3B82F6); // أزرق
      case CompetitionCategory.knowledge:
        return const Color(0xFF06B6D4); // سماوي
      case CompetitionCategory.seasonal:
        return const Color(0xFFF59E0B); // ذهبي
    }
  }

  LinearGradient get gradient => LinearGradient(
        colors: [color, color.withValues(alpha: 0.72)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

// ════════════════════════════════════════════════════════════════════════════
//  حالة المسابقة
// ════════════════════════════════════════════════════════════════════════════
enum CompetitionStatus { active, upcoming, ended }

extension CompetitionStatusX on CompetitionStatus {
  String get label {
    switch (this) {
      case CompetitionStatus.active:
        return 'جارية الآن';
      case CompetitionStatus.upcoming:
        return 'قريباً';
      case CompetitionStatus.ended:
        return 'انتهت';
    }
  }

  Color get color {
    switch (this) {
      case CompetitionStatus.active:
        return const Color(0xFF10B981);
      case CompetitionStatus.upcoming:
        return const Color(0xFFF59E0B);
      case CompetitionStatus.ended:
        return const Color(0xFF94A3B8);
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  نوع الجائزة
// ════════════════════════════════════════════════════════════════════════════
enum PrizeType { digital, physical }

extension PrizeTypeX on PrizeType {
  String get label => this == PrizeType.digital ? 'جائزة رقمية' : 'جائزة مادية';
  IconData get icon =>
      this == PrizeType.digital ? Icons.workspace_premium_rounded : Icons.card_giftcard_rounded;
}

// ════════════════════════════════════════════════════════════════════════════
//  دليل المشاركة اليومي (نص أو صورة)
// ════════════════════════════════════════════════════════════════════════════
class ParticipationProof {
  final String id;
  final String? text;
  final String? imagePath;
  final DateTime submittedAt;

  const ParticipationProof({
    required this.id,
    this.text,
    this.imagePath,
    required this.submittedAt,
  });

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;
}

// ════════════════════════════════════════════════════════════════════════════
//  المسابقة
// ════════════════════════════════════════════════════════════════════════════
class Competition {
  final String id;
  final String title;
  final String description;
  final CompetitionCategory category;
  final int participants;
  final int maxParticipants; // 0 = غير محدود
  final int rewardPoints;
  final int target; // الهدف (عدد أيام/مرات لإكمال المسابقة)
  final int winnerCount;
  final DateTime startsAt;
  final DateTime endsAt;
  final List<String> conditions; // الشروط
  final List<String> steps; // خطوات المشاركة
  final PrizeType prizeType;
  final String prizeTitle;
  final String prizeDescription;
  final String? prizeInstructions; // تعليمات الاستلام (للجائزة المادية)
  final String? coverImagePath;
  final String createdBy; // اسم المشرف المنشئ

  const Competition({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.participants = 0,
    this.maxParticipants = 0,
    required this.rewardPoints,
    this.target = 7,
    this.winnerCount = 1,
    required this.startsAt,
    required this.endsAt,
    this.conditions = const [],
    this.steps = const [],
    this.prizeType = PrizeType.digital,
    required this.prizeTitle,
    this.prizeDescription = '',
    this.prizeInstructions,
    this.coverImagePath,
    this.createdBy = 'إدارة التطبيق',
  });

  // مشتقّات الفئة (تُستخدم في الواجهات بدل الحقول المباشرة)
  IconData get icon => category.icon;
  Color get color => category.color;
  LinearGradient get gradient => category.gradient;

  /// الحالة تُحسب تلقائياً من التاريخ/الوقت فقط — لا علاقة لها بعدد المشاركين.
  CompetitionStatus get status => statusFromDates(startsAt, endsAt);

  String get statusLabel => status.label;
  Color get statusColor => status.color;

  bool get isUnlimited => maxParticipants <= 0;
  bool get isFull => !isUnlimited && participants >= maxParticipants;

  /// الأيام المتبقية حتى الانتهاء (سالب إن انتهت).
  int get daysLeft => endsAt.difference(DateTime.now()).inHours ~/ 24;

  /// الحالة المحسوبة من التواريخ (للمسابقات المُنشأة حديثاً).
  static CompetitionStatus statusFromDates(DateTime start, DateTime end) {
    final now = DateTime.now();
    if (now.isBefore(start)) return CompetitionStatus.upcoming;
    if (now.isAfter(end)) return CompetitionStatus.ended;
    return CompetitionStatus.active;
  }

  Competition copyWith({
    String? title,
    String? description,
    CompetitionCategory? category,
    int? participants,
    int? maxParticipants,
    int? rewardPoints,
    int? target,
    int? winnerCount,
    DateTime? startsAt,
    DateTime? endsAt,
    List<String>? conditions,
    List<String>? steps,
    PrizeType? prizeType,
    String? prizeTitle,
    String? prizeDescription,
    String? prizeInstructions,
    String? coverImagePath,
    String? createdBy,
  }) {
    return Competition(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      participants: participants ?? this.participants,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      target: target ?? this.target,
      winnerCount: winnerCount ?? this.winnerCount,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      conditions: conditions ?? this.conditions,
      steps: steps ?? this.steps,
      prizeType: prizeType ?? this.prizeType,
      prizeTitle: prizeTitle ?? this.prizeTitle,
      prizeDescription: prizeDescription ?? this.prizeDescription,
      prizeInstructions: prizeInstructions ?? this.prizeInstructions,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  مشاركة المستخدم في مسابقة (تقدّمه + أدلّته)
// ════════════════════════════════════════════════════════════════════════════
class CompetitionEntry {
  final String competitionId;
  final bool joined;
  final List<ParticipationProof> proofs;
  final int earnedPoints; // نقاط كسبها داخل هذه المسابقة
  final int rank; // ترتيبه الحالي (تقديري)

  const CompetitionEntry({
    required this.competitionId,
    this.joined = false,
    this.proofs = const [],
    this.earnedPoints = 0,
    this.rank = 0,
  });

  int get progress => proofs.length;

  CompetitionEntry copyWith({
    bool? joined,
    List<ParticipationProof>? proofs,
    int? earnedPoints,
    int? rank,
  }) {
    return CompetitionEntry(
      competitionId: competitionId,
      joined: joined ?? this.joined,
      proofs: proofs ?? this.proofs,
      earnedPoints: earnedPoints ?? this.earnedPoints,
      rank: rank ?? this.rank,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  بطاقة المطالبة بالجائزة (تُحفظ في "جوائزي")
// ════════════════════════════════════════════════════════════════════════════
enum ClaimStatus { pending, received, expired }

extension ClaimStatusX on ClaimStatus {
  String get label {
    switch (this) {
      case ClaimStatus.pending:
        return 'بانتظار الاستلام';
      case ClaimStatus.received:
        return 'تم الاستلام';
      case ClaimStatus.expired:
        return 'انتهت المهلة';
    }
  }

  Color get color {
    switch (this) {
      case ClaimStatus.pending:
        return const Color(0xFFF59E0B);
      case ClaimStatus.received:
        return const Color(0xFF10B981);
      case ClaimStatus.expired:
        return const Color(0xFFEF4444);
    }
  }
}

class ClaimCard {
  final String id;
  final String competitionTitle;
  final String winnerName;
  final String prizeTitle;
  final PrizeType prizeType;
  final String claimCode; // الكود الفريد
  final ClaimStatus status;
  final DateTime wonAt;
  final DateTime deadline; // مهلة الاستلام
  final String instructions; // تعليمات الاستلام
  final int pointsCost; // النقاط التي ستُخصم عند تأكيد الاستلام
  final Color color;

  const ClaimCard({
    required this.id,
    required this.competitionTitle,
    required this.winnerName,
    required this.prizeTitle,
    required this.prizeType,
    required this.claimCode,
    this.status = ClaimStatus.pending,
    required this.wonAt,
    required this.deadline,
    this.instructions = '',
    this.pointsCost = 0,
    this.color = AppColors.primary,
  });

  /// محتوى رمز الـ QR.
  String get qrData => 'CHARITY-CLAIM:$claimCode';

  bool get isExpired =>
      status == ClaimStatus.pending && DateTime.now().isAfter(deadline);

  int get daysToClaim => deadline.difference(DateTime.now()).inHours ~/ 24;

  ClaimCard copyWith({ClaimStatus? status}) {
    return ClaimCard(
      id: id,
      competitionTitle: competitionTitle,
      winnerName: winnerName,
      prizeTitle: prizeTitle,
      prizeType: prizeType,
      claimCode: claimCode,
      status: status ?? this.status,
      wonAt: wonAt,
      deadline: deadline,
      instructions: instructions,
      pointsCost: pointsCost,
      color: color,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  مشارك في لوحة الصدارة
// ════════════════════════════════════════════════════════════════════════════
class Participant {
  final String name;
  final int points;
  final int khatmaJuz;
  final int competitions;
  final String area;

  const Participant({
    required this.name,
    required this.points,
    required this.khatmaJuz,
    required this.competitions,
    required this.area,
  });
}

// ════════════════════════════════════════════════════════════════════════════
//  جائزة قابلة للاستبدال بالنقاط (متجر الجوائز)
// ════════════════════════════════════════════════════════════════════════════
class Prize {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final IconData icon;
  final Color color;
  final int stock;
  final PrizeType type;
  final String instructions; // تعليمات الاستلام (للجائزة المادية)

  const Prize({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.icon,
    required this.color,
    required this.stock,
    this.type = PrizeType.physical,
    this.instructions = '',
  });

  bool get inStock => stock > 0;

  Prize copyWith({
    String? title,
    String? description,
    int? pointsCost,
    IconData? icon,
    Color? color,
    int? stock,
    PrizeType? type,
    String? instructions,
  }) {
    return Prize(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      pointsCost: pointsCost ?? this.pointsCost,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      stock: stock ?? this.stock,
      type: type ?? this.type,
      instructions: instructions ?? this.instructions,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  استبدال جائزة من المتجر (سجل استبدالي) — منفصل عن "جوائزي".
//  المادية تُولّد كود + QR وتُخصم النقاط عند تأكيد المشرف.
// ════════════════════════════════════════════════════════════════════════════
class StoreRedemption {
  final String id;
  final String prizeTitle;
  final PrizeType type;
  final int pointsCost;
  final String claimCode;
  final ClaimStatus status;
  final DateTime redeemedAt;
  final DateTime deadline;
  final String instructions;
  final Color color;
  final IconData icon;

  const StoreRedemption({
    required this.id,
    required this.prizeTitle,
    required this.type,
    required this.pointsCost,
    required this.claimCode,
    this.status = ClaimStatus.pending,
    required this.redeemedAt,
    required this.deadline,
    this.instructions = '',
    this.color = AppColors.pink,
    this.icon = Icons.card_giftcard_rounded,
  });

  String get qrData => 'CHARITY-STORE:$claimCode';

  bool get isPhysical => type == PrizeType.physical;

  bool get isExpired =>
      status == ClaimStatus.pending && DateTime.now().isAfter(deadline);

  StoreRedemption copyWith({ClaimStatus? status}) {
    return StoreRedemption(
      id: id,
      prizeTitle: prizeTitle,
      type: type,
      pointsCost: pointsCost,
      claimCode: claimCode,
      status: status ?? this.status,
      redeemedAt: redeemedAt,
      deadline: deadline,
      instructions: instructions,
      color: color,
      icon: icon,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  مركز "الأكثر تفاعلاً" — 5 لوحات صدارة مستقلة، كل واحدة بمعيارها الخاص.
// ════════════════════════════════════════════════════════════════════════════
enum EngagementCategory { social, orgSupport, khatma, familyDonation, delegates }

extension EngagementCategoryX on EngagementCategory {
  String get title {
    switch (this) {
      case EngagementCategory.social:
        return 'تواصل اجتماعي';
      case EngagementCategory.orgSupport:
        return 'تواصل مباشر مع المؤسسة';
      case EngagementCategory.khatma:
        return 'مشاركة الختمة القرآنية';
      case EngagementCategory.familyDonation:
        return 'تبرّع للعوائل المتعفّفة';
      case EngagementCategory.delegates:
        return 'المندوبين الأكثر نشاطاً';
    }
  }

  String get subtitle {
    switch (this) {
      case EngagementCategory.social:
        return 'شارك منشوراتنا وساهم بنشر الخير';
      case EngagementCategory.orgSupport:
        return 'الأكثر دعماً لتطوير المؤسسة';
      case EngagementCategory.khatma:
        return 'الأكثر إنجازاً في الختمة الجماعية';
      case EngagementCategory.familyDonation:
        return 'الأكثر مبادرة بالتبرّع';
      case EngagementCategory.delegates:
        return 'الأكثر التزاماً ومتابعة ميدانية';
    }
  }

  IconData get icon {
    switch (this) {
      case EngagementCategory.social:
        return Icons.share_rounded;
      case EngagementCategory.orgSupport:
        return Icons.handshake_rounded;
      case EngagementCategory.khatma:
        return Icons.menu_book_rounded;
      case EngagementCategory.familyDonation:
        return Icons.volunteer_activism_rounded;
      case EngagementCategory.delegates:
        return Icons.badge_rounded;
    }
  }

  Color get color {
    switch (this) {
      case EngagementCategory.social:
        return const Color(0xFF3B82F6);
      case EngagementCategory.orgSupport:
        return const Color(0xFF7C3AED);
      case EngagementCategory.khatma:
        return const Color(0xFF10B981);
      case EngagementCategory.familyDonation:
        return const Color(0xFFEC4899);
      case EngagementCategory.delegates:
        return const Color(0xFFF59E0B);
    }
  }

  LinearGradient get gradient => LinearGradient(
        colors: [color, color.withValues(alpha: 0.72)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// وحدة القياس المعروضة بجانب رقم الترتيب.
  String get unit {
    switch (this) {
      case EngagementCategory.social:
        return 'نقطة';
      case EngagementCategory.orgSupport:
        return 'د.ع';
      case EngagementCategory.khatma:
        return 'جزء';
      case EngagementCategory.familyDonation:
        return 'مرة تبرّع';
      case EngagementCategory.delegates:
        return 'نشاط';
    }
  }

  /// هل تُعرض بطاقة "موقعي الحالي" أسفل القائمة؟
  /// المندوبون قائمة إدارية معلوماتية، لا يشارك فيها المستخدم كفرد.
  bool get showsMyPosition => this != EngagementCategory.delegates;
}

/// مُشارك عام داخل أيّ من لوحات الصدارة الخمس (نموذج موحّد لتبسيط العرض).
class EngagementEntry {
  final String name;
  final num value;
  final String subtitle;

  const EngagementEntry({
    required this.name,
    required this.value,
    this.subtitle = '',
  });
}

/// نشاط مندوب — نموذج تمثيلي مستقل خاص بقسم "المندوبين الأكثر نشاطاً"
/// (لا يرتبط ببيانات صفحة العوائل الفعلية).
class DelegateActivity {
  final String name;
  final String area;
  final int subscriberCount;
  final int onTimeRate; // نسبة الالتزام بالتسديد بالموعد (%)
  final int newSubscribers; // مشتركون جدد هذا الشهر

  const DelegateActivity({
    required this.name,
    required this.area,
    required this.subscriberCount,
    required this.onTimeRate,
    required this.newSubscribers,
  });

  /// نقاط نشاط مُحتسبة: وزن أكبر للالتزام بالتسديد ثم عدد المشتركين ثم الجدد.
  int get activityScore => (onTimeRate * 3) + (subscriberCount * 4) + (newSubscribers * 10);

  EngagementEntry toEntry() => EngagementEntry(
        name: name,
        value: activityScore,
        subtitle: '$area • $subscriberCount مشترك • $onTimeRate% التزام • $newSubscribers جديد',
      );
}

// ════════════════════════════════════════════════════════════════════════════
//  طلب مشاركة اجتماعية (فيسبوك) — يحتاج اعتماد الأدمن مع تحديد النقاط.
// ════════════════════════════════════════════════════════════════════════════
enum ShareRequestStatus { pending, approved }

class SocialShareRequest {
  final String id;
  final DateTime submittedAt;
  final ShareRequestStatus status;
  final int awardedPoints;

  const SocialShareRequest({
    required this.id,
    required this.submittedAt,
    this.status = ShareRequestStatus.pending,
    this.awardedPoints = 0,
  });

  SocialShareRequest copyWith({ShareRequestStatus? status, int? awardedPoints}) {
    return SocialShareRequest(
      id: id,
      submittedAt: submittedAt,
      status: status ?? this.status,
      awardedPoints: awardedPoints ?? this.awardedPoints,
    );
  }
}
