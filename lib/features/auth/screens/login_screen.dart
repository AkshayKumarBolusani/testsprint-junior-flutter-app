import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/network/connectivity_util.dart';
import '../../../core/design/widgets/gradient_primary_button.dart';
import '../../../core/design/widgets/premium_card.dart';
import '../../../core/utils/validators.dart';
import '../../common/widgets/app_logo.dart';
import '../../common/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final online = await deviceHasUsableNetwork();
      if (!online) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No network connection. Turn on Wi‑Fi or mobile data and try again.'),
          ),
        );
        return;
      }
      await ref.read(authNotifierProvider.notifier).login(email: _email.text, password: _password.text);
      final user = ref.read(authNotifierProvider).user;
      if (!mounted) return;
      if (user == null) return;
      context.go(user.isStudent ? '/student/dashboard' : '/admin/dashboard');
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      final data = e.response?.data;
      final serverMsg = data is Map ? data['message']?.toString() : null;
      final rawMsg = e.message ?? '';
      final isTimeout = e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout ||
          rawMsg.contains('receiveTimeout') ||
          rawMsg.contains('connectionTimeout');
      final text = code == 401
          ? 'Wrong password.'
          : isTimeout
              ? 'The server took too long to respond. Check your connection, or try again in a moment (the API may be waking up).'
              : (serverMsg != null && serverMsg.isNotEmpty)
                  ? serverMsg
                  : (rawMsg.isNotEmpty)
                      ? rawMsg
                      : 'Login failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surface,
              scheme.primary.withValues(alpha: 0.05),
              scheme.tertiary.withValues(alpha: 0.06),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.s20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Hero(
                        tag: 'app_logo',
                        child: AppLogo(size: 88),
                      ),
                      const SizedBox(height: AppSpacing.s24),
                      Text(
                        AppStrings.loginTitle,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      Text(AppStrings.loginSubtitle, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: AppSpacing.s24),
                      PremiumCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextField(
                              controller: _email,
                              label: 'Email',
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.email,
                            ),
                            const SizedBox(height: AppSpacing.s14),
                            AppTextField(
                              controller: _password,
                              label: 'Password',
                              obscureText: true,
                              validator: Validators.password,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => context.push('/forgot-password'),
                                child: const Text('Need help signing in?'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s20),
                      GradientPrimaryButton(
                        label: 'Sign in',
                        isLoading: _loading,
                        onPressed: _loading ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
