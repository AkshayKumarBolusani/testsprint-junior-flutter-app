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

class ManagePromosScreen extends ConsumerWidget {
  const ManagePromosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(promosAdminListProvider);
    final canPromo = AdminAccess.canCreatePromo(ref.watch(authNotifierProvider).user);

    return AdminPageScaffold(
      title: 'Manage Promos',
      floatingActionButton: canPromo
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/admin/promos/new'),
              icon: const Icon(Icons.add),
              label: const Text('Add promo'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(promosAdminListProvider),
        child: async.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => ErrorState(message: '$e', onRetry: () => ref.invalidate(promosAdminListProvider)),
          data: (rows) {
            if (rows.isEmpty) return const EmptyState(title: 'No promos');
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = rows[i];
                final id = p['_id']?.toString() ?? '';
                final title = p['title']?.toString() ?? '';
                final st = p['status']?.toString() ?? '';
                return Card(
                  child: ListTile(
                    title: Text(title),
                    subtitle: Text(st),
                    onTap: () => context.push('/admin/promos/$id/edit'),
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

class AddEditPromoScreen extends ConsumerStatefulWidget {
  const AddEditPromoScreen({super.key, this.promoId});

  final String? promoId;

  @override
  ConsumerState<AddEditPromoScreen> createState() => _AddEditPromoScreenState();
}

class _AddEditPromoScreenState extends ConsumerState<AddEditPromoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _imageUrl = TextEditingController();
  final _ctaText = TextEditingController();
  final _ctaLink = TextEditingController();

  String _status = DomainConstants.contentStatus.first;
  String? _targetClass;

  var _loading = false;
  var _saving = false;

  bool get _edit => widget.promoId != null;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _imageUrl.dispose();
    _ctaText.dispose();
    _ctaLink.dispose();
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
      final map = await ref.read(promoDetailProvider(widget.promoId!).future);
      _title.text = map['title']?.toString() ?? '';
      _description.text = map['description']?.toString() ?? '';
      _imageUrl.text = map['imageUrl']?.toString() ?? '';
      _ctaText.text = map['ctaText']?.toString() ?? '';
      _ctaLink.text = map['ctaLink']?.toString() ?? '';
      _status = map['status']?.toString() ?? _status;
      final tc = map['targetClass'];
      _targetClass = tc?.toString();
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
      final body = <String, dynamic>{
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'imageUrl': _imageUrl.text.trim(),
        'ctaText': _ctaText.text.trim(),
        'ctaLink': _ctaLink.text.trim(),
        'status': _status,
        'targetClass': _targetClass,
      };
      final Response res;
      if (_edit) {
        res = await dio.put('${ApiEndpoints.promos}/${widget.promoId}', data: body);
      } else {
        res = await dio.post(ApiEndpoints.promos, data: body);
      }
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) {
        throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
      }
      ref.invalidate(promosAdminListProvider);
      if (!mounted) return;
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
      final res = await dio.delete('${ApiEndpoints.promos}/${widget.promoId}');
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) {
        throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
      }
      ref.invalidate(promosAdminListProvider);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _edit ? 'Edit promo' : 'Add promo';
    final canPromo = AdminAccess.canCreatePromo(ref.watch(authNotifierProvider).user);

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
                controller: _title,
                label: 'Title',
                validator: (v) => Validators.required(v, 'Title'),
              ),
              const SizedBox(height: 12),
              AppTextField(controller: _description, label: 'Description'),
              const SizedBox(height: 12),
              AppTextField(controller: _imageUrl, label: 'Image URL'),
              const SizedBox(height: 12),
              AppTextField(controller: _ctaText, label: 'CTA text'),
              const SizedBox(height: 12),
              AppTextField(controller: _ctaLink, label: 'CTA link'),
              const SizedBox(height: 12),
              DropdownField<String>(
                label: 'Status',
                value: _status,
                items: DomainConstants.contentStatus
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _status = v ?? _status),
              ),
              const SizedBox(height: 12),
              DropdownField<String?>(
                label: 'Target class',
                value: _targetClass,
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('All classes')),
                  ...DomainConstants.classLevels.map(
                    (c) => DropdownMenuItem(value: c, child: Text(c)),
                  ),
                ],
                onChanged: (v) => setState(() => _targetClass = v),
              ),
              const SizedBox(height: 20),
              if (canPromo) ...[
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
