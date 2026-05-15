import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_cache.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

const _dashboardTimeout = Duration(seconds: 22);

Future<Map<String, dynamic>> _fetchDashboardMap(
  Dio dio,
  String path, {
  required ApiResponseCache cache,
  required String cacheKey,
}) async {
  final res = await dio.get(path).timeout(_dashboardTimeout);
  final map = Map<String, dynamic>.from(res.data as Map);
  if (map['success'] != true) {
    throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
  }
  final data = Map<String, dynamic>.from(map['data'] as Map);
  unawaited(cache.writeMap(cacheKey, data));
  return data;
}

final studentDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final link = ref.keepAlive();
  Timer(const Duration(minutes: 5), link.close);

  final cache = ref.watch(apiResponseCacheProvider);
  final cached = cache.readMap('student_dashboard');
  if (cached != null) {
    unawaited(_refreshStudentDashboard(ref));
    return cached;
  }

  final dio = ref.watch(dioProvider);
  return _fetchDashboardMap(
    dio,
    ApiEndpoints.studentDashboard,
    cache: cache,
    cacheKey: 'student_dashboard',
  );
});

Future<void> _refreshStudentDashboard(Ref ref) async {
  try {
    final dio = ref.read(dioProvider);
    final cache = ref.read(apiResponseCacheProvider);
    await _fetchDashboardMap(
      dio,
      ApiEndpoints.studentDashboard,
      cache: cache,
      cacheKey: 'student_dashboard',
    );
    ref.invalidate(studentDashboardProvider);
  } catch (_) {
    /* keep stale cache */
  }
}

Future<void> _refreshAdminDashboard(Ref ref) async {
  try {
    final dio = ref.read(dioProvider);
    final cache = ref.read(apiResponseCacheProvider);
    await _fetchDashboardMap(
      dio,
      ApiEndpoints.adminDashboard,
      cache: cache,
      cacheKey: 'admin_dashboard',
    );
    ref.invalidate(adminDashboardProvider);
  } catch (_) {
    /* keep stale cache */
  }
}

final adminDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final link = ref.keepAlive();
  Timer(const Duration(minutes: 5), link.close);

  final cache = ref.watch(apiResponseCacheProvider);
  final cached = cache.readMap('admin_dashboard');
  if (cached != null) {
    unawaited(_refreshAdminDashboard(ref));
    return cached;
  }

  final dio = ref.watch(dioProvider);
  return _fetchDashboardMap(
    dio,
    ApiEndpoints.adminDashboard,
    cache: cache,
    cacheKey: 'admin_dashboard',
  );
});

final studentAvailableTestsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.testsAvailable);
  final map = Map<String, dynamic>.from(res.data as Map);
  if (map['success'] != true) {
    throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
  }
  final data = map['data'] as List<dynamic>;
  return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
});

final studentPromosProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.promosStudent);
  final map = Map<String, dynamic>.from(res.data as Map);
  if (map['success'] != true) {
    throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
  }
  final data = map['data'] as List<dynamic>;
  return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
});

final appSettingsAdminProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.settingsApp);
  final map = Map<String, dynamic>.from(res.data as Map);
  if (map['success'] != true) {
    throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
  }
  return Map<String, dynamic>.from(map['data'] as Map);
});

final notificationsListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.notifications);
  final map = Map<String, dynamic>.from(res.data as Map);
  if (map['success'] != true) {
    throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
  }
  final data = map['data'] as List<dynamic>? ?? [];
  return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
});

final studentsListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.students);
  final map = Map<String, dynamic>.from(res.data as Map);
  if (map['success'] != true) {
    throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
  }
  final data = map['data'] as List<dynamic>;
  return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
});

final studentResultsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.resultsMy);
  final map = Map<String, dynamic>.from(res.data as Map);
  if (map['success'] != true) {
    throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
  }
  final data = map['data'] as List<dynamic>;
  return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
});

final testDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.testById(id));
  final map = Map<String, dynamic>.from(res.data as Map);
  if (map['success'] != true) {
    throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
  }
  return Map<String, dynamic>.from(map['data'] as Map);
});

final resultDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.resultById(id));
  final map = Map<String, dynamic>.from(res.data as Map);
  if (map['success'] != true) {
    throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
  }
  return Map<String, dynamic>.from(map['data'] as Map);
});

final rankingsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, testId) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.rankingsByTest(testId));
  final map = Map<String, dynamic>.from(res.data as Map);
  if (map['success'] != true) {
    throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
  }
  final data = map['data'] as List<dynamic>;
  return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
});

final studentDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.studentById(id));
  final map = Map<String, dynamic>.from(res.data as Map);
  if (map['success'] != true) {
    throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
  }
  return Map<String, dynamic>.from(map['data'] as Map);
});
