import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class AdminGuard {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> authenticateAdmin() async {
    try {
      // Check if hardware is available
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();

      // If the device doesn't support biometrics or PIN at all, allow access
      // (This prevents locking yourself out on broken hardware)
      if (!canCheckBiometrics && !isDeviceSupported) return true;

      return await _auth.authenticate(
        localizedReason: 'Please authenticate to access Admin Mission Control',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // ✅ ALLOWS PIN/PATTERN FALLBACK
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint("❌ Security Error: ${e.message}");
      return false;
    } catch (e) {
      return false;
    }
  }

  // Feature 2: Master PIN (Logic)
  static bool verifyAppPin(String enteredPin) {
    const String masterAdminPin = "1234"; // Your secret master PIN
    return enteredPin == masterAdminPin;
  }
}