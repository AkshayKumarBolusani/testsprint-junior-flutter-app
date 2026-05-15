import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/drawer_menu_leading.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/widgets/dashboard_shimmer.dart';
import '../../../core/design/widgets/premium_card.dart';
import '../../../core/theme/brand_theme_extension.dart';
import '../../common/widgets/app_logo.dart';
import '../../common/widgets/empty_state.dart';
import '../../common/widgets/error_state.dart';
import '../widgets/student_drawer.dart';
import 'student_api_providers.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dash = ref.watch(studentDashboardProvider);
    final promos = ref.watch(studentPromosProvider);

    return Scaffold(
      drawer: const StudentDrawer(),
      body: RefreshIndicator(
        edgeOffset: 120,
        onRefresh: () async {
          await Future.wait([
            ref.refresh(studentDashboardProvider.future),
            ref.refresh(studentPromosProvider.future),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              floating: true,
              pinned: true,
              expandedHeight: 128,
              leading: const DrawerMenuLeading(),
              leadingWidth: DrawerMenuLeading.widthFor(context),
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  const AppLogo(size: 36),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Text(
                      AppStrings.appName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Tests',
                  onPressed: () => context.go('/student/tests'),
                  icon: const Icon(Icons.play_circle_outline_rounded),
                ),
                IconButton(
                  onPressed: () => context.push('/settings'),
                  icon: const Icon(Icons.tune_rounded),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s16, 0, AppSpacing.s16, AppSpacing.s24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  dash.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.s24),
                      child: DashboardShimmer(),
                    ),
                    error: (e, _) => ErrorState(
                      message: '$e',
                      onRetry: () => ref.invalidate(studentDashboardProvider),
                    ),
                    data: (data) => _StudentDashContent(data: data),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  SectionHeader(
                    title: 'Your promos',
                    subtitle: 'Curated updates from your institute',
                    actionLabel: 'Tests',
                    onAction: () => context.go('/student/tests'),
                  ),
                  promos.when(
                    loading: () => const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator.adaptive()),
                    ),
                    error: (e, _) => PremiumCard(
                      padding: const EdgeInsets.all(AppSpacing.s16),
                      child: Text('Could not load promos. Pull to refresh.', style: Theme.of(context).textTheme.bodyMedium),
                    ),
                    data: (items) {
                      if (items.isEmpty) {
                        return const EmptyState(title: 'No promos right now');
                      }
                      return Column(
                        children: items.map((p) {
                          final title = p['title']?.toString() ?? '';
                          final desc = p['description']?.toString() ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                            child: _PromoBanner(title: title, description: desc),
                          );
                        }).toList(),
                      );
                    },
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

class _StudentDashContent extends StatelessWidget {
  const _StudentDashContent({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = context.brand;
    final textTheme = Theme.of(context).textTheme;

    final profile = Map<String, dynamic>.from(data['profile'] as Map);
    final welcome = profile['name']?.toString() ?? 'Student';
    final cls = profile['studentClass']?.toString() ?? '';
    final syllabus = profile['syllabus']?.toString() ?? '';

    final available = data['availableTestsCount']?.toString() ?? '0';
    final practice = data['practiceTestsCount']?.toString() ?? '0';

    final recentRaw = data['recentResults'] as List<dynamic>? ?? [];
    final recent = recentRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WelcomeHero(
          name: welcome,
          cls: cls,
          syllabus: syllabus,
          accentGradient: brand.primaryGradient,
          scheme: scheme,
          textTheme: textTheme,
        ),
        const SizedBox(height: AppSpacing.s24),
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                icon: Icons.edit_note_rounded,
                label: 'Available',
                value: available,
                caption: 'tests open now',
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: _KpiTile(
                icon: Icons.bolt_rounded,
                label: 'Practice',
                value: practice,
                caption: 'focused sets',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        _StreakHintCard(scheme: scheme, textTheme: textTheme),
        const SizedBox(height: AppSpacing.s24),
        const SectionHeader(
          title: 'Quick access',
          subtitle: 'Move fast — stay in flow',
        ),
        const _QuickAccessGrid(),
        const SizedBox(height: AppSpacing.s24),
        SectionHeader(
          title: 'Continue learning',
          subtitle: recent.isEmpty ? 'Your latest attempts will land here' : 'Pick up where you left off',
          actionLabel: recent.isNotEmpty ? 'All results' : null,
          onAction: recent.isNotEmpty ? () => context.go('/student/results') : null,
        ),
        if (recent.isEmpty)
          PremiumCard(
            child: Row(
              children: [
                Icon(Icons.auto_graph_rounded, color: scheme.primary, size: 28),
                const SizedBox(width: AppSpacing.s16),
                Expanded(
                  child: Text(
                    'Complete a test to see your performance trail and rank insights.',
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: recent.map((r) {
              final testField = r['testId'];
              var title = 'Test';
              if (testField is Map) {
                title = testField['title']?.toString() ?? title;
              }
              final score = r['score']?.toString() ?? '—';
              final total = r['totalMarks']?.toString();
              final scoreLine = total != null ? '$score / $total' : score;

              String? when;
              final rawDate = r['submittedAt'];
              if (rawDate != null) {
                try {
                  when = DateFormat.yMMMd().add_jm().format(DateTime.parse(rawDate.toString()).toLocal());
                } catch (_) {}
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                child: PremiumCard(
                  onTap: () {
                    final id = r['_id']?.toString();
                    if (id != null) context.push('/student/results/$id');
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(Icons.fact_check_rounded, color: scheme.primary),
                      ),
                      const SizedBox(width: AppSpacing.s16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                            if (when != null)
                              Text(when, style: textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(scoreLine, style: textTheme.titleMedium?.copyWith(color: scheme.primary)),
                          Text('Score', style: textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: AppSpacing.s24),
        const SectionHeader(title: 'Performance snapshot', subtitle: 'Keep your momentum visible'),
        Row(
          children: [
            Expanded(
              child: PremiumCard(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.military_tech_outlined, color: brand.accentViolet),
                    const SizedBox(height: AppSpacing.s8),
                    Text('Leaderboard', style: textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      'See how you compare after each test.',
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    TextButton(
                      onPressed: () => context.go('/student/rankings'),
                      child: const Text('Open rankings'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: PremiumCard(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.school_outlined, color: brand.accentCyan),
                    const SizedBox(height: AppSpacing.s8),
                    Text('Your track', style: textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      '$cls • $syllabus',
                      style: textTheme.bodySmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    TextButton(
                      onPressed: () => context.go('/student/profile'),
                      child: const Text('Profile'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({
    required this.name,
    required this.cls,
    required this.syllabus,
    required this.accentGradient,
    required this.scheme,
    required this.textTheme,
  });

  final String name;
  final String cls;
  final String syllabus;
  final LinearGradient accentGradient;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary.withValues(alpha: 0.12),
                      scheme.tertiary.withValues(alpha: 0.06),
                      scheme.surface.withValues(alpha: 0.001),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -20,
              top: -20,
              child: IgnorePointer(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: accentGradient,
                  ),
                  foregroundDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.surface.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back',
                    style: textTheme.labelLarge?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.65),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    name,
                    style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    [if (cls.isNotEmpty) 'Class $cls', if (syllabus.isNotEmpty) syllabus]
                        .join(' · '),
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  FilledButton.icon(
                    onPressed: () => context.go('/student/tests'),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start a test'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary, size: 22),
          const SizedBox(height: AppSpacing.s12),
          Text(label, style: textTheme.bodySmall),
          const SizedBox(height: AppSpacing.s4),
          Text(value, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.s4),
          Text(caption, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _StreakHintCard extends StatelessWidget {
  const _StreakHintCard({required this.scheme, required this.textTheme});

  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              gradient: LinearGradient(
                colors: [
                  scheme.secondary.withValues(alpha: 0.28),
                  scheme.primary.withValues(alpha: 0.18),
                ],
              ),
            ),
            child: Icon(Icons.local_fire_department_outlined, color: scheme.primary, size: 24),
          ),
          const SizedBox(width: AppSpacing.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Study streak', style: textTheme.titleSmall),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  'Consistency builds confidence — take a practice set to keep momentum.',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid();

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickItem(Icons.play_circle_outline_rounded, 'Tests', () => context.go('/student/tests')),
      _QuickItem(Icons.analytics_outlined, 'Results', () => context.go('/student/results')),
      _QuickItem(Icons.emoji_events_outlined, 'Rankings', () => context.go('/student/rankings')),
      _QuickItem(Icons.person_outline_rounded, 'Profile', () => context.go('/student/profile')),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = (constraints.maxWidth - AppSpacing.s12) / 2;
        return Wrap(
          spacing: AppSpacing.s12,
          runSpacing: AppSpacing.s12,
          children: items
              .map(
                (q) => SizedBox(
                  width: w,
                  child: PremiumCard(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16, horizontal: AppSpacing.s12),
                    onTap: q.onTap,
                    child: Column(
                      children: [
                        Icon(q.icon, size: 28),
                        const SizedBox(height: AppSpacing.s8),
                        Text(q.label, style: Theme.of(context).textTheme.labelLarge),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _QuickItem {
  _QuickItem(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PremiumCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.tertiary.withValues(alpha: 0.12),
                      scheme.primary.withValues(alpha: 0.08),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FEATURED', style: textTheme.labelSmall?.copyWith(letterSpacing: 1.4)),
                  const SizedBox(height: AppSpacing.s8),
                  Text(title, style: textTheme.titleMedium),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s8),
                    Text(description, style: textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
