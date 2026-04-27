import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../themes/app_theme.dart';
import '../logic/progression_view_model.dart';
import '../models/rx_data_point.dart';
import 'progression_chart.dart';

/// Visit-by-visit delta strip: one mini "pill" per consecutive pair of
/// visits, tinted by direction (more minus = warm, less minus = cool, stable
/// = grey). Helps the patient see at a glance which years had the biggest
/// jumps. Renders nothing when there are fewer than 2 visits.
class ProgressionDeltaStrip extends StatelessWidget {
  final ProgressionViewModel viewModel;
  const ProgressionDeltaStrip({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    if (!viewModel.hasEnoughData) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'prog_strip_title'.tr(),
          style: const TextStyle(
            color: AppColors.displayValue,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _eyeRow(Eye.right),
        const SizedBox(height: 6),
        _eyeRow(Eye.left),
      ],
    );
  }

  Widget _eyeRow(Eye eye) {
    final color = eye == Eye.right ? EyeColors.right : EyeColors.left;
    final label = eye == Eye.right
        ? 'prog_eye_short_right'.tr()
        : 'prog_eye_short_left'.tr();
    final pts = viewModel.points
        .where((p) => p.value(eye, viewModel.metric) != null)
        .toList();
    if (pts.length < 2) {
      return Row(
        children: [
          _eyeBadge(label, color),
          const SizedBox(width: 8),
          Text(
            'prog_strip_no_data'.tr(),
            style: const TextStyle(color: AppColors.label, fontSize: 12),
          ),
        ],
      );
    }
    return Row(
      children: [
        _eyeBadge(label, color),
        const SizedBox(width: 8),
        // Pills are arranged in chronological order (oldest → newest). Force
        // LTR here so the visual time direction stays consistent regardless
        // of the surrounding locale.
        Expanded(
          child: Directionality(
            textDirection: ui.TextDirection.ltr,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 1; i < pts.length; i++)
                    _deltaPill(from: pts[i - 1], to: pts[i], eye: eye),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _eyeBadge(String text, Color color) {
    return Container(
      width: 28,
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _deltaPill({
    required RxDataPoint from,
    required RxDataPoint to,
    required Eye eye,
  }) {
    final a = from.value(eye, viewModel.metric)!;
    final b = to.value(eye, viewModel.metric)!;
    final d = b - a;
    Color bg;
    if (d.abs() < 0.125) {
      bg = AppColors.borderDefault;
    } else if (d < 0) {
      bg = AppColors.error.withValues(alpha: 0.55);
    } else {
      bg = AppColors.accentTeal.withValues(alpha: 0.55);
    }
    final label = '${d > 0 ? '+' : ''}${d.toStringAsFixed(2)}';
    final fmt = DateFormat('MMM yyyy', 'en');
    return Tooltip(
      message:
          '${fmt.format(from.date)} → ${fmt.format(to.date)}\n'
          '$label D',
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
