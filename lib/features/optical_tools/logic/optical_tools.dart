// Pure optical-tool calculations — no Flutter imports.
//
// Conventions used throughout:
//   • Powers are in diopters (D); positive = converging, negative = diverging.
//   • Distances are in meters unless explicitly named `_mm` or `_cm`.
//   • Cylinder is signed; the same eye can be expressed as plus-cyl or
//     minus-cyl — they are mathematically equivalent prescriptions.
//   • Axis is in degrees, kept in the closed range (0, 180]. The
//     conventional value for a horizontal meridian is 180, never 0.
//   • All functions throw [ArgumentError] on physically invalid input
//     (e.g. axis 250°, working distance ≤ 0). They never silently clamp.
//
// Each tool block carries the formula in a comment so the math is
// reviewable in source without reading the full file.

import 'dart:math' as math;

// ─────────────────────────────────────────────────────────────────────────
// Validators (shared)
// ─────────────────────────────────────────────────────────────────────────

void _validateAxis(double axis) {
  if (axis.isNaN || axis < 0 || axis > 180) {
    throw ArgumentError.value(axis, 'axis', 'must be in [0, 180] degrees');
  }
}

void _validateFinite(double v, String name) {
  if (v.isNaN || v.isInfinite) {
    throw ArgumentError.value(v, name, 'must be a finite number');
  }
}

/// Normalises an axis into the conventional range (0, 180].
/// 0° is mapped to 180° because they represent the same horizontal meridian.
double normaliseAxis(double axis) {
  var a = axis % 180.0;
  if (a <= 0) a += 180.0;
  return a;
}

/// Rounds a diopter value to the nearest clinical step (default 0.25 D).
double roundToStep(double value, {double step = 0.25}) {
  if (step <= 0) {
    throw ArgumentError.value(step, 'step', 'must be > 0');
  }
  return (value / step).roundToDouble() * step;
}

// ─────────────────────────────────────────────────────────────────────────
// 1) Spherical equivalent
//    SE = SPH + CYL/2
// ─────────────────────────────────────────────────────────────────────────

/// Returns the spherical equivalent of a sphero-cylindrical prescription.
/// Sign-agnostic: works the same whether [cyl] is plus or minus form.
double sphericalEquivalent({required double sph, required double cyl}) {
  _validateFinite(sph, 'sph');
  _validateFinite(cyl, 'cyl');
  return sph + cyl / 2.0;
}

// ─────────────────────────────────────────────────────────────────────────
// 2) Cylinder transposition (plus ↔ minus)
//    new_SPH  = SPH + CYL
//    new_CYL  = -CYL
//    new_AXIS = (AXIS + 90) mod 180   // 0 → 180
// ─────────────────────────────────────────────────────────────────────────

/// Result of a cylinder transposition.
class TransposedRx {
  final double sph;
  final double cyl;
  final double axis;
  const TransposedRx({
    required this.sph,
    required this.cyl,
    required this.axis,
  });

  @override
  String toString() => 'sph=$sph cyl=$cyl axis=$axis';
}

/// Transposes a sphero-cyl Rx between plus-cyl and minus-cyl notation.
/// Equivalent in either direction — call once to flip the sign.
TransposedRx transposeCylinder({
  required double sph,
  required double cyl,
  required double axis,
}) {
  _validateFinite(sph, 'sph');
  _validateFinite(cyl, 'cyl');
  _validateAxis(axis);
  return TransposedRx(
    sph: sph + cyl,
    cyl: -cyl,
    axis: normaliseAxis(axis + 90.0),
  );
}

// ─────────────────────────────────────────────────────────────────────────
// 3) Vertex distance compensation
//    F_new = F / (1 − (d_old − d_new) · F)
//
//    For sphero-cyl: compensate each principal meridian (SPH and SPH+CYL)
//    separately, then re-transpose to sph/cyl/axis. Axis is invariant.
// ─────────────────────────────────────────────────────────────────────────

/// Compensates a single power [f] (D) for a change in vertex distance.
/// [oldVertexMm] is where the refraction was performed, [newVertexMm] is
/// where the lens will sit. For glasses → CL pass `newVertexMm: 0`.
double vertexCompensatePower({
  required double f,
  required double oldVertexMm,
  required double newVertexMm,
}) {
  _validateFinite(f, 'f');
  _validateFinite(oldVertexMm, 'oldVertexMm');
  _validateFinite(newVertexMm, 'newVertexMm');
  if (oldVertexMm < 0 || newVertexMm < 0) {
    throw ArgumentError('vertex distances must be ≥ 0');
  }
  final d = (oldVertexMm - newVertexMm) / 1000.0; // meters
  final denom = 1.0 - d * f;
  if (denom == 0) {
    throw ArgumentError('singular vertex compensation (denominator = 0)');
  }
  return f / denom;
}

