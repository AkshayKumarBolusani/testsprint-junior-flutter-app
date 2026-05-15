import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../common/widgets/empty_state.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/loading_widget.dart';
import '../dashboard/student_api_providers.dart';
import '../widgets/student_page_scaffold.dart';

class AvailableTestsScreen extends ConsumerWidget {
  const AvailableTestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tests = ref.watch(studentAvailableTestsProvider);

    return StudentPageScaffold(
      title: 'Available tests',
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(studentAvailableTestsProvider),
        child: tests.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => ErrorState(message: '$e', onRetry: () => ref.invalidate(studentAvailableTestsProvider)),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(title: 'No tests available right now');
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final t = items[idx];
                final id = t['_id']?.toString() ?? '';
                final title = t['title']?.toString() ?? 'Test';
                final type = t['testType']?.toString() ?? '';
                final marks = t['totalMarks']?.toString() ?? '';
                final duration = t['durationMinutes']?.toString() ?? '';

                return Card(
                  child: ListTile(
                    title: Text(title),
                    subtitle: Text('$type • $marks marks • $duration min'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/student/tests/$id/instructions'),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

