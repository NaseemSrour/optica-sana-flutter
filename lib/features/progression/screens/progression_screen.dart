import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../db_flutter/models.dart';
import '../../../flutter_services/customer_service.dart';
import '../../../themes/app_theme.dart';
import '../../../widgets/app_notification.dart';
import '../logic/dummy_data.dart';
import '../logic/progression_view_model.dart';
import '../models/rx_data_point.dart';
import '../widgets/progression_chart.dart';
import '../widgets/progression_delta_strip.dart';
import '../widgets/progression_legend.dart';
import '../widgets/progression_summary.dart';

/// Stand-alone screen that hosts the prescription-progression visualizations.
///
/// **Alpha-testing entry point** — the entire feature lives under
/// `lib/features/progression/`. Wire this screen up wherever the host UI
/// wants the patient/clinician to view the trend (e.g. an action button on
/// `CustomerDetailsScreen`).
///
/// Pass [useDummyData] to bypass the database and render a generated
/// 8-year history. Useful for visual QA before real patients have enough
/// visits on file.
class ProgressionScreen extends StatefulWidget {
  final Customer customer;
  final CustomerService customerService;
  final bool useDummyData;

  const ProgressionScreen({
    super.key,
    required this.customer,
    required this.customerService,
    this.useDummyData = false,
  });

  @override
  State<ProgressionScreen> createState() => _ProgressionScreenState();
}

class _ProgressionScreenState extends State<ProgressionScreen> {
  late Future<List<RxDataPoint>> _future;
  RxMetric _metric = RxMetric.sphere;
  bool _invertY = false;