/// Compensates a full sphero-cyl Rx for a vertex change.
/// Returns sph/cyl/axis in the original cylinder sign convention.
TransposedRx vertexCompensateRx({
  required double sph,
  required double cyl,
  required double axis,
  required double oldVertexMm,
  required double newVertexMm,
}) {
  _validateFinite(sph, 'sph');
  _validateFinite(cyl, 'cyl');
  _validateAxis(axis);
  final m1 = vertexCompensatePower(
    f: sph,
    oldVertexMm: oldVertexMm,
    newVertexMm: newVertexMm,
  );
  final m2 = vertexCompensatePower(
    f: sph + cyl,
    oldVertexMm: oldVertexMm,
    newVertexMm: newVertexMm,
  );
  return TransposedRx(sph: m1, cyl: m2 - m1, axis: axis);
}

/// Vertex compensation is clinically meaningful only above ~|4.00 D|.
/// Returns the larger absolute meridian power, useful for an "is this
/// worth compensating?" UI hint.
double vertexSignificanceThreshold({required double sph, required double cyl}) {
  return math.max(sph.abs(), (sph + cyl).abs());
}

// ─────────────────────────────────────────────────────────────────────────
// 4) PD conversion
// ─────────────────────────────────────────────────────────────────────────

/// Symmetric split — approximation only, valid when there is no measurable
/// facial asymmetry. Caller is responsible for showing a warning.
({double odPd, double osPd}) splitTotalPd(double totalPdMm) {
  _validateFinite(totalPdMm, 'totalPdMm');
  if (totalPdMm <= 0 || totalPdMm > 90) {
    throw ArgumentError.value(totalPdMm, 'totalPdMm', 'expected 30–90 mm');
  }
  final half = totalPdMm / 2.0;
  return (odPd: half, osPd: half);
}

/// Sums monocular PDs into a binocular total.
double sumMonocularPd({required double odMm, required double osMm}) {
  _validateFinite(odMm, 'odMm');
  _validateFinite(osMm, 'osMm');
  if (odMm < 15 || osMm < 15 || odMm > 50 || osMm > 50) {
    throw ArgumentError('monocular PD expected 15–50 mm per eye');
  }
  return odMm + osMm;
}

/// Empirical near PD from distance PD: subtract ~3 mm for ~40 cm working
/// distance. Caller may override the offset for unusual working distances.
double nearPdFromDistance(double distancePdMm, {double offsetMm = 3.0}) {
  _validateFinite(distancePdMm, 'distancePdMm');
  if (distancePdMm <= 0) {
    throw ArgumentError.value(distancePdMm, 'distancePdMm', 'must be > 0');
  }
  return distancePdMm - offsetMm;
}

// ─────────────────────────────────────────────────────────────────────────
// 5) Near addition & working distance
//
//    Hofstetter amplitude of accommodation (AA), diopters:
//      min_AA = 15.0 − 0.25·age
//      avg_AA = 18.5 − 0.30·age
//      max_AA = 25.0 − 0.40·age
//
//    Required add for working distance d (m):
//      demand        = 1 / d
//      add           = demand − 0.5 · available_AA   (½ in reserve)
//      add ≥ 0, capped at +3.50 D, rounded to 0.25 D step
// ─────────────────────────────────────────────────────────────────────────

class HofstetterAA {
  final double minDiopters;
  final double avgDiopters;
  final double maxDiopters;
  const HofstetterAA(this.minDiopters, this.avgDiopters, this.maxDiopters);
}

HofstetterAA hofstetterAmplitude(int age) {
  if (age < 5 || age > 100) {
    throw ArgumentError.value(age, 'age', 'expected 5–100');
  }
  return HofstetterAA(
    math.max(0, 15.0 - 0.25 * age),
    math.max(0, 18.5 - 0.30 * age),
    math.max(0, 25.0 - 0.40 * age),
  );
}

/// Suggests a near addition power.
/// [workingDistanceCm] — reading distance (default 40 cm).
/// [availableAA] — measured amplitude of accommodation in D, or null to
///   default to the patient's Hofstetter average from [age].
/// Caps result to +3.50 D (typical PAL/bifocal range) and rounds to 0.25.
double suggestNearAdd({
  required int age,
  double workingDistanceCm = 40.0,
  double? availableAA,
}) {
  if (workingDistanceCm <= 0) {
    throw ArgumentError.value(workingDistanceCm, 'workingDistanceCm');
  }
  final aa = availableAA ?? hofstetterAmplitude(age).avgDiopters;
  if (aa < 0) {
    throw ArgumentError.value(aa, 'availableAA', 'must be ≥ 0');
  }
  final demand = 1.0 / (workingDistanceCm / 100.0);
  final raw = demand - 0.5 * aa;
  final clamped = raw.clamp(0.0, 3.50);
  return roundToStep(clamped.toDouble(), step: 0.25);
}

