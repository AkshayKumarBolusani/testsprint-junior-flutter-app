import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/widgets/empty_state.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/loading_widget.dart';
import '../admin_api_providers.dart';
import '../widgets/admin_page_scaffold.dart';

/// Pick a test and view submissions (`GET /api/results/test/:testId`).
class AdminResultsScreen extends ConsumerStatefulWidget {
  const AdminResultsScreen({super.key});

  @override
  ConsumerState<AdminResultsScreen> createState() => _AdminResultsScreenState();
}

class _AdminResultsScreenState extends ConsumerState<AdminResultsScreen> {
  String? _testId;

  @override
  Widget build(BuildContext context) {
    final testsAsync = ref.watch(adminTestsListProvider);

    return AdminPageScaffold(
      title: 'Results (Admin)',
      body: testsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorState(message: '$e', onRetry: () => ref.invalidate(adminTestsListProvider)),
        data: (tests) {
          if (tests.isEmpty) {
            return const EmptyState(title: 'No tests to show results for');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select test',
                    border: OutlineInputBorder(),
                  ),
                  // ignore: deprecated_member_use
                  value: _testId != null && tests.any((t) => t['_id']?.toString() == _testId) ? _testId : null,
                  items: tests
                      .map(
                        (t) => DropdownMenuItem(
                          value: t['_id']?.toString(),
                          child: Text(t['title']?.toString() ?? ''),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _testId = v),
                ),
              ),
              Expanded(
                child: _testId == null
                    ? const Center(child: Text('Choose a test'))
                    : _ResultsList(testId: _testId!),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ResultsList extends ConsumerWidget {
  const _ResultsList({required this.testId});

  final String testId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminResultsForTestProvider(testId));

    return async.when(
      loading: () => const LoadingWidget(),
      error: (e, _) =>
          ErrorState(message: '$e', onRetry: () => ref.invalidate(adminResultsForTestProvider(testId))),
      data: (results) {
        if (results.isEmpty) {
          return const EmptyState(title: 'No submissions yet');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final r = results[i];
            final score = r['score']?.toString() ?? '';
            final tm = r['totalMarks']?.toString() ?? '';
            final student = r['studentId'];
            var name = '—';
            if (student is Map) {
              name = student['name']?.toString() ?? '—';
            }
            final at = r['submittedAt']?.toString() ?? '';
            return ListTile(
              title: Text(name),
              subtitle: Text('Score: $score / $tm\n$at'),
              isThreeLine: true,
            );
          },
        );
      },
    );
  }
}
