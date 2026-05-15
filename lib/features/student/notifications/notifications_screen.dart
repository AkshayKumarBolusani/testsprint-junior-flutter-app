import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/widgets/premium_card.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/loading_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../../admin/widgets/admin_page_scaffold.dart';
import '../dashboard/student_api_providers.dart';
import '../widgets/student_page_scaffold.dart';

/// In-app announcements from [GET /api/notifications] (server-filtered by role/class).
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsListProvider);
    final user = ref.watch(authNotifierProvider).user;

    final body = async.when(
        loading: () => const LoadingWidget(message: 'Loading announcements…'),
        error: (e, _) => ErrorState(
          message: '$e',
          onRetry: () => ref.invalidate(notificationsListProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s24),
                child: Text(
                  'No announcements yet.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.s16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s12),
            itemBuilder: (context, i) {
              final n = items[i];
              final title = n['title']?.toString() ?? '';
              final body = n['body']?.toString() ?? '';
              final created = n['createdAt']?.toString();
              String? when;
              if (created != null) {
                try {
                  when = DateFormat.yMMMd().add_jm().format(DateTime.parse(created).toLocal());
                } catch (_) {}
              }
              return PremiumCard(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    if (when != null) ...[
                      const SizedBox(height: AppSpacing.s4),
                      Text(when, style: Theme.of(context).textTheme.bodySmall),
                    ],
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s12),
                      Text(body, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ],
                ),
              );
            },
          );
        },
    );

    if (user != null && !user.isStudent) {
      return AdminPageScaffold(title: 'Announcements', body: body);
    }
    return StudentPageScaffold(title: 'Announcements', body: body);
  }
}
