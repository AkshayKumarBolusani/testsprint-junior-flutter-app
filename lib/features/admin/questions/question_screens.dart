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
import '../../common/widgets/loading_widget.dart';
import '../../../core/admin/admin_access.dart';
import '../../auth/providers/auth_provider.dart';
import '../admin_api_providers.dart';
import '../widgets/admin_page_scaffold.dart';

class ManageQuestionsScreen extends ConsumerStatefulWidget {
  const ManageQuestionsScreen({super.key});

  @override
  ConsumerState<ManageQuestionsScreen> createState() => _ManageQuestionsScreenState();
}

class _ManageQuestionsScreenState extends ConsumerState<ManageQuestionsScreen> {
  String? _classLevel;
  String? _syllabus;
  String? _subjectId;
  var _pendingOnly = false;

  var _loading = false;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final qp = <String, dynamic>{};
      if (_classLevel != null) qp['classLevel'] = _classLevel;
      if (_syllabus != null) qp['syllabus'] = _syllabus;
      if (_subjectId != null) qp['subject'] = _subjectId;
      if (_pendingOnly) qp['reviewStatus'] = 'pending_review';
      final res = await dio.get(ApiEndpoints.questions, queryParameters: qp.isEmpty ? null : qp);
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) throw Exception(map['message']?.toString());
      final data = map['data'] as List<dynamic>? ?? [];
      _rows = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approvePending(Map<String, dynamic> q) async {
    final id = q['_id']?.toString() ?? '';
    if (id.isEmpty) return;
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve short answer'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Correct answer text',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Approve')),
        ],
      ),
    );
    if (!mounted) {
      ctrl.dispose();
      return;
    }
    if (ok != true) {
      ctrl.dispose();
      return;
    }
    final answer = ctrl.text.trim();
    ctrl.dispose();
    if (answer.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter correct answer')));
      return;
    }
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.patch(ApiEndpoints.questionApprove(id), data: {'correctAnswer': answer});
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) {
        throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(map['message']?.toString() ?? 'Approved')),
      );
      await _fetch();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsListProvider);
    final user = ref.watch(authNotifierProvider).user;
    final canAuthor = AdminAccess.canAuthorCourseSubjectQuestionTest(user);
    final canCompose = AdminAccess.showComposeNotification(user);

    return AdminPageScaffold(
      title: 'Manage Questions',
      actions: [
        IconButton(
          tooltip: _pendingOnly ? 'Show all questions' : 'Pending review only',
          icon: Icon(_pendingOnly ? Icons.filter_alt : Icons.filter_alt_outlined),
          onPressed: () {
            setState(() => _pendingOnly = !_pendingOnly);
            _fetch();
          },
        ),
        if (canAuthor)
          IconButton(
            tooltip: 'Bulk import',
            icon: const Icon(Icons.upload_file_outlined),
            onPressed: () => context.push('/admin/questions/bulk'),
          ),
        if (canCompose)
          IconButton(
            tooltip: 'Send notification',
            icon: const Icon(Icons.send_outlined),
            onPressed: () => context.push('/admin/notifications/compose'),
          ),
      ],
      floatingActionButton: canAuthor
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/admin/questions/new'),
              icon: const Icon(Icons.add),
              label: const Text('Add question'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Class filter'),
                        // ignore: deprecated_member_use
                        value: _classLevel,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Any')),
                          ...DomainConstants.classLevels.map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          ),
                        ],
                        onChanged: (v) => setState(() => _classLevel = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Syllabus'),
                        // ignore: deprecated_member_use
                        value: _syllabus,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Any')),
                          ...DomainConstants.syllabi.map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          ),
                        ],
                        onChanged: (v) => setState(() => _syllabus = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                subjects.when(
                  data: (list) {
                    final opts = list
                        .where((s) =>
                            (_classLevel == null || s['classLevel']?.toString() == _classLevel) &&
                            (_syllabus == null || s['syllabus']?.toString() == _syllabus))
                        .toList();
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Subject'),
                      // ignore: deprecated_member_use
                      value: _subjectId,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Any')),
                        ...opts.map((s) => DropdownMenuItem(
                              value: s['_id']?.toString(),
                              child: Text(s['name']?.toString() ?? ''),
                            )),
                      ],
                      onChanged: (v) => setState(() => _subjectId = v),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 8),
                FilledButton(onPressed: _fetch, child: const Text('Apply filters')),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetch,
              child: _loading
                  ? const LoadingWidget()
                  : _rows.isEmpty
                      ? const EmptyState(title: 'No questions')
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _rows.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final q = _rows[i];
                            final id = q['_id']?.toString() ?? '';
                            final text = q['questionText']?.toString() ?? '';
                            final qt = q['questionType']?.toString() ?? '';
                            final review = q['reviewStatus']?.toString() ?? 'approved';
                            final pending = review == 'pending_review';
                            return Card(
                              child: ListTile(
                                title: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
                                subtitle: Text(
                                  pending ? '$qt · pending review' : qt,
                                  style: pending
                                      ? TextStyle(color: Theme.of(context).colorScheme.tertiary)
                                      : null,
                                ),
                                trailing: pending && canAuthor && qt == 'SHORT_ANSWER'
                                    ? IconButton(
                                        tooltip: 'Approve',
                                        icon: const Icon(Icons.check_circle_outline),
                                        onPressed: () => _approvePending(q),
                                      )
                                    : null,
                                onTap: () => context.push('/admin/questions/$id/edit'),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddEditQuestionScreen extends ConsumerStatefulWidget {
  const AddEditQuestionScreen({super.key, this.questionId});

  final String? questionId;

  @override
  ConsumerState<AddEditQuestionScreen> createState() => _AddEditQuestionScreenState();
}

class _AddEditQuestionScreenState extends ConsumerState<AddEditQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _text = TextEditingController();
  final _expl = TextEditingController();
  final _o1 = TextEditingController();
  final _o2 = TextEditingController();
  final _o3 = TextEditingController();
  final _o4 = TextEditingController();
  final _shortCorrect = TextEditingController();

  String _qType = DomainConstants.questionTypes.first;
  String _classLevel = DomainConstants.classLevels.first;
  String _syllabus = DomainConstants.syllabi.first;
  String _difficulty = DomainConstants.difficulties.first;
  String? _subjectId;
  String _tfCorrect = 'True';

  var _loading = false;
  var _saving = false;
  String? _mcqCorrect;
  var _shortPendingReview = false;
  String? _loadedReviewStatus;

  bool get _edit => widget.questionId != null;

  @override
  void dispose() {
    _text.dispose();
    _expl.dispose();
    _o1.dispose();
    _o2.dispose();
    _o3.dispose();
    _o4.dispose();
    _shortCorrect.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (_edit) {
      _loading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  List<String> _mcqOptions() {
    return [_o1.text.trim(), _o2.text.trim(), _o3.text.trim(), _o4.text.trim()].where((e) => e.isNotEmpty).toList();
  }

  Future<void> _load() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get(ApiEndpoints.questionById(widget.questionId!));
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) throw Exception(map['message']?.toString());
      final q = Map<String, dynamic>.from(map['data'] as Map);
      _text.text = q['questionText']?.toString() ?? '';
      _expl.text = q['explanation']?.toString() ?? '';
      _qType = q['questionType']?.toString() ?? _qType;
      _classLevel = q['classLevel']?.toString() ?? _classLevel;
      _syllabus = q['syllabus']?.toString() ?? _syllabus;
      _difficulty = q['difficulty']?.toString() ?? _difficulty;
      final sub = q['subject'];
      if (sub is Map) {
        _subjectId = sub['_id']?.toString();
      } else {
        _subjectId = q['subject']?.toString();
      }
      final opts = q['options'];
      if (opts is List && opts.isNotEmpty) {
        final s = opts.map((e) => e.toString()).toList();
        if (s.isNotEmpty) _o1.text = s[0];
        if (s.length > 1) _o2.text = s[1];
        if (s.length > 2) _o3.text = s[2];
        if (s.length > 3) _o4.text = s[3];
      }
      final ca = q['correctAnswer'];
      if (_qType == 'MCQ') {
        _mcqCorrect = ca?.toString();
      } else if (_qType == 'TRUE_FALSE') {
        _tfCorrect = (ca == true || ca.toString().toLowerCase() == 'true') ? 'True' : 'False';
      } else {
        _shortCorrect.text = ca?.toString() ?? '';
      }
      _loadedReviewStatus = q['reviewStatus']?.toString();
      _shortPendingReview = _qType == 'SHORT_ANSWER' && _loadedReviewStatus == 'pending_review';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  dynamic _buildCorrectAnswer() {
    if (_qType == 'MCQ') return _mcqCorrect ?? '';
    if (_qType == 'TRUE_FALSE') return _tfCorrect;
    return _shortCorrect.text.trim();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_subjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick a subject')));
      return;
    }
    if (_qType == 'MCQ') {
      final opts = _mcqOptions();
      if (opts.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Need at least 2 MCQ options')));
        return;
      }
      if (_mcqCorrect == null || !opts.contains(_mcqCorrect)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick correct option from list')));
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      final base = <String, dynamic>{
        'questionText': _text.text.trim(),
        'questionType': _qType,
        'explanation': _expl.text.trim(),
        'classLevel': _classLevel,
        'syllabus': _syllabus,
        'subject': _subjectId,
        'difficulty': _difficulty,
      };
      if (_qType == 'SHORT_ANSWER' && _shortPendingReview) {
        base['reviewStatus'] = 'pending_review';
        base['correctAnswer'] = '';
      } else {
        base['correctAnswer'] = _buildCorrectAnswer();
        if (_qType == 'SHORT_ANSWER') base['reviewStatus'] = 'approved';
      }
      if (_qType == 'MCQ') {
        base['options'] = _mcqOptions();
      }
      final Response res;
      if (_edit) {
        res = await dio.put(ApiEndpoints.questionById(widget.questionId!), data: base);
      } else {
        res = await dio.post(ApiEndpoints.questions, data: base);
      }
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) {
        throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
      }
      ref.invalidate(subjectsListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_edit ? 'Saved' : 'Created')));
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
      final res = await dio.delete(ApiEndpoints.questionById(widget.questionId!));
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) {
        throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
      }
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _edit ? 'Edit question' : 'Add question';
    final canAuthor = AdminAccess.canAuthorCourseSubjectQuestionTest(ref.watch(authNotifierProvider).user);

    if (_edit && _loading) {
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
                controller: _text,
                label: 'Question text',
                validator: (v) => Validators.required(v, 'Question'),
              ),
              const SizedBox(height: 12),
              DropdownField<String>(
                label: 'Type',
                value: _qType,
                items: DomainConstants.questionTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _qType = v ?? _qType;
                  if (_qType != 'SHORT_ANSWER') _shortPendingReview = false;
                }),
              ),
              const SizedBox(height: 12),
              subjects.when(
                data: (list) {
                  final sid = _subjectId;
                  return DropdownField<String>(
                    label: 'Subject',
                    value: sid,
                    items: list
                        .map(
                          (s) => DropdownMenuItem(
                            value: s['_id']?.toString(),
                            child: Text('${s['name']} (${s['classLevel']})'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _subjectId = v),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
              ),
              const SizedBox(height: 12),
              DropdownField<String>(
                label: 'Class',
                value: _classLevel,
                items: DomainConstants.classLevels
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _classLevel = v ?? _classLevel),
              ),
              const SizedBox(height: 12),
              DropdownField<String>(
                label: 'Syllabus',
                value: _syllabus,
                items: DomainConstants.syllabi
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _syllabus = v ?? _syllabus),
              ),
              const SizedBox(height: 12),
              DropdownField<String>(
                label: 'Difficulty',
                value: _difficulty,
                items: DomainConstants.difficulties
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() => _difficulty = v ?? _difficulty),
              ),
              const SizedBox(height: 12),
              AppTextField(controller: _expl, label: 'Explanation (optional)'),
              if (_qType == 'MCQ') ...[
                const SizedBox(height: 12),
                const Text('MCQ options'),
                AppTextField(controller: _o1, label: 'Option A'),
                AppTextField(controller: _o2, label: 'Option B'),
                AppTextField(controller: _o3, label: 'Option C (opt)'),
                AppTextField(controller: _o4, label: 'Option D (opt)'),
                DropdownField<String>(
                  label: 'Correct answer',
                  value: _mcqCorrect,
                  items: _mcqOptions()
                      .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                      .toList(),
                  onChanged: (v) => setState(() => _mcqCorrect = v),
                ),
              ],
              if (_qType == 'TRUE_FALSE')
                DropdownField<String>(
                  label: 'Correct',
                  value: _tfCorrect,
                  items: const [
                    DropdownMenuItem(value: 'True', child: Text('True')),
                    DropdownMenuItem(value: 'False', child: Text('False')),
                  ],
                  onChanged: (v) => setState(() => _tfCorrect = v ?? _tfCorrect),
                ),
              if (_qType == 'SHORT_ANSWER') ...[
                if (!_edit || _loadedReviewStatus == 'pending_review')
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Submit for staff review'),
                    subtitle: const Text('No correct answer until approved'),
                    value: _shortPendingReview,
                    onChanged: (v) => setState(() => _shortPendingReview = v),
                  ),
                AppTextField(
                  controller: _shortCorrect,
                  label: 'Correct answer text',
                  readOnly: _shortPendingReview,
                  validator: (v) =>
                      _shortPendingReview ? null : Validators.required(v, 'Answer'),
                ),
              ],
              const SizedBox(height: 20),
              if (canAuthor) ...[
                AppButton(label: _edit ? 'Save' : 'Create', isLoading: _saving, onPressed: _save),
                if (_edit) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
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
