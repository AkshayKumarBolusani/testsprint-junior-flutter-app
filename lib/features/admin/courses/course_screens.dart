import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/domain_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_message.dart';
import '../../../core/utils/validators.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';
import '../../common/widgets/dropdown_field.dart';
import '../../../core/admin/admin_access.dart';
import '../../auth/providers/auth_provider.dart';
import '../../common/widgets/empty_state.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/loading_widget.dart';
import '../admin_api_providers.dart';
import '../widgets/admin_page_scaffold.dart';

class ManageCoursesScreen extends ConsumerWidget {
  const ManageCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(coursesListProvider);
    final user = ref.watch(authNotifierProvider).user;
    final canAuthor = AdminAccess.canAuthorCourseSubjectQuestionTest(user);

    return AdminPageScaffold(
      title: 'Manage Courses',
      floatingActionButton: canAuthor
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/admin/courses/new'),
              icon: const Icon(Icons.add),
              label: const Text('Add course'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(coursesListProvider),
        child: async.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => ErrorState(message: '$e', onRetry: () => ref.invalidate(coursesListProvider)),
          data: (rows) {
            if (rows.isEmpty) return const EmptyState(title: 'No courses');
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = rows[i];
                final id = c['_id']?.toString() ?? '';
                final title = c['title']?.toString() ?? '';
                final cl = c['classLevel']?.toString() ?? '';
                final syll = c['syllabus']?.toString() ?? '';
                final st = c['status']?.toString() ?? '';
                return Card(
                  child: ListTile(
                    title: Text(title),
                    subtitle: Text('$cl • $syll • $st'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/admin/courses/$id/edit'),
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

class AddEditCourseScreen extends ConsumerStatefulWidget {
  const AddEditCourseScreen({super.key, this.courseId});

  final String? courseId;

  @override
  ConsumerState<AddEditCourseScreen> createState() => _AddEditCourseScreenState();
}

class _AddEditCourseScreenState extends ConsumerState<AddEditCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();

  String _classLevel = DomainConstants.classLevels.first;
  String _syllabus = DomainConstants.syllabi.first;
  String _status = DomainConstants.contentStatus.first;
  final Set<String> _subjectIds = {};

  var _loading = false;
  var _saving = false;

  bool get _edit => widget.courseId != null;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
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

  Future<void> _load() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get(ApiEndpoints.courseById(widget.courseId!));
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) throw Exception(map['message']?.toString());
      final c = Map<String, dynamic>.from(map['data'] as Map);
      _title.text = c['title']?.toString() ?? '';
      _description.text = c['description']?.toString() ?? '';
      _classLevel = c['classLevel']?.toString() ?? _classLevel;
      _syllabus = c['syllabus']?.toString() ?? _syllabus;
      _status = c['status']?.toString() ?? _status;
      _subjectIds.clear();
      final subs = c['subjects'];
      if (subs is List) {
        for (final s in subs) {
          if (s is Map) {
            _subjectIds.add(s['_id']?.toString() ?? '');
          } else {
            _subjectIds.add(s.toString());
          }
        }
      }
      _subjectIds.removeWhere((e) => e.isEmpty);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(messageFromDio(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _filteredSubjects(AsyncValue<List<Map<String, dynamic>>> async) {
    return async.maybeWhen(
      data: (list) => list
          .where((s) => s['classLevel']?.toString() == _classLevel && s['syllabus']?.toString() == _syllabus)
          .toList(),
      orElse: () => [],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      final body = {
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'classLevel': _classLevel,
        'syllabus': _syllabus,
        'status': _status,
        'subjects': _subjectIds.toList(),
      };
      final Response res;
      if (_edit) {
        res = await dio.put(ApiEndpoints.courseById(widget.courseId!), data: body);
      } else {
        res = await dio.post(ApiEndpoints.courses, data: body);
      }
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) {
        throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
      }
      ref.invalidate(coursesListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_edit ? 'Course updated' : 'Course created')));
      context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(messageFromDio(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete course?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.delete(ApiEndpoints.courseById(widget.courseId!));
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) {
        throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
      }
      ref.invalidate(coursesListProvider);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(messageFromDio(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _edit ? 'Edit course' : 'Add course';
    if (_edit && _loading) {
      return AdminPageScaffold(
        title: title,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final subjectsAsync = ref.watch(subjectsListProvider);
    final filtered = _filteredSubjects(subjectsAsync);
    final canAuthor = AdminAccess.canAuthorCourseSubjectQuestionTest(ref.watch(authNotifierProvider).user);

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
                label: 'Status',
                value: _status,
                items: DomainConstants.contentStatus
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _status = v ?? _status),
              ),
              const SizedBox(height: 16),
              Text('Linked subjects ($_classLevel / $_syllabus)', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              if (subjectsAsync.isLoading) const LinearProgressIndicator(),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: filtered.map((s) {
                  final id = s['_id']?.toString() ?? '';
                  final name = s['name']?.toString() ?? '';
                  final on = _subjectIds.contains(id);
                  return FilterChip(
                    label: Text(name),
                    selected: on,
                    onSelected: canAuthor
                        ? (v) => setState(() {
                              if (v) {
                                _subjectIds.add(id);
                              } else {
                                _subjectIds.remove(id);
                              }
                            })
                        : null,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              if (canAuthor) ...[
                AppButton(label: _edit ? 'Save' : 'Create', isLoading: _saving, onPressed: _save),
                if (_edit) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete course'),
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
