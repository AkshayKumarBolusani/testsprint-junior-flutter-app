import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_cache.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

Future<Map<String, dynamic>> _fetchDashboardMap(
  Dio dio,
  String path, {
  required ApiResponseCache cache,
  required String cacheKey,
}) async {
  final res = await dio.apiGet(path);
  final data = parseSuccessDataMap(res);
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
  final link = ref.keepAlive();
  Timer(const Duration(minutes: 5), link.close);

  final cache = ref.watch(apiResponseCacheProvider);
  const cacheKey = 'student_tests_available';
  final cached = cache.readList(cacheKey);
  if (cached != null) {
    unawaited(_refreshTestsAvailable(ref));
    return cached;
  }

  final dio = ref.watch(dioProvider);
  final res = await dio.apiGet(ApiEndpoints.testsAvailable);
  final list = parseSuccessList(res);
  unawaited(cache.writeList(cacheKey, list));
  return list;
});

Future<void> _refreshTestsAvailable(Ref ref) async {
  try {
    final dio = ref.read(dioProvider);
    final cache = ref.read(apiResponseCacheProvider);
    final res = await dio.apiGet(ApiEndpoints.testsAvailable);
    final list = parseSuccessList(res);
    unawaited(cache.writeList('student_tests_available', list));
  } catch (_) {}
}

final studentPromosProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.apiGet(ApiEndpoints.promosStudent);
  return parseSuccessList(res);
});

final appSettingsAdminProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.apiGet(ApiEndpoints.settingsApp);
  return parseSuccessDataMap(res);
});

final notificationsListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final link = ref.keepAlive();
  Timer(const Duration(minutes: 3), link.close);

  final cache = ref.watch(apiResponseCacheProvider);
  const cacheKey = 'notifications';
  final cached = cache.readList(cacheKey);
  if (cached != null) {
    unawaited(_refreshNotifications(ref));
    return cached;
  }

  final dio = ref.watch(dioProvider);
  final res = await dio.apiGet(ApiEndpoints.notifications);
  final list = parseSuccessList(res);
  unawaited(cache.writeList(cacheKey, list));
  return list;
});

Future<void> _refreshNotifications(Ref ref) async {
  try {
    final dio = ref.read(dioProvider);
    final cache = ref.read(apiResponseCacheProvider);
    final res = await dio.apiGet(ApiEndpoints.notifications);
    unawaited(cache.writeList('notifications', parseSuccessList(res)));
  } catch (_) {}
}

final studentsListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final link = ref.keepAlive();
  Timer(const Duration(minutes: 5), link.close);

  final cache = ref.watch(apiResponseCacheProvider);
  const cacheKey = 'admin_students';
  final cached = cache.readList(cacheKey);
  if (cached != null) {
    unawaited(_refreshStudentsList(ref));
    return cached;
  }

  final dio = ref.watch(dioProvider);
  final res = await dio.apiGet(ApiEndpoints.students);
  final list = parseSuccessList(res);
  unawaited(cache.writeList(cacheKey, list));
  return list;
});

Future<void> _refreshStudentsList(Ref ref) async {
  try {
    final dio = ref.read(dioProvider);
    final cache = ref.read(apiResponseCacheProvider);
    final res = await dio.apiGet(ApiEndpoints.students);
    unawaited(cache.writeList('admin_students', parseSuccessList(res)));
  } catch (_) {}
}

final studentResultsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final link = ref.keepAlive();
  Timer(const Duration(minutes: 5), link.close);

  final cache = ref.watch(apiResponseCacheProvider);
  const cacheKey = 'student_results';
  final cached = cache.readList(cacheKey);
  if (cached != null) {
    unawaited(_refreshStudentResults(ref));
    return cached;
  }

  final dio = ref.watch(dioProvider);
  final res = await dio.apiGet(ApiEndpoints.resultsMy);
  final list = parseSuccessList(res);
  unawaited(cache.writeList(cacheKey, list));
  return list;
});

Future<void> _refreshStudentResults(Ref ref) async {
  try {
    final dio = ref.read(dioProvider);
    final cache = ref.read(apiResponseCacheProvider);
    final res = await dio.apiGet(ApiEndpoints.resultsMy);
    unawaited(cache.writeList('student_results', parseSuccessList(res)));
  } catch (_) {}
}

final testDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.apiGet(ApiEndpoints.testById(id));
  return parseSuccessDataMap(res);
});

final resultDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.apiGet(ApiEndpoints.resultById(id));
  return parseSuccessDataMap(res);
});

final rankingsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, testId) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.apiGet(ApiEndpoints.rankingsByTest(testId));
  return parseSuccessList(res);
});

final studentDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.apiGet(ApiEndpoints.studentById(id));
  return parseSuccessDataMap(res);
});
