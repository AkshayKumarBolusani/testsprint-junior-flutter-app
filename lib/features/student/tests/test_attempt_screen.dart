import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/widgets/gradient_primary_button.dart';
import '../../../core/design/widgets/premium_card.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../common/widgets/confirm_dialog.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/loading_widget.dart';
import '../dashboard/student_api_providers.dart';

// ignore_for_file: deprecated_member_use

class TestAttemptScreen extends ConsumerWidget {
  const TestAttemptScreen({super.key, required this.testId});

  final String testId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTest = ref.watch(testDetailProvider(testId));

    return Scaffold(
      appBar: AppBar(title: const Text('Focus mode')),
      body: asyncTest.when(
        loading: () => const LoadingWidget(message: 'Preparing test…'),
        error: (e, _) => ErrorState(message: '$e', onRetry: () => ref.invalidate(testDetailProvider(testId))),
        data: (test) => _AttemptBody(test: test, testId: testId),
      ),
    );
  }
}

class _AttemptBody extends ConsumerStatefulWidget {
  const _AttemptBody({required this.test, required this.testId});

  final Map<String, dynamic> test;
  final String testId;

  @override
  ConsumerState<_AttemptBody> createState() => _AttemptBodyState();
}

class _AttemptBodyState extends ConsumerState<_AttemptBody> {
  late final List<Map<String, dynamic>> questions;
  int index = 0;
  final Map<String, dynamic> answers = {};

  Timer? timer;
  int secondsRemaining = 0;

  bool submitting = false;

  @override
  void initState() {
    super.initState();
    final raw = widget.test['questions'] as List<dynamic>? ?? [];
    questions = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    final minutes = int.tryParse(widget.test['durationMinutes']?.toString() ?? '') ?? 60;
    secondsRemaining = minutes * 60;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (secondsRemaining <= 1) {
        t.cancel();
        _submit(auto: true);
        return;
      }
      setState(() => secondsRemaining -= 1);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String _fmt(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Future<void> _submit({bool auto = false}) async {
    if (submitting) return;

    if (!auto) {
      final ok = await showConfirmDialog(
        context: context,
        title: 'Submit test?',
        message: 'You cannot change answers after submitting.',
      );
      if (ok != true) return;
    }

    setState(() => submitting = true);

    try {
      final dio = ref.read(dioProvider);
      final payloadAnswers = questions.map((q) {
        final id = q['_id']?.toString() ?? '';
        return {'questionId': id, 'selectedAnswer': answers[id]};
      }).toList();

      final res = await dio.post(
        ApiEndpoints.resultsSubmit,
        data: {
          'testId': widget.testId,
          'answers': payloadAnswers,
        },
      );

      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) {
        throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
      }

      final created = Map<String, dynamic>.from(map['data'] as Map);
      final rid = created['_id']?.toString();
      if (!mounted || rid == null) return;

      context.go('/student/results/$rid');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Center(child: Text('This test has no questions.'));
    }

    final q = questions[index];
    final qid = q['_id']?.toString() ?? '';
    final text = q['questionText']?.toString() ?? '';
    final type = q['questionType']?.toString() ?? 'MCQ';

    Widget questionWidget;

    if (type == 'MCQ') {
      final opts = (q['options'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
      questionWidget = Column(
        children: opts
            .map(
              (o) => RadioListTile<String>(
                value: o,
                groupValue: answers[qid]?.toString(),
                title: Text(o),
                onChanged: submitting
                    ? null
                    : (v) => setState(() {
                          answers[qid] = v;
                        }),
              ),
            )
            .toList(),
      );
    } else if (type == 'TRUE_FALSE') {
      final current = answers[qid]?.toString();
      questionWidget = Column(
        children: [
          RadioListTile<String>(
            title: const Text('True'),
            value: 'True',
            groupValue: current,
            onChanged: submitting ? null : (v) => setState(() => answers[qid] = v),
          ),
          RadioListTile<String>(
            title: const Text('False'),
            value: 'False',
            groupValue: current,
            onChanged: submitting ? null : (v) => setState(() => answers[qid] = v),
          ),
        ],
      );
    } else {
      questionWidget = TextFormField(
        enabled: !submitting,
        initialValue: answers[qid]?.toString() ?? '',
        decoration: const InputDecoration(labelText: 'Your answer'),
        onChanged: (v) => answers[qid] = v,
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final progress = questions.isEmpty ? 0.0 : (index + 1) / questions.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumCard(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          colors: [scheme.primary.withValues(alpha: 0.15), scheme.secondary.withValues(alpha: 0.1)],
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined, size: 18, color: scheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            _fmt(secondsRemaining),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(type, style: Theme.of(context).textTheme.labelLarge),
                  ],
                ),
                const SizedBox(height: AppSpacing.s16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(value: progress, minHeight: 6),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  'Question ${index + 1} of ${questions.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Expanded(
            child: PremiumCard(
              padding: const EdgeInsets.all(AppSpacing.s20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.35)),
                    const SizedBox(height: AppSpacing.s16),
                    questionWidget,
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: submitting || index == 0 ? null : () => setState(() => index -= 1),
                  child: const Text('Previous'),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: FilledButton(
                  onPressed: submitting
                      ? null
                      : () {
                          if (index < questions.length - 1) {
                            setState(() => index += 1);
                          } else {
                            _submit(auto: false);
                          }
                        },
                  child: Text(index < questions.length - 1 ? 'Next' : 'Submit'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          GradientPrimaryButton(
            label: 'Submit now',
            isLoading: submitting,
            onPressed: submitting ? null : () => _submit(auto: false),
          ),
        ],
      ),
    );
  }
}
