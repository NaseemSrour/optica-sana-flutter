import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../themes/app_theme.dart';
import '../widgets/progression_chart.dart';

/// Compact horizontal legend showing the eye → color mapping used by the
/// progression chart. Stateless and reusable in summary views.
class ProgressionLegend extends StatelessWidget {
  const ProgressionLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _LegendDot(color: EyeColors.right, label: 'prog_legend_right'.tr()),
        _LegendDot(color: EyeColors.left, label: 'prog_legend_left'.tr()),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.displayValue, fontSize: 13),
        ),
      ],
    );
  }
}
