import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';

/// Side navigation for student-facing screens.
class StudentDrawer extends ConsumerWidget {
  const StudentDrawer({super.key});

  void _go(BuildContext context, String path) {
    Navigator.of(context).pop();
    context.go(path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final current = GoRouterState.of(context).uri.path;
    final scheme = Theme.of(context).colorScheme;

    Widget tile(String title, IconData icon, String path) {
      final selected =
          current == path || (path != '/student/dashboard' && current.startsWith('$path/'));
      return ListTile(
        leading: Icon(icon),
        title: Text(title),
        selected: selected,
        selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.35),
        onTap: () => _go(context, path),
      );
    }

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Learn', style: Theme.of(context).textTheme.titleMedium),
                  if (user != null)
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            const Divider(),
            tile('Home', Icons.home_outlined, '/student/dashboard'),
            tile('Tests', Icons.play_circle_outline_rounded, '/student/tests'),
            tile('Results', Icons.fact_check_outlined, '/student/results'),
            tile('Leaderboard', Icons.emoji_events_outlined, '/student/rankings'),
            tile('Profile', Icons.person_outlined, '/student/profile'),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Announcements'),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/notifications');
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/settings');
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: scheme.error),
              title: Text('Sign out', style: TextStyle(color: scheme.error)),
              onTap: () async {
                Navigator.of(context).pop();
                await ref.read(authNotifierProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
