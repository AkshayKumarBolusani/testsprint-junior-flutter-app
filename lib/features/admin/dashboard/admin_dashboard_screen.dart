import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/admin/admin_access.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/widgets/dashboard_shimmer.dart';
import '../../../core/design/widgets/premium_card.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_message.dart';
import '../../../core/theme/brand_theme_extension.dart';
import '../../auth/providers/auth_provider.dart';
import '../../common/widgets/error_state.dart';
import '../../../core/widgets/drawer_menu_leading.dart';
import '../../student/dashboard/student_api_providers.dart';
import '../widgets/admin_drawer.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final user = auth.user;

    final dash = ref.watch(adminDashboardProvider);

    return Scaffold(
      drawer: const AdminDrawer(),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminDashboardProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              pinned: true,
              leading: const DrawerMenuLeading(),
              leadingWidth: DrawerMenuLeading.widthFor(context),
              automaticallyImplyLeading: false,
              actions: [
                if (AdminAccess.showSeedDatabase(user))
                  IconButton(
                    tooltip: 'Seed sample data',
                    onPressed: () => _runAdminSeed(context, ref),
                    icon: const Icon(Icons.auto_awesome),
                  ),
                IconButton(
                  onPressed: () => context.push('/settings'),
                  icon: const Icon(Icons.tune_outlined),
                ),
              ],
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Operations'),
                  if (user != null)
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s16, 0, AppSpacing.s16, AppSpacing.s32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (user != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
                      child: Text(
                        '${user.name} · ${user.role}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  dash.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.s24),
                      child: DashboardShimmer(),
                    ),
                    error: (e, _) => ErrorState(
                      message: '$e',
                      onRetry: () => ref.invalidate(adminDashboardProvider),
                    ),
                    data: (data) => _AdminBody(data: data, user: user),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminBody extends StatelessWidget {
  const _AdminBody({required this.data, required this.user});

  final Map<String, dynamic> data;
  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final brand = context.brand;

    final students = data['totalStudents']?.toString() ?? '0';
    final active = data['activeStudents']?.toString() ?? '0';
    final tests = data['totalTests']?.toString() ?? '0';
    final published = data['publishedTests']?.toString() ?? '0';
    final results = data['totalResults']?.toString() ?? '0';

    final classWise = data['classWiseStudents'] as List<dynamic>? ?? [];
    final buckets = classWise
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((m) => m['count'] != null)
        .toList();
    final maxCount = buckets.fold<int>(0, (p, m) {
      final c = (m['count'] as num?)?.toInt() ?? 0;
      return c > p ? c : p;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Live KPIs',
          subtitle: 'High-level health of your learning program',
        ),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Students',
                value: students,
                icon: Icons.groups_2_outlined,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: _KpiCard(
                label: 'Active',
                value: active,
                icon: Icons.person_search_rounded,
                color: brand.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Tests',
                value: tests,
                icon: Icons.fact_check_outlined,
                color: brand.accentCyan,
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: _KpiCard(
                label: 'Published',
                value: published,
                icon: Icons.publish_rounded,
                color: brand.accentViolet,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        _KpiCard(
          label: 'Results logged',
          value: results,
          icon: Icons.insights_outlined,
          color: scheme.secondary,
        ),
        const SizedBox(height: AppSpacing.s24),
        const SectionHeader(
          title: 'Students by class',
          subtitle: 'Distribution across assigned cohorts',
        ),
        if (buckets.isEmpty)
          PremiumCard(
            child: Text(
              'No student cohort data yet.',
              style: textTheme.bodyMedium,
            ),
          )
        else
          PremiumCard(
            padding: const EdgeInsets.all(AppSpacing.s20),
            child: Column(
              children: buckets.map((row) {
                final label = row['_id']?.toString() ?? '—';
                final count = (row['count'] as num?)?.toInt() ?? 0;
                final ratio = maxCount > 0 ? count / maxCount : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Class $label', style: textTheme.titleSmall),
                          Text('$count', style: textTheme.titleSmall?.copyWith(color: scheme.primary)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 8,
                          backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: AppSpacing.s24),
        _RoleWorkspaceCard(user: user),
        const SectionHeader(
          title: 'Control center',
          subtitle: 'Manage courses, content, and people',
        ),
        if (AdminAccess.showStudents(user))
          _ActionTile(
            title: 'Students',
            subtitle: 'Create, edit, activate/deactivate',
            icon: Icons.badge_outlined,
            onTap: () => context.go('/admin/students'),
          ),
        if (AdminAccess.showStaff(user))
          _ActionTile(
            title: 'Staff',
            subtitle: 'Super admin — team access',
            icon: Icons.admin_panel_settings_outlined,
            onTap: () => context.go('/admin/staff'),
          ),
        if (AdminAccess.showCoursesSubjectsQuestionsTests(user)) ...[
          _ActionTile(
            title: 'Courses',
            subtitle: 'Catalog & structure',
            icon: Icons.menu_book_outlined,
            onTap: () => context.go('/admin/courses'),
          ),
          _ActionTile(
            title: 'Subjects',
            subtitle: 'Subjects under courses',
            icon: Icons.category_outlined,
            onTap: () => context.go('/admin/subjects'),
          ),
          _ActionTile(
            title: 'Tests',
            subtitle: 'Create & publish assessments',
            icon: Icons.assignment_outlined,
            onTap: () => context.go('/admin/tests'),
          ),
          _ActionTile(
            title: 'Questions',
            subtitle: 'Author the question bank',
            icon: Icons.quiz_outlined,
            onTap: () => context.go('/admin/questions'),
          ),
        ],
        if (AdminAccess.showPromos(user))
          _ActionTile(
            title: 'Promos',
            subtitle: 'Banners and announcements',
            icon: Icons.campaign_outlined,
            onTap: () => context.go('/admin/promos'),
          ),
        if (AdminAccess.showAdminResults(user))
          _ActionTile(
            title: 'Results',
            subtitle: 'Review submissions',
            icon: Icons.table_chart_outlined,
            onTap: () => context.go('/admin/results'),
          ),
        if (AdminAccess.showAppSettings(user))
          _ActionTile(
            title: 'App settings',
            subtitle: 'Maintenance, branding, support contacts',
            icon: Icons.settings_suggest_outlined,
            onTap: () => context.go('/admin/app-settings'),
          ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.bodySmall),
                Text(value, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: PremiumCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
        child: Row(
          children: [
            Icon(icon, size: 26),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.s4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45)),
          ],
        ),
      ),
    );
  }
}

/// Short, role-specific guidance so admins understand why some modules are hidden.
class _RoleWorkspaceCard extends StatelessWidget {
  const _RoleWorkspaceCard({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final u = user;
    if (u == null) return const SizedBox.shrink();

    final lines = <String>[];
    switch (u.role) {
      case AdminAccess.contentManager:
        lines.addAll([
          'You build courses, subjects, questions, and tests.',
          'Student accounts are created by Admin or Super Admin under Students.',
        ]);
        break;
      case AdminAccess.supportStaff:
        lines.addAll([
          'You can open Students and Results for the classes assigned to you.',
          'You cannot create students or catalog content; ask an Admin or Super Admin if you need that access.',
        ]);
        break;
      case AdminAccess.admin:
        lines.addAll([
          'Start with Courses for each class and syllabus, then Subjects → Questions → Tests.',
          'If a list is empty, you may still have no courses yet—or your account may be limited to specific classes (Super Admin can adjust Staff access).',
        ]);
        break;
      case AdminAccess.superAdmin:
        lines.addAll([
          'Use the sparkle toolbar action to seed sample catalog data, or add a course manually.',
          'Manage team roles and class access under Staff.',
        ]);
        break;
      default:
        return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s24),
      child: PremiumCard(
        padding: const EdgeInsets.all(AppSpacing.s20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded, color: scheme.primary, size: 22),
                const SizedBox(width: AppSpacing.s8),
                Text(
                  'Your workspace',
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            ...lines.map(
              (l) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, size: 18, color: scheme.primary.withValues(alpha: 0.75)),
                    const SizedBox(width: AppSpacing.s10),
                    Expanded(child: Text(l, style: textTheme.bodyMedium)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _runAdminSeed(BuildContext context, WidgetRef ref) async {
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Seed sample data?'),
      content: const Text(
        'Creates subjects, courses, questions, tests, promos where missing. Safe to run repeatedly.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Run')),
      ],
    ),
  );
  if (go != true || !context.mounted) return;
  try {
    final dio = ref.read(dioProvider);
    final res = await dio.post(ApiEndpoints.seedDatabase);
    final map = Map<String, dynamic>.from(res.data as Map);
    if (map['success'] != true) {
      throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
    }
    ref.invalidate(adminDashboardProvider);
    if (!context.mounted) return;
    final summary = map['data']?.toString() ?? 'OK';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Seed complete: $summary')));
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(messageFromDio(e))));
    }
  }
}
