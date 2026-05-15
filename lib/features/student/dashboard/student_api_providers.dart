import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

final studentDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.studentDashboard);
  final map = Map<String, dynamic>.from(res.data as Map);
  if (map['success'] != true) {
    throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
  }
  return Map<String, dynamic>.from(map['data'] as Map);
});

final adminDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.adminDashboard);
  final map = Map<String, dynamic>.from(res.data as Map);
  if (map['success'] != true) {
    throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
  }
  return Map<String, dynamic>.from(map['data'] as Map);
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
