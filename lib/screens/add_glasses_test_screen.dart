import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../db_flutter/models.dart';
import '../features/optical_tools/screens/optical_tools_sheet.dart';
import '../flutter_services/customer_service.dart';
import '../flutter_services/dropdown_options_service.dart';
import '../themes/app_theme.dart';
import '../widgets/app_notification.dart';
import '../widgets/dropdown_field.dart';
import '../widgets/field_validation.dart';
import '../widgets/numeric_mask_formatter.dart';

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
    'r_add_read': quarterStepCheck(fieldKey: 'r_add_read'),
    'r_add_int': quarterStepCheck(fieldKey: 'r_add_int'),
    'r_add_bif': quarterStepCheck(fieldKey: 'r_add_bif'),
    'r_add_mul': quarterStepCheck(fieldKey: 'r_add_mul'),
    'l_add_read': quarterStepCheck(fieldKey: 'l_add_read'),
    'l_add_int': quarterStepCheck(fieldKey: 'l_add_int'),
    'l_add_bif': quarterStepCheck(fieldKey: 'l_add_bif'),
    'l_add_mul': quarterStepCheck(fieldKey: 'l_add_mul'),
  };

  /// Fields whose focus loss triggers a derived-value recomputation.
  late final Map<String, FieldAction> _blurActions = {
    'r_pd': sumOrDoubleAction(aKey: 'r_pd', bKey: 'l_pd', targetKey: 'sum_pd'),
    'l_pd': sumOrDoubleAction(aKey: 'r_pd', bKey: 'l_pd', targetKey: 'sum_pd'),
    'r_sphere': padFractionalZerosAction(fieldKey: 'r_sphere', fracDigits: 2),
    'l_sphere': padFractionalZerosAction(fieldKey: 'l_sphere', fracDigits: 2),
    'r_cylinder': padFractionalZerosAction(
      fieldKey: 'r_cylinder',
      fracDigits: 2,
    ),
    'l_cylinder': padFractionalZerosAction(
      fieldKey: 'l_cylinder',
      fracDigits: 2,
    ),
    'r_prism': padFractionalZerosAction(fieldKey: 'r_prism', fracDigits: 2),
    'l_prism': padFractionalZerosAction(fieldKey: 'l_prism', fracDigits: 2),
    'r_add_read': padFractionalZerosAction(
      fieldKey: 'r_add_read',
      fracDigits: 2,
    ),
    'r_add_int': padFractionalZerosAction(fieldKey: 'r_add_int', fracDigits: 2),
    'r_add_bif': padFractionalZerosAction(fieldKey: 'r_add_bif', fracDigits: 2),
    'r_add_mul': padFractionalZerosAction(fieldKey: 'r_add_mul', fracDigits: 2),
    'l_add_read': padFractionalZerosAction(
      fieldKey: 'l_add_read',
      fracDigits: 2,
    ),
    'l_add_int': padFractionalZerosAction(fieldKey: 'l_add_int', fracDigits: 2),
    'l_add_bif': padFractionalZerosAction(fieldKey: 'l_add_bif', fracDigits: 2),
    'l_add_mul': padFractionalZerosAction(fieldKey: 'l_add_mul', fracDigits: 2),
  };

  /// Shared instances so widget identity stays stable across rebuilds.
  static final _signedThreeDotTwoMask = [
    NumericMaskFormatter(intDigits: 3, fracDigits: 2, allowSign: true),
  ];
  static final _twoDotTwoMask = [
    NumericMaskFormatter(intDigits: 2, fracDigits: 2),
  ];
  static final _oneDotTwoMask = [
    NumericMaskFormatter(intDigits: 1, fracDigits: 2),
  ];

  late final Map<String, List<TextInputFormatter>> _inputFormatters = {
    'r_sphere': _signedThreeDotTwoMask,
    'l_sphere': _signedThreeDotTwoMask,
    'r_cylinder': _signedThreeDotTwoMask,
    'l_cylinder': _signedThreeDotTwoMask,
    'r_prism': _twoDotTwoMask,
    'l_prism': _twoDotTwoMask,
    'r_add_read': _oneDotTwoMask,
    'r_add_int': _oneDotTwoMask,
    'r_add_bif': _oneDotTwoMask,
    'r_add_mul': _oneDotTwoMask,
    'l_add_read': _oneDotTwoMask,
    'l_add_int': _oneDotTwoMask,
    'l_add_bif': _oneDotTwoMask,
    'l_add_mul': _oneDotTwoMask,
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

  void _openOpticalTools() {
    showOpticalToolsSheet(
      context,
      hostContext: OpticalToolsContext(
        defaultEye: 'OD',
        readEye: (eye) {
          final p = eye == 'OS' ? 'l' : 'r';
          double? parse(String key) {
            final c = _controllers[key];
            if (c == null) return null;
            final raw = stripNumericMask(c.text).trim();
            if (raw.isEmpty) return null;
            return double.tryParse(raw);
          }

          return (
            sph: parse('${p}_sphere'),
            cyl: parse('${p}_cylinder'),
            axis: parse('${p}_axis'),
          );
        },
        onApply: (eye, sph, cyl, axis) {
          final p = eye == 'OS' ? 'l' : 'r';
          String fmt(double v) {
            // Signed-three-dot-two mask expects explicit sign.
            final sign = v < 0 ? '-' : '+';
            return '$sign${v.abs().toStringAsFixed(2)}';
          }

          _controllers['${p}_sphere']?.text = fmt(sph);
          _controllers['${p}_cylinder']?.text = fmt(cyl);
          _controllers['${p}_axis']?.text = axis.round().toString();
        },
      ),
    );
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
        // Masked fields may still contain placeholder `_`s at save time if
        // the user hit Ctrl+S without ever blurring the field.
        final raw = _inputFormatters.containsKey(key)
            ? stripNumericMask(controller.text)
            : controller.text;
        if (key == 'exam_date') {
          newMap[key] = _formatDateForDb(raw);
        } else {
          newMap[key] = raw;
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
              icon: Image.asset(
                'assets/icons/calculations_icon.png',
                width: 48,
                height: 48,
              ),
              tooltip: 'tooltip_optical_tools'.tr(),
              onPressed: _openOpticalTools,
            ),
            const SizedBox(width: 8),
            const VerticalDivider(indent: 12, endIndent: 12, width: 1),
            const SizedBox(width: 8),
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
                  _buildAdditionalInfo(),
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
          style: AppTextStyles.input(),
          decoration: InputDecoration(
            labelText: labels[index],
            hintText: key.contains('date') ? 'hint_date'.tr() : null,
            isDense: true,
          ),
        );
      },
    );
  }

  Widget _buildAdditionalInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Each column is its own FocusTraversalGroup so Tab exhausts all
        // fields in the left column before jumping to the right column.
        Expanded(
          child: FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: Column(
              children: [
                _buildDropdownOrTextField(
                  'dominant_eye',
                  'field_dominant_eye'.tr(),
                ),
                const SizedBox(height: 16),
                _buildPrefixPairField(
                  label: 'field_iop'.tr(),
                  prefixA: 'R:',
                  keyA: 'r_iop',
                  prefixB: 'L:',
                  keyB: 'l_iop',
                ),
                const SizedBox(height: 16),
                _buildDropdownOrTextField(
                  'glasses_role',
                  'field_glasses_role'.tr(),
                ),
                const SizedBox(height: 16),
                _buildDropdownOrTextField(
                  'lenses_material',
                  'field_lenses_material'.tr(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'lenses_diameter_1',
                        'field_lenses_diam_1'.tr(),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '/',
                        style: TextStyle(
                          color: AppColors.label,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildTextField(
                        'lenses_diameter_2',
                        'field_lenses_diam_2'.tr(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPrefixPairField(
                  label: 'field_lenses_dia_dec'.tr(),
                  prefixA: 'H:',
                  keyA: 'lenses_diameter_decentration_horizontal',
                  prefixB: 'V:',
                  keyB: 'lenses_diameter_decentration_vertical',
                ),
                const SizedBox(height: 16),
                _buildDropdownOrTextField(
                  'segment_diameter',
                  'field_segment_diam'.tr(),
                ),
                const SizedBox(height: 16),
                _buildDropdownOrTextField(
                  'lenses_manufacturer',
                  'field_lenses_manufacturer'.tr(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'lenses_color',
                        'field_lenses_color'.tr(),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '/',
                        style: TextStyle(
                          color: AppColors.label,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildDropdownOrTextField(
                        'lenses_coated',
                        'field_lenses_coated'.tr(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: Column(
              children: [
                _buildTextField('catalog_num', 'field_catalog_num'.tr()),
                const SizedBox(height: 16),
                _buildTextField(
                  'frame_manufacturer',
                  'field_frame_manufacturer'.tr(),
                ),
                const SizedBox(height: 16),
                _buildTextField('frame_supplier', 'field_frame_supplier'.tr()),
                const SizedBox(height: 16),
                _buildTextField('frame_model', 'field_frame_model'.tr()),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'frame_size',
                        'field_frame_size'.tr(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        'frame_bar_length',
                        'field_frame_bar_length'.tr(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        'frame_color',
                        'field_frame_color'.tr(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField('diagnosis', 'field_diagnosis'.tr()),
                const SizedBox(height: 16),
                _buildTextField('notes', 'field_notes'.tr(), maxLines: 5),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Shows a DropdownField when options for [key] are loaded, otherwise a
  /// regular text field. Free-typed values are preserved via the controller.
  Widget _buildDropdownOrTextField(String key, String label) {
    if (_dropdownOptions[key]?.isNotEmpty ?? false) {
      return DropdownField(
        label: label,
        options: _dropdownOptions[key]!,
        controller: _controllers[key],
      );
    }
    return _buildTextField(key, label);
  }

  Widget _buildPrefixPairField({
    required String label,
    required String prefixA,
    required String keyA,
    required String prefixB,
    required String keyB,
  }) {
    Widget inlineField(String key) => TextFormField(
      controller: _controllers[key],
      style: TextStyle(
        color: AppColors.inputValue,
        fontWeight: AppTextStyles.inputWeight,
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
        filled: false,
      ),
    );

    return InputDecorator(
      isEmpty: false,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Row(
        children: [
          Text(
            prefixA,
            style: const TextStyle(
              color: AppColors.label,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(child: inlineField(keyA)),
          const SizedBox(width: 16),
          Text(
            prefixB,
            style: const TextStyle(
              color: AppColors.label,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(child: inlineField(keyB)),
        ],
      ),
    );
  }

  Widget _buildTextField(String key, String label, {int? maxLines = 1}) {
    return TextFormField(
      controller: _controllers[key],
      maxLines: maxLines,
      style: AppTextStyles.input(),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
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
      inputFormatters: _inputFormatters[key],
      style: TextStyle(
        color: AppColors.inputValue,
        fontWeight: AppTextStyles.inputWeight,
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
