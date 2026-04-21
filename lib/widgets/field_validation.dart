import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import 'app_notification.dart';

/// A validator that inspects the current values of several fields and returns
/// an error message (already localized) to display, or `null` when valid.
typedef FieldCheck =
    String? Function(Map<String, TextEditingController> controllers);

/// An action that runs against the current field values on blur, typically
/// to populate a computed field. Returning normally is enough — implementations
/// are expected to mutate the target controller(s) directly.
typedef FieldAction =
    void Function(Map<String, TextEditingController> controllers);

/// Wraps a form field so that when focus leaves any descendant, [check] runs
/// against [controllers] and any returned error is shown via [AppNotification].
///
/// Does not change the child's appearance or focus traversal — the wrapper
/// itself is not focusable and is skipped in traversal.
class OnBlurValidator extends StatelessWidget {
  final Map<String, TextEditingController>? controllers;
  final FieldCheck? check;
  final String? Function()? simpleCheck;
  final Widget child;

  const OnBlurValidator({
    super.key,
    required Map<String, TextEditingController> this.controllers,
    required FieldCheck this.check,
    required this.child,
  }) : simpleCheck = null;

  /// Variant for screens that don't use a shared controllers map. Pass a
  /// closure that already captures whatever state it needs and returns an
  /// error message to display, or `null` when valid.
  const OnBlurValidator.simple({
    super.key,
    required String? Function() this.simpleCheck,
    required this.child,
  }) : controllers = null,
       check = null;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (hasFocus) {
        if (hasFocus) return;
        final error = simpleCheck != null
            ? simpleCheck!()
            : check!(controllers!);
        if (error != null) {
          AppNotification.show(context, error, type: NotificationType.error);
        }
      },
      child: child,
    );
  }
}

// ─── Reusable check factories ─────────────────────────────────────────────

/// Requires [fieldKey]'s controller to hold a non-empty trimmed value.
/// [errorTrKey] is the `easy_localization` key for the message to show.
FieldCheck requiredFieldCheck({
  required String fieldKey,
  required String errorTrKey,
}) {
  return (controllers) {
    final v = controllers[fieldKey]?.text.trim() ?? '';
    return v.isEmpty ? errorTrKey.tr() : null;
  };
}

/// Simple-form variant of [requiredFieldCheck] for screens that don't use a
/// shared controllers map. Captures the [controller] directly.
String? Function() simpleRequiredCheck({
  required TextEditingController controller,
  required String errorTrKey,
}) {
  return () => controller.text.trim().isEmpty ? errorTrKey.tr() : null;
}

/// If the value of [cylinderKey] is non-empty and non-zero, the value of
/// [axisKey] must be an integer between 0 and 180 (inclusive).
FieldCheck glassesAxisCheck({
  required String axisKey,
  required String cylinderKey,
}) {
  return (controllers) {
    final cyl = controllers[cylinderKey]?.text.trim() ?? '';
    final axis = controllers[axisKey]?.text.trim() ?? '';

    final cylNum = double.tryParse(cyl.replaceAll(',', '.'));
    final cylIsSet = cyl.isNotEmpty && cylNum != null && cylNum != 0;
    if (!cylIsSet) return null;

    final axisNum = int.tryParse(axis);
    if (axisNum == null || axisNum < 0 || axisNum > 180) {
      return 'msg_axis_invalid'.tr();
    }
    return null;
  };
}

/// If [fieldKey] is non-empty and parses as a number, it must be a multiple
/// of 0.25 (i.e. its fractional part is one of .00 / .25 / .50 / .75).
/// Empty fields are considered valid. [errorTrKey] is the localization key
/// for the error message to show when the value doesn't fit the step.
FieldCheck quarterStepCheck({
  required String fieldKey,
  String errorTrKey = 'msg_quarter_step_invalid',
}) {
  return (controllers) {
    final raw = controllers[fieldKey]?.text.replaceAll('_', '').trim() ?? '';
    final cleaned = raw.endsWith('.') ? raw.substring(0, raw.length - 1) : raw;
    if (cleaned.isEmpty || cleaned == '+' || cleaned == '-') return null;
    final value = double.tryParse(cleaned.replaceAll(',', '.'));
    if (value == null) return null;
    // Scale by 4 and compare to the nearest integer so binary-float noise
    // (e.g. 0.1 + 0.15 ≠ 0.25) doesn't trip the check.
    final scaled = value * 4;
    if ((scaled - scaled.roundToDouble()).abs() > 1e-6) {
      return errorTrKey.tr();
    }
    return null;
  };
}

// ─── Form-level helpers ───────────────────────────────────────────────────

/// Runs every [checks] against [controllers] and returns the first error
/// encountered, or `null` if all pass. Use this from a Save handler to block
/// saving when validations fail.
String? runChecks(
  Map<String, TextEditingController> controllers,
  List<FieldCheck> checks,
) {
  for (final check in checks) {
    final err = check(controllers);
    if (err != null) return err;
  }
  return null;
}

// ─── On-blur auto-fill actions ────────────────────────────────────────────

/// Wraps a form field so that when focus leaves any descendant, [action]
/// runs against [controllers]. The action is expected to mutate one or more
/// controllers in-place (typically to compute derived values).
///
/// Transparent to focus traversal and does not change the child's appearance.
class OnBlurAction extends StatelessWidget {
  final Map<String, TextEditingController> controllers;
  final FieldAction action;
  final Widget child;

