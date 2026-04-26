import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../themes/app_theme.dart';
import '../logic/progression_view_model.dart';
import '../models/rx_data_point.dart';

/// Color used for each eye throughout the progression feature.
class EyeColors {
  EyeColors._();
  static const Color right = Color(0xFF4FC3F7); // sky blue (OD)
  static const Color left = Color(0xFFEF5350); // soft red (OS)
}

/// Interactive line chart that renders [ProgressionViewModel.spotsFor] for
/// both eyes. Hover/tap a point to see the full Rx for that visit. When the
/// time span exceeds 5 years the chart is wrapped in a horizontal scroller
/// so the user can pan; otherwise it fits the available width.
///
/// Y-axis is optionally inverted (`invertY: true`) so worsening myopia trends
/// downward — matching the way many opticians read prescription charts.
class ProgressionChart extends StatelessWidget {
  final ProgressionViewModel viewModel;
  final bool invertY;
  final double height;

  const ProgressionChart({
    super.key,
    required this.viewModel,
    this.invertY = false,
    this.height = 360,
  });

  static const _minPixelsPerYear = 90.0;

  @override
  Widget build(BuildContext context) {
    if (!viewModel.hasEnoughData) {
      return _EmptyState(viewModel: viewModel);
    }

    final span = viewModel.spanYears;
    final useScroll = viewModel.shouldEnableScroll;

    return LayoutBuilder(
      builder: (context, constraints) {
        final naturalWidth = constraints.maxWidth;
        final scrollWidth = (span * _minPixelsPerYear).clamp(
          naturalWidth,
          double.infinity,
        );
        final width = useScroll ? scrollWidth : naturalWidth;
        // Force LTR inside the chart so axis labels (years, diopters) read
        // left-to-right regardless of the surrounding app locale.
        final chart = Directionality(
          textDirection: ui.TextDirection.ltr,
          child: SizedBox(
            height: height,
            width: width,
            child: _buildChart(context),
          ),
        );
        if (!useScroll) return chart;
        return SizedBox(
          height: height,
          child: Scrollbar(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: chart,
            ),
          ),
        );
      },
    );
  }

  LineChart _buildChart(BuildContext context) {
    final yb = viewModel.yBounds();
    final xb = viewModel.xBounds();
    final yStep = viewModel.yGridStep();
    final xLabelStep = viewModel.xLabelInterval();

    return LineChart(
      LineChartData(
        minX: xb.min,
        maxX: xb.max,
        minY: invertY ? -yb.max : yb.min,
        maxY: invertY ? -yb.min : yb.max,
        clipData: const FlClipData.all(),
        backgroundColor: Colors.transparent,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: yStep,
          verticalInterval: xLabelStep,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.borderDefault.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (_) => FlLine(
            color: AppColors.borderDefault.withValues(alpha: 0.25),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.borderDefault, width: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'prog_axis_diopters'.tr(),
                style: const TextStyle(color: AppColors.label, fontSize: 12),
              ),
            ),
            axisNameSize: 18,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              interval: yStep,
              getTitlesWidget: (value, meta) {
                final actual = invertY ? -value : value;
                if ((actual * 4).round() % (yStep * 4).round() != 0) {
                  return const SizedBox.shrink();
                }
                final sign = actual > 0 ? '+' : '';
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    '$sign${actual.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.displayValue,
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: xLabelStep,
              getTitlesWidget: (value, meta) {
                final date = viewModel.dateForX(value);
                // Force English locale on the X-axis so the chart stays
                // language-neutral (months always shown as MMM).
                final fmt = xLabelStep < 1
                    ? DateFormat('MMM yy', 'en')
                    : DateFormat('yyyy', 'en');
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    fmt.format(date),
                    style: const TextStyle(
                      color: AppColors.displayValue,
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          _seriesFor(Eye.right, EyeColors.right),
          _seriesFor(Eye.left, EyeColors.left),
        ],
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surface.withValues(alpha: 0.95),
            tooltipBorder: const BorderSide(color: AppColors.borderDefault),
            tooltipRoundedRadius: 8,
            getTooltipItems: (spots) => _tooltipItems(spots),
          ),
        ),
      ),
    );
  }

  LineChartBarData _seriesFor(Eye eye, Color color) {
    final spots = viewModel.spotsFor(eye);
    final transformed = invertY
        ? spots.map((s) => FlSpot(s.x, -s.y)).toList(growable: false)
        : spots;
    return LineChartBarData(
      spots: transformed,
      isCurved: false,
      color: color,
      barWidth: 3,
      dotData: FlDotData(
        show: true,
        getDotPainter: (s, p, b, i) => FlDotCirclePainter(
          radius: 4,
          color: color,
          strokeColor: Colors.white,
          strokeWidth: 1.5,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.08),
      ),
    );
  }

  List<LineTooltipItem?> _tooltipItems(List<LineBarSpot> spots) {
    return spots.map((s) {
      final eye = s.barIndex == 0 ? Eye.right : Eye.left;
      final color = eye == Eye.right ? EyeColors.right : EyeColors.left;
      final date = viewModel.dateForX(s.x);
      // Find the matching data point for full Rx context.
      final point = viewModel.points.firstWhere(
        (p) => p.date == date,
        orElse: () => viewModel.points.reduce(
          (a, b) =>
              (a.date.difference(date).abs() < b.date.difference(date).abs())
              ? a
              : b,
        ),
      );
      final sph = point.value(eye, RxMetric.sphere);
      final cyl = point.value(eye, RxMetric.cylinder);
      final axis = eye == Eye.right ? point.rAxis : point.lAxis;
      final eyeLabel = eye == Eye.right ? 'OD' : 'OS';
      final body = StringBuffer();
      // Tooltip uses English locale for dates so it stays LTR-friendly
      // alongside the rest of the chart.
      body.writeln(DateFormat('dd MMM yyyy', 'en').format(date));
      body.writeln('Sph: ${_fmt(sph)}');
      body.writeln('Cyl: ${_fmt(cyl)}');
      if (axis != null) body.write('Axis: $axis°');
      return LineTooltipItem(
        '$eyeLabel\n',
        TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
        children: [
          TextSpan(
            text: body.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.normal,
              fontSize: 11,
            ),
          ),
        ],
      );
    }).toList();
  }

  static String _fmt(double? v) {
    if (v == null) return '—';
    final sign = v > 0 ? '+' : (v < 0 ? '' : '');
    return '$sign${v.toStringAsFixed(2)}';
  }
}

class _EmptyState extends StatelessWidget {
  final ProgressionViewModel viewModel;
  const _EmptyState({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final hasOne = viewModel.points.length == 1;
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderDefault),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasOne ? Icons.timeline : Icons.show_chart,
                size: 48,
                color: AppColors.label,
              ),
              const SizedBox(height: 12),
              Text(
                hasOne
                    ? 'prog_empty_one_title'.tr()
                    : 'prog_empty_zero_title'.tr(),
                style: const TextStyle(
                  color: AppColors.displayValue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hasOne
                    ? 'prog_empty_one_body'.tr()
                    : 'prog_empty_zero_body'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.label, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
