import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/loading_widget.dart';
import '../widgets/student_page_scaffold.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authMeUserProvider);

    return StudentPageScaffold(
      title: 'Profile',
      body: me.when(
        loading: () => const LoadingWidget(message: 'Loading profile…'),
        error: (e, _) => ErrorState(
          message: '$e',
          onRetry: () => ref.invalidate(authMeUserProvider),
        ),
        data: (user) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(user.email),
              const SizedBox(height: 8),
              Text('Role: ${user.role}'),
              if (user.isStudent) ...[
                const SizedBox(height: 8),
                Text('Class: ${user.studentClass ?? ''}'),
                Text('Syllabus: ${user.syllabus ?? ''}'),
              ] else ...[
                const SizedBox(height: 8),
                Text('Assigned classes: ${user.assignedClasses.join(', ')}'),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  ref.invalidate(authMeUserProvider);
                  await ref.read(authNotifierProvider.notifier).refreshMe();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile refreshed')));
                  }
                },
                child: const Text('Refresh from server'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
