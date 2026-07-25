import 'package:flutter/material.dart';
import 'package:charity_app/features/competitions/domain/competition_models.dart';

/// لوحة الصدارة — الأكثر تفاعلاً هذا الأسبوع (مرتّبة تنازلياً بالنقاط).
const List<Participant> mockLeaderboard = [
  Participant(name: 'أحمد محمد الكريمي', points: 2840, khatmaJuz: 6, competitions: 4, area: 'الكرخ'),
  Participant(name: 'سارة علي الموسوي', points: 2610, khatmaJuz: 5, competitions: 3, area: 'الرصافة'),
  Participant(name: 'حسين رضا الجبوري', points: 2375, khatmaJuz: 4, competitions: 5, area: 'الأعظمية'),
  Participant(name: 'نور محمد الهاشمي', points: 1980, khatmaJuz: 3, competitions: 2, area: 'الكاظمية'),
  Participant(name: 'زينب قاسم العبيدي', points: 1755, khatmaJuz: 4, competitions: 2, area: 'الدورة'),
  Participant(name: 'علي حسن الزبيدي', points: 1490, khatmaJuz: 2, competitions: 3, area: 'الشعب'),
  Participant(name: 'فاطمة عبد الله', points: 1320, khatmaJuz: 3, competitions: 1, area: 'الغزالية'),
  Participant(name: 'محمد كاظم الساعدي', points: 1185, khatmaJuz: 2, competitions: 2, area: 'البياع'),
  Participant(name: 'رقية جواد', points: 970, khatmaJuz: 1, competitions: 2, area: 'زيونة'),
  Participant(name: 'عباس وليد', points: 845, khatmaJuz: 1, competitions: 1, area: 'الجادرية'),
];

/// تواصل اجتماعي — الأكثر مشاركة لمنشورات المؤسسة على فيسبوك (نقاط يمنحها الأدمن).
const List<EngagementEntry> mockSocialLeaderboard = [
  EngagementEntry(name: 'أحمد محمد الكريمي', value: 480, subtitle: 'الكرخ • 24 مشاركة'),
  EngagementEntry(name: 'سارة علي الموسوي', value: 410, subtitle: 'الرصافة • 21 مشاركة'),
  EngagementEntry(name: 'حسين رضا الجبوري', value: 355, subtitle: 'الأعظمية • 18 مشاركة'),
  EngagementEntry(name: 'نور محمد الهاشمي', value: 290, subtitle: 'الكاظمية • 15 مشاركة'),
  EngagementEntry(name: 'زينب قاسم العبيدي', value: 260, subtitle: 'الدورة • 13 مشاركة'),
  EngagementEntry(name: 'علي حسن الزبيدي', value: 205, subtitle: 'الشعب • 10 مشاركات'),
  EngagementEntry(name: 'فاطمة عبد الله', value: 170, subtitle: 'الغزالية • 9 مشاركات'),
];

/// تواصل مباشر مع المؤسسة — الأكثر دعماً لتطوير الجمعية (إجمالي المبلغ بالدينار).
const List<EngagementEntry> mockOrgSupportLeaderboard = [
  EngagementEntry(name: 'محمد كاظم الساعدي', value: 750000, subtitle: 'البياع • داعم دائم'),
  EngagementEntry(name: 'رقية جواد', value: 620000, subtitle: 'زيونة • داعم دائم'),
  EngagementEntry(name: 'عباس وليد', value: 500000, subtitle: 'الجادرية'),
  EngagementEntry(name: 'أحمد محمد الكريمي', value: 400000, subtitle: 'الكرخ'),
  EngagementEntry(name: 'سارة علي الموسوي', value: 300000, subtitle: 'الرصافة'),
  EngagementEntry(name: 'حسين رضا الجبوري', value: 250000, subtitle: 'الأعظمية'),
];

/// تبرّع للعوائل المتعفّفة — مرتّبة حسب عدد مرّات التبرّع (بغضّ النظر عن المبلغ).
const List<EngagementEntry> mockFamilyDonationLeaderboard = [
  EngagementEntry(name: 'زينب قاسم العبيدي', value: 34, subtitle: 'الدورة • تبرّع متكرر'),
  EngagementEntry(name: 'علي حسن الزبيدي', value: 29, subtitle: 'الشعب • تبرّع متكرر'),
  EngagementEntry(name: 'فاطمة عبد الله', value: 25, subtitle: 'الغزالية'),
  EngagementEntry(name: 'محمد كاظم الساعدي', value: 21, subtitle: 'البياع'),
  EngagementEntry(name: 'رقية جواد', value: 18, subtitle: 'زيونة'),
  EngagementEntry(name: 'عباس وليد', value: 14, subtitle: 'الجادرية'),
  EngagementEntry(name: 'نور محمد الهاشمي', value: 11, subtitle: 'الكاظمية'),
];