  const OnBlurAction({
    super.key,
    required this.controllers,
    required this.action,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (hasFocus) {
        if (hasFocus) return;
        action(controllers);
      },
      child: child,
    );
  }
}

/// Composes multiple [FieldAction]s so a single field can trigger several
/// recomputations on blur.
FieldAction composeActions(List<FieldAction> actions) {
  return (controllers) {
    for (final a in actions) {
      a(controllers);
    }
  };
}

// ─── Reusable action factories ────────────────────────────────────────────

double? _parseNum(String? raw) {
  if (raw == null) return null;
  // Strip mask placeholders and any dangling trailing dot that the
  // NumericMaskFormatter may have left behind (e.g. `7.__` → `7`).
  var trimmed = raw.replaceAll('_', '').trim();
  if (trimmed.endsWith('.')) {
    trimmed = trimmed.substring(0, trimmed.length - 1);
  }
  if (trimmed.isEmpty) return null;
  return double.tryParse(trimmed.replaceAll(',', '.'));
}

/// Formats a computed numeric result so that whole values render as integers
/// (e.g. `63` not `63.0`) and decimals are capped at [fractionDigits] without
/// trailing zeros (e.g. `0.25`, `-1.2`).
String _formatNum(double value, {int fractionDigits = 2}) {
  if (!value.isFinite) return '';
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  final fixed = value.toStringAsFixed(fractionDigits);
  // Strip trailing zeros and a dangling decimal point.
  return fixed.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
}

/// Writes [newText] into [controller] only if it differs, preserving the
/// field's existing empty state when the computed result is empty.
void _setControllerText(TextEditingController? controller, String newText) {
  if (controller == null) return;
  if (controller.text == newText) return;
  controller.text = newText;
}

/// Populates [targetKey] with the sum of [aKey] and [bKey] when both are
/// filled. When only one is filled, writes that value × 2. When both are
/// empty, clears the target.
FieldAction sumOrDoubleAction({
  required String aKey,
  required String bKey,
  required String targetKey,
  int fractionDigits = 2,
}) {
  return (controllers) {
    final a = _parseNum(controllers[aKey]?.text);
    final b = _parseNum(controllers[bKey]?.text);

    String result;
    if (a != null && b != null) {
      result = _formatNum(a + b, fractionDigits: fractionDigits);
    } else if (a != null) {
      result = _formatNum(a * 2, fractionDigits: fractionDigits);
    } else if (b != null) {
      result = _formatNum(b * 2, fractionDigits: fractionDigits);
    } else {
      result = '';
    }
    _setControllerText(controllers[targetKey], result);
  };
}

/// Populates [targetKey] with the arithmetic mean of [aKey] and [bKey], but
/// only when both fields parse as numbers. Leaves the target untouched
/// otherwise (so a previously computed value is not overwritten on partial
/// input).
FieldAction averageAction({
  required String aKey,
  required String bKey,
  required String targetKey,
  int fractionDigits = 2,
}) {
  return (controllers) {
    final a = _parseNum(controllers[aKey]?.text);
    final b = _parseNum(controllers[bKey]?.text);
    if (a == null || b == null) return;
    _setControllerText(
      controllers[targetKey],
      _formatNum((a + b) / 2, fractionDigits: fractionDigits),
    );
  };
}

/// Populates [targetKey] with the keratometric cylinder computed from the
/// horizontal and vertical radii:
///
///   targetKey = (337.5 / aKey) - (337.5 / bKey)   [in diopters]
///
/// Only runs when both radii parse as non-zero numbers.
FieldAction keratometryCylAction({
  required String hKey,
  required String vKey,
  required String targetKey,
  int fractionDigits = 2,
}) {
  return (controllers) {
    final rh = _parseNum(controllers[hKey]?.text);
    final rv = _parseNum(controllers[vKey]?.text);
    if (rh == null || rv == null) return;
    if (rh == 0 || rv == 0) return;
    final cyl = (337.5 / rh) - (337.5 / rv);
    _setControllerText(
      controllers[targetKey],
      _formatNum(cyl, fractionDigits: fractionDigits),
    );
  };
}

/// Pads [fieldKey] with trailing fractional zeros so it always displays
/// exactly [fracDigits] digits after the decimal point (e.g. `7.5` → `7.50`).
/// Empty values stay empty; unparseable values are left untouched.
FieldAction padFractionalZerosAction({
  required String fieldKey,
  required int fracDigits,
}) {
  return (controllers) {
    final ctrl = controllers[fieldKey];
    if (ctrl == null) return;
    // Strip mask placeholders (`_`) and a trailing dot so a partially typed
    // masked value like `7.__` still pads cleanly to `7.00`.
    var raw = ctrl.text.replaceAll('_', '').trim();
    if (raw.endsWith('.')) raw = raw.substring(0, raw.length - 1);
    if (raw.isEmpty || raw == '+' || raw == '-') {
      // If the controller only ever held mask placeholders (or a lone
      // sign), clear it so the field reverts to a clean empty state.
      if (ctrl.text.isNotEmpty) ctrl.text = '';
      return;
    }
    // toStringAsFixed preserves `-` naturally but drops an explicit `+`.
    // Remember it so we can re-prepend after formatting.
    final keepPlus = raw.startsWith('+');
    final value = double.tryParse(raw.replaceAll(',', '.'));
    if (value == null) return;
    final formatted = value.toStringAsFixed(fracDigits);
    final withSign = keepPlus && !formatted.startsWith('-')
        ? '+$formatted'
        : formatted;
    _setControllerText(ctrl, withSign);
  };
}
