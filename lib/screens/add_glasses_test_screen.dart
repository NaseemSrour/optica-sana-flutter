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
  };

  String _domEyeDisplay(String v) => 'dominant_eye_$v'.tr();

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
        SaveIntent: CallbackAction<SaveIntent>(
          onInvoke: (_) => _saveTest(),
        ),
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
      decoration: InputDecoration(
        labelText: 'field_notes'.tr(),
        isDense: true,
      ),
      maxLines: 3,
    );
  }

  Widget _buildNonEyeDataFields() {
    final nonEyeDataKeys = _controllers.keys
        .where(
          (k) =>
              !k.startsWith('r_') &&
              !k.startsWith('l_') &&
              k != 'exam_date' &&
              k != 'examiner' &&
              k != 'notes' &&
              k != 'both_va' &&
              k != 'sum_pd' &&
              k != 'near_pd',
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
        if (_gridDropdownKeys.contains(key)) {
          return DropdownField(
            label: _labelFor(key),
            options: _dropdownOptions[key] ?? [],
            value: _controllers[key]?.text.isEmpty ?? true
                ? null
                : _controllers[key]!.text,
            onChanged: (v) => setState(() => _controllers[key]!.text = v ?? ''),
            displayMapper:
                key == 'dominant_eye' ? _domEyeDisplay : null,
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
          8: FlexColumnWidth(4),
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
        // VA column (index 6): r_va + both_va stacked for R; l_va only for L
        eye == 'R'
            ? _buildStackedVaCell(keys[6])
            : _buildTextFormFieldCell(keys[6]),
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
        // PD column: sum_pd / near_pd for R; empty for L
        eye == 'R' ? _buildPdCell() : const SizedBox(),
      ],
    );
  }

  Widget _buildStackedVaCell(String vaKey) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTextFormFieldCell(vaKey),
        Container(height: 1, color: AppColors.tableBorder),
        _buildTextFormFieldCell('both_va'),
      ],
    );
  }

  Widget _buildPdCell() {
    return Row(
      children: [
        Expanded(child: _buildTextFormFieldCell('sum_pd')),
        const Text(
          '/',
          style: TextStyle(color: AppColors.label, fontSize: 12),
        ),
        Expanded(child: _buildTextFormFieldCell('near_pd')),
      ],
    );
  }

  Widget _buildTextFormFieldCell(String key) {
    if (_tableDropdownKeys.contains(key)) {
      return DropdownField(
        compact: true,
        options: _dropdownOptions[key] ?? [],
        value: _controllers[key]?.text.isEmpty ?? true
            ? null
            : _controllers[key]!.text,
        onChanged: (v) => setState(() => _controllers[key]!.text = v ?? ''),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextFormField(
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
      ),
    );
  }
}

class SaveIntent extends Intent {}

class BackIntent extends Intent {}
