import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import 'auth_provider.dart';

/// Purpose: User Profile & Settings State Management Provider
/// Author: Antigravity AI

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(apiClientProvider));
});

class UserState {
  final UserModel? profile;
  final UserSettingsModel? settings;
  final bool isLoading;
  final String? error;

  UserState({
    this.profile,
    this.settings,
    required this.isLoading,
    this.error,
  });
}

class UserNotifier extends StateNotifier<UserState> {
  final UserRepository repository;
  final Ref ref;

  UserNotifier(this.repository, this.ref)
      : super(UserState(isLoading: true)) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    state = UserState(profile: state.profile, settings: state.settings, isLoading: true);
    try {
      final prof = await repository.getProfile();
      final setts = await repository.getSettings();
      state = UserState(profile: prof, settings: setts, isLoading: false);
      if (prof != null) {
        ref.read(authProvider.notifier).updateUser(prof);
      }
    } catch (e) {
      state = UserState(profile: state.profile, settings: state.settings, isLoading: false, error: e.toString());
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final updated = await repository.updateProfile(data);
      if (updated != null) {
        state = UserState(profile: updated, settings: state.settings, isLoading: false);
        ref.read(authProvider.notifier).updateUser(updated);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> updateSettings(Map<String, dynamic> data) async {
    try {
      final updated = await repository.updateSettings(data);
      if (updated != null) {
        state = UserState(profile: state.profile, settings: updated, isLoading: false);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<Map<String, dynamic>?> changePassword(String currentPassword, String newPassword) async {
    return await repository.changePassword(currentPassword, newPassword);
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(ref.watch(userRepositoryProvider), ref);
});
