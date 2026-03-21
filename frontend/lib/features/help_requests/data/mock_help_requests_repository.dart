import 'package:charity_app/features/help_requests/domain/entities/help_request.dart';
import 'package:charity_app/features/help_requests/domain/entities/location_info.dart';
import 'package:charity_app/features/help_requests/domain/entities/media_attachment.dart';
import 'package:charity_app/features/help_requests/domain/entities/request_status.dart';
import 'package:charity_app/features/help_requests/domain/entities/request_type.dart';
import 'package:charity_app/features/help_requests/domain/entities/urgency_level.dart';
import 'package:charity_app/features/help_requests/domain/repositories/help_requests_repository.dart';

class MockHelpRequestsRepository implements HelpRequestsRepository {
  final List<HelpRequest> _requests = [
    HelpRequest(
      id: 'req_001',
      type: RequestType.foodBasket,
      status: RequestStatus.approved,
      submittedAt: DateTime.now().subtract(const Duration(hours: 3)),
      submittedByUserId: 'user_002',
      fullName: 'أم حسن الكريمي',
      phone: '07901234567',
      governorate: 'بغداد',
      area: 'الكرخ',
      fullAddress: 'شارع الكفاح، محلة 315، بيت رقم 7',
      title: 'سلة غذائية لأسرة من 6 أفراد',
      description: 'أسرة مكونة من 6 أفراد بحاجة ماسة لسلة غذائية شهرية',
      urgency: UrgencyLevel.high,
      familySize: 6,
      notes: 'يوجد طفل رضيع بحاجة لحليب أطفال',
      location: const LocationInfo(
        latitude: 33.3152,
        longitude: 44.3661,
        address: 'شارع الكفاح، محلة 315',
        governorate: 'بغداد',
        area: 'الكرخ',
      ),
      attachments: [
        MediaAttachment(
          id: 'att_001',
          type: AttachmentType.image,
          name: 'صورة الهوية',
          mockPath: 'mock/images/id_card.jpg',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ],
      typeData: const {
        'essentialNeeds': 'أرز، طحين، زيت، سكر، حليب أطفال',
        'monthlyIncome': '0',
        'dietaryNotes': 'طفل رضيع يحتاج حليب خاص',
      },
    ),
    HelpRequest(
      id: 'req_002',
      type: RequestType.doctorBooking,
      status: RequestStatus.underReview,
      submittedAt: DateTime.now().subtract(const Duration(days: 1)),
      submittedByUserId: 'user_003',
      fullName: 'محمد عبد الله السامرائي',
      phone: '07812345678',
      governorate: 'بغداد',
      area: 'الرصافة',
      fullAddress: 'حي الجهاد، شارع 14، رقم 22',
      title: 'حجز طبيب قلب',
      description: 'أعاني من آلام في الصدر وضيق في التنفس منذ أسبوعين',
      urgency: UrgencyLevel.critical,
      familySize: 4,
      notes: null,
      location: const LocationInfo(
        latitude: 33.3406,
        longitude: 44.4009,
        address: 'حي الجهاد، شارع 14',
        governorate: 'بغداد',
        area: 'الرصافة',
      ),
      attachments: [
        MediaAttachment(
          id: 'att_002',
          type: AttachmentType.voiceNote,
          name: 'تسجيل صوتي للأعراض',
          durationSeconds: 45,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
      typeData: const {
        'specialty': 'أمراض القلب',
        'preferredDate': '2026-03-20',
        'preferredTime': '10:00 صباحاً',
        'symptoms': 'ألم في الصدر، ضيق تنفس، تعب شديد',
        'previousDiagnosis': 'ضغط دم مرتفع منذ 3 سنوات',
      },
    ),
    HelpRequest(
      id: 'req_003',
      type: RequestType.financial,
      status: RequestStatus.pending,
      submittedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      submittedByUserId: 'user_001',
      fullName: 'فاطمة علي الحسيني',
      phone: '07723456789',
      governorate: 'كربلاء',
      area: 'المركز',
      fullAddress: 'شارع الإمام علي، بناية الأمل، شقة 3',
      title: 'دعم مالي لسداد إيجار متأخر',
      description: 'بحاجة لمساعدة مالية لسداد إيجار متأخر شهرين',
      urgency: UrgencyLevel.high,
      familySize: 3,
      notes: 'زوجي مريض وغير قادر على العمل',
      location: const LocationInfo(
        latitude: 32.6150,
        longitude: 44.0142,
        address: 'شارع الإمام علي، بناية الأمل',
        governorate: 'كربلاء',
        area: 'المركز',
      ),
      attachments: const [],
      typeData: const {
        'requestedAmount': '150000',
        'reasonForRequest': 'إيجار متأخر وتكاليف معيشية',
        'monthlyIncome': '0',
        'currentSupport': 'لا يوجد أي دخل حالياً',
      },
    ),
    HelpRequest(
      id: 'req_004',
      type: RequestType.treatment,
      status: RequestStatus.completed,
      submittedAt: DateTime.now().subtract(const Duration(days: 5)),
      submittedByUserId: 'user_001',
      fullName: 'عمر جاسم العبيدي',
      phone: '07634567890',
      governorate: 'البصرة',
      area: 'العشار',
      fullAddress: 'شارع النضال، قرب مستشفى الصداقة',
      title: 'تغطية تكاليف علاج السكري',
      description: 'أعاني من مرض السكري منذ 10 سنوات وأحتاج أدوية شهرية',
      urgency: UrgencyLevel.medium,
      familySize: 5,
      notes: 'الأدوية تنفد قبل نهاية الشهر',
      location: const LocationInfo(
        latitude: 30.5085,
        longitude: 47.7804,
        address: 'شارع النضال، قرب مستشفى الصداقة',
        governorate: 'البصرة',
        area: 'العشار',
      ),
      attachments: [
        MediaAttachment(
          id: 'att_003',
          type: AttachmentType.image,
          name: 'وصفة طبية',
          mockPath: 'mock/images/prescription.jpg',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        MediaAttachment(
          id: 'att_004',
          type: AttachmentType.image,
          name: 'تقرير طبي',
          mockPath: 'mock/images/medical_report.jpg',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ],
      typeData: const {
        'diagnosis': 'مرض السكري من النوع الثاني',
        'medicineDetails': 'ميتفورمين 1000mg، جليبنكلاميد 5mg',
        'hospitalClinic': 'مستشفى الصداقة - البصرة',
        'medicalNotes': 'مراجعة شهرية مطلوبة',
        'referenceDetails': 'وصفة طبية مرفقة',
      },
    ),
    HelpRequest(
      id: 'req_005',
      type: RequestType.householdMaterials,
      status: RequestStatus.rejected,
      submittedAt: DateTime.now().subtract(const Duration(days: 2)),
      submittedByUserId: 'user_004',
      fullName: 'زينب حمد الشمري',
      phone: '07545678901',
      governorate: 'الأنبار',
      area: 'الرمادي',
      fullAddress: 'حي التحرير، قرب المدرسة المركزية',
      title: 'أثاث منزلي أساسي لأسرة نازحة',
      description: 'أسرة نازحة تحتاج أثاثاً أساسياً بعد فقدان منزلها',
      urgency: UrgencyLevel.high,
      familySize: 7,
      notes: 'تم رفضها بسبب ناقص في الوثائق، سيتم إعادة التقديم',
      location: const LocationInfo(
        latitude: 33.4258,
        longitude: 43.2994,
        address: 'حي التحرير، قرب المدرسة المركزية',
        governorate: 'الأنبار',
        area: 'الرمادي',
      ),
      attachments: const [],
      typeData: const {
        'requestedItems': 'فراش، بطانيات، طاولة طعام، كراسي',
        'quantity': 'فراش × 4، بطانية × 6، طاولة × 1، كراسي × 6',
        'housingStatus': 'مستأجر',
        'conditionDetails': 'المنزل فارغ تماماً بعد النزوح',
      },
    ),
    HelpRequest(
      id: 'req_006',
      type: RequestType.generalHelp,
      status: RequestStatus.underReview,
      submittedAt: DateTime.now().subtract(const Duration(hours: 12)),
      submittedByUserId: 'user_005',
      fullName: 'أحمد كاظم المالكي',
      phone: '07456789012',
      governorate: 'النجف',
      area: 'المركز',
      fullAddress: 'شارع الرسول، بيت رقم 44',
      title: 'مساعدة عاجلة لأسرة يتيمة',
      description:
          'أسرة من أرملة و3 أطفال يتامى تحتاج دعماً شاملاً في المعيشة والتعليم',
      urgency: UrgencyLevel.critical,
      familySize: 4,
      notes: 'الأطفال منقطعون عن الدراسة',
      location: const LocationInfo(
        latitude: 31.9920,
        longitude: 44.3152,
        address: 'شارع الرسول، بيت رقم 44',
        governorate: 'النجف',
        area: 'المركز',
      ),
      attachments: [
        MediaAttachment(
          id: 'att_005',
          type: AttachmentType.voiceNote,
          name: 'رسالة صوتية',
          durationSeconds: 120,
          createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        ),
      ],
      typeData: const {
        'caseDetails':
            'أرملة مع 3 أطفال أعمارهم 6، 9، 12 سنة. المنزل مستأجر والأجرة متأخرة. الأطفال بحاجة لمستلزمات مدرسية.',
      },
    ),
  ];

  @override
  List<HelpRequest> getAll() => List.unmodifiable(_requests);

  @override
  HelpRequest? getById(String id) {
    try {
      return _requests.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  HelpRequest add(HelpRequest request) {
    _requests.add(request);
    return request;
  }

  @override
  HelpRequest? update(HelpRequest request) {
    final index = _requests.indexWhere((r) => r.id == request.id);
    if (index == -1) return null;
    if (!_requests[index].isEditable) return null;
    _requests[index] = request;
    return request;
  }

  @override
  HelpRequest? forceUpdateStatus(String id, RequestStatus newStatus) {
    final index = _requests.indexWhere((r) => r.id == id);
    if (index == -1) return null;
    _requests[index] = _requests[index].copyWith(status: newStatus);
    return _requests[index];
  }

  @override
  bool delete(String id) {
    final index = _requests.indexWhere((r) => r.id == id);
    if (index == -1) return false;
    _requests.removeAt(index);
    return true;
  }
}
