import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Purpose: 4-Digit MPIN Local Authentication & Secure Storage Service
/// Author: Antigravity AI

class MpinService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _keyMpinHash = 'mpin_hash';
  static const String _keyMpinSalt = 'mpin_salt';
  static const String _keyFailedAttempts = 'mpin_failed_attempts';
  static const String _keyLockoutTimestamp = 'mpin_lockout_until';

  static const int maxAttempts = 5;
  static const int lockoutMinutes = 5;

  /// Check if user has established an MPIN on this device
  static Future<bool> hasMpin() async {
    final hash = await _storage.read(key: _keyMpinHash);
    return hash != null && hash.isNotEmpty;
  }

  /// Store 4-Digit MPIN securely using SHA-256 and salt
  static Future<bool> setMpin(String pin) async {
    if (pin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pin)) {
      return false;
    }

    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);

    await _storage.write(key: _keyMpinSalt, value: salt);
    await _storage.write(key: _keyMpinHash, value: hash);
    await _storage.delete(key: _keyFailedAttempts);
    await _storage.delete(key: _keyLockoutTimestamp);

    return true;
  }

  /// Verify entered 4-digit MPIN against stored hash
  static Future<MpinVerificationResult> verifyMpin(String pin) async {
    if (await isLockedOut()) {
      final lockoutUntilStr = await _storage.read(key: _keyLockoutTimestamp);
      final lockoutUntil = DateTime.tryParse(lockoutUntilStr ?? '') ?? DateTime.now();
      final remaining = lockoutUntil.difference(DateTime.now()).inSeconds;
      return MpinVerificationResult(
        success: false,
        isLockedOut: true,
        remainingLockoutSeconds: remaining > 0 ? remaining : 0,
        errorMessage: 'Too many failed attempts. Try again later.',
      );
    }

    final storedHash = await _storage.read(key: _keyMpinHash);
    final storedSalt = await _storage.read(key: _keyMpinSalt);

    if (storedHash == null || storedSalt == null) {
      return const MpinVerificationResult(
        success: false,
        errorMessage: 'MPIN is not set up on this device.',
      );
    }

    final inputHash = _hashPin(pin, storedSalt);

    if (inputHash == storedHash) {
      // Reset failed attempts counter on success
      await _storage.delete(key: _keyFailedAttempts);
      await _storage.delete(key: _keyLockoutTimestamp);
      return const MpinVerificationResult(success: true);
    } else {
      // Handle failed attempt
      final failedStr = await _storage.read(key: _keyFailedAttempts) ?? '0';
      final failedCount = (int.tryParse(failedStr) ?? 0) + 1;

      if (failedCount >= maxAttempts) {
        final lockoutUntil = DateTime.now().add(const Duration(minutes: lockoutMinutes));
        await _storage.write(key: _keyLockoutTimestamp, value: lockoutUntil.toIso8601String());
        await _storage.delete(key: _keyFailedAttempts);

        return MpinVerificationResult(
          success: false,
          isLockedOut: true,
          remainingLockoutSeconds: lockoutMinutes * 60,
          errorMessage: 'Incorrect MPIN. Device locked for $lockoutMinutes minutes.',
        );
      } else {
        await _storage.write(key: _keyFailedAttempts, value: failedCount.toString());
        final remainingAttempts = maxAttempts - failedCount;
        return MpinVerificationResult(
          success: false,
          remainingAttempts: remainingAttempts,
          errorMessage: 'Incorrect MPIN. $remainingAttempts attempt(s) remaining.',
        );
      }
    }
  }

  /// Check if device is currently locked out due to multiple failed attempts
  static Future<bool> isLockedOut() async {
    final lockoutUntilStr = await _storage.read(key: _keyLockoutTimestamp);
    if (lockoutUntilStr == null) return false;

    final lockoutUntil = DateTime.tryParse(lockoutUntilStr);
    if (lockoutUntil == null) return false;

    if (DateTime.now().isBefore(lockoutUntil)) {
      return true;
    } else {
      // Lockout period expired
      await _storage.delete(key: _keyLockoutTimestamp);
      await _storage.delete(key: _keyFailedAttempts);
      return false;
    }
  }

  /// Delete MPIN data (e.g. on logout or MPIN reset)
  static Future<void> clearMpin() async {
    await _storage.delete(key: _keyMpinHash);
    await _storage.delete(key: _keyMpinSalt);
    await _storage.delete(key: _keyFailedAttempts);
    await _storage.delete(key: _keyLockoutTimestamp);
  }

  static String _generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  static String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$pin:$salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

class MpinVerificationResult {
  final bool success;
  final bool isLockedOut;
  final int remainingLockoutSeconds;
  final int remainingAttempts;
  final String? errorMessage;

  const MpinVerificationResult({
    required this.success,
    this.isLockedOut = false,
    this.remainingLockoutSeconds = 0,
    this.remainingAttempts = 5,
    this.errorMessage,
  });
}
