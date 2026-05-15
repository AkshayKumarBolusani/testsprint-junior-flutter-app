import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Runs once at app start. Android does **not** show a dialog for INTERNET /
/// ACCESS_NETWORK_STATE — those are granted at install from the manifest.
/// We only request runtime permissions that actually need a prompt.
Future<void> requestLaunchPermissions() async {
  if (!Platform.isAndroid && !Platform.isIOS) return;

  final status = await Permission.notification.status;
  if (status.isGranted || status.isLimited) return;
  if (status.isPermanentlyDenied) return;
  await Permission.notification.request();
}
