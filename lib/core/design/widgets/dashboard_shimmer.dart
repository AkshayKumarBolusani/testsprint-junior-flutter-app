import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../design_tokens.dart';

/// Full-width skeleton blocks for dashboard-style loading.
class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlight = Theme.of(context).colorScheme.surface;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _box(height: 120, radius: AppRadius.md),
          const SizedBox(height: AppSpacing.s16),
          Row(
            children: [
              Expanded(child: _box(height: 88)),
              const SizedBox(width: AppSpacing.s12),
              Expanded(child: _box(height: 88)),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          _box(height: 52),
          const SizedBox(height: AppSpacing.s12),
          _box(height: 100),
        ],
      ),
    );
  }

  Widget _box({required double height, double radius = AppRadius.sm}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
