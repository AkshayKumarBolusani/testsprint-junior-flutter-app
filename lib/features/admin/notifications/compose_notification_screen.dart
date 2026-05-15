import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/domain_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';
import '../../common/widgets/dropdown_field.dart';
import '../widgets/admin_page_scaffold.dart';

/// Admin / super-admin: targeted in-app notification.
class ComposeNotificationScreen extends ConsumerStatefulWidget {
  const ComposeNotificationScreen({super.key});

  @override
  ConsumerState<ComposeNotificationScreen> createState() => _ComposeNotificationScreenState();
}

class _ComposeNotificationScreenState extends ConsumerState<ComposeNotificationScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _studentIds = TextEditingController();

  var _mode = 0;
  String? _targetClass = DomainConstants.classLevels.first;
  String? _syllabus = DomainConstants.syllabi.first;
  var _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _studentIds.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _title.text.trim();
    if (t.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title required')));
      return;
    }
    setState(() => _sending = true);
    try {
      final dio = ref.read(dioProvider);
      final payload = <String, dynamic>{
        'title': t,
        'body': _body.text.trim(),
        'targetRoles': ['STUDENT'],
      };
      if (_mode == 1) {
        final ids = _studentIds.text
            .split(RegExp(r'[\s,;]+'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (ids.isEmpty) {
          throw Exception('Enter at least one student Mongo _id');
        }
        payload['studentIds'] = ids;
      } else {
        payload['targetClass'] = _targetClass!;
        payload['targetSyllabus'] = _syllabus!;
      }

      final res = await dio.apiPost(ApiEndpoints.notifications, data: payload);
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) {
        throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification sent')));
      context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;
    final can = user?.role == 'SUPER_ADMIN' || user?.role == 'ADMIN';
    if (!can) {
      return const AdminPageScaffold(
        title: 'Send notification',
        body: Center(child: Text('Only Admin or Super Admin can send notifications.')),
      );
    }

    return AdminPageScaffold(
      title: 'Send notification',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('By class'), icon: Icon(Icons.school_outlined)),
              ButtonSegment(value: 1, label: Text('By student IDs'), icon: Icon(Icons.person_search_outlined)),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 16),
          AppTextField(controller: _title, label: 'Title', validator: null),
          const SizedBox(height: 12),
          AppTextField(controller: _body, label: 'Message body'),
          const SizedBox(height: 16),
          if (_mode == 0) ...[
            DropdownField<String>(
              label: 'Class',
              value: _targetClass,
              items: DomainConstants.classLevels
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _targetClass = v),
            ),
            const SizedBox(height: 12),
            DropdownField<String>(
              label: 'Syllabus',
              value: _syllabus,
              items: DomainConstants.syllabi
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _syllabus = v),
            ),
          ] else ...[
            TextFormField(
              controller: _studentIds,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Student Mongo _ids (space, comma, or newline separated)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
          const SizedBox(height: 24),
          AppButton(label: 'Send', isLoading: _sending, onPressed: _send),
        ],
      ),
    );
  }
}
