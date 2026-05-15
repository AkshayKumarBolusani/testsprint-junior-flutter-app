import 'package:dio/dio.dart';

/// Prefer server `message` JSON over generic Dio wrapper text.
String messageFromDio(Object error, {String fallback = 'Something went wrong'}) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final m = data['message']?.toString().trim();
      if (m != null && m.isNotEmpty) return m;
    }
    final msg = error.message?.trim();
    if (msg != null && msg.isNotEmpty) return msg;
  }
  final s = '$error'.trim();
  return s.isEmpty ? fallback : s;
}
