import 'dart:math';

import '../../../db_flutter/models.dart';

/// Generates a believable progression of [GlassesTest] rows for offline
/// preview / UI testing of the progression feature. Sphere drifts slightly
/// more myopic each year, cylinder fluctuates, axis is roughly stable.
///
/// Pass a [seed] to make the output deterministic.
class ProgressionDummyData {
  ProgressionDummyData._();

  static List<GlassesTest> generate({
    required int customerId,
    int years = 8,
    int testsPerYear = 1,
    int seed = 42,
  }) {
    final rng = Random(seed);
    final out = <GlassesTest>[];
    var rSph = -1.25;
    var lSph = -1.50;
    var rCyl = -0.50;
    var lCyl = -0.75;
    var rAx = 175;
    var lAx = 5;

    final start = DateTime.now().subtract(Duration(days: 365 * years));
    final totalTests = years * testsPerYear;
    for (var i = 0; i < totalTests; i++) {
      final date = start.add(
        Duration(days: ((i / testsPerYear) * 365).round() + rng.nextInt(40)),
      );

      // Drift slightly more myopic each year.
      rSph -= 0.125 + rng.nextDouble() * 0.25;
      lSph -= 0.125 + rng.nextDouble() * 0.25;

      // Cylinder fluctuates in 0.25 steps within ±0.25 of previous.
      rCyl = _quarterStep(rCyl + (rng.nextDouble() - 0.5) * 0.5);
      lCyl = _quarterStep(lCyl + (rng.nextDouble() - 0.5) * 0.5);

      // Axis wobbles within ±5°.
      rAx = (rAx + rng.nextInt(11) - 5) % 180;
      lAx = (lAx + rng.nextInt(11) - 5) % 180;

      out.add(
        GlassesTest(
          id: i + 1,
          customerId: customerId,
          examDate: date,
          rSphere: _fmt(rSph),
          lSphere: _fmt(lSph),
          rCylinder: _fmt(rCyl),
          lCylinder: _fmt(lCyl),
          rAxis: rAx.toString(),
          lAxis: lAx.toString(),
          rVa: '6',
          lVa: '6',
        ),
      );
    }
    return out;
  }

  static double _quarterStep(double v) => (v * 4).round() / 4;

  static String _fmt(double v) {
    final stepped = _quarterStep(v);
    final sign = stepped >= 0 ? '+' : '-';
    return '$sign${stepped.abs().toStringAsFixed(2)}';
  }
}
