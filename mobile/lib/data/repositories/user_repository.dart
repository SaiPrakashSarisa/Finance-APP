import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';

/// Purpose: User Profile & Settings Data Repository
/// Author: Antigravity AI

class UserRepository {
  final ApiClient apiClient;

  UserRepository(this.apiClient);

  Future<UserModel?> getProfile() async {
    final response = await apiClient.get(ApiEndpoints.profile);
    if (response.data != null && response.data['success'] == true) {
      return UserModel.fromJson(response.data['data']);
    }
    return null;
  }

  Future<UserModel?> updateProfile(Map<String, dynamic> data) async {
    final response = await apiClient.put(ApiEndpoints.profile, data: data);
    if (response.data != null && response.data['success'] == true) {
      return UserModel.fromJson(response.data['data']);
    }
    return null;
  }

  Future<UserSettingsModel?> getSettings() async {
    final response = await apiClient.get(ApiEndpoints.settings);
    if (response.data != null && response.data['success'] == true) {
      return UserSettingsModel.fromJson(response.data['data']);
    }
    return null;
  }

  Future<UserSettingsModel?> updateSettings(Map<String, dynamic> data) async {
    final response = await apiClient.patch(ApiEndpoints.settings, data: data);
    if (response.data != null && response.data['success'] == true) {
      return UserSettingsModel.fromJson(response.data['data']);
    }
    return null;
  }

  Future<Map<String, dynamic>?> changePassword(String currentPassword, String newPassword) async {
    final response = await apiClient.put(
      ApiEndpoints.changePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
    if (response.data != null) {
      return Map<String, dynamic>.from(response.data);
    }
    return null;
  }
}
