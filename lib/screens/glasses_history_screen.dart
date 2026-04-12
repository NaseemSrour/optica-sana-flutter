import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db_flutter/models.dart';
import '../flutter_services/customer_service.dart';
import '../themes/app_theme.dart';
import '../widgets/glasses_test_table.dart';

class GlassesHistoryScreen extends StatefulWidget {
  final Customer customer;
  final CustomerService customerService;

  const GlassesHistoryScreen({
    Key? key,
    required this.customer,
    required this.customerService,
  }) : super(key: key);

  @override
  State<GlassesHistoryScreen> createState() => _GlassesHistoryScreenState();
}

class _GlassesHistoryScreenState extends State<GlassesHistoryScreen> {
  List<GlassesTest> _tests = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isEditing = false;

  final FocusNode _focusNode = FocusNode();
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final tests = await widget.customerService.getGlassesHistory(
        widget.customer.id,
      );
      setState(() {
        _tests = tests;
        _isLoading = false;
        if (_tests.isNotEmpty) {
          _updateControllersForCurrentTest();
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'msg_error_loading_history'.tr(namedArgs: {'error': e.toString()}),
            ),
          ),
        );
      }
    }
  }

  void _updateControllersForCurrentTest() {
    if (_tests.isEmpty) return;
    final currentTest = _tests[_currentIndex];
    final testMap = currentTest.toMap();
    testMap.forEach((key, value) {
      _controllers[key] = TextEditingController(text: value?.toString() ?? '');
    });
  }

  void _navigateTests(int delta) {
    if (_tests.isEmpty) return;
    final newIndex = (_currentIndex + delta).clamp(0, _tests.length - 1);
    if (newIndex != _currentIndex) {
      setState(() {
        _currentIndex = newIndex;
        _updateControllersForCurrentTest();
      });
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveTest() async {
    if (!_isEditing || _tests.isEmpty) return;

    final updatedValues = <String, dynamic>{
      'id': _tests[_currentIndex].id,
      'customer_id': _tests[_currentIndex].customerId,
    };

    _controllers.forEach((key, controller) {
      updatedValues[key] = controller.text;
    });

    try {
      final updatedTest = GlassesTest.fromMap(updatedValues);
      await widget.customerService.updateGlassesTest(updatedTest);
      setState(() {
        _tests[_currentIndex] = updatedTest;
        _isEditing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('msg_test_saved'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'msg_test_save_error'.tr(namedArgs: {'error': e.toString()}),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTest = _tests.isNotEmpty ? _tests[_currentIndex] : null;

    return FocusableActionDetector(
      autofocus: true,
      focusNode: _focusNode,
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.f2): EditIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
            SaveIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): BackIntent(),
        LogicalKeySet(LogicalKeyboardKey.add): NextIntent(),
        LogicalKeySet(LogicalKeyboardKey.numpadAdd): NextIntent(),
        LogicalKeySet(LogicalKeyboardKey.minus): PreviousIntent(),
        LogicalKeySet(LogicalKeyboardKey.numpadSubtract): PreviousIntent(),
      },
      actions: {
        EditIntent: CallbackAction<EditIntent>(
          onInvoke: (_) => _toggleEditMode(),
        ),
        SaveIntent: CallbackAction<SaveIntent>(onInvoke: (_) => _saveTest()),
        BackIntent: CallbackAction<BackIntent>(
          onInvoke: (_) {
            if (_isEditing) {
              _toggleEditMode();
            } else {
              Navigator.pop(context);
            }
            return null;
          },
        ),
        NextIntent: CallbackAction<NextIntent>(
          onInvoke: (_) => _navigateTests(-1),
        ),
        PreviousIntent: CallbackAction<PreviousIntent>(
          onInvoke: (_) => _navigateTests(1),
        ),
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditing
                ? 'title_glasses_history_editing'.tr()
                : 'title_glasses_history'.tr(),
          ),
          actions: [
            if (_tests.isNotEmpty)
              IconButton(
                tooltip: _isEditing ? 'tooltip_save'.tr() : 'tooltip_edit'.tr(),
                icon: Icon(_isEditing ? Icons.save : Icons.edit),
                onPressed: _isEditing ? _saveTest : _toggleEditMode,
              ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _tests.isEmpty
              ? Center(child: Text('msg_no_glasses_history'.tr()))
              : Column(
                  children: [
                    _buildCustomerHeader(),
                    _buildTestNavigationHeader(currentTest),
                    Expanded(child: _buildTestDataForm(currentTest!)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCustomerHeader() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Wrap(
        spacing: 24,
        runSpacing: 8,
        children: [
          _buildHeaderInfo(
            'label_name'.tr(),
            '${widget.customer.fname} ${widget.customer.lname}',
          ),
          _buildHeaderInfo('label_ssn'.tr(), widget.customer.ssn.toString()),
          _buildHeaderInfo('label_id'.tr(), widget.customer.id.toString()),
          _buildHeaderInfo(
            'label_birth_date'.tr(),
            widget.customer.birthDate ?? 'label_na'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: Theme.of(context).textTheme.labelLarge),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }

  Widget _buildTestNavigationHeader(GlassesTest? test) {
    if (test == null) return const SizedBox.shrink();
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.navHeaderGradient),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'nav_test'.tr(namedArgs: {
              'current': (_tests.length - _currentIndex).toString(),
              'total': _tests.length.toString(),
            }),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            '${'label_date'.tr()}: ${DateFormat('dd/MM/yyyy').format(test.examDate)}',
            style: const TextStyle(color: AppColors.displayValue, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTestDataForm(GlassesTest test) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GlassesTestTable(
            glassesTest: test,
            isEditing: _isEditing,
            controllers: _controllers,
          ),
          const SizedBox(height: 20),
          _buildAdditionalInfo(test),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo(GlassesTest test) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('dominant_eye', 'field_dominant_eye'.tr()),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('r_iop', 'field_r_iop'.tr())),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('l_iop', 'field_l_iop'.tr())),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField('glasses_role', 'field_glasses_role'.tr()),
              const SizedBox(height: 16),
              _buildTextField('lenses_material', 'field_lenses_material'.tr()),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('lenses_diameter_1', 'field_lenses_diam_1'.tr()),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField('lenses_diameter_2', 'field_lenses_diam_2'.tr()),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'lenses_diameter_decentration_horizontal',
                      'field_lenses_dia_dec_h'.tr(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      'lenses_diameter_decentration_vertical',
                      'field_lenses_dia_dec_v'.tr(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField('segment_diameter', 'field_segment_diam'.tr()),
              const SizedBox(height: 16),
              _buildTextField('diagnosis', 'field_diagnosis'.tr()),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              _buildTextField('lenses_manufacturer', 'field_lenses_manufacturer'.tr()),
              const SizedBox(height: 16),
              _buildTextField('lenses_color', 'field_lenses_color'.tr()),
              const SizedBox(height: 16),
              _buildTextField('lenses_coated', 'field_lenses_coated'.tr()),
              const SizedBox(height: 16),
              _buildTextField('catalog_num', 'field_catalog_num'.tr()),
              const SizedBox(height: 16),
              _buildTextField('frame_manufacturer', 'field_frame_manufacturer'.tr()),
              const SizedBox(height: 16),
              _buildTextField('frame_supplier', 'field_frame_supplier'.tr()),
              const SizedBox(height: 16),
              _buildTextField('frame_model', 'field_frame_model'.tr()),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField('frame_size', 'field_frame_size'.tr())),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField('frame_bar_length', 'field_frame_bar_length'.tr()),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('frame_color', 'field_frame_color'.tr())),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField('notes', 'field_notes'.tr(), maxLines: 5),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String key, String label, {int? maxLines = 1}) {
    return TextFormField(
      controller: _controllers[key],
      enabled: _isEditing,
      maxLines: maxLines,
      style: TextStyle(
        color: _isEditing ? AppColors.inputValue : AppColors.displayValue,
        fontWeight: _isEditing ? FontWeight.w600 : FontWeight.normal,
      ),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

}

class EditIntent extends Intent {}

class SaveIntent extends Intent {}

class BackIntent extends Intent {}

class NextIntent extends Intent {}

class PreviousIntent extends Intent {}
