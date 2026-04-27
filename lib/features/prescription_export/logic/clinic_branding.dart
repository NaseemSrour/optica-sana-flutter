import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

/// Branding shown on the prescription PDF header.
///
/// Currently sourced from translation keys (`rx_pdf_clinic_*`) so non-technical
/// staff can change the clinic name / phone / address by editing the locale
/// JSONs. Promote to `AppSettings` if/when an in-app settings UI is added.
class ClinicBranding {
  final String name;
  final String phone;
  final String address;
  final Uint8List? logoBytes;

  const ClinicBranding({
    required this.name,
    required this.phone,
    required this.address,
    this.logoBytes,
  });

  /// Loads the bundled logo from assets. Returns `null` on failure so the PDF
  /// builder can render a header without the image rather than crashing.
  static Future<Uint8List?> loadLogo({
    String assetPath = 'assets/images/logo.png',
  }) async {
    try {
      final data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}
