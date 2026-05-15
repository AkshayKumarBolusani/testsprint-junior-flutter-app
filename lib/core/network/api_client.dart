import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/storage_providers.dart';
import '../../features/auth/providers/auth_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      // Vercel cold start + Mongo + TLS on slow mobile links can exceed 30s.
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 90),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // flutter_secure_storage can hang indefinitely on some Android Keystore paths.
        // Login must not wait on that — otherwise no packet is ever sent to the server.
        String? token;
        try {
          token = await storage
              .readToken()
              .timeout(const Duration(seconds: 3), onTimeout: () => null);
        } catch (_) {
          token = null;
        }
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401) {
          final path = e.requestOptions.path;
          if (!path.contains('/api/auth/login')) {
            await ref.read(authNotifierProvider.notifier).logout();
          }
        }
        handler.next(e);
      },
    ),
  );

  return dio;
});
