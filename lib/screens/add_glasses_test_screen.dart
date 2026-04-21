import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../db_flutter/models.dart';
import '../flutter_services/customer_service.dart';
import '../flutter_services/dropdown_options_service.dart';
import '../themes/app_theme.dart';
import '../widgets/app_notification.dart';
import '../widgets/dropdown_field.dart';
import '../widgets/field_validation.dart';

class AddGlassesTestScreen extends StatefulWidget {
  final Customer customer;
  final CustomerService customerService;

  const AddGlassesTestScreen({
    Key? key,
    required this.customer,
    required this.customerService,
  }) : super(key: key);

  @override
  _AddGlassesTestScreenState createState() => _AddGlassesTestScreenState();
}

class _AddGlassesTestScreenState extends State<AddGlassesTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _focusNode = FocusNode();
  final _controllers = <String, TextEditingController>{};
  final _dropdownOptions = <String, List<String>>{};

  static const _tableDropdownKeys = {'r_base', 'l_base'};
  static const _gridDropdownKeys = {
    'dominant_eye',
    'glasses_role',
    'lenses_material',
    'segment_diameter',
    'lenses_manufacturer',
    'lenses_coated',
    'examiner',
  };

  /// Fields that run an on-blur validation. The key is the field whose focus
  /// loss triggers the [FieldCheck]; the check itself may inspect any related
  /// fields via the shared controllers map.
  late final Map<String, FieldCheck> _blurChecks = {
    'r_axis': glassesAxisCheck(axisKey: 'r_axis', cylinderKey: 'r_cylinder'),
    'l_axis': glassesAxisCheck(axisKey: 'l_axis', cylinderKey: 'l_cylinder'),
    'r_cylinder': glassesAxisCheck(
      axisKey: 'r_axis',
      cylinderKey: 'r_cylinder',
    ),
    'l_cylinder': glassesAxisCheck(
      axisKey: 'l_axis',
      cylinderKey: 'l_cylinder',
    ),
  };

  /// Fields whose focus loss triggers a derived-value recomputation.
  late final Map<String, FieldAction> _blurActions = {
    'r_pd': sumOrDoubleAction(aKey: 'r_pd', bKey: 'l_pd', targetKey: 'sum_pd'),
    'l_pd': sumOrDoubleAction(aKey: 'r_pd', bKey: 'l_pd', targetKey: 'sum_pd'),
  };

  /// Wraps [child] in an [OnBlurValidator] when [key] has a registered check.
  Widget _wrapIfValidated(String key, Widget child) {
    final check = _blurChecks[key];
    final action = _blurActions[key];
    Widget result = child;
    if (action != null) {
      result = OnBlurAction(
        controllers: _controllers,
        action: action,
        child: result,
      );
    }
    if (check != null) {
      result = OnBlurValidator(
        controllers: _controllers,
        check: check,
        child: result,
      );
    }
    return result;
  }

  String _formatDateForDb(String date) {
    if (date.isEmpty) return '';
    try {
      final inputDate = DateFormat('d/M/yyyy').parse(date);
      return DateFormat('yyyy-MM-dd').format(inputDate);
    } catch (e) {
      return date;
    }
  }

  @override
  void initState() {
    super.initState();
    final sampleTest = GlassesTest(
      id: 465,
      customerId: widget.customer.id,
      examDate: DateTime.now(),
    );
    sampleTest.toMap().forEach((key, value) {
      if (key != 'id' && key != 'customer_id') {
        _controllers[key] = TextEditingController(
          text: key == 'exam_date'
              ? DateFormat('dd/MM/yyyy').format(DateTime.now())
              : value?.toString() ?? '',
        );
      }
    });
    _loadDropdownOptions();
  }

  void _loadDropdownOptions() {
    for (final key in {..._tableDropdownKeys, ..._gridDropdownKeys}) {
      DropdownOptionsService.instance.getOptions(key).then((opts) {
        if (mounted) setState(() => _dropdownOptions[key] = opts);
      });
    }
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _saveTest() async {
    if (_formKey.currentState!.validate()) {
      // Run all registered blur checks up-front so the user cannot bypass
      // them by hitting Ctrl+S without focusing the fields first. Use a Set
      // over the values to avoid running the same shared check twice.
      final uniqueChecks = _blurChecks.values.toSet().toList();
      final err = runChecks(_controllers, uniqueChecks);
      if (err != null) {
        AppNotification.show(context, err, type: NotificationType.error);
        return;
      }

      final newMap = <String, dynamic>{
        'customer_id': widget.customer.id,
        'id': -1,
      };
      _controllers.forEach((key, controller) {
        if (key == 'exam_date') {
          newMap[key] = _formatDateForDb(controller.text);
        } else {
          newMap[key] = controller.text;
        }
      });

      try {
        final newTest = GlassesTest.fromMap(newMap);
        await widget.customerService.addGlassesTest(newTest);
        if (mounted) {
          Navigator.pop(context);
          AppNotification.show(
            context,
            'msg_glasses_saved'.tr(),
            type: NotificationType.success,
          );
        }
      } catch (e) {
        if (mounted) {
          AppNotification.show(
            context,
            'msg_glasses_save_error'.tr(namedArgs: {'error': e.toString()}),
            type: NotificationType.error,
          );
        }
      }
    }
  }

  String _labelFor(String key) {
    const map = {
      'dominant_eye': 'field_dominant_eye',
      'glasses_role': 'field_glasses_role',
      'lenses_material': 'field_lenses_material',
      'lenses_diameter_1': 'field_lenses_diam_1',
      'lenses_diameter_2': 'field_lenses_diam_2',
      'lenses_diameter_decentration_horizontal': 'field_lenses_dia_dec_h',
      'lenses_diameter_decentration_vertical': 'field_lenses_dia_dec_v',
      'segment_diameter': 'field_segment_diam',
      'diagnosis': 'field_diagnosis',
      'lenses_manufacturer': 'field_lenses_manufacturer',
      'lenses_color': 'field_lenses_color',
      'lenses_coated': 'field_lenses_coated',
      'catalog_num': 'field_catalog_num',
      'frame_manufacturer': 'field_frame_manufacturer',
      'frame_supplier': 'field_frame_supplier',
      'frame_model': 'field_frame_model',
      'frame_size': 'field_frame_size',
      'frame_bar_length': 'field_frame_bar_length',
      'frame_color': 'field_frame_color',
    };
    final trKey = map[key];
    return trKey != null ? trKey.tr() : key.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      autofocus: true,
      focusNode: _focusNode,
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
            SaveIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): BackIntent(),
      },
      actions: {
        SaveIntent: CallbackAction<SaveIntent>(onInvoke: (_) => _saveTest()),
        BackIntent: CallbackAction<BackIntent>(
          onInvoke: (_) {
            Navigator.pop(context);
            return null;
          },
        ),
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'title_add_glasses'.tr(
              namedArgs: {
                'name': '${widget.customer.fname} ${widget.customer.lname}',
              },
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'tooltip_save'.tr(),
              onPressed: _saveTest,
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildTopFields(),
                  const SizedBox(height: 20),
                  _buildEyeDataTable(),
                  const SizedBox(height: 20),
                  _buildNonEyeDataFields(),
                  const SizedBox(height: 20),
                  _buildNotesField(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopFields() {
    final keys = ['exam_date', 'examiner'];
    final labels = ['field_exam_date'.tr(), 'field_examiner'.tr()];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        childAspectRatio: 5,
        crossAxisSpacing: 20,
        mainAxisSpacing: 10,
      ),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        if (key == 'examiner') {
          return DropdownField(
            label: labels[index],
            controller: _controllers['examiner'],
            options: _dropdownOptions['examiner'] ?? [],
          );
        }
        return TextFormField(
          controller: _controllers[key],
          style: const TextStyle(
            color: AppColors.inputValue,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            labelText: labels[index],
            hintText: key.contains('date') ? 'hint_date'.tr() : null,
            isDense: true,
          ),
        );
      },
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _controllers['notes'],
      style: const TextStyle(
        color: AppColors.inputValue,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(labelText: 'field_notes'.tr(), isDense: true),
      maxLines: 3,
    );
  }

  Widget _buildNonEyeDataFields() {
    final nonEyeDataKeys = _controllers.keys
        .where(
          (k) =>
              // r_iop is re-included below even though it starts with r_
              (!k.startsWith('r_') && !k.startsWith('l_') || k == 'r_iop') &&
              k != 'exam_date' &&
              k != 'examiner' &&
              k != 'notes' &&
              k != 'both_va' &&
              k != 'sum_pd' &&
              k != 'near_pd' &&
              k !=
                  'lenses_diameter_2' && // combined into lenses_diameter_1 cell
              k !=
                  'lenses_diameter_decentration_vertical', // combined into decentration_h cell
        )
        .toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        childAspectRatio: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: nonEyeDataKeys.length,
      itemBuilder: (context, index) {
        final key = nonEyeDataKeys[index];
        if (key == 'lenses_diameter_1') {
          return _buildDiameterCombinedCell();
        }
        if (key == 'r_iop') {
          return _buildIopCombinedCell();
        }
        if (key == 'lenses_diameter_decentration_horizontal') {
          return _buildDecentrationCombinedCell();
        }
        if (_gridDropdownKeys.contains(key)) {
          return DropdownField(
            label: _labelFor(key),
            options: _dropdownOptions[key] ?? [],
            controller: _controllers[key],
          );
        }
        return TextFormField(
          controller: _controllers[key],
          style: const TextStyle(
            color: AppColors.inputValue,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            labelText: _labelFor(key),
            hintText: key.contains('date') ? 'hint_date'.tr() : null,
            isDense: true,
          ),
        );
      },
    );
  }

  Widget _buildEyeDataTable() {
    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Table(
        border: TableBorder.all(color: AppColors.tableBorder),
        columnWidths: const {
          0: IntrinsicColumnWidth(),
          6: FlexColumnWidth(
            1.5,
          ), // Base column wider for UP/DOWN/IN/OUT dropdown
          7: FlexColumnWidth(
            2,
          ), // VA column wider to fit staggered r_va/both_va/l_va
          8: FlexColumnWidth(4),
          10: FlexColumnWidth(2.5), // PD column wider to fit sum/near stagger
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          _buildHeaders(context),
          _buildEyeDataRow('R', _getRightEyeKeys()),
          _buildEyeDataRow('L', _getLeftEyeKeys()),
        ],
      ),
    );
  }

  TableRow _buildHeaders(BuildContext context) {
    final headers = [
      '',
      'FV',
      'Sphere',
      'Cylinder',
      'Axis',
      'Prism',
      'Base',
      'VA',
      'Read',
      'Int.',
      'Bif.',
      'Mul.',
      'High',
      'PD',
    ];
    return TableRow(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
      children: [
        ...headers.take(8).map((h) => _headerCell(context, h)),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Column(
            children: [
              _headerCell(context, 'Addition', isSubHeader: false),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: headers
                    .sublist(8, 12)
                    .map(
                      (h) => Expanded(
                        child: _headerCell(context, h, isSubHeader: true),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        ...headers.sublist(12).map((h) => _headerCell(context, h)),
      ],
    );
  }

  Widget _headerCell(
    BuildContext context,
    String text, {
    bool isSubHeader = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: isSubHeader ? 12 : null,
          ),
        ),
      ),
    );
  }

  List<String> _getRightEyeKeys() {
    return [
      'r_fv',
      'r_sphere',
      'r_cylinder',
      'r_axis',
      'r_prism',
      'r_base',
      'r_va',
      'r_add_read',
      'r_add_int',
      'r_add_bif',
      'r_add_mul',
      'r_high',
      'r_pd',
    ];
  }

  List<String> _getLeftEyeKeys() {
    return [
      'l_fv',
      'l_sphere',
      'l_cylinder',
      'l_axis',
      'l_prism',
      'l_base',
      'l_va',
      'l_add_read',
      'l_add_int',
      'l_add_bif',
      'l_add_mul',
      'l_high',
      'l_pd',
    ];
  }

  TableRow _buildEyeDataRow(String eye, List<String> keys) {
    return TableRow(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              eye,
              style: const TextStyle(
                color: AppColors.label,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        // FV, Sphere, Cylinder, Axis, Prism, Base (indices 0–5)
        ...keys.take(6).map((key) => _buildTextFormFieldCell(key)),
        // VA column (index 6): r_va only for R; l_va + both_va stacked for L
        eye == 'R'
            ? _buildTextFormFieldCell(keys[6])
            : _buildStackedVaCell(keys[6]),
        // Addition sub-columns (indices 7–10)
        TableCell(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: keys
                .sublist(7, 11)
                .map((key) => Expanded(child: _buildTextFormFieldCell(key)))
                .toList(),
          ),
        ),
        // High column (index 11)
        _buildTextFormFieldCell(keys[11]),
        // PD column: r_pd for R; staggered sum_pd/near_pd + l_pd for L
        _buildPdCell(eye, keys[12]),
      ],
    );
  }

  Widget _buildStackedVaCell(String vaKey) {
    // both_va top-right, l_va bottom-left (mirroring the DOS UI layout).
    // Focus traversal enters the cell on l_va (left-side field in the row)
    // and then moves up to both_va before leaving the cell.
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Spacer(),
              Expanded(
                child: FocusTraversalOrder(
                  order: const NumericFocusOrder(2),
                  child: _buildTextFormFieldCell('both_va'),
                ),
              ),
            ],
          ),
          Container(height: 1, color: AppColors.tableBorder),
          Row(
            children: [
              Expanded(
                child: FocusTraversalOrder(
                  order: const NumericFocusOrder(1),
                  child: _buildTextFormFieldCell(vaKey),
                ),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPdCell(String eye, String pdKey) {
    if (eye == 'R') {
      // r_pd on the left half
      return Row(
        children: [
          Expanded(child: _buildTextFormFieldCell(pdKey)),
          const Spacer(),
        ],
      );
    }
    // L row: sum_pd/near_pd top-right, l_pd bottom-left. Tab order enters
    // on l_pd, then sum_pd, then near_pd before leaving the cell.
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Spacer(),
              Expanded(child: _buildSumNearPdCell()),
            ],
          ),
          Container(height: 1, color: AppColors.tableBorder),
          Row(
            children: [
              Expanded(
                child: FocusTraversalOrder(
                  order: const NumericFocusOrder(1),
                  child: _buildTextFormFieldCell(pdKey),
                ),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSumNearPdCell() {
    return Row(
      children: [
        Expanded(
          child: FocusTraversalOrder(
            order: const NumericFocusOrder(2),
            child: _buildTextFormFieldCell('sum_pd'),
          ),
        ),
        const Text('/', style: TextStyle(color: AppColors.label, fontSize: 12)),
        Expanded(
          child: FocusTraversalOrder(
            order: const NumericFocusOrder(3),
            child: _buildTextFormFieldCell('near_pd'),
          ),
        ),
      ],
    );
  }

  Widget _buildDiameterCombinedCell() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _controllers['lenses_diameter_1'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.inputValue,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: 'field_lenses_diam_1'.tr(),
              isDense: true,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '/',
            style: TextStyle(color: AppColors.label, fontSize: 16),
          ),
        ),
        Expanded(
          child: TextFormField(
            controller: _controllers['lenses_diameter_2'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.inputValue,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: 'field_lenses_diam_2'.tr(),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineField(String key) {
    return TextFormField(
      controller: _controllers[key],
      style: const TextStyle(
        color: AppColors.inputValue,
        fontWeight: FontWeight.w600,
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
        filled: false,
      ),
    );
  }

  Widget _buildIopCombinedCell() {
    return InputDecorator(
      isEmpty: false,
      decoration: InputDecoration(
        labelText: 'field_iop'.tr(),
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Row(
        children: [
          const Text(
            'R:',
            style: TextStyle(
              color: AppColors.label,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(child: _buildInlineField('r_iop')),
          const SizedBox(width: 16),
          const Text(
            'L:',
            style: TextStyle(
              color: AppColors.label,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(child: _buildInlineField('l_iop')),
        ],
      ),
    );
  }

  Widget _buildDecentrationCombinedCell() {
    return InputDecorator(
      isEmpty: false,
      decoration: InputDecoration(
        labelText: 'field_lenses_dia_dec'.tr(),
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Row(
        children: [
          const Text(
            'H:',
            style: TextStyle(
              color: AppColors.label,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: _buildInlineField('lenses_diameter_decentration_horizontal'),
          ),
          const SizedBox(width: 16),
          const Text(
            'V:',
            style: TextStyle(
              color: AppColors.label,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: _buildInlineField('lenses_diameter_decentration_vertical'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormFieldCell(String key) {
    if (_tableDropdownKeys.contains(key)) {
      return DropdownField(
        compact: true,
        options: _dropdownOptions[key] ?? [],
        controller: _controllers[key],
        value: _controllers[key]?.text.isEmpty ?? true
            ? null
            : _controllers[key]!.text,
        onChanged: (v) => setState(() => _controllers[key]!.text = v ?? ''),
      );
    }

    final isFv =
        key == 'r_fv' ||
        key == 'l_fv' ||
        key == 'r_va' ||
        key == 'l_va' ||
        key == 'both_va';

    final field = TextFormField(
      controller: _controllers[key],
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.inputValue,
        fontWeight: FontWeight.w600,
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        filled: false,
        isDense: true,
      ),
    );

    if (!isFv) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: _wrapIfValidated(key, field),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '6/',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(child: field),
        ],
      ),
    );
  }
}

class SaveIntent extends Intent {}

class BackIntent extends Intent {}
