import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../themes/app_theme.dart';
import '../logic/progression_view_model.dart';
import '../models/rx_data_point.dart';
import 'progression_chart.dart';

/// Row of summary cards shown above the chart. Each card highlights one
/// quick-glance metric: latest Rx per eye and overall change since the very
/// first recorded test. Designed to be friendly for both clinician and
/// patient — no jargon beyond "Sph"/"Cyl".
class ProgressionSummary extends StatelessWidget {
  final ProgressionViewModel viewModel;
  const ProgressionSummary({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    if (viewModel.isEmpty) return const SizedBox.shrink();

    final firstDate = viewModel.points.first.date;
    final lastDate = viewModel.points.last.date;
    // Time-range labels stay in English so dates remain unambiguous and LTR.
    final fmt = DateFormat('MMM yyyy', 'en');
    final spanLabel = viewModel.points.length == 1
        ? fmt.format(firstDate)
        : '${fmt.format(firstDate)}  →  ${fmt.format(lastDate)}';

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _Card(
          accent: AppColors.accentTeal,
          icon: Icons.event_note,
          label: 'prog_summary_visits'.tr(),
          primary: '${viewModel.points.length}',
          secondary: spanLabel,
          ltrSecondary: true,
        ),
        _EyeCard(
          eye: Eye.right,
          label: 'prog_summary_latest_right'.tr(),
          viewModel: viewModel,
        ),
        _EyeCard(
          eye: Eye.left,
          label: 'prog_summary_latest_left'.tr(),
          viewModel: viewModel,
        ),
        if (viewModel.hasEnoughData) ...[
          _DeltaCard(eye: Eye.right, viewModel: viewModel),
          _DeltaCard(eye: Eye.left, viewModel: viewModel),
        ],
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String label;
  final String primary;
  final String? secondary;

  /// When `true`, force the secondary line to render LTR — useful for date
  /// ranges that should not be flipped by the surrounding RTL locale.
  final bool ltrSecondary;

  const _Card({
    required this.accent,
    required this.icon,
    required this.label,
    required this.primary,
    this.secondary,
    this.ltrSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.label,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            primary,
            style: const TextStyle(
              color: AppColors.displayValue,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (secondary != null) ...[
            const SizedBox(height: 2),
            ltrSecondary
                ? Directionality(
                    textDirection: ui.TextDirection.ltr,
                    child: Text(
                      secondary!,
                      style: const TextStyle(
                        color: AppColors.label,
                        fontSize: 11,
                      ),
                    ),
                  )
                : Text(
                    secondary!,
                    style: const TextStyle(
                      color: AppColors.label,
                      fontSize: 11,
                    ),
                  ),
          ],
        ],
      ),
    );
  }
}

class _EyeCard extends StatelessWidget {
  final Eye eye;
  final String label;
  final ProgressionViewModel viewModel;
  const _EyeCard({
    required this.eye,
    required this.label,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final color = eye == Eye.right ? EyeColors.right : EyeColors.left;
    // Pull the latest values for both metrics, regardless of current toggle.
    double? latestSph;
    double? latestCyl;
    int? latestAxis;
    DateTime? latestDate;
    for (final p in viewModel.points.reversed) {
      final sph = p.value(eye, RxMetric.sphere);
      final cyl = p.value(eye, RxMetric.cylinder);
      if (sph != null || cyl != null) {
        latestSph = sph;
        latestCyl = cyl;
        latestAxis = eye == Eye.right ? p.rAxis : p.lAxis;
        latestDate = p.date;
        break;
      }
    }
    final dateLabel = latestDate == null
        ? '—'
        : DateFormat('dd MMM yyyy', 'en').format(latestDate);

    return Container(
      width: 240,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.remove_red_eye_outlined, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.label,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _kv('prog_kv_sph'.tr(), _fmt(latestSph)),
          _kv('prog_kv_cyl'.tr(), _fmt(latestCyl)),
          _kv('prog_kv_axis'.tr(), latestAxis == null ? '—' : '$latestAxis°'),
          const SizedBox(height: 4),
          Directionality(
            textDirection: ui.TextDirection.ltr,
            child: Text(
              dateLabel,
              style: const TextStyle(color: AppColors.label, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              k,
              style: const TextStyle(color: AppColors.label, fontSize: 12),
            ),
          ),
          Text(
            v,
            style: const TextStyle(
              color: AppColors.displayValue,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(double? v) {
    if (v == null) return '—';
    final sign = v > 0 ? '+' : '';
    return '$sign${v.toStringAsFixed(2)}';
  }
}

/// "Change since first visit" card — colored by direction (more myopic = bad,
/// stable = neutral, less myopic = good).
class _DeltaCard extends StatelessWidget {
  final Eye eye;
  final ProgressionViewModel viewModel;
  const _DeltaCard({required this.eye, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final delta = viewModel.totalDelta(eye);
    final metricLabel = viewModel.metric == RxMetric.sphere
        ? 'prog_kv_sph'.tr()
        : 'prog_kv_cyl'.tr();
    final headerLabel = eye == Eye.right
        ? 'prog_summary_change_right'.tr(namedArgs: {'metric': metricLabel})
        : 'prog_summary_change_left'.tr(namedArgs: {'metric': metricLabel});

    String trend;
    Color color;
    IconData icon;
    if (delta == null || delta.abs() < 0.125) {
      trend = 'prog_trend_stable'.tr();
      color = AppColors.success;
      icon = Icons.trending_flat;
    } else if (delta < 0) {
      // More myopic / more cylinder magnitude — typical worsening.
      trend = 'prog_trend_more_minus'.tr();
      color = AppColors.error;
      icon = Icons.trending_down;
    } else {
      trend = 'prog_trend_less_minus'.tr();
      color = AppColors.accentTeal;
      icon = Icons.trending_up;
    }

    final value = delta == null
        ? '—'
        : '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(2)} D';

    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  headerLabel,
                  style: const TextStyle(
                    color: AppColors.label,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            trend,
            style: const TextStyle(color: AppColors.label, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
