import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists in-progress attempt when the app is backgrounded or killed.
abstract final class TestAttemptSession {
  static const _key = 'testsprint_active_attempt';
  static const quitGraceSeconds = 10;

  static Future<void> save({
    required String testId,
    required Map<String, dynamic> answers,
    required int secondsRemaining,
    required DateTime quitAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'testId': testId,
        'answers': answers,
        'secondsRemaining': secondsRemaining,
        'quitAt': quitAt.toUtc().toIso8601String(),
      }),
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<ActiveAttempt?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return ActiveAttempt(
        testId: map['testId']?.toString() ?? '',
        answers: Map<String, dynamic>.from(map['answers'] as Map? ?? {}),
        secondsRemaining: (map['secondsRemaining'] as num?)?.toInt() ?? 0,
        quitAt: DateTime.tryParse(map['quitAt']?.toString() ?? '') ?? DateTime.now(),
      );
    } catch (_) {
      await clear();
      return null;
    }
  }
}

class ActiveAttempt {
  const ActiveAttempt({
    required this.testId,
    required this.answers,
    required this.secondsRemaining,
    required this.quitAt,
  });

  final String testId;
  final Map<String, dynamic> answers;
  final int secondsRemaining;
  final DateTime quitAt;

  int secondsSinceQuit() => DateTime.now().difference(quitAt).inSeconds;

  bool shouldAutoSubmit() => secondsSinceQuit() >= TestAttemptSession.quitGraceSeconds;

  int countdownRemaining() =>
      (TestAttemptSession.quitGraceSeconds - secondsSinceQuit()).clamp(0, TestAttemptSession.quitGraceSeconds);
}
