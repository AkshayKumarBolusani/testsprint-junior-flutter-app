import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/domain_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/utils/validators.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';
import '../../common/widgets/dropdown_field.dart';
import '../../common/widgets/empty_state.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/loading_widget.dart';
import '../../student/dashboard/student_api_providers.dart';
import '../../../core/admin/admin_access.dart';
import '../../auth/providers/auth_provider.dart';
import '../admin_api_providers.dart';
import '../widgets/admin_page_scaffold.dart';

class ManageTestsScreen extends ConsumerWidget {
  const ManageTestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminTestsListProvider);
    final canAuthor = AdminAccess.canAuthorCourseSubjectQuestionTest(ref.watch(authNotifierProvider).user);

    return AdminPageScaffold(
      title: 'Manage Tests',
      floatingActionButton: canAuthor
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/admin/tests/new'),
              icon: const Icon(Icons.add),
              label: const Text('Add test'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminTestsListProvider),
        child: async.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => ErrorState(message: '$e', onRetry: () => ref.invalidate(adminTestsListProvider)),
          data: (rows) {
            if (rows.isEmpty) return const EmptyState(title: 'No tests');
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final t = rows[i];
                final id = t['_id']?.toString() ?? '';
                final title = t['title']?.toString() ?? '';
                final st = t['status']?.toString() ?? '';
                final ty = t['testType']?.toString() ?? '';
                return Card(
                  child: ListTile(
                    title: Text(title),
                    subtitle: Text('$ty • $st'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (st == 'draft' && canAuthor)
                          IconButton(
                            tooltip: 'Publish',
                            icon: const Icon(Icons.publish_outlined),
                            onPressed: () async {
                              try {
                                final dio = ref.read(dioProvider);
                                final res = await dio.apiPatch(ApiEndpoints.testPublish(id));
                                final map = Map<String, dynamic>.from(res.data as Map);
                                if (map['success'] != true) {
                                  throw DioException(
                                    requestOptions: res.requestOptions,
                                    message: map['message']?.toString(),
                                  );
                                }
                                ref.invalidate(adminTestsListProvider);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Published')));
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                                }
                              }
                            },
                          ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => context.push('/admin/tests/$id/edit'),
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

class AddEditTestScreen extends ConsumerStatefulWidget {
  const AddEditTestScreen({super.key, this.testId});

  final String? testId;

  @override
  ConsumerState<AddEditTestScreen> createState() => _AddEditTestScreenState();
}

class _AddEditTestScreenState extends ConsumerState<AddEditTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _duration = TextEditingController(text: '60');
  final _marks = TextEditingController(text: '100');

  String _testType = DomainConstants.testTypes.first;
  String _classLevel = DomainConstants.classLevels.first;
  String _syllabus = DomainConstants.syllabi.first;
  String _status = DomainConstants.testStatus.first;
  String? _subjectId;

  final Set<String> _qIds = {};
  List<Map<String, dynamic>> _questionPool = [];
  var _loadingPool = false;
  var _loadingTest = false;
  var _saving = false;

  bool get _edit => widget.testId != null;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _duration.dispose();
    _marks.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (_edit) {
      _loadingTest = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadTest());
    }
  }

  Future<void> _loadTest() async {
    try {
      final map = await ref.read(testDetailProvider(widget.testId!).future);
      _title.text = map['title']?.toString() ?? '';
      _description.text = map['description']?.toString() ?? '';
      _testType = map['testType']?.toString() ?? _testType;
      _classLevel = map['classLevel']?.toString() ?? _classLevel;
      _syllabus = map['syllabus']?.toString() ?? _syllabus;
      _status = map['status']?.toString() ?? _status;
      _duration.text = map['durationMinutes']?.toString() ?? '60';
      _marks.text = map['totalMarks']?.toString() ?? '100';
      final sub = map['subject'];
      if (sub is Map) {
        _subjectId = sub['_id']?.toString();
      } else {
        _subjectId = map['subject']?.toString();
      }
      _qIds.clear();
      final qs = map['questions'];
      if (qs is List) {
        for (final q in qs) {
          if (q is Map) {
            _qIds.add(q['_id']?.toString() ?? '');
          } else {
            _qIds.add(q.toString());
          }
        }
      }
      _qIds.removeWhere((e) => e.isEmpty);
      await _loadQuestions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loadingTest = false);
    }
  }

  Future<void> _loadQuestions() async {
    if (_subjectId == null) return;
    setState(() => _loadingPool = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.apiGet(
        ApiEndpoints.questions,
        queryParameters: {
          'classLevel': _classLevel,
          'syllabus': _syllabus,
          'subject': _subjectId,
        },
      );
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) throw Exception(map['message']?.toString());
      final data = map['data'] as List<dynamic>? ?? [];
      _questionPool = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loadingPool = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_subjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select subject')));
      return;
    }
    if (_qIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick at least one question')));
      return;
    }
    final dur = int.tryParse(_duration.text.trim());
    final marks = double.tryParse(_marks.text.trim());
    if (dur == null || dur < 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid duration')));
      return;
    }
    if (marks == null || marks < 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid marks')));
      return;
    }

    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      final body = {
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'testType': _testType,
        'classLevel': _classLevel,
        'syllabus': _syllabus,
        'subject': _subjectId,
        'durationMinutes': dur,
        'totalMarks': marks,
        'questions': _qIds.toList(),
        'status': _status,
      };
      final Response res;
      if (_edit) {
        res = await dio.apiPut(ApiEndpoints.testById(widget.testId!), data: body);
      } else {
        res = await dio.apiPost(ApiEndpoints.tests, data: body);
      }
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) {
        throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
      }
      ref.invalidate(adminTestsListProvider);
      if (_edit) ref.invalidate(testDetailProvider(widget.testId!));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_edit ? 'Test updated' : 'Test created')));
      context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.apiDelete(ApiEndpoints.testById(widget.testId!));
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) {
        throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
      }
      ref.invalidate(adminTestsListProvider);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _edit ? 'Edit test' : 'Add test';
    final canAuthor = AdminAccess.canAuthorCourseSubjectQuestionTest(ref.watch(authNotifierProvider).user);

    if (_edit && _loadingTest) {
      return AdminPageScaffold(
        title: title,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final subjects = ref.watch(subjectsListProvider);

    return AdminPageScaffold(
      title: title,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              AppTextField(
                controller: _title,
                label: 'Title',
                validator: (v) => Validators.required(v, 'Title'),
              ),
              const SizedBox(height: 12),
              AppTextField(controller: _description, label: 'Description'),
              const SizedBox(height: 12),
              DropdownField<String>(
                label: 'Test type',
                value: _testType,
                items: DomainConstants.testTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _testType = v ?? _testType),
              ),
              const SizedBox(height: 12),
              DropdownField<String>(
                label: 'Class',
                value: _classLevel,
                items: DomainConstants.classLevels
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _classLevel = v ?? _classLevel;
                  _subjectId = null;
                  _qIds.clear();
                  _questionPool.clear();
                  _loadQuestions();
                }),
              ),
              const SizedBox(height: 12),
              DropdownField<String>(
                label: 'Syllabus',
                value: _syllabus,
                items: DomainConstants.syllabi
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _syllabus = v ?? _syllabus;
                  _subjectId = null;
                  _qIds.clear();
                  _questionPool.clear();
                  _loadQuestions();
                }),
              ),
              const SizedBox(height: 12),
              subjects.when(
                data: (list) {
                  final matching = list
                      .where((s) => s['classLevel']?.toString() == _classLevel && s['syllabus']?.toString() == _syllabus)
                      .toList();
                  return DropdownField<String>(
                    label: 'Subject',
                    value: _subjectId != null && matching.any((s) => s['_id']?.toString() == _subjectId)
                        ? _subjectId
                        : null,
                    items: matching
                        .map(
                          (s) => DropdownMenuItem(
                            value: s['_id']?.toString(),
                            child: Text(s['name']?.toString() ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() {
                      _subjectId = v;
                      _qIds.clear();
                      _loadQuestions();
                    }),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _duration,
                      label: 'Duration (min)',
                      keyboardType: TextInputType.number,
                      validator: (v) => Validators.required(v, 'Duration'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _marks,
                      label: 'Total marks',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => Validators.required(v, 'Marks'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownField<String>(
                label: 'Status',
                value: _status,
                items: DomainConstants.testStatus
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _status = v ?? _status),
              ),
              const SizedBox(height: 16),
              Text('Questions', style: Theme.of(context).textTheme.titleMedium),
              if (_loadingPool) const LinearProgressIndicator(),
              ..._questionPool.map((q) {
                final id = q['_id']?.toString() ?? '';
                final qt = q['questionText']?.toString() ?? '';
                final sel = _qIds.contains(id);
                return CheckboxListTile(
                  value: sel,
                  title: Text(qt, maxLines: 2, overflow: TextOverflow.ellipsis),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _qIds.add(id);
                    } else {
                      _qIds.remove(id);
                    }
                  }),
                );
              }),
              const SizedBox(height: 16),
              if (canAuthor) ...[
                AppButton(label: _edit ? 'Save test' : 'Create test', isLoading: _saving, onPressed: _save),
                if (_edit) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete test'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
