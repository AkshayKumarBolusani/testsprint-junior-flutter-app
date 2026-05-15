import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/widgets/premium_card.dart';
import '../../../core/theme/brand_theme_extension.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/loading_widget.dart';
import '../dashboard/student_api_providers.dart';
import '../widgets/student_page_scaffold.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, required this.resultId});

  final String resultId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(resultDetailProvider(resultId));
    final scheme = Theme.of(context).colorScheme;
    final brand = context.brand;

    return StudentPageScaffold(
      title: 'Your result',
      body: async.when(
        loading: () => const LoadingWidget(message: 'Loading result…'),
        error: (e, _) => ErrorState(message: '$e', onRetry: () => ref.invalidate(resultDetailProvider(resultId))),
        data: (r) {
          final scoreNum = num.tryParse(r['score']?.toString() ?? '');
          final totalNum = num.tryParse(r['totalMarks']?.toString() ?? '');
          final score = r['score']?.toString() ?? '';
          final total = r['totalMarks']?.toString() ?? '';
          final correct = r['correctCount']?.toString() ?? '';
          final wrong = r['wrongCount']?.toString() ?? '';
          final unattempted = r['unattemptedCount']?.toString() ?? '';

          final test = Map<String, dynamic>.from(r['testId'] as Map? ?? {});
          final title = test['title']?.toString() ?? 'Test';

          final pct = (scoreNum != null && totalNum != null && totalNum > 0) ? (scoreNum / totalNum).clamp(0.0, 1.0) : 0.0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, AppSpacing.s32),
            children: [
              PremiumCard(
                padding: const EdgeInsets.all(AppSpacing.s24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Score overview', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.s8),
                    Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: AppSpacing.s20),
                    Center(
                      child: SizedBox(
                        width: 132,
                        height: 132,
                        child: Stack(
                          alignment: Alignment.center,
                          fit: StackFit.expand,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: pct),
                              duration: AppDurations.medium,
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) {
                                return CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 10,
                                  backgroundColor: scheme.surfaceContainerHighest,
                                  color: scheme.primary,
                                  strokeCap: StrokeCap.round,
                                );
                              },
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: pct),
                                  duration: AppDurations.medium,
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, _) {
                                    return Text(
                                      '${(value * 100).round()}%',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                                    );
                                  },
                                ),
                                Text(
                                  '$score / $total',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s20),
                    Row(
                      children: [
                        Expanded(
                          child: _StatPill(icon: Icons.check_circle_outline_rounded, label: 'Correct', value: correct, color: brand.success),
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        Expanded(
                          child: _StatPill(icon: Icons.cancel_outlined, label: 'Wrong', value: wrong, color: brand.error),
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        Expanded(
                          child: _StatPill(
                            icon: Icons.remove_circle_outline_rounded,
                            label: 'Skipped',
                            value: unattempted,
                            color: scheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s20),
              const SectionHeader(title: 'Answer review', subtitle: 'Learn from each attempt'),
              ...(r['answers'] as List<dynamic>? ?? []).map((raw) {
                final a = Map<String, dynamic>.from(raw as Map);
                final selected = a['selectedAnswer']?.toString() ?? '';
                final correctAns = a['correctAnswer']?.toString() ?? '';
                final ok = a['isCorrect'] == true;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                  child: PremiumCard(
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              ok ? Icons.check_rounded : Icons.close_rounded,
                              color: ok ? brand.success : brand.error,
                              size: 22,
                            ),
                            const SizedBox(width: AppSpacing.s8),
                            Text(
                              ok ? 'Correct' : 'Review',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: ok ? brand.success : brand.error,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        Text('Your answer: $selected', style: Theme.of(context).textTheme.bodyMedium),
                        Text('Correct answer: $correctAns', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12, horizontal: AppSpacing.s8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: AppSpacing.s4),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
