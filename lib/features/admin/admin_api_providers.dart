import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

List<Map<String, dynamic>> _listFromResponse(Response<dynamic> res) {
  final map = Map<String, dynamic>.from(res.data as Map);
  if (map['success'] != true) {
    throw DioException(
      requestOptions: res.requestOptions,
      message: map['message']?.toString() ?? 'Request failed',
    );
  }
  final data = map['data'] as List<dynamic>? ?? [];
  return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
}

/// Staff (users) — backend: /api/users (SUPER_ADMIN only).
final staffListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.users);
  return _listFromResponse(res);
});

final staffDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.userById(id));
  final map = Map<String, dynamic>.from(res.data as Map);
  if (map['success'] != true) {
    throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
  }
  return Map<String, dynamic>.from(map['data'] as Map);
});

final coursesListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.courses);
  return _listFromResponse(res);
});

final courseDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.courseById(id));
  final map = Map<String, dynamic>.from(res.data as Map);
  if (map['success'] != true) {
    throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
  }
  return Map<String, dynamic>.from(map['data'] as Map);
});

final subjectsListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.subjects);
  return _listFromResponse(res);
});

final subjectDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.subjectById(id));
  final map = Map<String, dynamic>.from(res.data as Map);
  if (map['success'] != true) {
    throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
  }
  return Map<String, dynamic>.from(map['data'] as Map);
});

/// Admin tests list (all statuses / filters optional via query in screens).
final adminTestsListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.tests);
  return _listFromResponse(res);
});

final promosAdminListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.promos);
  return _listFromResponse(res);
});

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
  final res = await dio.get(ApiEndpoints.resultsForTest(testId));
  return _listFromResponse(res);
});
