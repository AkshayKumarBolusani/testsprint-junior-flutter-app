import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/domain_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/utils/validators.dart';
import '../../../core/admin/admin_access.dart';
import '../../auth/providers/auth_provider.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';
import '../../common/widgets/dropdown_field.dart';
import '../../student/dashboard/student_api_providers.dart';
import '../widgets/admin_page_scaffold.dart';

/// Edit existing student (PUT /api/students/:id).
class EditStudentScreen extends ConsumerStatefulWidget {
  const EditStudentScreen({super.key, required this.studentId});

  final String studentId;

  @override
  ConsumerState<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends ConsumerState<EditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  String _studentClass = DomainConstants.classLevels.first;
  String _syllabus = DomainConstants.syllabi.first;
  String _status = 'active';
  var _loading = true;
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get(ApiEndpoints.studentById(widget.studentId));
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) throw Exception(map['message']?.toString());
      final s = Map<String, dynamic>.from(map['data'] as Map);
      _name.text = s['name']?.toString() ?? '';
      _phone.text = s['phone']?.toString() ?? '';
      _studentClass = s['studentClass']?.toString() ?? _studentClass;
      _syllabus = s['syllabus']?.toString() ?? _syllabus;
      _status = s['status']?.toString() ?? 'active';
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
      final res = await dio.put(
        ApiEndpoints.studentById(widget.studentId),
        data: {
          'name': _name.text.trim(),
          'phone': _phone.text.trim(),
          'studentClass': _studentClass,
          'syllabus': _syllabus,
          'status': _status,
        },
      );
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) {
        throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
      }
      ref.invalidate(studentsListProvider);
      ref.invalidate(studentDetailProvider(widget.studentId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student updated')));
      context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = AdminAccess.canEditStudentProfile(ref.watch(authNotifierProvider).user);

    if (_loading) {
      return const AdminPageScaffold(
        title: 'Edit student',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!canEdit) {
      return const AdminPageScaffold(
        title: 'Edit student',
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('You do not have permission to edit student profiles.'),
          ),
        ),
      );
    }

    return AdminPageScaffold(
      title: 'Edit student',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              AppTextField(controller: _name, label: 'Full name', validator: (v) => Validators.required(v, 'Name')),
              const SizedBox(height: 12),
              AppTextField(controller: _phone, label: 'Phone (optional)'),
              const SizedBox(height: 12),
              DropdownField<String>(
                label: 'Class',
                value: _studentClass,
                items: DomainConstants.classLevels
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _studentClass = v ?? _studentClass),
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
                items: DomainConstants.userStatus
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _status = v ?? _status),
              ),
              const SizedBox(height: 18),
              AppButton(label: 'Save changes', isLoading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