// ─────────────────────────────────────────────────────────────────────────
// 6) Prentice's rule
//    Δ (prism diopters) = c (cm) · F (D)
// ─────────────────────────────────────────────────────────────────────────

/// Vertical/horizontal sense — caller must pass the lens power in the
/// meridian aligned with the decentration direction.
/// Returns prism magnitude in prism diopters (Δ); base direction depends
/// on lens sign and decentration direction and is left to the caller/UI.
double prenticePrism({required double decentrationMm, required double powerD}) {
  _validateFinite(decentrationMm, 'decentrationMm');
  _validateFinite(powerD, 'powerD');
  return (decentrationMm / 10.0) * powerD;
}

// ─────────────────────────────────────────────────────────────────────────
// 7) Soft toric LARS axis compensation
//    Left-Add Right-Subtract (clinician's view of the patient's eye).
//    Using a positive `rotationDeg` for "to clinician's left" / "patient's
//    right side" to match the LARS mnemonic.
// ─────────────────────────────────────────────────────────────────────────

class TorricRotationResult {
  final double orderedAxis;

  /// True when |rotation| > 20°; the caller should refit the lens rather
  /// than just compensate the axis.
  final bool refitRecommended;
  const TorricRotationResult(this.orderedAxis, this.refitRecommended);
}

TorricRotationResult compensateTorricAxisLARS({
  required double measuredAxis,
  required double rotationDeg,
}) {
  _validateAxis(measuredAxis);
  _validateFinite(rotationDeg, 'rotationDeg');
  return TorricRotationResult(
    normaliseAxis(measuredAxis + rotationDeg),
    rotationDeg.abs() > 20.0,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// 8) Visual acuity conversions
//    decimal = num/den          (e.g. 20/40 → 0.5)
//    MAR     = 1/decimal
//    logMAR  = log10(MAR) = −log10(decimal)
// ─────────────────────────────────────────────────────────────────────────

double snellenToDecimal({
  required double numerator,
  required double denominator,
}) {
  _validateFinite(numerator, 'numerator');
  _validateFinite(denominator, 'denominator');
  if (numerator <= 0 || denominator <= 0) {
    throw ArgumentError('Snellen values must be > 0');
  }
  return numerator / denominator;
}

double decimalToLogMAR(double decimal) {
  _validateFinite(decimal, 'decimal');
  if (decimal <= 0) {
    throw ArgumentError.value(decimal, 'decimal', 'must be > 0');
  }
  return -math.log(decimal) / math.ln10;
}

double logMARToDecimal(double logMar) {
  _validateFinite(logMar, 'logMar');
  return math.pow(10.0, -logMar).toDouble();
}

// ─────────────────────────────────────────────────────────────────────────
// 9) Back-vertex power generic helper — alias for arbitrary d_old/d_new
//    handled by [vertexCompensatePower]. Provided for discoverability.
// ─────────────────────────────────────────────────────────────────────────
//    (No new code — call vertexCompensatePower directly.)

// ─────────────────────────────────────────────────────────────────────────
// 10) Anisometropia magnification estimate (rule of thumb)
//     ~1% size difference per diopter of sphere difference through standard
//     plastic lenses (n≈1.50, t≈2 mm, vertex≈12 mm). Screening only.
// ─────────────────────────────────────────────────────────────────────────

class AniseikoniaEstimate {
  final double diopterDifference;
  final double approxPercent;

  /// True when the estimated magnification difference is clinically
  /// meaningful (≥ ~3%). Caller decides whether to warn the user.
  final bool clinicallySignificant;
  const AniseikoniaEstimate(
    this.diopterDifference,
    this.approxPercent,
    this.clinicallySignificant,
  );
}

AniseikoniaEstimate estimateAniseikonia({
  required double sphOd,
  required double sphOs,
  double percentPerDiopter = 1.0,
}) {
  _validateFinite(sphOd, 'sphOd');
  _validateFinite(sphOs, 'sphOs');
  if (percentPerDiopter <= 0) {
    throw ArgumentError.value(percentPerDiopter, 'percentPerDiopter');
  }
  final diff = (sphOd - sphOs).abs();
  final pct = diff * percentPerDiopter;
  return AniseikoniaEstimate(diff, pct, pct >= 3.0);
}
