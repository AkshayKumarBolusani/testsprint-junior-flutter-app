import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/auth_session_storage.dart';
import '../../../core/storage/storage_providers.dart';

class UserModel {
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.phone,
    this.assignedClasses = const [],
    this.studentClass,
    this.syllabus,
  });

  /// Normalizes API role strings so routing / RBAC matches the backend enums.
  static String normalizeRole(String? raw) {
    var s = (raw ?? '').trim();
    if (s.isEmpty) return '';
    s = s.toUpperCase().replaceAll(RegExp(r'[\s-]+'), '_');
    while (s.contains('__')) {
      s = s.replaceAll('__', '_');
    }
    const aliases = <String, String>{
      'SUPERADMIN': 'SUPER_ADMIN',
      'CONTENTMANAGER': 'CONTENT_MANAGER',
      'SUPPORTSTAFF': 'SUPPORT_STAFF',
    };
    return aliases[s] ?? s;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: normalizeRole(json['role']?.toString()),
      status: json['status']?.toString() ?? 'active',
      phone: json['phone']?.toString(),
      assignedClasses:
          (json['assignedClasses'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      studentClass: json['studentClass']?.toString(),
      syllabus: json['syllabus']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'email': email,
        'role': role,
        'status': status,
        if (phone != null) 'phone': phone,
        'assignedClasses': assignedClasses,
        if (studentClass != null) 'studentClass': studentClass,
        if (syllabus != null) 'syllabus': syllabus,
      };

  /// `GET /api/auth/me` and login payloads use `{ user: {...}, token, ... }`.
  static UserModel fromAuthDataMap(Map<String, dynamic> data) {
    final nested = data['user'];
    if (nested is Map) {
      return UserModel.fromJson(Map<String, dynamic>.from(nested));
    }
    return UserModel.fromJson(Map<String, dynamic>.from(data));
  }

  static Map<String, dynamic> userJsonFromAuthData(Map<String, dynamic> data) {
    final nested = data['user'];
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }
    return Map<String, dynamic>.from(data);
  }

  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final String? phone;
  final List<String> assignedClasses;
  final String? studentClass;
  final String? syllabus;

  bool get isStudent => role == 'STUDENT';

  bool get isStaff =>
      role == 'SUPER_ADMIN' ||
      role == 'ADMIN' ||
      role == 'CONTENT_MANAGER' ||
      role == 'SUPPORT_STAFF';
}

enum AuthPhase { loading, guest, authenticated }

class AuthState {
  const AuthState({
    required this.phase,
    this.user,
    this.token,
  });

  final AuthPhase phase;
  final UserModel? user;
  final String? token;

  static const loading = AuthState(phase: AuthPhase.loading);
  static const guest = AuthState(phase: AuthPhase.guest);

  AuthState copyWith({
    AuthPhase? phase,
    UserModel? user,
    String? token,
  }) {
    return AuthState(
      phase: phase ?? this.phase,
      user: user ?? this.user,
      token: token ?? this.token,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this.ref) : super(AuthState.loading);

  final Ref ref;

  AuthSessionStorage get _session => ref.read(authSessionStorageProvider);

  UserModel? _readCachedUser() {
    final raw = _session.cachedUserJson;
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return null;
      return UserModel.fromJson(Map<String, dynamic>.from(map));
    } catch (_) {
      return null;
    }
  }

  Future<void> bootstrap() async {
    final token = await _session.readToken();
    if (token == null || token.isEmpty) {
      state = AuthState.guest;
      return;
    }

    final cachedUser = _readCachedUser();
    if (cachedUser != null) {
      // Restore instantly — do not wait on /api/auth/me (Express path used to hang).
      state = AuthState(phase: AuthPhase.authenticated, user: cachedUser, token: token);
    }

    try {
      final dio = ref.read(dioProvider);
      final res = await dio.apiGet(ApiEndpoints.authMe);
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) {
        if (res.statusCode == 401) {
          await logout();
        }
        return;
      }
      final data = Map<String, dynamic>.from(map['data'] as Map);
      final user = UserModel.fromAuthDataMap(data);
      await _session.saveSession(
        token: token,
        userJson: UserModel.userJsonFromAuthData(data),
      );
      state = AuthState(phase: AuthPhase.authenticated, user: user, token: token);
    } on DioException catch (e) {
      // Only clear session when the token is actually invalid — not on timeout/offline.
      if (e.response?.statusCode == 401) {
        await logout();
        return;
      }
      if (cachedUser == null) {
        state = AuthState.guest;
      }
    } on TimeoutException {
      if (cachedUser == null) {
        state = AuthState.guest;
      }
    } catch (_) {
      if (cachedUser == null) {
        state = AuthState.guest;
      }
    }
  }

  Future<void> login({required String email, required String password}) async {
    final dio = ref.read(dioProvider);
    final res = await dio.apiPost(
      ApiEndpoints.authLogin,
      data: {'email': email.trim(), 'password': password},
    );

    final map = Map<String, dynamic>.from(res.data as Map);
    if (map['success'] != true) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: map['message']?.toString() ?? 'Login failed',
      );
    }

    final data = Map<String, dynamic>.from(map['data'] as Map);
    final token = data['token']?.toString() ?? '';
    final user = UserModel.fromAuthDataMap(data);
    final userJson = UserModel.userJsonFromAuthData(data);

    state = AuthState(phase: AuthPhase.authenticated, user: user, token: token);
    await _session.saveSession(token: token, userJson: userJson);
    // Best-effort mirror to secure storage (not required for session restore).
    unawaited(ref.read(secureStorageProvider).saveToken(token));
  }

  void replaceUser(UserModel user) {
    final token = state.token;
    if (token == null || token.isEmpty) return;
    state = AuthState(phase: AuthPhase.authenticated, user: user, token: token);
    unawaited(_session.saveSession(token: token, userJson: user.toJson()));
  }

  Future<void> logout() async {
    await _session.clearSession();
    try {
      await ref.read(secureStorageProvider).clearToken();
    } catch (_) {
      /* ignore */
    }
    state = AuthState.guest;
  }

  Future<void> refreshMe() async {
    final token = await _session.readToken();
    if (token == null || token.isEmpty) return;

    try {
      final dio = ref.read(dioProvider);
      final res = await dio.apiGet(ApiEndpoints.authMe);
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) return;
      final data = Map<String, dynamic>.from(map['data'] as Map);
      final user = UserModel.fromAuthDataMap(data);
      await _session.saveSession(
        token: token,
        userJson: UserModel.userJsonFromAuthData(data),
      );
      state = AuthState(phase: AuthPhase.authenticated, user: user, token: token);
    } catch (_) {
      /* ignore */
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

/// Current session user from the server (keeps [authNotifierProvider] in sync for drawer / guards).
final authMeUserProvider = FutureProvider.autoDispose<UserModel>((ref) async {
  final session = ref.read(authNotifierProvider);
  if (session.user != null && session.phase == AuthPhase.authenticated) {
    return session.user!;
  }
  final token = session.token ?? ref.read(authSessionStorageProvider).cachedToken;
  if (token == null || token.isEmpty) {
    throw StateError('Not signed in');
  }
  final dio = ref.read(dioProvider);
  final res = await dio.apiGet(ApiEndpoints.authMe);
  final map = Map<String, dynamic>.from(res.data as Map);
  if (map['success'] != true) {
    throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
  }
  final data = Map<String, dynamic>.from(map['data'] as Map);
  final user = UserModel.fromAuthDataMap(data);
  ref.read(authNotifierProvider.notifier).replaceUser(user);
  return user;
});
