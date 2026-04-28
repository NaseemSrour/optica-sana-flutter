import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart' as intl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../db_flutter/models.dart';
import 'clinic_branding.dart';
import 'rx_formatter.dart';

/// Builds a clinically-formatted prescription PDF for a single customer.
///
/// Caller must provide whichever tests are available (latest glasses Rx,
/// latest contact-lens Rx). Sections without data are skipped — the PDF
/// never invents values.
///
/// All text labels are rendered in English. The PDF is intentionally
/// language-agnostic: SPH/CYL/AXIS column conventions are universal and
/// keeping the document monolingual avoids bidi-mixing artefacts when
/// the patient name or notes contain Hebrew/Arabic characters.
class PrescriptionPdfBuilder {
  /// Optional Unicode fonts. If the asset exists at the listed path the
  /// builder will use it for non-Latin runs (Hebrew/Arabic) so patient names
  /// and notes render correctly. If missing, those characters fall back to
  /// the PDF default font and may render as boxes — drop the .ttf at one of
  /// these paths to fix:
  ///
  ///   assets/fonts/NotoSans-Regular.ttf
  ///   assets/fonts/NotoSansHebrew-Regular.ttf
  ///   assets/fonts/NotoNaskhArabic-Regular.ttf
  static const _fontAssetPaths = <String>[
    'assets/fonts/NotoSans-Regular.ttf',
    'assets/fonts/NotoSansHebrew-Regular.ttf',
    'assets/fonts/NotoNaskhArabic-Regular.ttf',
  ];

  /// Mutable per-build translator. Set at the top of [build] and read by
  /// all `_t/_ta` callers. Not reentrant — callers must not run two
  /// `build()` invocations concurrently. In practice the export screen
  /// awaits each build before letting the user click again, so this is
  /// fine and avoids plumbing a translator through every helper.
  static _PdfTr _tr = _PdfTr.fallback();

  static String _t(String key) => _tr.t(key);
  static String _ta(String key, Map<String, String> args) =>
      _tr.t(key, args: args);

