import 'package:fl_chart/fl_chart.dart';

import '../models/rx_data_point.dart';

/// Pure data layer that converts a list of normalized [RxDataPoint]s into
/// chart-ready primitives. Holds no widget state; safe to instantiate per
/// build. Callers pass the current [metric] toggle.
class ProgressionViewModel {
  final List<RxDataPoint> points;
  final RxMetric metric;

  /// Sorted ascending by date.
  ProgressionViewModel({
    required List<RxDataPoint> points,
    required this.metric,
  }) : points = (List<RxDataPoint>.from(points)
         ..sort((a, b) => a.date.compareTo(b.date)));

  bool get hasEnoughData => points.length >= 2;
  bool get isEmpty => points.isEmpty;

  /// Time span covered by the data, in fractional years. 0 when <2 points.
  double get spanYears {
    if (points.length < 2) return 0;
    final ms = points.last.date.difference(points.first.date).inMilliseconds;
    return ms / (1000 * 60 * 60 * 24 * 365.25);
  }

  /// Whether the chart should activate horizontal pan/scroll.
  bool get shouldEnableScroll => spanYears > 5;

  /// X-axis value for [d]: fractional years since the first point. Always 0
  /// for the first data point so the chart starts cleanly at x=0.
  double xFor(DateTime d) {
    if (points.isEmpty) return 0;
    final first = points.first.date;
    final ms = d.difference(first).inMilliseconds;
    return ms / (1000 * 60 * 60 * 24 * 365.25);
  }

  /// Inverse of [xFor].
  DateTime dateForX(double x) {
    if (points.isEmpty) return DateTime.now();
    final first = points.first.date;
    final ms = (x * (1000 * 60 * 60 * 24 * 365.25)).round();
    return first.add(Duration(milliseconds: ms));
  }

  /// Build [FlSpot]s for one eye, skipping points where the value is null.
  List<FlSpot> spotsFor(Eye eye) {
    final spots = <FlSpot>[];
    for (final p in points) {
      final v = p.value(eye, metric);
      if (v == null) continue;
      spots.add(FlSpot(xFor(p.date), v));
    }
    return spots;
  }

  /// Y-axis bounds rounded to a 0.25-step grid with a small padding so the
  /// extreme points are not flush against the top/bottom of the chart.
  ({double min, double max}) yBounds() {
    final values = <double>[];
    for (final p in points) {
      final r = p.value(Eye.right, metric);
      final l = p.value(Eye.left, metric);
      if (r != null) values.add(r);
      if (l != null) values.add(l);
    }
    if (values.isEmpty) return (min: -1.0, max: 1.0);
    var lo = values.reduce((a, b) => a < b ? a : b);
    var hi = values.reduce((a, b) => a > b ? a : b);
    // Pad by at least 0.5D so the line never hugs the border.
    lo = (lo - 0.5);
    hi = (hi + 0.5);
    // Snap to 0.25 grid.
    lo = (lo * 4).floor() / 4;
    hi = (hi * 4).ceil() / 4;
    if (lo == hi) {
      lo -= 0.5;
      hi += 0.5;
    }
    return (min: lo, max: hi);
  }

  /// Y-axis label interval. Picks a coarser step on wide ranges so labels
  /// stay readable.
  double yLabelInterval() {
    final b = yBounds();
    final span = b.max - b.min;
    if (span <= 2.0) return 0.25;
    if (span <= 4.0) return 0.5;
    if (span <= 8.0) return 1.0;
    return 2.0;
  }

  /// Major-grid step (used for both grid lines and label cadence).
  double yGridStep() => yLabelInterval();

  /// X-axis bounds in fractional years.
  ({double min, double max}) xBounds() {
    if (points.isEmpty) return (min: 0, max: 1);
    if (points.length == 1) return (min: -0.5, max: 0.5);
    return (min: 0, max: spanYears);
  }

  /// Best label interval for the X-axis depending on overall span.
  double xLabelInterval() {
    final span = spanYears;
    if (span <= 1) return 1 / 12; // monthly
    if (span <= 3) return 0.25; // quarterly
    if (span <= 8) return 1; // yearly
    return 2; // every 2 years
  }

  // ── Summary stats shown in the header cards ────────────────────────────

  /// First → last delta for the given eye/metric. Null when not computable.
  double? totalDelta(Eye eye) {
    final filtered = points.where((p) => p.value(eye, metric) != null).toList();
    if (filtered.length < 2) return null;
    return filtered.last.value(eye, metric)! -
        filtered.first.value(eye, metric)!;
  }

  /// Latest recorded value for [eye] / current [metric].
  double? latest(Eye eye) {
    for (final p in points.reversed) {
      final v = p.value(eye, metric);
      if (v != null) return v;
    }
    return null;
  }

  /// Number of distinct exam dates with at least one value for the metric.
  int countWithValues() => points
      .where(
        (p) =>
            p.value(Eye.right, metric) != null ||
            p.value(Eye.left, metric) != null,
      )
      .length;
}
