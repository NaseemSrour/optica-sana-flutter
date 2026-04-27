// Optical Tools — modal bottom sheet hosting clinically useful calculators.
//
// Open via [showOpticalToolsSheet]. Pass an [OpticalToolsContext] when
// launching from a data-entry screen so the relevant tools (vertex,
// transposition, SE) pre-populate from what the operator has already
// typed and offer an "Apply" button that writes the result back.
//
// The sheet itself is stateless across opens — calculators, not records.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../themes/app_theme.dart';
import '../logic/optical_tools.dart' as ot;

/// Optional context passed when the sheet is opened from a data-entry
/// screen. Lets pre-fill from the active form state and write back via
/// [onApply].
///
/// [readEye] returns the current sph/cyl/axis triple for the named eye
/// ('OD' or 'OS') from the host form's controllers. Returns nulls when
/// the field is empty/non-numeric — the sheet will treat those as 0.
///
/// [onApply] is invoked when the operator taps "Apply" inside a tool
/// card; it receives the eye and the new triple. The host writes back
/// into its own controllers.
class OpticalToolsContext {
  final ({double? sph, double? cyl, double? axis}) Function(String eye) readEye;
  final void Function(String eye, double sph, double cyl, double axis) onApply;

  /// Default eye to show first. The user can still toggle inside the sheet.
  final String defaultEye;

  const OpticalToolsContext({
    required this.readEye,
    required this.onApply,
    this.defaultEye = 'OD',
  });
}

Future<void> showOpticalToolsSheet(
  BuildContext context, {
  OpticalToolsContext? hostContext,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _OpticalToolsSheet(hostContext: hostContext),
  );
}

/// Builds a chip label of the form `[from] → [to]` using a Material arrow
/// icon that mirrors automatically under RTL Directionality.
Widget _arrowLabel(String from, String to) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(from),
      const SizedBox(width: 4),
      const Icon(Icons.arrow_right_alt, size: 18),
      const SizedBox(width: 4),
      Text(to),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Sheet shell
// ─────────────────────────────────────────────────────────────────────────

class _OpticalToolsSheet extends StatefulWidget {
  final OpticalToolsContext? hostContext;
  const _OpticalToolsSheet({this.hostContext});

  @override
  State<_OpticalToolsSheet> createState() => _OpticalToolsSheetState();
}

class _OpticalToolsSheetState extends State<_OpticalToolsSheet> {
  late String _activeEye;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _activeEye = widget.hostContext?.defaultEye ?? 'OD';
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxH = media.size.height * 0.92;
    final hasHost = widget.hostContext != null;

    final tools = <_ToolCardSpec>[
      _ToolCardSpec(
        id: 'vertex',
        title: 'optools_vertex_title'.tr(),
        subtitle: 'optools_vertex_subtitle'.tr(),
        icon: Icons.compare_arrows,
        builder: (ctx) =>
            _VertexCard(host: widget.hostContext, activeEye: _activeEye),
      ),
      _ToolCardSpec(
        id: 'transpose',
        title: 'optools_transpose_title'.tr(),
        subtitle: 'optools_transpose_subtitle'.tr(),
        icon: Icons.swap_horiz,
        builder: (ctx) =>
            _TransposeCard(host: widget.hostContext, activeEye: _activeEye),
      ),
      _ToolCardSpec(
        id: 'se',
        title: 'optools_se_title'.tr(),
        subtitle: 'optools_se_subtitle'.tr(),
        icon: Icons.functions,
        builder: (ctx) =>
            _SECard(host: widget.hostContext, activeEye: _activeEye),
      ),
      _ToolCardSpec(
        id: 'pd',
        title: 'optools_pd_title'.tr(),
        subtitle: 'optools_pd_subtitle'.tr(),
        icon: Icons.straighten,
        builder: (ctx) => const _PdCard(),
      ),
      _ToolCardSpec(
        id: 'add',
        title: 'optools_add_title'.tr(),
        subtitle: 'optools_add_subtitle'.tr(),
        icon: Icons.menu_book,
        builder: (ctx) => const _AddCard(),
      ),
      _ToolCardSpec(
        id: 'va',
        title: 'optools_va_title'.tr(),
        subtitle: 'optools_va_subtitle'.tr(),
        icon: Icons.visibility,
        builder: (ctx) => const _VaCard(),
      ),
      _ToolCardSpec(
        id: 'prentice',
        title: 'optools_prentice_title'.tr(),
        subtitle: 'optools_prentice_subtitle'.tr(),
        icon: Icons.architecture,
        builder: (ctx) => const _PrenticeCard(),
      ),
      _ToolCardSpec(
        id: 'lars',
        title: 'optools_lars_title'.tr(),
        subtitle: 'optools_lars_subtitle'.tr(),
        icon: Icons.rotate_right,
        builder: (ctx) => const _LarsCard(),
      ),
      _ToolCardSpec(
        id: 'aniseik',
        title: 'optools_aniseik_title'.tr(),
        subtitle: 'optools_aniseik_subtitle'.tr(),
        icon: Icons.compare,
        builder: (ctx) => const _AniseikCard(),
      ),
    ];

