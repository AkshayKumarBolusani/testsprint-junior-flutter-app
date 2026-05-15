import 'dart:async';

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
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 25),
      sendTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Prefer in-memory session token (instant). Avoid slow Keystore on every request.
        String? token = ref.read(authNotifierProvider).token;
        token ??= storage.cachedToken;
        if (token == null || token.isEmpty) {
          try {
            token = await storage
                .readToken()
                // If the token isn't in memory (fresh app start), keystore I/O may be slow.
                .timeout(const Duration(milliseconds: 2500), onTimeout: () => null);
          } catch (_) {
            token = null;
          }
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
            unawaited(ref.read(authNotifierProvider.notifier).logout());
          }
        }
        handler.next(e);
      },
    ),
  );

  return dio;
});
