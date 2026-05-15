import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/admin/admin_access.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/loading_widget.dart';
import '../../student/dashboard/student_api_providers.dart';
import '../widgets/admin_page_scaffold.dart';

class AdminAppSettingsScreen extends ConsumerWidget {
  const AdminAppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    if (!AdminAccess.showAppSettings(user)) {
      return const Scaffold(body: Center(child: Text('Access denied')));
    }

    final async = ref.watch(appSettingsAdminProvider);

    return async.when(
      loading: () => const AdminPageScaffold(
        title: 'App settings',
        body: LoadingWidget(message: 'Loading settings…'),
      ),
      error: (e, _) => AdminPageScaffold(
        title: 'App settings',
        body: ErrorState(message: '$e', onRetry: () => ref.invalidate(appSettingsAdminProvider)),
      ),
      data: (m) => _AppSettingsEditor(
        initial: m,
        onSaved: () => ref.invalidate(appSettingsAdminProvider),
      ),
    );
  }
}

class _AppSettingsEditor extends ConsumerStatefulWidget {
  const _AppSettingsEditor({required this.initial, required this.onSaved});

  final Map<String, dynamic> initial;
  final VoidCallback onSaved;

  @override
  ConsumerState<_AppSettingsEditor> createState() => _AppSettingsEditorState();
}

class _AppSettingsEditorState extends ConsumerState<_AppSettingsEditor> {
  late final TextEditingController _appName = TextEditingController(text: widget.initial['appName']?.toString() ?? '');
  late final TextEditingController _maintMsg =
      TextEditingController(text: widget.initial['maintenanceMessage']?.toString() ?? '');
  late final TextEditingController _supportEmail =
      TextEditingController(text: widget.initial['supportEmail']?.toString() ?? '');
  late final TextEditingController _supportPhone =
      TextEditingController(text: widget.initial['supportPhone']?.toString() ?? '');
  late bool _maintenance = widget.initial['maintenanceMode'] == true;
  var _saving = false;

  @override
  void dispose() {
    _appName.dispose();
    _maintMsg.dispose();
    _supportEmail.dispose();
    _supportPhone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.apiPut(
        ApiEndpoints.settingsApp,
        data: {
          'appName': _appName.text.trim(),
          'maintenanceMode': _maintenance,
          'maintenanceMessage': _maintMsg.text.trim(),
          'supportEmail': _supportEmail.text.trim(),
          'supportPhone': _supportPhone.text.trim(),
        },
      );
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) {
        throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
      }
      widget.onSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageScaffold(
      title: 'App settings',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _appName,
            decoration: const InputDecoration(labelText: 'App name'),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Maintenance mode'),
            subtitle: const Text('Show maintenance message to clients when enabled.'),
            value: _maintenance,
            onChanged: (v) => setState(() => _maintenance = v),
          ),
          TextField(
            controller: _maintMsg,
            decoration: const InputDecoration(labelText: 'Maintenance message'),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _supportEmail,
            decoration: const InputDecoration(labelText: 'Support email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _supportPhone,
            decoration: const InputDecoration(labelText: 'Support phone'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Save settings',
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