    final filtered = _search.isEmpty
        ? tools
        : tools
              .where(
                (t) =>
                    t.title.toLowerCase().contains(_search.toLowerCase()) ||
                    t.subtitle.toLowerCase().contains(_search.toLowerCase()),
              )
              .toList();

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.label.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.calculate, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'optools_title'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.displayValue,
                      ),
                    ),
                  ),
                  if (hasHost)
                    Tooltip(
                      message: 'optools_eye_tooltip'.tr(),
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'OD', label: Text('OD')),
                          ButtonSegment(value: 'OS', label: Text('OS')),
                        ],
                        selected: {_activeEye},
                        showSelectedIcon: false,
                        onSelectionChanged: (s) =>
                            setState(() => _activeEye = s.first),
                      ),
                    ),
                  IconButton(
                    tooltip: 'tooltip_close'.tr(),
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'optools_search_hint'.tr(),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            const Divider(height: 1),
            // Tool list
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (_, i) => _ToolExpansion(spec: filtered[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolCardSpec {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder;
  _ToolCardSpec({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
  });
}

class _ToolExpansion extends StatelessWidget {
  final _ToolCardSpec spec;
  const _ToolExpansion({required this.spec});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ExpansionTile(
        leading: Icon(spec.icon, color: AppColors.primary),
        title: Text(
          spec.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          spec.subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.label),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [Builder(builder: spec.builder)],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Shared input widgets
// ─────────────────────────────────────────────────────────────────────────

/// Compact diopter stepper. Emits null when the user clears the field.
class _DiopterField extends StatefulWidget {
  final String label;
  final double? initial;
  final double step;
  final bool allowSign;
  final ValueChanged<double?> onChanged;

  const _DiopterField({
    required this.label,
    required this.onChanged,
    this.initial,
    this.step = 0.25,
    this.allowSign = true,
  });

  @override
  State<_DiopterField> createState() => _DiopterFieldState();
}

class _DiopterFieldState extends State<_DiopterField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.initial == null ? '' : widget.initial!.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _bump(double delta) {
    final cur = double.tryParse(_ctrl.text) ?? 0.0;
    final next = ot.roundToStep(cur + delta, step: widget.step);
    _ctrl.text = next.toStringAsFixed(2);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final stepLabel = widget.step.toStringAsFixed(2);
    return Row(
      children: [
        IconButton(
          tooltip: 'optools_decrement_tooltip'.tr(
            namedArgs: {'step': stepLabel},
          ),
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () => _bump(-widget.step),
        ),
        Expanded(
          child: TextField(
            controller: _ctrl,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(
              decimal: true,
              signed: widget.allowSign,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                widget.allowSign ? RegExp(r'[-+0-9.]') : RegExp(r'[0-9.]'),
              ),
            ],
            decoration: InputDecoration(labelText: widget.label, isDense: true),
            onChanged: (v) =>
                widget.onChanged(v.trim().isEmpty ? null : double.tryParse(v)),
          ),
        ),
        IconButton(
          tooltip: 'optools_increment_tooltip'.tr(
            namedArgs: {'step': stepLabel},
          ),
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => _bump(widget.step),
        ),
      ],
    );
  }
}

/// Result block with copy + optional apply.
class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final String? hint;
  final Color? hintColor;
  final VoidCallback? onApply;

  const _ResultRow({
    required this.label,
    required this.value,
    this.hint,
    this.hintColor,
    this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.label,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.displayValue,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'optools_copy'.tr(),
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: value));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('optools_copied'.tr()),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
              if (onApply != null)
                Tooltip(
                  message: 'optools_apply_tooltip'.tr(),
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check, size: 16),
                    label: Text('optools_apply'.tr()),
                    onPressed: onApply,
                  ),
                ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint!,
              style: TextStyle(
                fontSize: 11,
                color: hintColor ?? AppColors.label,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Tool 1: Vertex compensation
// ─────────────────────────────────────────────────────────────────────────

class _VertexCard extends StatefulWidget {
  final OpticalToolsContext? host;
  final String activeEye;
  const _VertexCard({this.host, required this.activeEye});

  @override
  State<_VertexCard> createState() => _VertexCardState();
}

class _VertexCardState extends State<_VertexCard> {
  double? _sph;
  double? _cyl;
  double? _axis;
  double _oldVertex = 12.0;
  double _newVertex = 0.0;

  @override
  void initState() {
    super.initState();
    final h = widget.host;
    if (h != null) {
      final r = h.readEye(widget.activeEye);
      _sph = r.sph;
      _cyl = r.cyl;
      _axis = r.axis;
    }
  }

  ot.TransposedRx? _result() {
    if (_sph == null) return null;
    try {
      return ot.vertexCompensateRx(
        sph: _sph!,
        cyl: _cyl ?? 0,
        axis: _axis ?? 180,
        oldVertexMm: _oldVertex,
        newVertexMm: _newVertex,
      );
    } on ArgumentError {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _result();
    final maxAbs = _sph == null
        ? 0.0
        : ot.vertexSignificanceThreshold(sph: _sph!, cyl: _cyl ?? 0);
    final lowPower = maxAbs < 4.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DiopterField(
          label: 'SPH',
          initial: _sph,
          onChanged: (v) => setState(() => _sph = v),
        ),
        _DiopterField(
          label: 'CYL',
          initial: _cyl,
          onChanged: (v) => setState(() => _cyl = v),
        ),
        _DiopterField(
          label: 'AXIS',
          initial: _axis,
          step: 1,
          allowSign: false,
          onChanged: (v) => setState(() => _axis = v),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'optools_vertex_old'.tr(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  Slider(
                    value: _oldVertex,
                    min: 0,
                    max: 16,
                    divisions: 32,
                    label: '${_oldVertex.toStringAsFixed(1)} mm',
                    onChanged: (v) => setState(() => _oldVertex = v),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'optools_vertex_new'.tr(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  Slider(
                    value: _newVertex,
                    min: 0,
                    max: 16,
                    divisions: 32,
                    label: '${_newVertex.toStringAsFixed(1)} mm',
                    onChanged: (v) => setState(() => _newVertex = v),
                  ),
                ],
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              tooltip: 'optools_vertex_preset_g_cl_tooltip'.tr(),
              label: _arrowLabel(
                'optools_vertex_preset_g_cl_from'.tr(),
                'optools_vertex_preset_g_cl_to'.tr(),
              ),
              onPressed: () => setState(() {
                _oldVertex = 12;
                _newVertex = 0;
              }),
            ),
            ActionChip(
              tooltip: 'optools_vertex_preset_cl_g_tooltip'.tr(),
              label: _arrowLabel(
                'optools_vertex_preset_cl_g_from'.tr(),
                'optools_vertex_preset_cl_g_to'.tr(),
              ),
              onPressed: () => setState(() {
                _oldVertex = 0;
                _newVertex = 12;
              }),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (r != null)
          _ResultRow(
            label: 'optools_vertex_result_label'.tr(),
            value:
                'SPH ${ot.roundToStep(r.sph).toStringAsFixed(2)}  '
                'CYL ${ot.roundToStep(r.cyl).toStringAsFixed(2)}  '
                'AXIS ${r.axis.round()}°',
            hint: lowPower ? 'optools_vertex_low_power_hint'.tr() : null,
            hintColor: lowPower ? Colors.orange : null,
            onApply: widget.host == null
                ? null
                : () {
                    widget.host!.onApply(
                      widget.activeEye,
                      ot.roundToStep(r.sph),
                      ot.roundToStep(r.cyl),
                      r.axis,
                    );
                    Navigator.of(context).pop();
                  },
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Tool 2: Cylinder transposition
// ─────────────────────────────────────────────────────────────────────────

class _TransposeCard extends StatefulWidget {
  final OpticalToolsContext? host;
  final String activeEye;
  const _TransposeCard({this.host, required this.activeEye});

  @override
  State<_TransposeCard> createState() => _TransposeCardState();
}

class _TransposeCardState extends State<_TransposeCard> {
  double? _sph;
  double? _cyl;
  double? _axis;

  @override
  void initState() {
    super.initState();
    final h = widget.host;
    if (h != null) {
      final r = h.readEye(widget.activeEye);
      _sph = r.sph;
      _cyl = r.cyl;
      _axis = r.axis;
    }
  }

  @override
  Widget build(BuildContext context) {
    ot.TransposedRx? r;
    if (_sph != null) {
      try {
        r = ot.transposeCylinder(
          sph: _sph!,
          cyl: _cyl ?? 0,
          axis: _axis ?? 180,
        );
      } on ArgumentError {
        r = null;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DiopterField(
          label: 'SPH',
          initial: _sph,
          onChanged: (v) => setState(() => _sph = v),
        ),
        _DiopterField(
          label: 'CYL',
          initial: _cyl,
          onChanged: (v) => setState(() => _cyl = v),
        ),
        _DiopterField(
          label: 'AXIS',
          initial: _axis,
          step: 1,
          allowSign: false,
          onChanged: (v) => setState(() => _axis = v),
        ),
        const SizedBox(height: 12),
        if (r != null)
          _ResultRow(
            label: 'optools_transpose_result_label'.tr(),
            value:
                'SPH ${r.sph.toStringAsFixed(2)}  '
                'CYL ${r.cyl.toStringAsFixed(2)}  '
                'AXIS ${r.axis.round()}°',
            onApply: widget.host == null
                ? null
                : () {
                    widget.host!.onApply(
                      widget.activeEye,
                      r!.sph,
                      r.cyl,
                      r.axis,
                    );
                    Navigator.of(context).pop();
                  },
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Tool 3: Spherical equivalent
// ─────────────────────────────────────────────────────────────────────────

class _SECard extends StatefulWidget {
  final OpticalToolsContext? host;
  final String activeEye;
  const _SECard({this.host, required this.activeEye});

  @override
  State<_SECard> createState() => _SECardState();
}

class _SECardState extends State<_SECard> {
  double? _sph;
  double? _cyl;

  @override
  void initState() {
    super.initState();
    final h = widget.host;
    if (h != null) {
      final r = h.readEye(widget.activeEye);
      _sph = r.sph;
      _cyl = r.cyl;
    }
  }

  @override
  Widget build(BuildContext context) {
    double? se;
    if (_sph != null) {
      try {
        se = ot.sphericalEquivalent(sph: _sph!, cyl: _cyl ?? 0);
      } on ArgumentError {
        se = null;
      }
    }
    final highCyl = (_cyl ?? 0).abs() >= 0.75;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DiopterField(
          label: 'SPH',
          initial: _sph,
          onChanged: (v) => setState(() => _sph = v),
        ),
        _DiopterField(
          label: 'CYL',
          initial: _cyl,
          onChanged: (v) => setState(() => _cyl = v),
        ),
        const SizedBox(height: 12),
        if (se != null)
          _ResultRow(
            label: 'optools_se_result_label'.tr(),
            value: '${ot.roundToStep(se).toStringAsFixed(2)} D',
            hint: highCyl ? 'optools_se_high_cyl_hint'.tr() : null,
            hintColor: highCyl ? Colors.orange : null,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Tool 4: PD conversion
// ─────────────────────────────────────────────────────────────────────────

class _PdCard extends StatefulWidget {
  const _PdCard();

  @override
  State<_PdCard> createState() => _PdCardState();
}

class _PdCardState extends State<_PdCard> {
  double? _total;
  double? _od;
  double? _os;
  final double _nearOffset = 3.0;

  @override
  Widget build(BuildContext context) {
    String? splitText;
    String? sumText;
    String? nearText;
    try {
      if (_total != null) {
        final s = ot.splitTotalPd(_total!);
        splitText =
            'OD ${s.odPd.toStringAsFixed(1)} mm   OS ${s.osPd.toStringAsFixed(1)} mm';
      }
    } on ArgumentError {
      // ignore
    }
    try {
      if (_od != null && _os != null) {
        sumText =
            '${ot.sumMonocularPd(odMm: _od!, osMm: _os!).toStringAsFixed(1)} mm';
      }
    } on ArgumentError {
      /* ignore */
    }
    try {
      if (_total != null) {
        nearText =
            '${ot.nearPdFromDistance(_total!, offsetMm: _nearOffset).toStringAsFixed(1)} mm';
      }
    } on ArgumentError {
      /* ignore */
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DiopterField(
          label: 'optools_pd_total'.tr(),
          initial: _total,
          step: 0.5,
          allowSign: false,
          onChanged: (v) => setState(() => _total = v),
        ),
        const SizedBox(height: 8),
        if (splitText != null)
          _ResultRow(
            label: 'optools_pd_split_label'.tr(),
            value: splitText,
            hint: 'optools_pd_split_warn'.tr(),
            hintColor: Colors.orange,
          ),
        if (nearText != null) ...[
          const SizedBox(height: 8),
          _ResultRow(
            label: 'optools_pd_near_label'.tr(),
            value: nearText,
            hint: 'optools_pd_near_hint'.tr(),
          ),
        ],
        const Divider(height: 24),
        Row(
          children: [
            Expanded(
              child: _DiopterField(
                label: 'OD',
                initial: _od,
                step: 0.5,
                allowSign: false,
                onChanged: (v) => setState(() => _od = v),
              ),
            ),
            Expanded(
              child: _DiopterField(
                label: 'OS',
                initial: _os,
                step: 0.5,
                allowSign: false,
                onChanged: (v) => setState(() => _os = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (sumText != null)
          _ResultRow(label: 'optools_pd_sum_label'.tr(), value: sumText),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Tool 5: Near addition suggestion
// ─────────────────────────────────────────────────────────────────────────

class _AddCard extends StatefulWidget {
  const _AddCard();

  @override
  State<_AddCard> createState() => _AddCardState();
}

class _AddCardState extends State<_AddCard> {
  double _age = 50;
  double _workCm = 40;
  double? _measuredAA;

  @override
  Widget build(BuildContext context) {
    String? addText;
    String? aaText;
    try {
      final hof = ot.hofstetterAmplitude(_age.round());
      aaText =
          'min ${hof.minDiopters.toStringAsFixed(1)} D · '
          'avg ${hof.avgDiopters.toStringAsFixed(1)} D · '
          'max ${hof.maxDiopters.toStringAsFixed(1)} D';
      final add = ot.suggestNearAdd(
        age: _age.round(),
        workingDistanceCm: _workCm,
        availableAA: _measuredAA,
      );
      addText = '+${add.toStringAsFixed(2)} D';
    } on ArgumentError {
      // ignore
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${'optools_add_age'.tr()}: ${_age.round()}'),
        Slider(
          value: _age,
          min: 35,
          max: 80,
          divisions: 45,
          label: _age.round().toString(),
          onChanged: (v) => setState(() => _age = v),
        ),
        Text('${'optools_add_working'.tr()}: ${_workCm.round()} cm'),
        Slider(
          value: _workCm,
          min: 25,
          max: 100,
          divisions: 75,
          label: '${_workCm.round()} cm',
          onChanged: (v) => setState(() => _workCm = v),
        ),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              tooltip: 'optools_add_preset_30cm_tooltip'.tr(),
              label: const Text('30 cm'),
              onPressed: () => setState(() => _workCm = 30),
            ),
            ActionChip(
              tooltip: 'optools_add_preset_40cm_tooltip'.tr(),
              label: const Text('40 cm'),
              onPressed: () => setState(() => _workCm = 40),
            ),
            ActionChip(
              tooltip: 'optools_add_preset_65cm_tooltip'.tr(),
              label: const Text('65 cm'),
              onPressed: () => setState(() => _workCm = 65),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _DiopterField(
          label: 'optools_add_measured_aa'.tr(),
          initial: _measuredAA,
          allowSign: false,
          step: 0.25,
          onChanged: (v) => setState(() => _measuredAA = v),
        ),
        const SizedBox(height: 8),
        if (aaText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${'optools_add_hofstetter'.tr()}: $aaText',
              style: const TextStyle(fontSize: 11, color: AppColors.label),
            ),
          ),
        if (addText != null)
          _ResultRow(
            label: 'optools_add_result_label'.tr(),
            value: addText,
            hint: 'optools_add_hint'.tr(),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Tool 6: Visual acuity conversions
// ─────────────────────────────────────────────────────────────────────────

class _VaCard extends StatefulWidget {
  const _VaCard();

  @override
  State<_VaCard> createState() => _VaCardState();
}

class _VaCardState extends State<_VaCard> {
  double? _num = 6;
  double? _den = 6;

  @override
  Widget build(BuildContext context) {
    String? out;
    if (_num != null && _den != null) {
      try {
        final dec = ot.snellenToDecimal(numerator: _num!, denominator: _den!);
        final lm = ot.decimalToLogMAR(dec);
        out =
            'decimal ${dec.toStringAsFixed(2)}   '
            'logMAR ${lm.toStringAsFixed(2)}';
      } on ArgumentError {
        out = null;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _DiopterField(
                label: 'optools_va_num'.tr(),
                initial: _num,
                allowSign: false,
                step: 1,
                onChanged: (v) => setState(() => _num = v),
              ),
            ),
            Expanded(
              child: _DiopterField(
                label: 'optools_va_den'.tr(),
                initial: _den,
                allowSign: false,
                step: 1,
                onChanged: (v) => setState(() => _den = v),
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              tooltip: 'optools_va_preset_normal_tooltip'.tr(),
              label: const Text('6/6'),
              onPressed: () => setState(() {
                _num = 6;
                _den = 6;
              }),
            ),
            ActionChip(
              tooltip: 'optools_va_preset_normal_tooltip'.tr(),
              label: const Text('20/20'),
              onPressed: () => setState(() {
                _num = 20;
                _den = 20;
              }),
            ),
            ActionChip(
              tooltip: 'optools_va_preset_lowvision_tooltip'.tr(),
              label: const Text('20/40'),
              onPressed: () => setState(() {
                _num = 20;
                _den = 40;
              }),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (out != null)
          _ResultRow(label: 'optools_va_result_label'.tr(), value: out),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Tool 7: Prentice's rule
// ─────────────────────────────────────────────────────────────────────────

class _PrenticeCard extends StatefulWidget {
  const _PrenticeCard();

  @override
  State<_PrenticeCard> createState() => _PrenticeCardState();
}

class _PrenticeCardState extends State<_PrenticeCard> {
  double? _decMm;
  double? _powerD;

  @override
  Widget build(BuildContext context) {
    String? out;
    if (_decMm != null && _powerD != null) {
      try {
        final p = ot.prenticePrism(decentrationMm: _decMm!, powerD: _powerD!);
        out = '${p.abs().toStringAsFixed(2)} Δ';
      } on ArgumentError {
        out = null;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DiopterField(
          label: 'optools_prentice_dec'.tr(),
          initial: _decMm,
          allowSign: true,
          step: 0.5,
          onChanged: (v) => setState(() => _decMm = v),
        ),
        _DiopterField(
          label: 'optools_prentice_power'.tr(),
          initial: _powerD,
          allowSign: true,
          step: 0.25,
          onChanged: (v) => setState(() => _powerD = v),
        ),
        const SizedBox(height: 12),
        if (out != null)
          _ResultRow(
            label: 'optools_prentice_result_label'.tr(),
            value: out,
            hint: 'optools_prentice_base_hint'.tr(),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Tool 8: Toric LARS
// ─────────────────────────────────────────────────────────────────────────

class _LarsCard extends StatefulWidget {
  const _LarsCard();

  @override
  State<_LarsCard> createState() => _LarsCardState();
}

class _LarsCardState extends State<_LarsCard> {
  double? _measured;
  double _rotation = 0;

  @override
  Widget build(BuildContext context) {
    String? out;
    String? warn;
    if (_measured != null) {
      try {
        final r = ot.compensateTorricAxisLARS(
          measuredAxis: _measured!,
          rotationDeg: _rotation,
        );
        out = '${r.orderedAxis.round()}°';
        if (r.refitRecommended) warn = 'optools_lars_refit_warn'.tr();
      } on ArgumentError {
        out = null;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DiopterField(
          label: 'optools_lars_measured'.tr(),
          initial: _measured,
          allowSign: false,
          step: 1,
          onChanged: (v) => setState(() => _measured = v),
        ),
        Text(
          '${'optools_lars_rotation'.tr()}: ${_rotation.toStringAsFixed(0)}°',
        ),
        Slider(
          value: _rotation,
          min: -45,
          max: 45,
          divisions: 90,
          label: _rotation.toStringAsFixed(0),
          onChanged: (v) => setState(() => _rotation = v),
        ),
        Text(
          'optools_lars_legend'.tr(),
          style: const TextStyle(fontSize: 11, color: AppColors.label),
        ),
        const SizedBox(height: 12),
        if (out != null)
          _ResultRow(
            label: 'optools_lars_result_label'.tr(),
            value: out,
            hint: warn,
            hintColor: warn != null ? Colors.orange : null,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Tool 9: Aniseikonia estimate
// ─────────────────────────────────────────────────────────────────────────

class _AniseikCard extends StatefulWidget {
  const _AniseikCard();

  @override
  State<_AniseikCard> createState() => _AniseikCardState();
}

class _AniseikCardState extends State<_AniseikCard> {
  double? _od;
  double? _os;

  @override
  Widget build(BuildContext context) {
    String? out;
    String? warn;
    if (_od != null && _os != null) {
      try {
        final r = ot.estimateAniseikonia(sphOd: _od!, sphOs: _os!);
        out =
            'Δ ${r.diopterDifference.toStringAsFixed(2)} D   '
            '≈ ${r.approxPercent.toStringAsFixed(1)} %';
        if (r.clinicallySignificant) {
          warn = 'optools_aniseik_warn'.tr();
        }
      } on ArgumentError {
        out = null;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _DiopterField(
                label: 'OD SPH',
                initial: _od,
                onChanged: (v) => setState(() => _od = v),
              ),
            ),
            Expanded(
              child: _DiopterField(
                label: 'OS SPH',
                initial: _os,
                onChanged: (v) => setState(() => _os = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (out != null)
          _ResultRow(
            label: 'optools_aniseik_result_label'.tr(),
            value: out,
            hint: warn ?? 'optools_aniseik_hint'.tr(),
            hintColor: warn != null ? Colors.orange : null,
          ),
      ],
    );
  }
}
