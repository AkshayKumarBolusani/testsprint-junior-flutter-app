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

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text('Duration: $duration minutes • Total marks: $marks'),
                const SizedBox(height: 12),
                Text(desc),
                const Spacer(),
                FilledButton(
                  onPressed: () => context.go('/student/tests/$testId/attempt'),
                  child: const Text('Start test'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