/// المندوبين الأكثر نشاطاً — النشاط = عدد المشتركين + الالتزام بالتسديد + مشتركون جدد.
/// (بيانات تمثيلية مستقلة خاصة بهذا القسم، لا ترتبط ببيانات صفحة العوائل)
const List<DelegateActivity> mockDelegatesActivity = [
  DelegateActivity(name: 'أحمد محمد الكريمي', area: 'الكرخ', subscriberCount: 42, onTimeRate: 96, newSubscribers: 6),
  DelegateActivity(name: 'سارة علي الموسوي', area: 'الرصافة', subscriberCount: 38, onTimeRate: 94, newSubscribers: 5),
  DelegateActivity(name: 'حسين رضا الجبوري', area: 'الأعظمية', subscriberCount: 45, onTimeRate: 88, newSubscribers: 4),
  DelegateActivity(name: 'نور محمد الهاشمي', area: 'الكاظمية', subscriberCount: 30, onTimeRate: 92, newSubscribers: 7),
  DelegateActivity(name: 'علاء الدين فارس', area: 'الدورة', subscriberCount: 33, onTimeRate: 90, newSubscribers: 3),
  DelegateActivity(name: 'ريم سعد العلي', area: 'الشعب', subscriberCount: 27, onTimeRate: 85, newSubscribers: 2),
];

/// تحويل لوحة الختمة الحالية (مرتبة أصلاً بالنقاط) إلى ترتيب حسب أجزاء الختمة فقط.
List<EngagementEntry> khatmaEngagementEntries() {
  final sorted = [...mockLeaderboard]..sort((a, b) => b.khatmaJuz.compareTo(a.khatmaJuz));
  return sorted
      .map((p) => EngagementEntry(
            name: p.name,
            value: p.khatmaJuz,
            subtitle: '${p.area} • ${p.competitions} مسابقات',
          ))
      .toList();
}

/// الجوائز الأولية في متجر الجوائز (تُحمّل في الـ provider ويديرها المشرف).
List<Prize> seedStorePrizes() => const [
      Prize(id: 'p_basket', title: 'سلة غذائية كاملة', description: 'سلة مواد غذائية لعائلة', pointsCost: 1500, icon: Icons.shopping_basket_rounded, color: Color(0xFF10B981), stock: 12, type: PrizeType.physical, instructions: 'استلم السلة من مقر الجمعية مع إبراز كود الاستلام.'),
      Prize(id: 'p_mushaf', title: 'مصحف مخمل فاخر', description: 'مصحف بغلاف مخمل وخط واضح', pointsCost: 800, icon: Icons.menu_book_rounded, color: Color(0xFF7C3AED), stock: 25, type: PrizeType.physical, instructions: 'يُستلم من المقر أو يُشحن لعنوانك.'),
      Prize(id: 'p_cert', title: 'بطاقة شكر وتقدير', description: 'شهادة تقدير رسمية من المؤسسة', pointsCost: 300, icon: Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), stock: 99, type: PrizeType.digital),
      Prize(id: 'p_rug', title: 'سجادة صلاة فاخرة', description: 'سجادة صلاة عالية الجودة', pointsCost: 600, icon: Icons.mosque_rounded, color: Color(0xFF06B6D4), stock: 8, type: PrizeType.physical, instructions: 'تُستلم من المقر مع كود الاستلام.'),
      Prize(id: 'p_coupon', title: 'كوبون تبرّع باسمك', description: 'تبرّع رمزي يُسجّل باسمك', pointsCost: 2000, icon: Icons.volunteer_activism_rounded, color: Color(0xFFEC4899), stock: 5, type: PrizeType.digital),
      Prize(id: 'p_bag', title: 'حقيبة مدرسية', description: 'حقيبة مع قرطاسية لطالب', pointsCost: 1000, icon: Icons.backpack_rounded, color: Color(0xFF3B82F6), stock: 0, type: PrizeType.physical, instructions: 'تُستلم من المقر.'),
    ];

