import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../common/widgets/error_state.dart';
import '../../common/widgets/loading_widget.dart';
import '../admin_api_providers.dart';
import '../widgets/admin_page_scaffold.dart';

class ManageStaffScreen extends ConsumerWidget {
  const ManageStaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(staffListProvider);

    return AdminPageScaffold(
      title: 'Manage Staff',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/staff/new'),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Add staff'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(staffListProvider),
        child: async.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => ErrorState(message: '$e', onRetry: () => ref.invalidate(staffListProvider)),
          data: (staff) {
            if (staff.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No staff users yet.')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: staff.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final u = staff[i];
                final id = u['_id']?.toString() ?? u['id']?.toString() ?? '';
                final name = u['name']?.toString() ?? '';
                final email = u['email']?.toString() ?? '';
                final role = u['role']?.toString() ?? '';
                final status = u['status']?.toString() ?? '';
                return Card(
                  child: ListTile(
                    title: Text(name),
                    subtitle: Text('$email • $role • $status'),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => context.push('/admin/staff/$id/edit'),
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
