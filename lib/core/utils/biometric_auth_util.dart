import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

/// Biometric authentication utility
class BiometricAuthUtil {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if device supports biometric
  static Future<bool> isDeviceSupported() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      return isSupported && canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Check if fingerprint is available
  static Future<bool> isFingerprintAvailable() async {
    try {
      final available = await _localAuth.getAvailableBiometrics();
      return available.contains(BiometricType.fingerprint) ||
          available.contains(BiometricType.strong) ||
          available.contains(BiometricType.weak);
    } catch (_) {
      return false;
    }
  }

  /// Authenticate using biometric
  static Future<bool> authenticate({
    required String localizedReason,
  }) async {
    try {
      final isSupported = await isDeviceSupported();
      if (!isSupported) {
        return false;
      }

      final isFingerprintAvailable = await BiometricAuthUtil.isFingerprintAvailable();
      if (!isFingerprintAvailable) {
        return false;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      return didAuthenticate;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
