import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class SecurityService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const String _lockKey = 'app_biometric_lock';

  static Future<bool> isLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_lockKey) ?? false;
  }

  static Future<void> setLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockKey, enabled);
  }

  static Future<bool> authenticate() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) return true; // Let user in if device has no security

      // Stripped down to only the universally required parameter 
      // to ensure compatibility with your package version.
      return await _auth.authenticate(
        localizedReason: 'Unlock NOVE to access your private notes',
      );
    } on PlatformException catch (_) {
      return false;
    }
  }
}