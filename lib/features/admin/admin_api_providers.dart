import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_cache.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

Future<List<Map<String, dynamic>>> _fetchList(
  Dio dio,
  String path, {
  required ApiResponseCache cache,
  required String cacheKey,
}) async {
  final res = await dio.apiGet(path);
  final list = parseSuccessList(res);
  unawaited(cache.writeList(cacheKey, list));
  return list;
}

AutoDisposeFutureProvider<List<Map<String, dynamic>>> _cachedListProvider(
  String name,
  String path,
) {
  return FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
    final link = ref.keepAlive();
    Timer(const Duration(minutes: 5), link.close);

    final cache = ref.watch(apiResponseCacheProvider);
    final cached = cache.readList(name);
    if (cached != null) {
      unawaited(_refreshList(ref, path, name));
      return cached;
    }

    final dio = ref.watch(dioProvider);
    return _fetchList(dio, path, cache: cache, cacheKey: name);
  });
}

Future<void> _refreshList(Ref ref, String path, String cacheKey) async {
  try {
    final dio = ref.read(dioProvider);
    final cache = ref.read(apiResponseCacheProvider);
    await _fetchList(dio, path, cache: cache, cacheKey: cacheKey);
  } catch (_) {
    /* keep stale cache */
  }
}

/// Staff (users) — backend: /api/users (SUPER_ADMIN only).
final staffListProvider = _cachedListProvider('admin_staff', ApiEndpoints.users);

final staffDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.apiGet(ApiEndpoints.userById(id));
  return parseSuccessDataMap(res);
});

final coursesListProvider = _cachedListProvider('admin_courses', ApiEndpoints.courses);

final courseDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.apiGet(ApiEndpoints.courseById(id));
  return parseSuccessDataMap(res);
});

final subjectsListProvider = _cachedListProvider('admin_subjects', ApiEndpoints.subjects);

final subjectDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.apiGet(ApiEndpoints.subjectById(id));
  return parseSuccessDataMap(res);
});

final adminTestsListProvider = _cachedListProvider('admin_tests', ApiEndpoints.tests);

final promosAdminListProvider = _cachedListProvider('admin_promos', ApiEndpoints.promos);

final promoDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final list = await ref.watch(promosAdminListProvider.future);
  for (final p in list) {
    if (p['_id']?.toString() == id) return p;
  }
  throw StateError('Promo not found');
});

final adminResultsForTestProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, testId) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.apiGet(ApiEndpoints.resultsForTest(testId));
  return parseSuccessList(res);
});
