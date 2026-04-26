import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-facing app preferences persisted across restarts.
///
/// Currently exposes the font size used for "inserted value" inputs outside
/// of table cells (i.e. the amber user-typed text). Table cells intentionally
/// keep a fixed size so their layout stays stable.
class AppSettings extends ChangeNotifier {
  AppSettings._();

  static final AppSettings instance = AppSettings._();

  static const String _prefsKey = 'input_font_size';
  static const String _boldPrefsKey = 'input_bold';
  static const double defaultInputFontSize = 16.0;
  static const double minInputFontSize = 12.0;
  static const double maxInputFontSize = 36.0;
  static const bool defaultInputBold = false;

  double _inputFontSize = defaultInputFontSize;
  double get inputFontSize => _inputFontSize;

  bool _inputBold = defaultInputBold;
  bool get inputBold => _inputBold;

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final stored = _prefs!.getDouble(_prefsKey);
    if (stored != null &&
        stored >= minInputFontSize &&
        stored <= maxInputFontSize) {
      _inputFontSize = stored;
    }
    _inputBold = _prefs!.getBool(_boldPrefsKey) ?? defaultInputBold;
  }

  Future<void> setInputFontSize(double size) async {
    final clamped = size.clamp(minInputFontSize, maxInputFontSize).toDouble();
    if (clamped == _inputFontSize) return;
    _inputFontSize = clamped;
    notifyListeners();
    await _prefs?.setDouble(_prefsKey, _inputFontSize);
  }

  Future<void> resetInputFontSize() => setInputFontSize(defaultInputFontSize);

  Future<void> setInputBold(bool bold) async {
    if (bold == _inputBold) return;
    _inputBold = bold;
    notifyListeners();
    await _prefs?.setBool(_boldPrefsKey, _inputBold);
  }
}
