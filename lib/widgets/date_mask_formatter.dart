import 'package:flutter/services.dart';

/// Keeps a text field in `DD/MM/YYYY` mask format.
///
/// Fixed slashes at positions 2 and 5, underscores for empty digit slots.
/// Cursor auto-advances to the next empty slot after each digit is entered.
class DateMaskFormatter extends TextInputFormatter {
  static const List<int> _digitPos = [0, 1, 3, 4, 6, 7, 8, 9];

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
        text: '__/__/____',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    final clamped = digits.length > 8 ? digits.substring(0, 8) : digits;

    final buf = StringBuffer();
    int di = 0;
    for (int i = 0; i < 10; i++) {
      if (i == 2 || i == 5) {
        buf.write('/');
      } else {
        buf.write(di < clamped.length ? clamped[di++] : '_');
      }
    }

    final cursor = clamped.length >= 8 ? 10 : _digitPos[clamped.length];

    return TextEditingValue(
      text: buf.toString(),
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}
