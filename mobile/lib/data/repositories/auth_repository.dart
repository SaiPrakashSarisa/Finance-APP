import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';

/// Purpose: Authentication Repository
/// Author: Antigravity AI

class AuthRepository {
  final ApiClient apiClient;

  AuthRepository(this.apiClient);

  Future<UserModel?> login(String email, String password) async {
    final response = await apiClient.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );

    if (response.data != null && response.data['success'] == true) {
      final token = response.data['token'];
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
      }
      return UserModel.fromJson(response.data['user']);
    }
    return null;
  }

  Future<UserModel?> register(String name, String email, String password) async {
    final response = await apiClient.post(
      ApiEndpoints.register,
      data: {'name': name, 'email': email, 'password': password},
    );

    if (response.data != null && response.data['success'] == true) {
      final token = response.data['token'];
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
      }
      return UserModel.fromJson(response.data['user']);
    }
    return null;
  }

  Future<UserModel?> getCurrentUser() async {
    final response = await apiClient.get(ApiEndpoints.me);
    if (response.data != null && response.data['success'] == true) {
      return UserModel.fromJson(response.data['user']);
    }
    return null;
  }

  Future<void> logout() async {
    try {
      await apiClient.get(ApiEndpoints.logout);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }
}
