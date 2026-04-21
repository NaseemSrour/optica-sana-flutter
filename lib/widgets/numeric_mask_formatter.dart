import 'package:flutter/services.dart';

/// A masking [TextInputFormatter] that renders a fixed-width numeric slot
/// using underscore placeholders for not-yet-typed digits, so the user can
/// see exactly where the caret stands relative to the mask while typing.
///
/// Shape: [intDigits] slots before the decimal point, a literal `.`, and
/// [fracDigits] digit slots after it. Untyped positions render as `_`.
///
/// When [allowSign] is true, a leading `+`/`-` shares the integer slot
/// budget — one of the [intDigits] positions is consumed by the sign, so
/// the total width stays constant whether or not a sign is typed.
///
/// Example — `NumericMaskFormatter(intDigits: 1, fracDigits: 2)`:
///   * empty field stays empty (no template shown until the first keystroke)
///   * typing `7`            → `7.__`
///   * typing `5` next       → `7.5_`
///   * typing `0` next       → `7.50`
///
/// Example — `NumericMaskFormatter(intDigits: 3, fracDigits: 2, allowSign: true)`:
///   * typing `-`            → `-__.__`  (sign takes one int slot)
///   * typing `7` next       → `-7_.__`
///   * typing `5` next       → `-75.__`
///   * typing `7` without sign → `7__.__`  (unsigned uses all 3 int slots)
///   * typing `250` unsigned → `250.__`
///
/// Commas are normalized to `.` so European keyboards work. Pasting input
/// that would overflow the configured slots is rejected (the previous
/// value is kept).
class NumericMaskFormatter extends TextInputFormatter {
  final int intDigits;
  final int fracDigits;
  final bool allowSign;

  NumericMaskFormatter({
    required this.intDigits,
    required this.fracDigits,
    this.allowSign = false,
  });

  static const _placeholder = '_';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var input = newValue.text;

    // Extract optional leading sign. We only honor a `+`/`-` at the very
    // start — a sign buried mid-string is discarded as noise.
    String sign = '';
    if (allowSign && input.isNotEmpty) {
      final first = input[0];
      if (first == '+' || first == '-') {
        sign = first;
        input = input.substring(1);
      }
    }

    // Extract just the typed digits from whatever the framework handed us.
    // Underscores, dots, commas and anything else are discarded.
    final digits = input.replaceAll(RegExp(r'\D'), '');

    // Fully empty field (no sign, no digits): collapse to truly empty so
    // the template only appears after the user actually starts typing.
    if (sign.isEmpty && digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // When a sign is present it consumes one of the int-side slots, so
    // there are fewer digit slots available on that side.
    final intSlotCount = sign.isNotEmpty ? intDigits - 1 : intDigits;

    // Too many digits for the available slots → reject the edit.
    if (digits.length > intSlotCount + fracDigits) {
      return oldValue;
    }

    // Split digits between int and frac halves, padding the unused slots
    // with underscores.
    final intPart = digits.length >= intSlotCount
        ? digits.substring(0, intSlotCount)
        : digits.padRight(intSlotCount, _placeholder);

    String fracPart = '';
    if (fracDigits > 0) {
      final typedFrac = digits.length > intSlotCount
          ? digits.substring(intSlotCount)
          : '';
      fracPart = typedFrac.padRight(fracDigits, _placeholder);
    }

    final body = fracDigits > 0 ? '$intPart.$fracPart' : intPart;
    final text = '$sign$body';

    // Put the caret right after the last typed digit (or the sign, if no
    // digits yet) so the next keystroke lands in the correct slot.
    final int cursor;
    if (digits.length <= intSlotCount) {
      cursor = sign.length + digits.length;
    } else {
      // +1 accounts for the literal dot between int and frac halves.
      cursor = sign.length + intSlotCount + 1 + (digits.length - intSlotCount);
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}

/// Removes mask placeholders from [raw] so the value can be stored or
/// parsed. Also trims a dangling trailing `.` left when only integer
/// digits were typed (e.g. `7.__` → `7`). A lone leading sign with no
/// digits (`-` or `+`) collapses to empty.
String stripNumericMask(String raw) {
  var cleaned = raw.replaceAll('_', '');
  if (cleaned.endsWith('.')) {
    cleaned = cleaned.substring(0, cleaned.length - 1);
  }
  if (cleaned == '+' || cleaned == '-') return '';
  return cleaned;
}
