import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kToken = 'jwt_token';

  Future<void> saveToken(String token) => _storage.write(key: _kToken, value: token);

  Future<String?> readToken() => _storage.read(key: _kToken);

  Future<void> clearToken() => _storage.delete(key: _kToken);
}
