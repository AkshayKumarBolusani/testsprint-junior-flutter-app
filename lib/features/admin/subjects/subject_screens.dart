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
import '../../../core/admin/admin_access.dart';
import '../../auth/providers/auth_provider.dart';
import '../admin_api_providers.dart';
import '../widgets/admin_page_scaffold.dart';

class ManageSubjectsScreen extends ConsumerWidget {
  const ManageSubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(subjectsListProvider);
    final user = ref.watch(authNotifierProvider).user;
    final canAuthor = AdminAccess.canAuthorCourseSubjectQuestionTest(user);

    return AdminPageScaffold(
      title: 'Manage Subjects',
      floatingActionButton: canAuthor
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/admin/subjects/new'),
              icon: const Icon(Icons.add),
              label: const Text('Add subject'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(subjectsListProvider),
        child: async.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => ErrorState(message: '$e', onRetry: () => ref.invalidate(subjectsListProvider)),
          data: (rows) {
            if (rows.isEmpty) return const EmptyState(title: 'No subjects');
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final s = rows[i];
                final id = s['_id']?.toString() ?? '';
                final name = s['name']?.toString() ?? '';
                final cl = s['classLevel']?.toString() ?? '';
                final syll = s['syllabus']?.toString() ?? '';
                final st = s['status']?.toString() ?? '';
                return Card(
                  child: ListTile(
                    title: Text(name),
                    subtitle: Text('$cl • $syll • $st'),
                    onTap: () => context.push('/admin/subjects/$id/edit'),
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

class AddEditSubjectScreen extends ConsumerStatefulWidget {
  const AddEditSubjectScreen({super.key, this.subjectId});

  final String? subjectId;

  @override
  ConsumerState<AddEditSubjectScreen> createState() => _AddEditSubjectScreenState();
}

class _AddEditSubjectScreenState extends ConsumerState<AddEditSubjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();

  String _classLevel = DomainConstants.classLevels.first;
  String _syllabus = DomainConstants.syllabi.first;
  String _status = DomainConstants.contentStatus.first;

  var _loading = false;
  var _saving = false;

  bool get _edit => widget.subjectId != null;

  @override
  void dispose() {
    _name.dispose();
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
      final res = await dio.apiGet(ApiEndpoints.subjectById(widget.subjectId!));
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) throw Exception(map['message']?.toString());
      final s = Map<String, dynamic>.from(map['data'] as Map);
      _name.text = s['name']?.toString() ?? '';
      _classLevel = s['classLevel']?.toString() ?? _classLevel;
      _syllabus = s['syllabus']?.toString() ?? _syllabus;
      _status = s['status']?.toString() ?? _status;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      final body = {
        'name': _name.text.trim(),
        'classLevel': _classLevel,
        'syllabus': _syllabus,
        'status': _status,
      };
      final Response res;
      if (_edit) {
        res = await dio.apiPut(ApiEndpoints.subjectById(widget.subjectId!), data: body);
      } else {
        res = await dio.apiPost(ApiEndpoints.subjects, data: body);
      }
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) {
        throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
      }
      ref.invalidate(subjectsListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_edit ? 'Subject updated' : 'Subject created')));
      context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete subject?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.apiDelete(ApiEndpoints.subjectById(widget.subjectId!));
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) {
        throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
      }
      ref.invalidate(subjectsListProvider);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _edit ? 'Edit subject' : 'Add subject';
    final canAuthor = AdminAccess.canAuthorCourseSubjectQuestionTest(ref.watch(authNotifierProvider).user);

    if (_edit && _loading) {
      return AdminPageScaffold(
        title: title,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return AdminPageScaffold(
      title: title,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              AppTextField(
                controller: _name,
                label: 'Subject name',
                validator: (v) => Validators.required(v, 'Name'),
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
                label: 'Status',
                value: _status,
                items: DomainConstants.contentStatus
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _status = v ?? _status),
              ),
              const SizedBox(height: 24),
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
