import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/theme_provider.dart';

/// Short-lived JSON cache for dashboard payloads (stale-while-revalidate).
class ApiResponseCache {
  ApiResponseCache(this._prefs);

  final SharedPreferences _prefs;

  static const _prefix = 'api_cache_v1_';

  Map<String, dynamic>? readMap(String key, {Duration maxAge = const Duration(minutes: 10)}) {
    final raw = _prefs.getString('$_prefix$key');
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final at = decoded['at'] as int?;
      final data = decoded['data'];
      if (at == null || data is! Map) return null;
      final age = DateTime.now().millisecondsSinceEpoch - at;
      if (age > maxAge.inMilliseconds) return null;
      return Map<String, dynamic>.from(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeMap(String key, Map<String, dynamic> data) async {
    await _prefs.setString(
      '$_prefix$key',
      jsonEncode({
        'at': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      }),
    );
  }
}

final apiResponseCacheProvider = Provider<ApiResponseCache>((ref) {
  return ApiResponseCache(ref.watch(sharedPrefsProvider));
});
