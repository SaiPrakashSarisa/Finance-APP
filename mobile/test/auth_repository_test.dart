import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_app_mobile/core/network/api_client.dart';
import 'package:finance_app_mobile/data/repositories/auth_repository.dart';

void main() {
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    SharedPreferences.setMockInitialValues({});
  });

  test('New user creation and login workflow test', () async {
    final apiClient = ApiClient();
    final authRepository = AuthRepository(apiClient);

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final testName = 'Android Test User $timestamp';
    final testEmail = 'flutter_android_$timestamp@example.com';
    final testPassword = 'Password123!';

    // 1. Create New User (Register)
    final registeredUser = await authRepository.register(testName, testEmail, testPassword);
    expect(registeredUser, isNotNull);
    expect(registeredUser!.name, equals(testName));
    expect(registeredUser.email, equals(testEmail));
    print('✅ Registered new user: ${registeredUser.email} (${registeredUser.id})');

    // 2. Perform Login with the newly created user credentials
    final loggedInUser = await authRepository.login(testEmail, testPassword);
    expect(loggedInUser, isNotNull);
    expect(loggedInUser!.email, equals(testEmail));
    print('✅ Logged in successfully: ${loggedInUser.name}');

    // 3. Fetch Current User Profile (/api/auth/me)
    final meUser = await authRepository.getCurrentUser();
    expect(meUser, isNotNull);
    expect(meUser!.email, equals(testEmail));
    print('✅ Verified current user profile session: ${meUser.email}');
  });
}
