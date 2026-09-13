/// Purpose: User Profile & Settings Data Model
/// Author: Antigravity AI

class UserSettingsModel {
  final String dashboardRange;
  final bool budgetEnabled;

  UserSettingsModel({
    required this.dashboardRange,
    required this.budgetEnabled,
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      dashboardRange: json['dashboardRange'] ?? '1m',
      budgetEnabled: json['budgetEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dashboardRange': dashboardRange,
      'budgetEnabled': budgetEnabled,
    };
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? countryCode;
  final String? profilePicture;
  final UserSettingsModel settings;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.countryCode,
    this.profilePicture,
    required this.settings,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      countryCode: json['countryCode'],
      profilePicture: json['profilePicture'],
      settings: json['settings'] != null
          ? UserSettingsModel.fromJson(json['settings'])
          : UserSettingsModel(dashboardRange: '1m', budgetEnabled: true),
    );
  }
}
