import 'package:flutter/material.dart';

import '../../theme/brand_theme_extension.dart';
import '../design_tokens.dart';

class GradientPrimaryButton extends StatelessWidget {
  const GradientPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final gradient = context.brand.primaryGradient;
    final borderRadius = BorderRadius.circular(AppRadius.sm);

    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              splashColor: Colors.white.withValues(alpha: 0.2),
              highlightColor: Colors.white.withValues(alpha: 0.08),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: enabled
                      ? gradient
                      : LinearGradient(
                          colors: [
                            Colors.grey.shade400,
                            Colors.grey.shade500,
                          ],
                        ),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: AppDurations.fast,
                    child: isLoading
                        ? const SizedBox(
                            key: ValueKey('l'),
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            key: const ValueKey('t'),
                            label,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
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
