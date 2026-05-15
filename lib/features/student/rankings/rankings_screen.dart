import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/widgets/premium_card.dart';
import '../../common/widgets/empty_state.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/loading_widget.dart';
import '../dashboard/student_api_providers.dart';
import '../widgets/student_page_scaffold.dart';

class RankingsScreen extends ConsumerStatefulWidget {
  const RankingsScreen({super.key});

  @override
  ConsumerState<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends ConsumerState<RankingsScreen> {
  String? selectedTestId;

  @override
  Widget build(BuildContext context) {
    final testsAsync = ref.watch(studentAvailableTestsProvider);

    return StudentPageScaffold(
      title: 'Leaderboard',
      body: testsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorState(message: '$e', onRetry: () => ref.invalidate(studentAvailableTestsProvider)),
        data: (tests) {
          final usable = tests
              .map((t) => Map<String, dynamic>.from(t))
              .where((t) => (t['_id']?.toString().isNotEmpty ?? false))
              .toList();

          if (usable.isEmpty) {
            return const EmptyState(title: 'No tests to rank yet');
          }

          selectedTestId ??= usable.first['_id']!.toString();

          final rankingsAsync = ref.watch(rankingsProvider(selectedTestId!));

          return Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PremiumCard(
                  padding: const EdgeInsets.all(AppSpacing.s12),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select test',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    // ignore: deprecated_member_use
                    value: selectedTestId,
                    items: usable
                        .map(
                          (t) => DropdownMenuItem<String>(
                            value: t['_id']!.toString(),
                            child: Text(t['title']?.toString() ?? 'Test', overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedTestId = v),
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                Expanded(
                  child: rankingsAsync.when(
                    loading: () => const LoadingWidget(),
                    error: (e, _) => ErrorState(
                      message: '$e',
                      onRetry: () => ref.invalidate(rankingsProvider(selectedTestId!)),
                    ),
                    data: (rows) {
                      if (rows.isEmpty) {
                        return const EmptyState(title: 'No submissions yet');
                      }

                      final showPodium = rows.length >= 3;
                      final listRows = showPodium ? rows.skip(3).toList() : rows;

                      return ListView(
                        children: [
                          if (showPodium) _Podium(rows: rows.take(3).toList()),
                          if (showPodium) const SizedBox(height: AppSpacing.s16),
                          ...listRows.asMap().entries.map(
                            (e) {
                              final idx = e.key + (showPodium ? 3 : 0);
                              final row = e.value;
                              final rank = row['rank']?.toString() ?? '${idx + 1}';
                              final name = row['studentName']?.toString() ?? '';
                              final score = row['score']?.toString() ?? '';
                              final highlight = idx < 3;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.s10),
                                child: PremiumCard(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
                                  child: Row(
                                    children: [
                                      _RankBadge(rank: rank, emphasize: highlight),
                                      const SizedBox(width: AppSpacing.s12),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: Theme.of(context).textTheme.titleSmall,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        score,
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.rows});

  final List<dynamic> rows;

  @override
  Widget build(BuildContext context) {
    // rows order from API: expect rank 1,2,3 in first three entries
    final second = Map<String, dynamic>.from(rows[1] as Map);
    final first = Map<String, dynamic>.from(rows[0] as Map);
    final third = Map<String, dynamic>.from(rows[2] as Map);

    Widget tile(Map<String, dynamic> row, double height, Color accent) {
      final name = row['studentName']?.toString() ?? '';
      final score = row['score']?.toString() ?? '';
      return Expanded(
        child: PremiumCard(
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: SizedBox(
            height: height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.s4),
                Text(score, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: accent)),
              ],
            ),
          ),
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        tile(second, 100, scheme.secondary),
        const SizedBox(width: AppSpacing.s8),
        tile(first, 124, scheme.primary),
        const SizedBox(width: AppSpacing.s8),
        tile(third, 88, scheme.tertiary),
      ],
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, required this.emphasize});

  final String rank;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: emphasize ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      ),
      child: Text(
        rank,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: emphasize ? scheme.onPrimaryContainer : scheme.onSurface,
            ),
      ),
    );
  }
}
