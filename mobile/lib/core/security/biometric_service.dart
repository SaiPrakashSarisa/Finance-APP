import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Purpose: Device Biometric (Fingerprint / Face ID) Authentication Service
/// Author: Antigravity AI

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const String _keyBiometricEnabled = 'biometric_unlock_enabled';

  /// Check if the physical device has biometric hardware capable of checking biometrics
  static Future<bool> isBiometricsAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      debugPrint('Biometric availability check failed: $e');
      return false;
    }
  }

  /// Get list of enrolled biometric types (e.g. fingerprint, face)
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Get available biometrics failed: $e');
      return [];
    }
  }

  /// Check whether user has toggled biometric unlock ON in app settings
  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to true if hardware is available, or read user's saved preference
    final stored = prefs.getBool(_keyBiometricEnabled);
    if (stored == null) {
      // First time check: if device supports biometrics, default to true
      final available = await isBiometricsAvailable();
      if (available) {
        await prefs.setBool(_keyBiometricEnabled, true);
        return true;
      }
      return false;
    }
    return stored;
  }

  /// Save user's preference for biometric unlock
  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, enabled);
  }

  /// Trigger the native platform biometric authentication dialog (Fingerprint / Face Unlock)
  static Future<bool> authenticate({
    String reason = 'Scan your fingerprint to unlock Finance Hub',
  }) async {
    try {
      final available = await isBiometricsAvailable();
      if (!available) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        sensitiveTransaction: false,
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      debugPrint('Biometric authentication failed: $e');
      return false;
    }
  }
}
