import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only, lightweight password gate for the Welcome screen.
///
/// Security model:
///  - The password itself is never stored. We persist only a random salt
///    and the SHA-256 hash of (salt + password).
///  - Storage is [SharedPreferences] (platform-local). This is **not** a
///    cryptographic secret store; it is a UX-level lock to keep casual
///    onlookers out of customer data on a shared machine. Anyone with
///    filesystem access can wipe the preference file to reset the lock.
///  - If the user has not set a password yet ([hasPassword] is false),
///    the Welcome screen lets the user through without a prompt. A
///    password can be configured from the Settings screen.
class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const _hashKey = 'pwd_hash';
  static const _saltKey = 'pwd_salt';

  SharedPreferences? _prefs;
  String? _hash;
  String? _salt;

  bool get hasPassword => _hash != null && _hash!.isNotEmpty;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _hash = _prefs!.getString(_hashKey);
    _salt = _prefs!.getString(_saltKey);
  }

  /// Returns true when [password] matches the stored credential, or when
  /// no password has been configured (open entry).
  bool verify(String password) {
    if (!hasPassword) return true;
    return _computeHash(password, _salt!) == _hash;
  }

  /// Sets (or replaces) the app password. Pass an empty string to clear.
  Future<void> setPassword(String password) async {
    if (password.isEmpty) {
      await _prefs?.remove(_hashKey);
      await _prefs?.remove(_saltKey);
      _hash = null;
      _salt = null;
    } else {
      final salt = _generateSalt();
      final hash = _computeHash(password, salt);
      await _prefs?.setString(_saltKey, salt);
      await _prefs?.setString(_hashKey, hash);
      _salt = salt;
      _hash = hash;
    }
    notifyListeners();
  }

  Future<void> clearPassword() => setPassword('');

  String _generateSalt([int length = 16]) {
    final rand = Random.secure();
    final bytes = List<int>.generate(length, (_) => rand.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _computeHash(String password, String salt) {
    final bytes = utf8.encode('$salt::$password');
    return sha256.convert(bytes).toString();
  }
}
