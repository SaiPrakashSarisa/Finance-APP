import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';

/// Purpose: Authentication State Provider
/// Author: Antigravity AI
/// Last Modified: 2026-08-03

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? email;
  final String? name;
  final String? error;

  AuthState({
    required this.isAuthenticated,
    required this.isLoading,
    this.email,
    this.name,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? email,
    String? name,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      email: email ?? this.email,
      name: name ?? this.name,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient apiClient;

  AuthNotifier(this.apiClient)
      : super(AuthState(isAuthenticated: false, isLoading: true)) {
    checkSession();
  }

  Future<void> checkSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) {
        state = state.copyWith(isAuthenticated: false, isLoading: false);
        return;
      }

      final response = await apiClient.get(ApiEndpoints.me);
      if (response.data != null && response.data['success'] == true) {
        final userData = response.data['user'];
        state = AuthState(
          isAuthenticated: true,
          isLoading: false,
          email: userData['email'],
          name: userData['name'],
        );
      } else {
        state = state.copyWith(isAuthenticated: false, isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isAuthenticated: false, isLoading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      if (response.data != null && response.data['success'] == true) {
        final token = response.data['token'];
        final userData = response.data['user'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);

        state = AuthState(
          isAuthenticated: true,
          isLoading: false,
          email: userData['email'],
          name: userData['name'],
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data['error'] ?? 'Login failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network or authentication error',
      );
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    state = AuthState(isAuthenticated: false, isLoading: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(apiClientProvider));
});
