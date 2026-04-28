import 'dart:io' show Directory, File, Platform, Process;
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../db_flutter/models.dart';
import '../../../flutter_services/customer_service.dart';
import '../../../themes/app_theme.dart';
import '../../../widgets/app_notification.dart';
import '../logic/clinic_branding.dart';
import '../logic/prescription_pdf_builder.dart';

/// Save / share a prescription PDF for a customer.
///
/// Loads the latest glasses + contact-lens tests from `CustomerService`,
/// generates the PDF via [PrescriptionPdfBuilder], and offers two actions:
///
///  * **Save** — writes to `Documents/OptiSana/Prescriptions/<filename>.pdf`
///    on desktop / app documents on mobile, then opens it with the OS
///    default PDF handler so the user can print from there.
///  * **Share** — writes to a temp file and forwards to the system share
///    sheet (WhatsApp, email, etc.) on mobile/desktop where supported.
///
/// We deliberately do NOT in-app preview the PDF here. The `printing`
/// package was dropped because its Windows build downloads pdfium at
/// CMake-configure time and that download fails on locked-down networks.
/// Letting the OS handle preview/print is more reliable and offline-safe.
class PrescriptionExportScreen extends StatefulWidget {
  final Customer customer;
  final CustomerService customerService;

  /// Optional override: when supplied, the PDF reflects this exact glasses
  /// test instead of the customer's latest. Used by the history screen so
  /// the clinician can export the test currently on view.
  final GlassesTest? overrideGlasses;

  /// Optional override for the contact-lens test, mirroring [overrideGlasses].
  final ContactLensesTest? overrideLenses;

  /// When `true`, the export skips the contact-lens section even if a
  /// lens record exists. Useful when the entry point is the glasses
  /// history screen and the user only wants the spectacle Rx.
  final bool excludeContactLenses;

  const PrescriptionExportScreen({
    super.key,
    required this.customer,
    required this.customerService,
    this.overrideGlasses,
    this.overrideLenses,
    this.excludeContactLenses = false,
  });

  @override
  State<PrescriptionExportScreen> createState() =>
      _PrescriptionExportScreenState();
}

