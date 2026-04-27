import '../../../db_flutter/models.dart';

/// Which prescription metric to plot on the Y-axis.
enum RxMetric { sphere, cylinder }

/// Which eye a series belongs to.
enum Eye { right, left }

/// A single prescription snapshot for one customer at a given exam date.
///
/// Values are stored in **negative-cylinder convention** (the optical industry
/// standard): cylinder is always ≤ 0. If the source data was recorded in
/// positive-cyl form, [_normalize] transposes it before construction:
///
/// ```
/// sph_new   = sph + cyl
/// cyl_new   = -cyl
/// axis_new  = (axis + 90) mod 180
/// ```
///
/// This avoids visual jumps in cylinder progression when an examiner switched
/// notation between visits.
class RxDataPoint {
  final DateTime date;

  // Right eye
  final double? rSphere;
  final double? rCylinder;
  final int? rAxis;

  // Left eye
  final double? lSphere;
  final double? lCylinder;
  final int? lAxis;

  const RxDataPoint({
    required this.date,
    this.rSphere,
    this.rCylinder,
    this.rAxis,
    this.lSphere,
    this.lCylinder,
    this.lAxis,
  });

  /// Build a normalized point from a [GlassesTest] DB row.
  factory RxDataPoint.fromGlassesTest(GlassesTest t) {
    final r = _normalize(
      sphRaw: t.rSphere,
      cylRaw: t.rCylinder,
      axisRaw: t.rAxis,
    );
    final l = _normalize(
      sphRaw: t.lSphere,
      cylRaw: t.lCylinder,
      axisRaw: t.lAxis,
    );
    return RxDataPoint(
      date: t.examDate,
      rSphere: r.sph,
      rCylinder: r.cyl,
      rAxis: r.axis,
      lSphere: l.sph,
      lCylinder: l.cyl,
      lAxis: l.axis,
    );
  }

  /// Returns the value for [metric] on [eye], or `null` if missing.
  double? value(Eye eye, RxMetric metric) {
    switch (eye) {
      case Eye.right:
        return metric == RxMetric.sphere ? rSphere : rCylinder;
      case Eye.left:
        return metric == RxMetric.sphere ? lSphere : lCylinder;
    }
  }

  static _NormalizedRx _normalize({
    String? sphRaw,
    String? cylRaw,
    String? axisRaw,
  }) {
    final sph = double.tryParse((sphRaw ?? '').trim());
    final cyl = double.tryParse((cylRaw ?? '').trim());
    final axis = int.tryParse((axisRaw ?? '').trim());
    if (sph == null && cyl == null) {
      return const _NormalizedRx(null, null, null);
    }
    if (cyl != null && cyl > 0) {
      // Transpose to minus-cyl convention.
      final newSph = (sph ?? 0) + cyl;
      final newCyl = -cyl;
      final newAxis = axis == null ? null : (axis + 90) % 180;
      return _NormalizedRx(newSph, newCyl, newAxis);
    }
    return _NormalizedRx(sph, cyl, axis);
  }
}

class _NormalizedRx {
  final double? sph;
  final double? cyl;
  final int? axis;
  const _NormalizedRx(this.sph, this.cyl, this.axis);
}
