import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// JWT in memory first — [FlutterSecureStorage] can take 30s+ on some Android devices.
class SecureStorageService {
  SecureStorageService() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _kToken = 'jwt_token';

  String? _memoryToken;

  /// Synchronous read for Dio / guards (set on login before disk write finishes).
  String? get cachedToken => _memoryToken;

  Future<void> saveToken(String token) async {
    _memoryToken = token;
    try {
      await _storage
          .write(key: _kToken, value: token)
          // Some Android devices can take 30s+ for keystore I/O.
          // We allow more time so token is actually persisted before the app is backgrounded/killed.
          .timeout(const Duration(seconds: 15), onTimeout: () {});
    } catch (_) {
      /* memory token still valid for this session */
    }
  }

  Future<String?> readToken() async {
    final mem = _memoryToken;
    if (mem != null && mem.isNotEmpty) return mem;
    try {
      final disk = await _storage
          .read(key: _kToken)
          .timeout(const Duration(seconds: 15), onTimeout: () => null);
      if (disk != null && disk.isNotEmpty) {
        _memoryToken = disk;
      }
      return disk;
    } catch (_) {
      return _memoryToken;
    }
  }

  Future<void> clearToken() async {
    _memoryToken = null;
    try {
      await _storage
          .delete(key: _kToken)
          .timeout(const Duration(seconds: 15), onTimeout: () {});
    } catch (_) {
      /* ignore */
    }
  }
}