class _PrescriptionExportScreenState extends State<PrescriptionExportScreen> {
  late Future<_RxBundle> _bundleFuture;
  Uint8List? _cachedPdfBytes;
  String? _lastSavedPath;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _bundleFuture = _loadBundle();
  }

  Future<_RxBundle> _loadBundle() async {
    final id = widget.customer.id;
    final glasses =
        widget.overrideGlasses ??
        await widget.customerService.getLatestGlasses(id);
    final lenses = widget.excludeContactLenses
        ? null
        : (widget.overrideLenses ??
              await widget.customerService.getLatestContactLenses(id));
    final logo = await ClinicBranding.loadLogo();
    return _RxBundle(
      glasses: glasses,
      lenses: lenses,
      branding: ClinicBranding(
        name: 'OPTISANA',
        phone: 'RAMA: 04-9580336 / KFAR VRADIM: 04-9570043',
        address: '',
        logoBytes: logo,
      ),
    );
  }

  Future<Uint8List> _generate(_RxBundle b) async {
    final cached = _cachedPdfBytes;
    if (cached != null) return cached;
    final bytes = await PrescriptionPdfBuilder.build(
      customer: widget.customer,
      glasses: b.glasses,
      lenses: b.lenses,
      branding: b.branding,
    );
    _cachedPdfBytes = bytes;
    return bytes;
  }

  /// Resolves a stable folder under the user's Documents dir on desktop and
  /// the app documents dir on mobile. Created if missing.
  Future<Directory> _resolveSaveDir() async {
    Directory base;
    if (kIsWeb) {
      // Web is unsupported for direct file writes; share path is taken instead.
      base = await getTemporaryDirectory();
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // `getApplicationDocumentsDirectory` resolves to the user's Documents
      // folder on Windows/macOS/Linux — exactly what a clinician expects.
      base = await getApplicationDocumentsDirectory();
    } else {
      base = await getApplicationDocumentsDirectory();
    }
    final dir = Directory(p.join(base.path, 'OptiSana', 'Prescriptions'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _save(_RxBundle b) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _generate(b);
      final dir = await _resolveSaveDir();
      final filename = prescriptionFileName(widget.customer);
      final path = p.join(dir.path, filename);
      await File(path).writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      setState(() {
        _lastSavedPath = path;
        _busy = false;
      });
      AppNotification.show(
        context,
        'rx_pdf_saved'.tr(namedArgs: {'path': path}),
        type: NotificationType.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppNotification.show(
        context,
        'rx_pdf_save_error'.tr(namedArgs: {'error': e.toString()}),
        type: NotificationType.error,
      );
    }
  }

  /// Opens [path] using the OS default handler for `.pdf`. From there the
  /// user can print, zoom, etc. Falls back to a notification on failure.
  Future<void> _openExternally(String path) async {
    try {
      if (Platform.isWindows) {
        // `start` is a cmd builtin; the empty string is the window-title arg.
        await Process.start('cmd', ['/c', 'start', '', path]);
      } else if (Platform.isMacOS) {
        await Process.start('open', [path]);
      } else if (Platform.isLinux) {
        await Process.start('xdg-open', [path]);
      } else {
        // Mobile platforms: hand off to share sheet so the user can pick
        // a viewer / print app.
        await Share.shareXFiles([XFile(path, mimeType: 'application/pdf')]);
      }
    } catch (e) {
      if (!mounted) return;
      AppNotification.show(
        context,
        'rx_pdf_open_error'.tr(namedArgs: {'error': e.toString()}),
        type: NotificationType.error,
      );
    }
  }

  Future<void> _share(_RxBundle b) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _generate(b);
      final filename = prescriptionFileName(widget.customer);
      // share_plus needs a real file path. Use the temp dir so we don't
      // pollute the user's Documents folder with each share.
      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, filename));
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf', name: filename)],
        subject: 'rx_pdf_share_subject'.tr(
          namedArgs: {
            'name': '${widget.customer.fname} ${widget.customer.lname}',
          },
        ),
      );
      if (!mounted) return;
      setState(() => _busy = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppNotification.show(
        context,
        'rx_pdf_share_error'.tr(namedArgs: {'error': e.toString()}),
        type: NotificationType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'rx_pdf_screen_title'.tr(
            namedArgs: {
              'name': '${widget.customer.fname} ${widget.customer.lname}',
            },
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: FutureBuilder<_RxBundle>(
          future: _bundleFuture,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'rx_pdf_load_error'.tr(
                      namedArgs: {'error': snap.error.toString()},
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              );
            }
            final bundle = snap.data!;
            if (bundle.glasses == null && bundle.lenses == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'rx_pdf_nothing_to_export'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.label,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }
            return _buildBody(bundle);
          },
        ),
      ),
    );
  }

  Widget _buildBody(_RxBundle b) {
    final saved = _lastSavedPath;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            color: AppColors.surfaceVariant,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.picture_as_pdf_outlined,
                        size: 28,
                        color: AppColors.accentTeal,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'rx_pdf_summary_title'.tr(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.displayValue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _summaryLine(
                    Icons.person_outline,
                    '${widget.customer.fname} ${widget.customer.lname}',
                  ),
                  if (b.glasses != null)
                    _summaryLine(
                      Icons.remove_red_eye_outlined,
                      widget.overrideGlasses != null
                          ? 'rx_pdf_summary_selected_glasses'.tr()
                          : 'rx_pdf_summary_has_glasses'.tr(),
                    ),
                  if (b.lenses != null)
                    _summaryLine(
                      Icons.lens_outlined,
                      widget.overrideLenses != null
                          ? 'rx_pdf_summary_selected_contacts'.tr()
                          : 'rx_pdf_summary_has_contacts'.tr(),
                    ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: _busy ? null : () => _save(b),
                        icon: const Icon(Icons.save_alt_outlined),
                        label: Text('rx_pdf_btn_save'.tr()),
                      ),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : () => _share(b),
                        icon: const Icon(Icons.share_outlined),
                        label: Text('rx_pdf_btn_share'.tr()),
                      ),
                    ],
                  ),
                  if (_busy) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                  ],
                  if (saved != null) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      'rx_pdf_saved_at'.tr(),
                      style: const TextStyle(
                        color: AppColors.label,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      saved,
                      style: const TextStyle(
                        color: AppColors.displayValue,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () => _openExternally(saved),
                        icon: const Icon(Icons.open_in_new),
                        label: Text('rx_pdf_btn_open'.tr()),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'rx_pdf_print_hint'.tr(),
                    style: const TextStyle(
                      color: AppColors.label,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.label),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.displayValue,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RxBundle {
  final GlassesTest? glasses;
  final ContactLensesTest? lenses;
  final ClinicBranding branding;

  const _RxBundle({
    required this.glasses,
    required this.lenses,
    required this.branding,
  });
}
