import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../data/models/user_model.dart';

/// Purpose: Authentication & Session State Management Provider
/// Author: Antigravity AI

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final UserModel? user;
  final String? error;

  AuthState({
    required this.isAuthenticated,
    required this.isLoading,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    UserModel? user,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
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

  /// Instant local session check (0ms latency, zero cold-start delay)
  Future<void> checkSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        state = state.copyWith(isAuthenticated: false, isLoading: false);
        return;
      }

      // 1. Immediately restore cached user profile if present
      UserModel? cachedUser;
      final cachedUserStr = prefs.getString('cached_user');
      if (cachedUserStr != null && cachedUserStr.isNotEmpty) {
        try {
          cachedUser = UserModel.fromJson(jsonDecode(cachedUserStr));
        } catch (_) {}
      }

      // 2. Immediately mark user as authenticated locally (no waiting for remote API!)
      state = AuthState(
        isAuthenticated: true,
        isLoading: false,
        user: cachedUser,
      );

      // 3. Fire-and-forget background verification with remote server
      _verifySessionWithServer(token);
    } catch (_) {
      state = state.copyWith(isAuthenticated: false, isLoading: false);
    }
  }

  /// Non-blocking background verification with remote API
  Future<void> _verifySessionWithServer(String token) async {
    try {
      final response = await apiClient.get(ApiEndpoints.me);
      if (response.data != null && response.data['success'] == true) {
        final userObj = UserModel.fromJson(response.data['user']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_user', jsonEncode(userObj.toJson()));
        state = state.copyWith(user: userObj);
      } else if (response.statusCode == 401) {
        // Explicit 401 Unauthorized: token has expired or revoked on server
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('jwt_token');
        await prefs.remove('cached_user');
        state = AuthState(isAuthenticated: false, isLoading: false);
      }
    } catch (e) {
      // Network timeout / Render cold-start / Offline: DO NOT log the user out!
      // Keep local session valid so the user can continue using the app.
      debugPrint('Background session verification deferred: $e');
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
        final userObj = UserModel.fromJson(response.data['user']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('cached_user', jsonEncode(userObj.toJson()));

        state = AuthState(
          isAuthenticated: true,
          isLoading: false,
          user: userObj,
        );
        return true;
      } else {
        final serverError = response.data is Map ? (response.data['error'] ?? response.data['message']) : null;
        state = state.copyWith(
          isLoading: false,
          error: serverError?.toString() ?? 'Invalid email or password',
        );
        return false;
      }
    } catch (e) {
      String errorMessage = 'Unable to connect to server. Check your connection.';
      if (e is DioException) {
        if (e.response?.data is Map && (e.response?.data['error'] != null || e.response?.data['message'] != null)) {
          errorMessage = (e.response?.data['error'] ?? e.response?.data['message']).toString();
        } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Connection timed out. Target: ${apiClient.dio.options.baseUrl}';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = 'Cannot reach server at ${apiClient.dio.options.baseUrl}. Please check network connection.';
        }
      }
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.post(
        ApiEndpoints.register,
        data: {'name': name, 'email': email, 'password': password},
      );

      if (response.data != null && response.data['success'] == true) {
        final token = response.data['token'];
        final userObj = UserModel.fromJson(response.data['user']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('cached_user', jsonEncode(userObj.toJson()));

        state = AuthState(
          isAuthenticated: true,
          isLoading: false,
          user: userObj,
        );
        return true;
      } else {
        final serverError = response.data is Map ? (response.data['error'] ?? response.data['message']) : null;
        state = state.copyWith(
          isLoading: false,
          error: serverError?.toString() ?? 'Registration failed',
        );
        return false;
      }
    } catch (e) {
      String errorMessage = 'Unable to connect to server. Check your connection.';
      if (e is DioException) {
        if (e.response?.data is Map && (e.response?.data['error'] != null || e.response?.data['message'] != null)) {
          errorMessage = (e.response?.data['error'] ?? e.response?.data['message']).toString();
        } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Connection timed out. Target: ${apiClient.dio.options.baseUrl}';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = 'Cannot reach server at ${apiClient.dio.options.baseUrl}. Please check network connection.';
        }
      }
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await apiClient.get(ApiEndpoints.logout);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('cached_user');
    state = AuthState(isAuthenticated: false, isLoading: false);
  }

  void updateUser(UserModel updatedUser) {
    state = state.copyWith(user: updatedUser);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(apiClientProvider));
});
