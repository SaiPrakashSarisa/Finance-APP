import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:finance_app_mobile/core/security/mpin_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('MpinService Unit & Security Tests', () {
    test('Set and verify 4-digit MPIN correctly', () async {
      // Test invalid PIN format rejection
      final invalidShort = await MpinService.setMpin('12');
      expect(invalidShort, false);

      final invalidAlpha = await MpinService.setMpin('abcd');
      expect(invalidAlpha, false);

      // Set valid PIN
      final success = await MpinService.setMpin('4321');
      expect(success, true);

      final hasMpin = await MpinService.hasMpin();
      expect(hasMpin, true);

      // Verify correct PIN
      final correctResult = await MpinService.verifyMpin('4321');
      expect(correctResult.success, true);

      // Verify incorrect PIN
      final wrongResult = await MpinService.verifyMpin('9999');
      expect(wrongResult.success, false);
      expect(wrongResult.remainingAttempts, lessThan(5));

      // Clear MPIN
      await MpinService.clearMpin();
      final hasMpinAfterClear = await MpinService.hasMpin();
      expect(hasMpinAfterClear, false);
    });
  });
}
