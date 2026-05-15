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
import '../admin_api_providers.dart';
import '../widgets/admin_page_scaffold.dart';

/// [staffId] null => create (`/admin/staff/new`), non-null => edit.
class AddEditStaffScreen extends ConsumerStatefulWidget {
  const AddEditStaffScreen({super.key, this.staffId});

  final String? staffId;

  @override
  ConsumerState<AddEditStaffScreen> createState() => _AddEditStaffScreenState();
}

class _AddEditStaffScreenState extends ConsumerState<AddEditStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _pwdReset = TextEditingController();

  String _role = DomainConstants.staffRoles.first;
  String _status = 'active';
  var _allClasses = true;
  final Set<String> _selectedClasses = {};

  var _loading = false;
  var _saving = false;

  bool get _isEdit => widget.staffId != null;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _pwdReset.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    if (!_isEdit) return;
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get(ApiEndpoints.userById(widget.staffId!));
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) throw Exception(map['message']?.toString());
      final u = Map<String, dynamic>.from(map['data'] as Map);
      _name.text = u['name']?.toString() ?? '';
      _email.text = u['email']?.toString() ?? '';
      _phone.text = u['phone']?.toString() ?? '';
      _role = u['role']?.toString() ?? _role;
      _status = u['status']?.toString() ?? 'active';
      final assigned = u['assignedClasses'];
      if (assigned is List) {
        final list = assigned.map((e) => e.toString()).toList();
        if (list.contains(DomainConstants.allClassesSentinel)) {
          _allClasses = true;
          _selectedClasses.clear();
        } else {
          _allClasses = false;
          _selectedClasses
            ..clear()
            ..addAll(list.where((c) => DomainConstants.classLevels.contains(c)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitCreate() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_allClasses && _selectedClasses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one class, or enable all classes')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      final body = <String, dynamic>{
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        'role': _role,
        'phone': _phone.text.trim(),
        'status': _status,
        'allClassesAccess': _allClasses,
        if (!_allClasses) 'assignedClasses': _selectedClasses.toList(),
      };
      final res = await dio.post(ApiEndpoints.usersCreate, data: body);
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) {
        throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
      }
      ref.invalidate(staffListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff created')));
      context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.put(
        ApiEndpoints.userById(widget.staffId!),
        data: {
          'name': _name.text.trim(),
          'phone': _phone.text.trim(),
          'status': _status,
        },
      );
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) {
        throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
      }
      ref.invalidate(staffListProvider);
      ref.invalidate(staffDetailProvider(widget.staffId!));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveAccess() async {
    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.patch(
        ApiEndpoints.userAccess(widget.staffId!),
        data: {
          'allClassesAccess': _allClasses,
          if (!_allClasses) 'assignedClasses': _selectedClasses.toList(),
        },
      );
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) {
        throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
      }
      ref.invalidate(staffDetailProvider(widget.staffId!));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Access updated')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_pwdReset.text.trim().length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Min 8 characters')));
      return;
    }
    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.patch(
        ApiEndpoints.userPassword(widget.staffId!),
        data: {'newPassword': _pwdReset.text.trim()},
      );
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) {
        throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
      }
      _pwdReset.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
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
        title: const Text('Delete staff user?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.delete(ApiEndpoints.userById(widget.staffId!));
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) {
        throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
      }
      ref.invalidate(staffListProvider);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? 'Edit staff' : 'Add staff';

    if (_isEdit && _loading) {
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
              AppTextField(controller: _name, label: 'Full name', validator: (v) => Validators.required(v, 'Name')),
              const SizedBox(height: 12),
              if (_isEdit)
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Email'),
                  child: Text(_email.text.isEmpty ? '…' : _email.text),
                )
              else
                AppTextField(
                  controller: _email,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
              if (!_isEdit) ...[
                const SizedBox(height: 12),
                AppTextField(
                  controller: _password,
                  label: 'Password',
                  obscureText: true,
                  validator: (v) => (v != null && v.length >= 8) ? null : 'Min 8 characters',
                ),
              ],
              const SizedBox(height: 12),
              AppTextField(controller: _phone, label: 'Phone (optional)'),
              const SizedBox(height: 12),
              if (!_isEdit)
                DropdownField<String>(
                  label: 'Role',
                  value: _role,
                  items: DomainConstants.staffRoles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => _role = v ?? _role),
                ),
              if (!_isEdit) const SizedBox(height: 12),
              DropdownField<String>(
                label: 'Status',
                value: _status,
                items: DomainConstants.userStatus
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _status = v ?? _status),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Access all classes'),
                value: _allClasses,
                onChanged: (v) => setState(() => _allClasses = v),
              ),
              if (!_allClasses)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: DomainConstants.classLevels.map((c) {
                      final sel = _selectedClasses.contains(c);
                      return FilterChip(
                        label: Text(c),
                        selected: sel,
                        onSelected: (on) => setState(() {
                          if (on) {
                            _selectedClasses.add(c);
                          } else {
                            _selectedClasses.remove(c);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 8),
              if (_isEdit) ...[
                AppButton(label: 'Save profile', isLoading: _saving, onPressed: _saveProfile),
                const SizedBox(height: 12),
                AppButton(label: 'Save class access', isLoading: _saving, onPressed: _saveAccess),
                const SizedBox(height: 24),
                const Text('Reset password', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                AppTextField(controller: _pwdReset, label: 'New password', obscureText: true),
                const SizedBox(height: 8),
                AppButton(label: 'Apply new password', isLoading: _saving, onPressed: _resetPassword),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete user'),
                ),
              ] else
                AppButton(label: 'Create staff', isLoading: _saving, onPressed: _submitCreate),
            ],
          ),
        ),
      ),
    );
  }
}
