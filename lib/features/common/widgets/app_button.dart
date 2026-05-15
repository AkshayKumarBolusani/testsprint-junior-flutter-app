import 'package:flutter/material.dart';

import '../../../core/design/widgets/gradient_primary_button.dart';

class AppButton extends StatelessWidget {
  const AppButton({
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
    return GradientPrimaryButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
    );
  }
}
