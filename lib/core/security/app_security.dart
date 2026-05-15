import 'package:screen_protector/screen_protector.dart';
import 'package:safe_device/safe_device.dart';

/// Client-side hardening (screenshots, basic device checks).
/// Server auth + HTTPS remain the real security boundary.
abstract final class AppSecurity {
  static Future<bool> isDeviceCompromised() async {
    try {
      final jailbroken = await SafeDevice.isJailBroken;
      final realDevice = await SafeDevice.isRealDevice;
      final mockLocation = await SafeDevice.isMockLocation;
      return jailbroken || !realDevice || mockLocation;
    } catch (_) {
      return false;
    }
  }

  static Future<void> enableTestShield() async {
    try {
      await ScreenProtector.preventScreenshotOn();
    } catch (_) {}
  }

  static Future<void> disableTestShield() async {
    try {
      await ScreenProtector.preventScreenshotOff();
    } catch (_) {}
  }
}
