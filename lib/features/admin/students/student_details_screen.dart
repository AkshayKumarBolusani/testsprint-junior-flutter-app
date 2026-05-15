import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/admin/admin_access.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/widgets/premium_card.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_message.dart';
import '../../../core/theme/brand_theme_extension.dart';
import '../../auth/providers/auth_provider.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/loading_widget.dart';
import '../../student/dashboard/student_api_providers.dart';
import '../widgets/admin_page_scaffold.dart';

class StudentDetailsScreen extends ConsumerWidget {
  const StudentDetailsScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentDetailProvider(studentId));

    return AdminPageScaffold(
      title: 'Student',
      body: async.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorState(
          message: messageFromDio(e),
          onRetry: () => ref.invalidate(studentDetailProvider(studentId)),
        ),
        data: (s) => _DetailsContent(map: s, studentId: studentId),
      ),
    );
  }
}

class _DetailsContent extends ConsumerWidget {
  const _DetailsContent({required this.map, required this.studentId});

  final Map<String, dynamic> map;
  final String studentId;

  Future<void> _setStatus(WidgetRef ref, BuildContext context, String next) async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.apiPatch(
        ApiEndpoints.studentStatus(studentId),
        data: {'status': next},
      );
      final m = Map<String, dynamic>.from(res.data as Map);
      if (m['success'] != true) {
        throw DioException(requestOptions: res.requestOptions, message: m['message']?.toString());
      }
      ref.invalidate(studentDetailProvider(studentId));
      ref.invalidate(studentsListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status set to $next')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(messageFromDio(e))));
      }
    }
  }

  Future<void> _passwordDialog(WidgetRef ref, BuildContext context) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set new password'),
        content: SingleChildScrollView(
          child: AppTextField(
            controller: controller,
            label: 'New password (min 8)',
            obscureText: true,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Update')),
        ],
      ),
    );
    final pwd = controller.text.trim();
    controller.dispose();
    if (ok != true) return;
    if (pwd.length < 8) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password too short')));
      }
      return;
    }
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.apiPatch(
        ApiEndpoints.studentPassword(studentId),
        data: {'newPassword': pwd},
      );
      final m = Map<String, dynamic>.from(res.data as Map);
      if (m['success'] != true) {
        throw DioException(requestOptions: res.requestOptions, message: m['message']?.toString());
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(messageFromDio(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final canEdit = AdminAccess.canEditStudentProfile(user);
    final canResetPassword =
        user?.role == AdminAccess.superAdmin || user?.role == AdminAccess.admin || user?.role == AdminAccess.supportStaff;

    final name = map['name']?.toString() ?? '';
    final email = map['email']?.toString() ?? '';
    final phone = map['phone']?.toString() ?? '';
    final cls = map['studentClass']?.toString() ?? '';
    final syllabus = map['syllabus']?.toString() ?? '';
    final status = map['status']?.toString() ?? '';
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brand = context.brand;
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();

    final active = status.toLowerCase() == 'active';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s16),
      children: [
        PremiumCard(
          padding: const EdgeInsets.all(AppSpacing.s20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: Text(initial, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Student' : name,
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(email, style: textTheme.bodyMedium?.copyWith(color: scheme.onSurface.withValues(alpha: 0.72))),
                    const SizedBox(height: AppSpacing.s12),
                    Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: [
                        Chip(
                          avatar: Icon(
                            active ? Icons.verified_outlined : Icons.pause_circle_outline,
                            size: 18,
                            color: active ? brand.success : scheme.outline,
                          ),
                          label: Text(active ? 'Active' : 'Inactive'),
                          backgroundColor: active ? brand.success.withValues(alpha: 0.12) : scheme.surfaceContainerHighest,
                          side: BorderSide(color: scheme.outline.withValues(alpha: 0.25)),
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                        ),
                        if (cls.isNotEmpty)
                          Chip(
                            label: Text('Class $cls'),
                            visualDensity: VisualDensity.compact,
                            side: BorderSide(color: scheme.outline.withValues(alpha: 0.25)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s20),
        const SectionHeader(
          title: 'Profile',
          subtitle: 'Account details on file',
        ),
        PremiumCard(
          child: Column(
            children: [
              _InfoRow(icon: Icons.email_outlined, label: 'Email', value: email),
              const Divider(height: 1),
              _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: phone.isEmpty ? '—' : phone),
              const Divider(height: 1),
              _InfoRow(icon: Icons.menu_book_outlined, label: 'Syllabus', value: syllabus.isEmpty ? '—' : syllabus),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s24),
        const SectionHeader(
          title: 'Actions',
          subtitle: 'Manage this learner account',
        ),
        if (canEdit) ...[
          AppButton(
            label: 'Edit profile',
            onPressed: () => context.push('/admin/students/$studentId/edit'),
          ),
          const SizedBox(height: AppSpacing.s10),
          AppButton(
            label: active ? 'Deactivate account' : 'Activate account',
            onPressed: () => _setStatus(ref, context, active ? 'inactive' : 'active'),
          ),
          const SizedBox(height: AppSpacing.s10),
        ],
        if (canResetPassword)
          AppButton(
            label: 'Set new password',
            onPressed: () => _passwordDialog(ref, context),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: scheme.primary.withValues(alpha: 0.85)),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(color: scheme.onSurface.withValues(alpha: 0.62)),
                ),
                const SizedBox(height: AppSpacing.s4),
                SelectableText(
                  value,
                  style: textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