  // Notes panel state — kept local so the chart isn't rebuilt on every keystroke.
  late final TextEditingController _notesController;
  bool _isEditingNotes = false;
  bool _savingNotes = false;
  String _savedNotes = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
    _savedNotes = widget.customer.notes ?? '';
    _notesController = TextEditingController(text: _savedNotes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<List<RxDataPoint>> _load() async {
    try {
      final tests = widget.useDummyData
          ? ProgressionDummyData.generate(customerId: widget.customer.id)
          : await widget.customerService.getGlassesHistory(widget.customer.id);
      return tests.map(RxDataPoint.fromGlassesTest).toList();
    } catch (e) {
      if (mounted) {
        AppNotification.show(
          context,
          'prog_load_error'.tr(namedArgs: {'error': e.toString()}),
          type: NotificationType.error,
        );
      }
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'prog_title'.tr(
            namedArgs: {
              'name': '${widget.customer.fname} ${widget.customer.lname}',
            },
          ),
        ),
        actions: [
          IconButton(
            tooltip: _invertY
                ? 'prog_flip_y_inverted'.tr()
                : 'prog_flip_y'.tr(),
            icon: Icon(_invertY ? Icons.swap_vert : Icons.swap_vert_outlined),
            onPressed: () => setState(() => _invertY = !_invertY),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: FutureBuilder<List<RxDataPoint>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final points = snap.data ?? const [];
            final vm = ProgressionViewModel(points: points, metric: _metric);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProgressionSummary(viewModel: vm),
                  const SizedBox(height: 16),
                  _buildToolbar(),
                  const SizedBox(height: 12),
                  Card(
                    color: AppColors.surfaceVariant,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _metric == RxMetric.sphere
                                    ? 'prog_chart_title_sphere'.tr()
                                    : 'prog_chart_title_cylinder'.tr(),
                                style: const TextStyle(
                                  color: AppColors.displayValue,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              const ProgressionLegend(),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ProgressionChart(viewModel: vm, invertY: _invertY),
                          if (vm.shouldEnableScroll) ...[
                            const SizedBox(height: 6),
                            Text(
                              'prog_scroll_tip'.tr(),
                              style: const TextStyle(
                                color: AppColors.label,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (vm.hasEnoughData)
                    Card(
                      color: AppColors.surfaceVariant,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ProgressionDeltaStrip(viewModel: vm),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _buildNotesCard(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SegmentedButton<RxMetric>(
          segments: [
            ButtonSegment(
              value: RxMetric.sphere,
              label: Text('prog_metric_sphere'.tr()),
              icon: const Icon(Icons.show_chart),
            ),
            ButtonSegment(
              value: RxMetric.cylinder,
              label: Text('prog_metric_cylinder'.tr()),
              icon: const Icon(Icons.timeline),
            ),
          ],
          selected: {_metric},
          onSelectionChanged: (s) => setState(() => _metric = s.first),
        ),
        FilterChip(
          label: Text('prog_invert_y'.tr()),
          tooltip: 'prog_invert_y_tooltip'.tr(),
          selected: _invertY,
          onSelected: (v) => setState(() => _invertY = v),
          selectedColor: AppColors.primary.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  /// Inline notes editor at the bottom of the progression screen.
  ///
  /// Mirrors the read/edit toggle pattern from `CustomerDetailsScreen`:
  /// shows the saved notes in full (no maxLines cap) when read-only, and
  /// expands to a 5-line editor when toggled. Saves through
  /// `CustomerService.updateCustomer`, which runs the same validation as
  /// the customer details screen.
  Widget _buildNotesCard() {
    final hasNotes = _savedNotes.trim().isNotEmpty;
    return Card(
      color: AppColors.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.sticky_note_2_outlined,
                  color: AppColors.label,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'field_notes'.tr(),
                  style: const TextStyle(
                    color: AppColors.displayValue,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_savingNotes)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (_isEditingNotes) ...[
                  IconButton(
                    tooltip: 'prog_notes_cancel'.tr(),
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _notesController.text = _savedNotes;
                        _isEditingNotes = false;
                      });
                    },
                  ),
                  IconButton(
                    tooltip: 'prog_notes_save'.tr(),
                    icon: const Icon(Icons.save, color: AppColors.inputValue),
                    onPressed: _saveNotes,
                  ),
                ] else
                  IconButton(
                    tooltip: 'prog_notes_edit'.tr(),
                    icon: const Icon(Icons.edit, color: AppColors.primary),
                    onPressed: () => setState(() => _isEditingNotes = true),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isEditingNotes)
              TextField(
                controller: _notesController,
                enabled: !_savingNotes,
                maxLines: 5,
                minLines: 3,
                style: const TextStyle(
                  color: AppColors.inputValue,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'prog_notes_hint'.tr(),
                  isDense: true,
                ),
              )
            else if (hasNotes)
              SelectableText(
                _savedNotes,
                style: const TextStyle(
                  color: AppColors.displayValue,
                  fontSize: 14,
                ),
              )
            else
              Text(
                'prog_notes_empty'.tr(),
                style: const TextStyle(
                  color: AppColors.label,
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveNotes() async {
    final newNotes = _notesController.text;
    if (newNotes == _savedNotes) {
      setState(() => _isEditingNotes = false);
      return;
    }
    setState(() => _savingNotes = true);
    try {
      // Mutate the existing customer object so the upstream
      // CustomerDetailsScreen reflects the edit when the user navigates back.
      widget.customer.notes = newNotes;
      await widget.customerService.updateCustomer(widget.customer);
      if (!mounted) return;
      setState(() {
        _savedNotes = newNotes;
        _isEditingNotes = false;
        _savingNotes = false;
      });
      AppNotification.show(
        context,
        'prog_notes_saved'.tr(),
        type: NotificationType.success,
      );
    } catch (e) {
      // Roll back the in-memory mutation so we don't show stale data on retry.
      widget.customer.notes = _savedNotes;
      if (!mounted) return;
      setState(() => _savingNotes = false);
      AppNotification.show(
        context,
        'prog_notes_save_error'.tr(namedArgs: {'error': e.toString()}),
        type: NotificationType.error,
      );
    }
  }
}