  /// Builds the PDF document and returns its bytes (suitable for sharing,
  /// printing, or saving to disk).
  ///
  /// The document is always rendered in English / LTR.
  static Future<Uint8List> build({
    required Customer customer,
    required GlassesTest? glasses,
    required ContactLensesTest? lenses,
    required ClinicBranding branding,
    Duration validity = const Duration(days: 90),
  }) async {
    _tr = await _PdfTr.load('en');
    final doc = pw.Document(
      title: 'Prescription - ${customer.fname} ${customer.lname}',
      author: branding.name,
    );

    final fallbackFonts = await _loadFallbackFonts();
    final theme = pw.ThemeData.withFont(
      base: fallbackFonts.isNotEmpty ? fallbackFonts.first : null,
      bold: fallbackFonts.isNotEmpty ? fallbackFonts.first : null,
      fontFallback: fallbackFonts,
    );

    const isRtl = false;
    final warnings = _collectWarnings(glasses);

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 36),
          theme: theme,
          textDirection: pw.TextDirection.ltr,
        ),
        header: (ctx) => _buildHeader(branding, isRtl),
        footer: (ctx) => _buildFooter(ctx, branding, isRtl),
        build: (ctx) => [
          _buildPatientBlock(customer, glasses, isRtl),
          pw.SizedBox(height: 14),
          if (glasses != null) ...[
            _buildDistanceBlock(glasses),
            pw.SizedBox(height: 10),
            _buildPdLine(glasses),
            pw.SizedBox(height: 14),
            if (_hasAnyAdd(glasses)) ...[
              _buildNearAdditionBlock(glasses),
              pw.SizedBox(height: 14),
            ],
          ] else
            _buildEmptyNotice(_t('rx_pdf_no_glasses')),
          if (lenses != null) ...[
            pw.SizedBox(height: 4),
            _buildContactLensBlock(lenses),
            pw.SizedBox(height: 14),
          ],
          _buildNotesBlock(customer, glasses, lenses, isRtl),
          if (warnings.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            _buildWarningsBlock(warnings),
          ],
          pw.SizedBox(height: 24),
          _buildSignatureBlock(glasses, validity),
        ],
      ),
    );

    return doc.save();
  }

  // ── Sections ─────────────────────────────────────────────────────────────

  static pw.Widget _buildHeader(ClinicBranding b, bool isRtl) {
    // Layout is fixed regardless of locale: clinic name + contact info on
    // the LEFT, logo on the RIGHT. Wrapped in an LTR Directionality so it
    // doesn't get mirrored if the document direction is ever flipped.
    return pw.Directionality(
      textDirection: pw.TextDirection.ltr,
      child: pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 8),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.6),
          ),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    b.name,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey900,
                      letterSpacing: 0.4,
                    ),
                  ),
                  if (b.phone.trim().isNotEmpty)
                    pw.Text(
                      '${_t('rx_pdf_label_phone')}: ${b.phone}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                  if (b.address.trim().isNotEmpty)
                    pw.Text(
                      b.address,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                ],
              ),
            ),
            pw.SizedBox(width: 16),
            if (b.logoBytes != null)
              pw.Container(
                width: 148,
                height: 148,
                child: pw.Image(
                  pw.MemoryImage(b.logoBytes!),
                  fit: pw.BoxFit.contain,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildPatientBlock(Customer c, GlassesTest? g, bool isRtl) {
    final age = _ageFromDob(c.birthDate);
    final examDate = g != null
        ? intl.DateFormat('dd/MM/yyyy').format(g.examDate)
        : kRxEmpty;
    final issued = intl.DateFormat('dd/MM/yyyy').format(DateTime.now());
    final dob = _formatDobDdMmYyyy(c.birthDate);
    // The clinic operator works in Hebrew, where the PDF library can't
    // shape the script natively. Reverse the customer's name characters
    // so the Hebrew letters appear in the correct visual order on screen.
    // Only the customer name is touched — every other field stays as-is.
    final patientName = _reverseString('${c.fname} ${c.lname}');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          _t('rx_pdf_section_title'),
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey800,
          ),
        ),
        pw.SizedBox(height: 6),
        _kvGrid(isRtl, [
          _Kv(_t('rx_pdf_label_patient'), patientName),
          _Kv(_t('rx_pdf_label_id'), formatText(c.ssn)),
          _Kv(_t('rx_pdf_label_dob'), dob),
          _Kv(_t('rx_pdf_label_age'), age?.toString() ?? kRxEmpty),
          _Kv(_t('rx_pdf_label_exam_date'), examDate),
          _Kv(_t('rx_pdf_label_examiner'), formatText(g?.examiner)),
          _Kv(_t('rx_pdf_label_issued'), issued),
        ]),
      ],
    );
  }

  static pw.Widget _buildDistanceBlock(GlassesTest g) {
    final rEmpty = isEyeRowEmpty(
      sph: g.rSphere,
      cyl: g.rCylinder,
      axis: g.rAxis,
      add: g.rAddRead,
    );
    final lEmpty = isEyeRowEmpty(
      sph: g.lSphere,
      cyl: g.lCylinder,
      axis: g.lAxis,
      add: g.lAddRead,
    );

    final headers = [
      _t('rx_pdf_col_eye'),
      'SPH',
      'CYL',
      'AXIS',
      'PRISM',
      'BASE',
      'V.A.',
    ];
    final rows = <List<String>>[];
    if (!rEmpty) {
      rows.add([
        'OD',
        formatSignedDiopter(g.rSphere, planoLabel: _t('rx_pdf_value_plano')),
        formatSignedDiopter(g.rCylinder, planoLabel: _t('rx_pdf_value_plano')),
        formatAxis(g.rAxis),
        formatPrism(g.rPrism),
        formatText(g.rBase),
        formatText(g.rVa),
      ]);
    }
    if (!lEmpty) {
      rows.add([
        'OS',
        formatSignedDiopter(g.lSphere, planoLabel: _t('rx_pdf_value_plano')),
        formatSignedDiopter(g.lCylinder, planoLabel: _t('rx_pdf_value_plano')),
        formatAxis(g.lAxis),
        formatPrism(g.lPrism),
        formatText(g.lBase),
        formatText(g.lVa),
      ]);
    }

    final monocularNote = rEmpty != lEmpty;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle(_t('rx_pdf_section_distance')),
        pw.SizedBox(height: 4),
        if (rows.isEmpty)
          pw.Text(
            _t('rx_pdf_no_data'),
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
          )
        else
          _ltrTable(headers: headers, rows: rows),
        if (monocularNote) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            _t('rx_pdf_monocular_note'),
            style: pw.TextStyle(
              fontSize: 9,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildPdLine(GlassesTest g) {
    final dist = formatDualPd(rPd: g.rPd, lPd: g.lPd, sumPd: g.sumPd);
    final near = formatMm(g.nearPd);
    final nearTxt = near == kRxEmpty ? near : '$near mm';
    return pw.Directionality(
      textDirection: pw.TextDirection.ltr,
      child: pw.Row(
        children: [
          pw.Text(
            '${_t('rx_pdf_label_pd')}: $dist',
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(width: 24),
          pw.Text(
            '${_t('rx_pdf_label_near_pd')}: $nearTxt',
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildNearAdditionBlock(GlassesTest g) {
    final rAdd = formatAdd(g.rAddRead);
    final lAdd = formatAdd(g.lAddRead);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle(_t('rx_pdf_section_near')),
        pw.SizedBox(height: 4),
        pw.Directionality(
          textDirection: pw.TextDirection.ltr,
          child: pw.Row(
            children: [
              pw.Text('OD ADD: $rAdd', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(width: 24),
              pw.Text('OS ADD: $lAdd', style: const pw.TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildContactLensBlock(ContactLensesTest l) {
    final headers = [
      _t('rx_pdf_col_eye'),
      'BC',
      'DIA',
      'SPH',
      'CYL',
      'AXIS',
      _t('rx_pdf_col_lens'),
    ];
    final rEmpty = isEyeRowEmpty(
      sph: l.rLensSph,
      cyl: l.rLensCyl,
      axis: l.rLensAxis,
    );
    final lEmpty = isEyeRowEmpty(
      sph: l.lLensSph,
      cyl: l.lLensCyl,
      axis: l.lLensAxis,
    );
    final rows = <List<String>>[];
    if (!rEmpty) {
      rows.add([
        'OD',
        formatMm(l.rBaseCurveNumerator),
        formatMm(l.rDiameter),
        formatSignedDiopter(l.rLensSph, planoLabel: _t('rx_pdf_value_plano')),
        formatSignedDiopter(l.rLensCyl, planoLabel: _t('rx_pdf_value_plano')),
        formatAxis(l.rLensAxis),
        _lensName(l.rBrand, l.rManufacturer),
      ]);
    }
    if (!lEmpty) {
      rows.add([
        'OS',
        formatMm(l.lBaseCurveNumerator),
        formatMm(l.lDiameter),
        formatSignedDiopter(l.lLensSph, planoLabel: _t('rx_pdf_value_plano')),
        formatSignedDiopter(l.lLensCyl, planoLabel: _t('rx_pdf_value_plano')),
        formatAxis(l.lLensAxis),
        _lensName(l.lBrand, l.lManufacturer),
      ]);
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle(_t('rx_pdf_section_contacts')),
        pw.SizedBox(height: 4),
        if (rows.isEmpty)
          pw.Text(
            _t('rx_pdf_no_data'),
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
          )
        else
          _ltrTable(headers: headers, rows: rows),
      ],
    );
  }

  static pw.Widget _buildNotesBlock(
    Customer c,
    GlassesTest? g,
    ContactLensesTest? l,
    bool isRtl,
  ) {
    final parts = <String>[];
    void add(String? raw) {
      final t = raw?.trim();
      if (t != null && t.isNotEmpty) parts.add(t);
    }

    add(g?.diagnosis);
    if (parts.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(_t('rx_pdf_section_notes')),
        pw.SizedBox(height: 4),
        pw.Text(
          parts.join('\n'),
          style: const pw.TextStyle(fontSize: 11),
          textAlign: isRtl ? pw.TextAlign.right : pw.TextAlign.left,
        ),
      ],
    );
  }

  static pw.Widget _buildWarningsBlock(List<String> warnings) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        border: pw.Border.all(color: PdfColors.amber700, width: 0.6),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _t('rx_pdf_warnings_title'),
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.orange900,
            ),
          ),
          pw.SizedBox(height: 4),
          for (final w in warnings)
            pw.Bullet(
              text: w,
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.orange900,
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatureBlock(GlassesTest? g, Duration validity) {
    final issued = DateTime.now();
    final until = issued.add(validity);
    final issuedStr = intl.DateFormat('dd/MM/yyyy').format(issued);
    final untilStr = intl.DateFormat('dd/MM/yyyy').format(until);
    final months = (validity.inDays / 30).round();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 6),
        pw.Directionality(
          textDirection: pw.TextDirection.ltr,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '${_t('rx_pdf_label_issued')}: $issuedStr',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                _ta('rx_pdf_label_valid_until', {
                  'date': untilStr,
                  'months': '$months',
                }),
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 28),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(height: 0.6, color: PdfColors.grey700),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '${_t('rx_pdf_label_examiner')}: ${formatText(g?.examiner)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 32),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(height: 0.6, color: PdfColors.grey700),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    _t('rx_pdf_label_signature'),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context ctx, ClinicBranding b, bool isRtl) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.4),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              _t('rx_pdf_disclaimer'),
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            '${ctx.pageNumber} / ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  // ── Building blocks ─────────────────────────────────────────────────────

  static pw.Widget _sectionTitle(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blueGrey800,
      ),
    );
  }

  /// Two-column key/value grid that flips horizontal alignment for RTL.
  static pw.Widget _kvGrid(bool isRtl, List<_Kv> items) {
    final rows = <pw.TableRow>[];
    for (int i = 0; i < items.length; i += 2) {
      final left = items[i];
      final right = i + 1 < items.length ? items[i + 1] : null;
      rows.add(
        pw.TableRow(
          children: [
            _kvCell(left, isRtl),
            right != null ? _kvCell(right, isRtl) : pw.SizedBox(),
          ],
        ),
      );
    }
    return pw.Table(
      columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1)},
      children: rows,
    );
  }

  static pw.Widget _kvCell(_Kv kv, bool isRtl) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Text(
            '${kv.label}: ',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              kv.value,
              style: const pw.TextStyle(fontSize: 10),
              textAlign: isRtl ? pw.TextAlign.right : pw.TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  /// Forces LTR for the optical data table — column order (SPH/CYL/AXIS) is
  /// universal regardless of UI locale.
  static pw.Widget _ltrTable({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return pw.Directionality(
      textDirection: pw.TextDirection.ltr,
      child: pw.TableHelper.fromTextArray(
        headers: headers,
        data: rows,
        cellAlignment: pw.Alignment.center,
        headerAlignment: pw.Alignment.center,
        headerStyle: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
        cellStyle: const pw.TextStyle(fontSize: 11),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.4),
      ),
    );
  }

  static pw.Widget _buildEmptyNotice(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.4),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  static List<String> _collectWarnings(GlassesTest? g) {
    if (g == null) return const [];
    final out = <String>[];
    if (isCylNonZero(g.rCylinder) && formatAxis(g.rAxis) == kRxEmpty) {
      out.add(_ta('rx_pdf_warn_axis', {'eye': 'OD'}));
    }
    if (isCylNonZero(g.lCylinder) && formatAxis(g.lAxis) == kRxEmpty) {
      out.add(_ta('rx_pdf_warn_axis', {'eye': 'OS'}));
    }
    if (isPrismNonZero(g.rPrism) && formatText(g.rBase) == kRxEmpty) {
      out.add(_ta('rx_pdf_warn_base', {'eye': 'OD'}));
    }
    if (isPrismNonZero(g.lPrism) && formatText(g.lBase) == kRxEmpty) {
      out.add(_ta('rx_pdf_warn_base', {'eye': 'OS'}));
    }
    return out;
  }

  static bool _hasAnyAdd(GlassesTest g) {
    return formatAdd(g.rAddRead) != kRxEmpty ||
        formatAdd(g.lAddRead) != kRxEmpty;
  }

  static String _lensName(String? brand, String? manufacturer) {
    final b = (brand ?? '').trim();
    final m = (manufacturer ?? '').trim();
    if (b.isEmpty && m.isEmpty) return kRxEmpty;
    if (b.isEmpty) return m;
    if (m.isEmpty) return b;
    return '$b ($m)';
  }

  /// Reverses the characters of [s]. Used to manually flip the customer's
  /// Hebrew name for the PDF, since the embedded font doesn't shape the
  /// script natively. Surrogate-pair aware via [Runes] so non-BMP code
  /// points (rare in Hebrew but cheap to handle) survive the round-trip.
  static String _reverseString(String s) {
    if (s.isEmpty) return s;
    return String.fromCharCodes(s.runes.toList().reversed);
  }

  /// Renders a YYYY-MM-DD birth date stored in the DB as DD/MM/YYYY.
  /// Returns the placeholder constant when the input is missing or
  /// unparsable so the PDF never shows a malformed date.
  static String _formatDobDdMmYyyy(String? raw) {
    if (raw == null || raw.trim().isEmpty) return kRxEmpty;
    try {
      final d = intl.DateFormat('yyyy-MM-dd').parse(raw.trim());
      return intl.DateFormat('dd/MM/yyyy').format(d);
    } catch (_) {
      return raw.trim();
    }
  }

  static int? _ageFromDob(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final d = intl.DateFormat('yyyy-MM-dd').parse(raw.trim());
      final now = DateTime.now();
      var age = now.year - d.year;
      if (now.month < d.month || (now.month == d.month && now.day < d.day)) {
        age--;
      }
      return age >= 0 ? age : null;
    } catch (_) {
      return null;
    }
  }

  /// Loads any present optional Unicode fonts. Each missing asset is
  /// silently skipped so this never throws.
  static Future<List<pw.Font>> _loadFallbackFonts() async {
    final fonts = <pw.Font>[];
    for (final path in _fontAssetPaths) {
      try {
        final data = await rootBundle.load(path);
        fonts.add(pw.Font.ttf(data));
      } catch (_) {
        // Asset not present — fall back to default. Bundle the .ttf at the
        // path documented above to fix Hebrew/Arabic glyph rendering.
      }
    }
    return fonts;
  }
}

class _Kv {
  final String label;
  final String value;
  const _Kv(this.label, this.value);
}

/// Loads a single locale's translation JSON from the bundled assets and
/// exposes a `t(key, {args})` lookup.
///
/// Independent of `easy_localization`'s global state — picking `en` here
/// renders an English PDF even if the user's app locale is `he`. Falls
/// back to returning the key itself if the JSON or key is missing, so a
/// typo never crashes a build.
class _PdfTr {
  final Map<String, String> _entries;

  _PdfTr._(this._entries);

  factory _PdfTr.fallback() => _PdfTr._(const {});

  static Future<_PdfTr> load(String localeCode) async {
    final supported = {'en', 'he', 'ar'};
    final code = localeCode.toLowerCase().split('_').first;
    final useCode = supported.contains(code) ? code : 'en';
    try {
      final raw = await rootBundle.loadString(
        'assets/translations/$useCode.json',
      );
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return _PdfTr._(decoded.map((k, v) => MapEntry(k, v.toString())));
    } catch (_) {
      return _PdfTr.fallback();
    }
  }

  String t(String key, {Map<String, String>? args}) {
    var s = _entries[key] ?? key;
    if (args != null) {
      args.forEach((k, v) {
        s = s.replaceAll('{$k}', v);
      });
    }
    return s;
  }
}

/// Suggests a sensible filename for the produced PDF (no path separators
/// or unsafe characters).
String prescriptionFileName(Customer c) {
  final name = '${c.fname}_${c.lname}'.trim().replaceAll(RegExp(r'\s+'), '_');
  final safe = name.replaceAll(
    RegExp(r'[^A-Za-z0-9_\u0590-\u05FF\u0600-\u06FF-]'),
    '',
  );
  final stamp = intl.DateFormat('yyyyMMdd').format(DateTime.now());
  final base = safe.isEmpty ? 'prescription' : safe;
  return '${base}_$stamp.pdf';
}
