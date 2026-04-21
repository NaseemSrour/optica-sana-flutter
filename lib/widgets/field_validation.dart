import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import 'app_notification.dart';

/// A validator that inspects the current values of several fields and returns
/// an error message (already localized) to display, or `null` when valid.
typedef FieldCheck =
    String? Function(Map<String, TextEditingController> controllers);

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