/// المسابقات الأولية (تُحمّل في الـ provider ويمكن للمشرف إضافة المزيد).
List<Competition> seedCompetitions() {
  final now = DateTime.now();
  return [
    Competition(
      id: 'c_quran_kahf',
      title: 'تحدي حفظ سورة الكهف',
      description: 'احفظ سورة الكهف خلال أسبوع واكسب نقاطاً مضاعفة',
      category: CompetitionCategory.quran,
      participants: 128,
      maxParticipants: 300,
      rewardPoints: 500,
      target: 7,
      winnerCount: 3,
      startsAt: now.subtract(const Duration(days: 3)),
      endsAt: now.add(const Duration(days: 4)),
      conditions: const [
        'أن تكون مشتركاً في التطبيق',
        'حفظ السورة كاملة بالتجويد',
        'تسجيل التقدّم يومياً خلال المسابقة',
      ],
      steps: const [
        'اضغط "اشترك الآن"',
        'احفظ المقدار اليومي المطلوب',
        'ارفع دليلاً يومياً (تسجيل أو صورة)',
        'أكمل الحفظ قبل انتهاء المهلة',
      ],
      prizeType: PrizeType.physical,
      prizeTitle: 'مصحف مخمل فاخر + شهادة حفظ',
      prizeDescription: 'مصحف بغلاف مخمل وخط واضح مع شهادة تقدير رسمية',
      prizeInstructions: 'استلم جائزتك من مقر الجمعية خلال أوقات الدوام مع إبراز كود المطالبة.',
      createdBy: 'إدارة التطبيق',
    ),
    Competition(
      id: 'c_charity_marathon',
      title: 'ماراثون الصدقة اليومية',
      description: 'تبرّع كل يوم ولو بالقليل طوال الشهر',
      category: CompetitionCategory.charity,
      participants: 256,
      maxParticipants: 1000,
      rewardPoints: 750,
      target: 30,
      winnerCount: 5,
      startsAt: now.subtract(const Duration(days: 6)),
      endsAt: now.add(const Duration(days: 12)),
      conditions: const [
        'تبرّع يومي ولو بمبلغ رمزي',
        'عدم انقطاع أكثر من يومين متتاليين',
      ],
      steps: const [
        'اشترك في المسابقة',
        'تبرّع يومياً عبر قسم التبرّعات',
        'سجّل دليل تبرّعك اليومي',
      ],
      prizeType: PrizeType.digital,
      prizeTitle: 'وسام المتصدّق + نقاط مضاعفة',
      prizeDescription: 'شارة رقمية حصرية ومضاعفة نقاطك للشهر التالي',
      createdBy: 'إدارة التطبيق',
    ),
    Competition(
      id: 'c_quran_calligraphy',
      title: 'مسابقة أجمل خط قرآني',
      description: 'شارك بأجمل خط لآية قرآنية واربح',
      category: CompetitionCategory.knowledge,
      participants: 0,
      maxParticipants: 200,
      rewardPoints: 1000,
      target: 1,
      winnerCount: 3,
      startsAt: now.add(const Duration(days: 3)),
      endsAt: now.add(const Duration(days: 20)),
      conditions: const [
        'أن يكون الخط من عملك الشخصي',
        'وضوح الصورة المرفوعة',
      ],
      steps: const [
        'اشترك عند بدء المسابقة',
        'اكتب آية بخط جميل',
        'ارفع صورة عملك',
      ],
      prizeType: PrizeType.physical,
      prizeTitle: 'مجموعة أدوات خط عربي',
      prizeDescription: 'أقلام وأدوات خط احترافية للفائزين الثلاثة الأوائل',
      prizeInstructions: 'تُشحن الجائزة إلى عنوانك بعد التأكيد.',
      createdBy: 'إدارة التطبيق',
    ),
    Competition(
      id: 'c_worship_fajr',
      title: 'تحدي المحافظة على صلاة الفجر',
      description: 'حافظ على صلاة الفجر في جماعة لمدة أسبوعين',
      category: CompetitionCategory.worship,
      participants: 89,
      maxParticipants: 0,
      rewardPoints: 600,
      target: 14,
      winnerCount: 10,
      startsAt: now.subtract(const Duration(days: 2)),
      endsAt: now.add(const Duration(days: 12)),
      conditions: const ['تسجيل صلاة الفجر يومياً'],
      steps: const ['اشترك', 'سجّل صلاتك يومياً برفع دليل'],
      prizeType: PrizeType.digital,
      prizeTitle: 'وسام المحافظ على الفجر',
      prizeDescription: 'شارة رقمية + 600 نقطة',
      createdBy: 'إدارة التطبيق',
    ),
    Competition(
      id: 'c_seasonal_ramadan',
      title: 'تحدي ختمة رمضان',
      description: 'أتمم ختمة كاملة خلال الشهر الفضيل',
      category: CompetitionCategory.seasonal,
      participants: 412,
      maxParticipants: 500,
      rewardPoints: 1200,
      target: 30,
      winnerCount: 3,
      startsAt: now.subtract(const Duration(days: 40)),
      endsAt: now.subtract(const Duration(days: 8)),
      conditions: const ['إتمام ختمة كاملة خلال الشهر'],
      steps: const ['اشترك', 'اقرأ وردك اليومي', 'سجّل تقدّمك'],
      prizeType: PrizeType.physical,
      prizeTitle: 'عمرة أو هدية قيّمة',
      prizeDescription: 'جائزة كبرى للفائزين الثلاثة الأوائل',
      prizeInstructions: 'تواصل مع إدارة الجمعية لترتيب استلام الجائزة الكبرى.',
      createdBy: 'إدارة التطبيق',
    ),
  ];
}
