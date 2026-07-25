import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:charity_app/shared/providers/app_providers.dart';
import 'package:charity_app/features/competitions/domain/competition_models.dart';

const _uuid = Uuid();
const _kMySocialPointsKey = 'engagement_social_points_v1';
const _kMyOrgSupportKey = 'engagement_org_support_v1';
const _kMyFamilyDonationKey = 'engagement_family_donation_v1';

// ════════════════════════════════════════════════════════════════════════════
//  تواصل اجتماعي — المستخدم يُرسل "شاركت المنشور"، والأدمن يعتمد الطلب
//  ويحدّد عدد النقاط الممنوحة لكل مشاركة.
// ════════════════════════════════════════════════════════════════════════════
class SocialShareNotifier extends StateNotifier<List<SocialShareRequest>> {
  final SharedPreferences _prefs;
  SocialShareNotifier(this._prefs) : super(const []);

  int get myPoints => _prefs.getInt(_kMySocialPointsKey) ?? 0;

  bool get hasPending => state.any((r) => r.status == ShareRequestStatus.pending);

  /// المستخدم يبلّغ بأنه شارك المنشور — يُنشئ طلباً بانتظار اعتماد الأدمن.
  void submitShare() {
    if (hasPending) return;
    state = [
      SocialShareRequest(id: _uuid.v4(), submittedAt: DateTime.now()),
      ...state,
    ];
  }

  /// اعتماد الأدمن للطلب مع تحديد عدد النقاط الممنوحة.
  void approve(String requestId, int points) {
    final idx = state.indexWhere((r) => r.id == requestId);
    if (idx < 0) return;
    state = [...state]
      ..[idx] = state[idx].copyWith(status: ShareRequestStatus.approved, awardedPoints: points);
    _prefs.setInt(_kMySocialPointsKey, myPoints + points);
  }
}

final socialShareProvider =
    StateNotifierProvider<SocialShareNotifier, List<SocialShareRequest>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SocialShareNotifier(prefs);
});

// ════════════════════════════════════════════════════════════════════════════
//  إحصاءات المستخدم في قسمي "تواصل مباشر مع المؤسسة" و"تبرّع للعوائل" —
//  عدّادات بسيطة تُحفظ محلياً وتُستخدم لعرض بطاقة "موقعي الحالي".
// ════════════════════════════════════════════════════════════════════════════
class MyEngagementStatsNotifier extends StateNotifier<({int orgSupport, int familyDonations})> {
  final SharedPreferences _prefs;
  MyEngagementStatsNotifier(this._prefs)
      : super((
          orgSupport: _prefs.getInt(_kMyOrgSupportKey) ?? 0,
          familyDonations: _prefs.getInt(_kMyFamilyDonationKey) ?? 0,
        ));

  void addOrgSupport(int amount) {
    final updated = state.orgSupport + amount;
    _prefs.setInt(_kMyOrgSupportKey, updated);
    state = (orgSupport: updated, familyDonations: state.familyDonations);
  }

  void addFamilyDonation() {
    final updated = state.familyDonations + 1;
    _prefs.setInt(_kMyFamilyDonationKey, updated);
    state = (orgSupport: state.orgSupport, familyDonations: updated);
  }
}

final myEngagementStatsProvider = StateNotifierProvider<MyEngagementStatsNotifier,
    ({int orgSupport, int familyDonations})>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return MyEngagementStatsNotifier(prefs);
});
