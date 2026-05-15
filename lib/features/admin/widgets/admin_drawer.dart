import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/admin/admin_access.dart';
import '../../auth/providers/auth_provider.dart';

/// Side navigation for all admin modules (role-filtered).
class AdminDrawer extends ConsumerWidget {
  const AdminDrawer({super.key});

  void _go(BuildContext context, String path) {
    Navigator.of(context).pop();
    context.go(path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final current = GoRouterState.of(context).uri.path;
    final scheme = Theme.of(context).colorScheme;

    Widget tile(String title, IconData icon, String path, bool visible) {
      if (!visible) return const SizedBox.shrink();
      final selected = current == path || (path != '/admin/dashboard' && current.startsWith('$path/'));
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
                  Text('Admin console', style: Theme.of(context).textTheme.titleMedium),
                  if (user != null)
                    Text(
                      '${user.name} · ${user.role}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            const Divider(),
            tile('Dashboard', Icons.dashboard_outlined, '/admin/dashboard', true),
            tile('Students', Icons.badge_outlined, '/admin/students', AdminAccess.showStudents(user)),
            tile('Staff', Icons.admin_panel_settings_outlined, '/admin/staff', AdminAccess.showStaff(user)),
            tile('Courses', Icons.menu_book_outlined, '/admin/courses', AdminAccess.showCoursesSubjectsQuestionsTests(user)),
            tile('Subjects', Icons.category_outlined, '/admin/subjects', AdminAccess.showCoursesSubjectsQuestionsTests(user)),
            tile('Questions', Icons.quiz_outlined, '/admin/questions', AdminAccess.showCoursesSubjectsQuestionsTests(user)),
            tile('Bulk import questions', Icons.upload_file_outlined, '/admin/questions/bulk', AdminAccess.canAuthorCourseSubjectQuestionTest(user)),
            tile('Send notification', Icons.send_outlined, '/admin/notifications/compose', AdminAccess.showComposeNotification(user)),
            tile('Tests', Icons.assignment_outlined, '/admin/tests', AdminAccess.showCoursesSubjectsQuestionsTests(user)),
            tile('Promos', Icons.campaign_outlined, '/admin/promos', AdminAccess.showPromos(user)),
            tile('Results', Icons.table_chart_outlined, '/admin/results', AdminAccess.showAdminResults(user)),
            tile('App settings', Icons.settings_suggest_outlined, '/admin/app-settings', AdminAccess.showAppSettings(user)),
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
              title: const Text('Preferences'),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/settings');
              },
            ),
          ],
        ),
      ),
    );
  }
}
