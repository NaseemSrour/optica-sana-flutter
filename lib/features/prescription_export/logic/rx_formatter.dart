/// Pure formatters for prescription values.
///
/// Kept side-effect free (no imports beyond `dart:core`) so they are trivially
/// unit-testable and can be reused by both the on-screen Rx widgets and the
/// PDF builder.
library;

/// Default placeholder for empty / null values. Em-dash matches the
/// convention used in printed prescriptions.
const String kRxEmpty = '\u2014'; // —

/// Formats a sphere/cylinder dioptric value to a signed two-decimal string.
///
/// Rules:
/// * `null`/empty/whitespace → [kRxEmpty]
/// * Unparseable → [kRxEmpty]
/// * Exactly `0.00` → `Plano` (caller may swap the literal via [planoLabel])
/// * Otherwise: explicit sign, two decimals (`+2.50`, `-0.75`).
///
/// Uses Unicode minus (`\u2212`) for negatives so the printed glyph aligns
/// vertically with `+` (regular `-` is narrower in most fonts).
String formatSignedDiopter(String? raw, {String planoLabel = 'Plano'}) {
  if (raw == null) return kRxEmpty;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return kRxEmpty;
  final v = double.tryParse(trimmed.replaceAll('\u2212', '-'));
  if (v == null) return kRxEmpty;
  if (v == 0) return planoLabel;
  final abs = v.abs().toStringAsFixed(2);
  return v > 0 ? '+$abs' : '\u2212$abs';
}

/// Formats an addition (always positive) to `+X.XX`. Empty → [kRxEmpty].
String formatAdd(String? raw) {
  if (raw == null) return kRxEmpty;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return kRxEmpty;
  final v = double.tryParse(trimmed);
  if (v == null || v == 0) return kRxEmpty;
  // Clinically, ADD is positive. If someone entered a negative, show abs and
  // let the warnings layer flag it (we never silently flip a sign elsewhere).
  return '+${v.abs().toStringAsFixed(2)}';
}

/// Formats an axis as `NNN°`. Returns [kRxEmpty] if the axis is missing or
/// out of the clinical 1..180 range.
String formatAxis(String? raw) {
  if (raw == null) return kRxEmpty;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return kRxEmpty;
  final v = int.tryParse(trimmed) ?? double.tryParse(trimmed)?.round();
  if (v == null || v < 1 || v > 180) return kRxEmpty;
  return '$v\u00B0';
}

/// Returns `true` if a stored cylinder value is non-zero (and therefore
/// requires an axis to be clinically valid).
bool isCylNonZero(String? raw) {
  if (raw == null) return false;
  final v = double.tryParse(raw.trim());
  return v != null && v != 0;
}

/// Returns `true` if a stored prism value is non-zero (and therefore
/// requires a base direction).
bool isPrismNonZero(String? raw) {
  if (raw == null) return false;
  final v = double.tryParse(raw.trim());
  return v != null && v != 0;
}

/// Formats prism magnitude with a signed Δ prefix; empty/zero → [kRxEmpty].
String formatPrism(String? raw) {
  if (raw == null) return kRxEmpty;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return kRxEmpty;
  final v = double.tryParse(trimmed);
  if (v == null || v == 0) return kRxEmpty;
  return '${v.abs().toStringAsFixed(2)}\u0394'; // Δ (prism diopters)
}

/// Pass-through formatter for free-text fields (base direction, VA snellen,
/// frame model…). Empty → [kRxEmpty]. Trims surrounding whitespace.
String formatText(String? raw) {
  if (raw == null) return kRxEmpty;
  final trimmed = raw.trim();
  return trimmed.isEmpty ? kRxEmpty : trimmed;
}

/// Formats a millimetre numeric (PD, BC, DIA…) to one decimal, no sign.
/// Empty/unparseable → [kRxEmpty].
String formatMm(String? raw) {
  if (raw == null) return kRxEmpty;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return kRxEmpty;
  final v = double.tryParse(trimmed);
  if (v == null) return kRxEmpty;
  return v.toStringAsFixed(1);
}

/// Renders the PD line for a prescription:
/// * Both eyes given → `R/L mm` (e.g. `32.0 / 31.5 mm`)
/// * Only combined → `64 mm`
/// * Nothing → [kRxEmpty]
String formatDualPd({String? rPd, String? lPd, String? sumPd}) {
  final r = formatMm(rPd);
  final l = formatMm(lPd);
  if (r != kRxEmpty || l != kRxEmpty) {
    return '$r / $l mm';
  }
  final s = formatMm(sumPd);
  if (s != kRxEmpty) return '$s mm';
  return kRxEmpty;
}

/// True when both row's optical fields (sph/cyl/axis/add) are empty for an
/// eye — used to detect monocular prescriptions.
bool isEyeRowEmpty({String? sph, String? cyl, String? axis, String? add}) {
  bool empty(String? s) => s == null || s.trim().isEmpty;
  return empty(sph) && empty(cyl) && empty(axis) && empty(add);
}
