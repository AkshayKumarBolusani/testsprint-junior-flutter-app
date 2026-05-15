import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/admin/admin_access.dart';
import '../../../core/design/widgets/premium_card.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/network/dio_message.dart';
import '../../auth/providers/auth_provider.dart';
import '../../common/widgets/empty_state.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/loading_widget.dart';
import '../../student/dashboard/student_api_providers.dart';
import '../widgets/admin_page_scaffold.dart';

class ManageStudentsScreen extends ConsumerWidget {
  const ManageStudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentsListProvider);
    final user = ref.watch(authNotifierProvider).user;
    final canAdd = AdminAccess.canCreateStudent(user);

    return AdminPageScaffold(
      title: 'Students',
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/admin/students/new'),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Add student'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(studentsListProvider),
        child: async.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => ErrorState(message: messageFromDio(e), onRetry: () => ref.invalidate(studentsListProvider)),
          data: (students) {
            if (students.isEmpty) {
              return EmptyState(
                title: 'No students yet',
                subtitle: canAdd
                    ? 'Use the Add student button to create the first account in your scope.'
                    : 'Learners assigned to your classes will show up here.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.s16),
              itemCount: students.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s10),
              itemBuilder: (context, idx) {
                final s = students[idx];
                final id = s['_id']?.toString() ?? '';
                final name = s['name']?.toString() ?? '';
                final email = s['email']?.toString() ?? '';
                final cls = s['studentClass']?.toString() ?? '';
                final syllabus = s['syllabus']?.toString() ?? '';

                return PremiumCard(
                  onTap: () => context.push('/admin/students/$id'),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                        child: Text(
                          name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: AppSpacing.s4),
                            Text(
                              email,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.68),
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.s4),
                            Text(
                              '$cls · $syllabus',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ],
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
