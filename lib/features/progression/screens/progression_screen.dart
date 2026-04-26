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

  @override
  void initState() {
    super.initState();
    _future = _load();
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
}
