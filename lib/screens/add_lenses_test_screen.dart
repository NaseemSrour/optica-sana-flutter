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
import '../widgets/numeric_mask_formatter.dart';

class AddLensesTestScreen extends StatefulWidget {
  final Customer customer;
  final CustomerService customerService;

  const AddLensesTestScreen({
    Key? key,
    required this.customer,
    required this.customerService,
  }) : super(key: key);

  @override
  _AddLensesTestScreenState createState() => _AddLensesTestScreenState();
}

class _AddLensesTestScreenState extends State<AddLensesTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _focusNode = FocusNode();
  final _controllers = <String, TextEditingController>{};
  final _dropdownOptions = <String, List<String>>{};

  late final Map<String, FieldAction> _blurActions = {
    'r_rH': composeActions([
      padFractionalZerosAction(fieldKey: 'r_rH', fracDigits: 2),
      averageAction(aKey: 'r_rH', bKey: 'r_rV', targetKey: 'r_aver'),
      keratometryCylAction(hKey: 'r_rH', vKey: 'r_rV', targetKey: 'r_k_cyl'),
    ]),
    'r_rV': composeActions([
      padFractionalZerosAction(fieldKey: 'r_rV', fracDigits: 2),
      averageAction(aKey: 'r_rH', bKey: 'r_rV', targetKey: 'r_aver'),
      keratometryCylAction(hKey: 'r_rH', vKey: 'r_rV', targetKey: 'r_k_cyl'),
    ]),
    'l_rH': composeActions([
      padFractionalZerosAction(fieldKey: 'l_rH', fracDigits: 2),
      averageAction(aKey: 'l_rH', bKey: 'l_rV', targetKey: 'l_aver'),
      keratometryCylAction(hKey: 'l_rH', vKey: 'l_rV', targetKey: 'l_k_cyl'),
    ]),
    'l_rV': composeActions([
      padFractionalZerosAction(fieldKey: 'l_rV', fracDigits: 2),
      averageAction(aKey: 'l_rH', bKey: 'l_rV', targetKey: 'l_aver'),
      keratometryCylAction(hKey: 'l_rH', vKey: 'l_rV', targetKey: 'l_k_cyl'),
    ]),
    'r_diameter': padFractionalZerosAction(
      fieldKey: 'r_diameter',
      fracDigits: 2,
    ),
    'l_diameter': padFractionalZerosAction(
      fieldKey: 'l_diameter',
      fracDigits: 2,
    ),
    'r_base_curve_numerator': padFractionalZerosAction(
      fieldKey: 'r_base_curve_numerator',
      fracDigits: 2,
    ),
    'r_base_curve_denominator': padFractionalZerosAction(
      fieldKey: 'r_base_curve_denominator',
      fracDigits: 2,
    ),
    'l_base_curve_numerator': padFractionalZerosAction(
      fieldKey: 'l_base_curve_numerator',
      fracDigits: 2,
    ),
    'l_base_curve_denominator': padFractionalZerosAction(
      fieldKey: 'l_base_curve_denominator',
      fracDigits: 2,
    ),
    'r_lens_sph': padFractionalZerosAction(
      fieldKey: 'r_lens_sph',
      fracDigits: 2,
    ),
    'l_lens_sph': padFractionalZerosAction(
      fieldKey: 'l_lens_sph',
      fracDigits: 2,
    ),
    'r_lens_cyl': padFractionalZerosAction(
      fieldKey: 'r_lens_cyl',
      fracDigits: 2,
    ),
    'l_lens_cyl': padFractionalZerosAction(
      fieldKey: 'l_lens_cyl',
      fracDigits: 2,
    ),
  };

  /// Shared instances so widget identity stays stable across rebuilds.
  static final _oneDotTwoMask = [
    NumericMaskFormatter(intDigits: 1, fracDigits: 2),
  ];
  static final _signedThreeDotTwoMask = [
    NumericMaskFormatter(intDigits: 3, fracDigits: 2, allowSign: true),
  ];
  static final _twoDotTwoMask = [
    NumericMaskFormatter(intDigits: 2, fracDigits: 2),
  ];

  late final Map<String, List<TextInputFormatter>> _inputFormatters = {
    'r_rH': _oneDotTwoMask,
    'r_rV': _oneDotTwoMask,
    'l_rH': _oneDotTwoMask,
    'l_rV': _oneDotTwoMask,
    'r_diameter': _oneDotTwoMask,
    'l_diameter': _oneDotTwoMask,
    'r_base_curve_numerator': _oneDotTwoMask,
    'r_base_curve_denominator': _oneDotTwoMask,
    'l_base_curve_numerator': _oneDotTwoMask,
    'l_base_curve_denominator': _oneDotTwoMask,
    'r_lens_sph': _signedThreeDotTwoMask,
    'l_lens_sph': _signedThreeDotTwoMask,
    'r_lens_cyl': _twoDotTwoMask,
    'l_lens_cyl': _twoDotTwoMask,
  };

  /// Dropdown-list keys fetched at init time. Each provides free-text +
  /// autocompletion for a column in the prescription table.
  static const _dropdownListKeys = {
    'examiner',
    'contact_lens_type',
    'contact_lens_manufacturer',
    'contact_lens_brand',
  };

  /// Maps a field controller key to the dropdown list key that supplies
  /// its suggestions.
  static const _fieldToListKey = {
    'r_lens_type': 'contact_lens_type',
    'l_lens_type': 'contact_lens_type',
    'r_manufacturer': 'contact_lens_manufacturer',
    'l_manufacturer': 'contact_lens_manufacturer',
    'r_brand': 'contact_lens_brand',
    'l_brand': 'contact_lens_brand',
  };

  List<String> _optionsFor(String fieldKey) {
    final listKey = _fieldToListKey[fieldKey];
    if (listKey == null) return const [];
    return _dropdownOptions[listKey] ?? const [];
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
    for (final key in _dropdownListKeys) {
      DropdownOptionsService.instance.getOptions(key).then((opts) {
        if (mounted) setState(() => _dropdownOptions[key] = opts);
      });
    }
    final sampleTest = ContactLensesTest(
      id: 65454,
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
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _saveTest() async {
    if (_formKey.currentState!.validate()) {
      final newMap = <String, dynamic>{
        'id': 0,
        'customer_id': widget.customer.id,
      };
      _controllers.forEach((key, controller) {
        // Masked fields may still contain placeholder `_`s at save time if
        // the user hit Ctrl+S without ever blurring the field. Clean those
        // out before persisting.
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
        final newTest = ContactLensesTest.fromMap(newMap);
        await widget.customerService.addContactLensesTest(newTest);
        if (mounted) {
          Navigator.pop(context);
          AppNotification.show(
            context,
            'msg_lenses_saved'.tr(),
            type: NotificationType.success,
          );
        }
      } catch (e) {
        if (mounted) {
          AppNotification.show(
            context,
            'msg_lenses_save_error'.tr(namedArgs: {'error': e.toString()}),
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
            'title_add_lenses'.tr(namedArgs: {'name': widget.customer.fname}),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNonTableFields(),
                  const SizedBox(height: 20),
                  _buildKeratometryTable(context),
                  const SizedBox(height: 20),
                  _buildPrescriptionTable(context),
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

  Widget _buildNonTableFields() {
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

  Widget _buildKeratometryTable(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: AppColors.success, width: 3),
            ),
          ),
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            'section_keratometry'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Directionality(
          textDirection: ui.TextDirection.ltr,
          child: Table(
            border: TableBorder.all(color: AppColors.tableBorder),
            columnWidths: const {0: IntrinsicColumnWidth()},
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              _buildKeratometryHeaders(context),
              _buildKeratometryRow(context, 'R', _getRightKeratometryKeys()),
              _buildKeratometryRow(context, 'L', _getLeftKeratometryKeys()),
            ],
          ),
        ),
      ],
    );
  }

  TableRow _buildKeratometryHeaders(BuildContext context) {
    final headers = [
      'rH',
      'rV',
      'Aver',
      'Cylinder',
      'AxH',
      'rT',
      'rN',
      'rI',
      'Rs',
    ];
    return TableRow(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
      children: [
        _headerCell(context, ''),
        ...headers.map((h) => _headerCell(context, h)),
      ],
    );
  }

  List<String> _getRightKeratometryKeys() => [
    'r_rH',
    'r_rV',
    'r_aver',
    'r_k_cyl',
    'r_axH',
    'r_rT',
    'r_rN',
    'r_rI',
    'r_rS',
  ];

  List<String> _getLeftKeratometryKeys() => [
    'l_rH',
    'l_rV',
    'l_aver',
    'l_k_cyl',
    'l_axH',
    'l_rT',
    'l_rN',
    'l_rI',
    'l_rS',
  ];

  TableRow _buildKeratometryRow(
    BuildContext context,
    String eye,
    List<String> keys,
  ) {
    return TableRow(
      children: [
        _headerCell(context, eye, isRowHeader: true),
        ...keys.map((key) => _buildTextFormFieldCell(key)),
      ],
    );
  }

  Widget _buildPrescriptionTable(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: AppColors.accentOrange, width: 3),
            ),
          ),
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            'section_lens_prescription'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Directionality(
          textDirection: ui.TextDirection.ltr,
          child: Table(
            border: TableBorder.all(color: AppColors.tableBorder),
            columnWidths: const {0: IntrinsicColumnWidth()},
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              _buildPrescriptionHeaders(context),
              _buildPrescriptionRow(context, 'R', _getRightPrescriptionKeys()),
              _buildPrescriptionRow(context, 'L', _getLeftPrescriptionKeys()),
            ],
          ),
        ),
      ],
    );
  }

  TableRow _buildPrescriptionHeaders(BuildContext context) {
    final headers = [
      'Type',
      'Manufacturer',
      'Brand',
      'Diam',
      'B.C.',
      'Sph',
      'Cyl',
      'Axis',
      'Mat.',
      'Tint',
      'VA',
    ];
    return TableRow(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
      children: [
        _headerCell(context, ''),
        ...headers.map((h) => _headerCell(context, h)),
      ],
    );
  }

  List<String> _getRightPrescriptionKeys() => [
    'r_lens_type',
    'r_manufacturer',
    'r_brand',
    'r_diameter',
    'r_base_curve_numerator',
    'r_lens_sph',
    'r_lens_cyl',
    'r_lens_axis',
    'r_material',
    'r_tint',
    'r_va',
  ];

  List<String> _getLeftPrescriptionKeys() => [
    'l_lens_type',
    'l_manufacturer',
    'l_brand',
    'l_diameter',
    'l_base_curve_numerator',
    'l_lens_sph',
    'l_lens_cyl',
    'l_lens_axis',
    'l_material',
    'l_tint',
    'l_va',
  ];

  TableRow _buildPrescriptionRow(
    BuildContext context,
    String eye,
    List<String> keys,
  ) {
    return TableRow(
      children: [
        _headerCell(context, eye, isRowHeader: true),
        ...keys.map((key) {
          if (key.contains('base_curve')) {
            final denKey = key.replaceFirst('numerator', 'denominator');
            return _buildDoubleInputCell(key, denKey);
          }
          if (key == 'r_va') return _buildTextFormFieldCell('r_va');
          if (key == 'l_va') return _buildLensesVaCell();
          return _buildTextFormFieldCell(key);
        }),
      ],
    );
  }

  // L row VA cell: both_va top-right, l_va bottom-left
  Widget _buildLensesVaCell() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Spacer(),
            Expanded(child: _buildTextFormFieldCell('both_va')),
          ],
        ),
        Container(height: 1, color: AppColors.tableBorder),
        Row(
          children: [
            Expanded(child: _buildTextFormFieldCell('l_va')),
            const Spacer(),
          ],
        ),
      ],
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

  Widget _headerCell(
    BuildContext context,
    String text, {
    bool isRowHeader = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: isRowHeader ? AppColors.label : AppColors.displayValue,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormFieldCell(String key) {
    final hasSixPrefix = key == 'r_va' || key == 'l_va' || key == 'both_va';

    final field = _buildInputWidget(key);

    if (!hasSixPrefix) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: _wrapWithBlurAction(key, field),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        children: [
          const Text(
            '6/',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(child: _wrapWithBlurAction(key, field)),
        ],
      ),
    );
  }

  Widget _wrapWithBlurAction(String key, Widget child) {
    final action = _blurActions[key];
    if (action == null) return child;
    return OnBlurAction(
      controllers: _controllers,
      action: action,
      child: child,
    );
  }

  /// Builds the raw input widget for [key]: a compact [DropdownField] when
  /// options are registered for that field, otherwise a plain [TextFormField].
  /// Both variants share the same inputFormatters / styling.
  Widget _buildInputWidget(String key) {
    final opts = _optionsFor(key);
    if (opts.isNotEmpty) {
      return DropdownField(
        compact: true,
        options: opts,
        controller: _controllers[key],
        inputFormatters: _inputFormatters[key],
      );
    }
    return TextFormField(
      controller: _controllers[key],
      textAlign: TextAlign.center,
      inputFormatters: _inputFormatters[key],
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
  }

  Widget _buildDoubleInputCell(String numKey, String denKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        children: [
          Expanded(
            child: _wrapWithBlurAction(numKey, _buildInputWidget(numKey)),
          ),
          const Text('/', style: TextStyle(color: AppColors.label)),
          Expanded(
            child: _wrapWithBlurAction(denKey, _buildInputWidget(denKey)),
          ),
        ],
      ),
    );
  }
}

class SaveIntent extends Intent {}

class BackIntent extends Intent {}
