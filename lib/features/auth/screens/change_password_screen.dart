import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/utils/validators.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';
import '../../admin/widgets/admin_page_scaffold.dart';
import '../../auth/providers/auth_provider.dart';
import '../../student/widgets/student_page_scaffold.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  var _loading = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_next.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.apiPost(
        ApiEndpoints.authChangePassword,
        data: {
          'currentPassword': _current.text,
          'newPassword': _next.text,
        },
      );

      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) {
        throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
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
    final user = ref.watch(authNotifierProvider).user;

    final form = Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            AppTextField(
              controller: _current,
              label: 'Current password',
              obscureText: true,
              validator: (v) => Validators.password(v),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _next,
              label: 'New password',
              obscureText: true,
              validator: (v) => (v != null && v.length >= 8) ? null : 'Min 8 characters',
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _confirm,
              label: 'Confirm new password',
              obscureText: true,
              validator: (v) => (v != null && v.isNotEmpty) ? null : 'Required',
            ),
            const Spacer(),
            AppButton(label: 'Update password', isLoading: _loading, onPressed: _submit),
          ],
        ),
      ),
    );

    if (user != null && !user.isStudent) {
      return AdminPageScaffold(title: 'Change password', body: form);
    }
    return StudentPageScaffold(title: 'Change password', body: form);
  }
}
