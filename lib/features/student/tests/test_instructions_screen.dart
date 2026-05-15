import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../common/widgets/error_state.dart';
import '../../common/widgets/loading_widget.dart';
import '../dashboard/student_api_providers.dart';
import '../widgets/student_page_scaffold.dart';

class TestInstructionsScreen extends ConsumerWidget {
  const TestInstructionsScreen({super.key, required this.testId});

  final String testId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTest = ref.watch(testDetailProvider(testId));

    return StudentPageScaffold(
      title: 'Instructions',
      body: asyncTest.when(
        loading: () => const LoadingWidget(message: 'Loading test…'),
        error: (e, _) => ErrorState(message: '$e', onRetry: () => ref.invalidate(testDetailProvider(testId))),
        data: (test) {
          final title = test['title']?.toString() ?? 'Test';
          final desc = test['description']?.toString() ?? '';
          final marks = test['totalMarks']?.toString() ?? '';
          final duration = test['durationMinutes']?.toString() ?? '';
          final maxAttempts = test['maxAttempts'] ?? 1;
          final attemptsUsed = test['attemptsUsed'] ?? 0;
          final attemptsRemaining = test['attemptsRemaining'] ?? maxAttempts;
          final canStart = (attemptsRemaining as num) > 0;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text('Duration: $duration minutes • Total marks: $marks'),
                Text('Attempts: $attemptsUsed / $maxAttempts used'),
                const SizedBox(height: 12),
                Text(desc),
                const SizedBox(height: 16),
                const Text(
                  'Leaving the app during a test starts a 10-second countdown, then your test is submitted automatically. '
                  'Screenshots and screen recording are blocked during the attempt.',
                ),
                const Spacer(),
                FilledButton(
                  onPressed: canStart ? () => context.go('/student/tests/$testId/attempt') : null,
                  child: Text(canStart ? 'Start test' : 'No attempts left'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
