import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

class AddEditStudentScreen extends ConsumerStatefulWidget {
  const AddEditStudentScreen({super.key});

  @override
  ConsumerState<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends ConsumerState<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();

  static const _classes = ['5th', '6th', '7th', '8th', '9th', '10th'];
  static const _syllabi = ['Telangana State Board', 'AP State Board', 'CBSE'];

  String _studentClass = _classes.first;
  String _syllabus = _syllabi.first;
  String _status = 'active';

  var _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post(
        ApiEndpoints.studentsCreate,
        data: {
          'name': _name.text.trim(),
          'email': _email.text.trim(),
          'password': _password.text,
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

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student created')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = AdminAccess.canCreateStudent(ref.watch(authNotifierProvider).user);

    return AdminPageScaffold(
      title: 'Add student',
      body: !canCreate
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('You do not have permission to create students.'),
              ),
            )
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              AppTextField(controller: _name, label: 'Full name', validator: (v) => Validators.required(v, 'Name')),
              const SizedBox(height: 12),
              AppTextField(
                controller: _email,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _password,
                label: 'Temporary password',
                obscureText: true,
                validator: (v) => (v != null && v.length >= 8) ? null : 'Min 8 characters',
              ),
              const SizedBox(height: 12),
              AppTextField(controller: _phone, label: 'Phone (optional)'),
              const SizedBox(height: 12),
              DropdownField<String>(
                label: 'Class',
                value: _studentClass,
                items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _studentClass = v ?? _studentClass),
              ),
              const SizedBox(height: 12),
              DropdownField<String>(
                label: 'Syllabus',
                value: _syllabus,
                items: _syllabi.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _syllabus = v ?? _syllabus),
              ),
              const SizedBox(height: 12),
              DropdownField<String>(
                label: 'Status',
                value: _status,
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                ],
                onChanged: (v) => setState(() => _status = v ?? _status),
              ),
              const SizedBox(height: 18),
              AppButton(label: 'Create student', isLoading: _loading, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
