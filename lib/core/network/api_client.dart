import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/storage_providers.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Per-request ceiling (gateway + Mongo should finish well under this).
const apiTimeout = Duration(seconds: 35);

final dioProvider = Provider<Dio>((ref) {
  final session = ref.watch(authSessionStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 45),
      sendTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        String? token = ref.read(authNotifierProvider).token;
        token ??= session.cachedToken;
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

extension DioApi on Dio {
  Future<Response<dynamic>> apiGet(
    String path, {
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) {
    return get(path, queryParameters: queryParameters).timeout(timeout ?? apiTimeout);
  }

  Future<Response<dynamic>> apiPost(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) {
    return post(path, data: data, queryParameters: queryParameters)
        .timeout(timeout ?? apiTimeout);
  }

  Future<Response<dynamic>> apiPut(
    String path, {
    Object? data,
    Duration? timeout,
  }) {
    return put(path, data: data).timeout(timeout ?? apiTimeout);
  }

  Future<Response<dynamic>> apiPatch(
    String path, {
    Object? data,
    Duration? timeout,
  }) {
    return patch(path, data: data).timeout(timeout ?? apiTimeout);
  }

  Future<Response<dynamic>> apiDelete(
    String path, {
    Duration? timeout,
  }) {
    return delete(path).timeout(timeout ?? apiTimeout);
  }
}

Map<String, dynamic> parseSuccessMap(Response<dynamic> res) {
  final map = Map<String, dynamic>.from(res.data as Map);
  if (map['success'] != true) {
    throw DioException(
      requestOptions: res.requestOptions,
      response: res,
      message: map['message']?.toString() ?? 'Request failed',
    );
  }
  return map;
}

List<Map<String, dynamic>> parseSuccessList(Response<dynamic> res) {
  final map = parseSuccessMap(res);
  final data = map['data'] as List<dynamic>? ?? [];
  return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
}

Map<String, dynamic> parseSuccessDataMap(Response<dynamic> res) {
  final map = parseSuccessMap(res);
  return Map<String, dynamic>.from(map['data'] as Map);
}
