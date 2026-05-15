import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../common/widgets/empty_state.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/loading_widget.dart';
import '../dashboard/student_api_providers.dart';
import '../widgets/student_page_scaffold.dart';

class StudentResultsScreen extends ConsumerWidget {
  const StudentResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentResultsProvider);

    return StudentPageScaffold(
      title: 'Results',
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(studentResultsProvider),
        child: async.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => ErrorState(message: '$e', onRetry: () => ref.invalidate(studentResultsProvider)),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(title: 'No results yet');
            }

            final df = DateFormat.yMMMd().add_jm();

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final r = items[idx];
                final id = r['_id']?.toString() ?? '';
                final score = r['score']?.toString() ?? '';
                final total = r['totalMarks']?.toString() ?? '';

                final test = Map<String, dynamic>.from(r['testId'] as Map? ?? {});
                final title = test['title']?.toString() ?? 'Test';

                final submittedRaw = r['submittedAt'];
                DateTime? submitted;
                if (submittedRaw is String) {
                  submitted = DateTime.tryParse(submittedRaw);
                }

                return Card(
                  child: ListTile(
                    title: Text(title),
                    subtitle: Text('Score: $score / $total • ${submitted == null ? '' : df.format(submitted.toLocal())}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/student/results/$id'),
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
