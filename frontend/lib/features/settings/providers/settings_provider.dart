import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:charity_app/shared/providers/app_providers.dart';
import 'package:charity_app/shared/models/user_model.dart';
import 'package:charity_app/core/permissions/role.dart';

// ── Organization Settings ─────────────────────────────────────────────────────
class OrgSettings {
  final String name;
  final String phone;
  final String address;

  const OrgSettings({
    required this.name,
    required this.phone,
    required this.address,
  });

  OrgSettings copyWith({String? name, String? phone, String? address}) =>
      OrgSettings(
        name: name ?? this.name,
        phone: phone ?? this.phone,
        address: address ?? this.address,
      );
}

class OrgSettingsNotifier extends StateNotifier<OrgSettings> {
  final SharedPreferences _prefs;

  OrgSettingsNotifier(this._prefs)
      : super(OrgSettings(
          name: _prefs.getString('org_name') ?? 'منظمة الخير الخيرية',
          phone: _prefs.getString('org_phone') ?? '+964 770 000 0000',
          address: _prefs.getString('org_address') ?? 'بغداد، العراق',
        ));

  void update({String? name, String? phone, String? address}) {
    state = state.copyWith(name: name, phone: phone, address: address);
    if (name != null) _prefs.setString('org_name', name);
    if (phone != null) _prefs.setString('org_phone', phone);
    if (address != null) _prefs.setString('org_address', address);
  }
}

final orgSettingsProvider =
    StateNotifierProvider<OrgSettingsNotifier, OrgSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OrgSettingsNotifier(prefs);
});

// ── Notification Settings ─────────────────────────────────────────────────────
class NotificationSettings {
  final bool aidAlerts;
  final bool emailDigest;

  const NotificationSettings({
    this.aidAlerts = true,
    this.emailDigest = false,
  });

  NotificationSettings copyWith({bool? aidAlerts, bool? emailDigest}) =>
      NotificationSettings(
        aidAlerts: aidAlerts ?? this.aidAlerts,
        emailDigest: emailDigest ?? this.emailDigest,
      );
}

class NotificationSettingsNotifier
    extends StateNotifier<NotificationSettings> {
  final SharedPreferences _prefs;

  NotificationSettingsNotifier(this._prefs)
      : super(NotificationSettings(
          aidAlerts: _prefs.getBool('notif_aid_alerts') ?? true,
          emailDigest: _prefs.getBool('notif_email_digest') ?? false,
        ));

  void toggleAidAlerts() {
    state = state.copyWith(aidAlerts: !state.aidAlerts);
    _prefs.setBool('notif_aid_alerts', state.aidAlerts);
  }

  void toggleEmailDigest() {
    state = state.copyWith(emailDigest: !state.emailDigest);
    _prefs.setBool('notif_email_digest', state.emailDigest);
  }
}

final notificationSettingsProvider = StateNotifierProvider<
    NotificationSettingsNotifier, NotificationSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NotificationSettingsNotifier(prefs);
});

// ── Users Management ──────────────────────────────────────────────────────────
class UsersNotifier extends StateNotifier<List<UserModel>> {
  UsersNotifier()
      : super([
          UserModel.admin(
            id: 'user_001',
            name: 'مدير النظام',
            email: 'admin@charity.org',
          ),
          UserModel.employee(
            id: 'user_002',
            name: 'أحمد محمد',
            email: 'employee@charity.org',
          ),
          UserModel.employee(
            id: 'user_003',
            name: 'سارة علي',
            email: 'sarah@charity.org',
          ),
        ]);

  void toggleActive(String userId) {
    state = [
      for (final u in state)
        if (u.id == userId) u.copyWith(isActive: !u.isActive) else u,
    ];
  }

  void updatePermissions(String userId, Set<Permission> permissions) {
    state = [
      for (final u in state)
        if (u.id == userId) u.copyWith(permissions: permissions) else u,
    ];
  }

  void addUser({
    required String name,
    required String email,
    required UserRole role,
  }) {
    const uuid = Uuid();
    final newUser = UserModel(
      id: uuid.v4(),
      name: name,
      email: email,
      role: role,
      permissions: Set.from(defaultPermissions[role]!),
    );
    state = [...state, newUser];
  }

  void removeUser(String userId) {
    state = state.where((u) => u.id != userId).toList();
  }

  void updateUser(UserModel updated) {
    state = [
      for (final u in state) if (u.id == updated.id) updated else u,
    ];
  }
}

final usersProvider =
    StateNotifierProvider<UsersNotifier, List<UserModel>>((ref) {
  return UsersNotifier();
});
