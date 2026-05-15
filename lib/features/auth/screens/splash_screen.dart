import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/theme/brand_theme_extension.dart';
import '../../common/widgets/app_logo.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: AppDurations.medium)..forward();
  late final Animation<double> _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authNotifierProvider.notifier).bootstrap();
      if (!mounted) return;

      final auth = ref.read(authNotifierProvider);
      final router = GoRouter.of(context);

      if (auth.phase == AuthPhase.guest) {
        router.go('/login');
        return;
      }

      if (auth.phase == AuthPhase.authenticated && auth.user != null) {
        router.go(auth.user!.isStudent ? '/student/dashboard' : '/admin/dashboard');
        return;
      }

      router.go('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = context.brand;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.surface,
              scheme.primary.withValues(alpha: 0.09),
              AppColors.darkBg.withValues(alpha: scheme.brightness == Brightness.dark ? 0.4 : 0),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _controller,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: 'app_logo',
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: brand.cardShadow,
                      ),
                      child: const AppLogo(size: 96),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  Text(
                    'TestSprint Junior',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    'Preparing your workspace…',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.s32),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
