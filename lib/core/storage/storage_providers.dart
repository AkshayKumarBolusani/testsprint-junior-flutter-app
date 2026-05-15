import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme_provider.dart';
import 'auth_session_storage.dart';
import 'secure_storage_service.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final authSessionStorageProvider = Provider<AuthSessionStorage>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return AuthSessionStorage(prefs);
});
