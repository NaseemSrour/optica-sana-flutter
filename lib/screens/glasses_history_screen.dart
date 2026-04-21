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
  final _dropdownOptions = <String, List<String>>{};

  static const _tableDropdownKeys = {'r_base', 'l_base', 'examiner'};
  static const _gridDropdownKeys = {
    'dominant_eye',
    'glasses_role',
    'lenses_material',
    'segment_diameter',
    'lenses_manufacturer',
    'lenses_coated',
  };

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

  late final Map<String, FieldAction> _blurActions = {
    'r_pd': sumOrDoubleAction(aKey: 'r_pd', bKey: 'l_pd', targetKey: 'sum_pd'),
    'l_pd': sumOrDoubleAction(aKey: 'r_pd', bKey: 'l_pd', targetKey: 'sum_pd'),
  };

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _loadHistory();
    for (final key in {..._tableDropdownKeys, ..._gridDropdownKeys}) {
      DropdownOptionsService.instance.getOptions(key).then((opts) {
        if (mounted) setState(() => _dropdownOptions[key] = opts);
      });
    }
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
        AppNotification.show(
          context,
          'msg_error_loading_history'.tr(namedArgs: {'error': e.toString()}),
          type: NotificationType.error,
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

    final uniqueChecks = _blurChecks.values.toSet().toList();
    final err = runChecks(_controllers, uniqueChecks);
    if (err != null) {
      AppNotification.show(context, err, type: NotificationType.error);
      return;
    }

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
        AppNotification.show(
          context,
          'msg_test_saved'.tr(),
          type: NotificationType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(
          context,
          'msg_test_save_error'.tr(namedArgs: {'error': e.toString()}),
          type: NotificationType.error,
        );
      }
    }
  }

  Future<void> _confirmDeleteCurrentTest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'confirm_delete_title'.tr(),
          style: TextStyle(color: Colors.red),
        ),
        content: Text('confirm_delete_test_body'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('btn_cancel'.tr()),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('btn_delete'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final testId = _tests[_currentIndex].id;
      await widget.customerService.deleteGlassesTest(testId);
      setState(() {
        _tests.removeAt(_currentIndex);
        if (_tests.isNotEmpty) {
          _currentIndex = _currentIndex.clamp(0, _tests.length - 1);
          _updateControllersForCurrentTest();
        }
      });
      if (mounted) {
        if (_tests.isEmpty) {
          Navigator.pop(context);
        } else {
          AppNotification.show(
            context,
            'msg_test_deleted'.tr(),
            type: NotificationType.success,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(
          context,
          'msg_delete_error'.tr(namedArgs: {'error': e.toString()}),
          type: NotificationType.error,
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
        // Navigation shortcuts are disabled while editing so that - and +
        // are not swallowed before reaching the focused text fields.
        if (!_isEditing) LogicalKeySet(LogicalKeyboardKey.add): NextIntent(),
        if (!_isEditing)
          LogicalKeySet(LogicalKeyboardKey.numpadAdd): NextIntent(),
        if (!_isEditing)
          LogicalKeySet(LogicalKeyboardKey.minus): PreviousIntent(),
        if (!_isEditing)
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
            if (_tests.isNotEmpty) ...[
              IconButton(
                tooltip: _isEditing ? 'tooltip_save'.tr() : 'tooltip_edit'.tr(),
                icon: Icon(
                  _isEditing ? Icons.save : Icons.edit,
                  color: _isEditing ? AppColors.inputValue : AppColors.primary,
                ),
                onPressed: _isEditing ? _saveTest : _toggleEditMode,
              ),
              PopupMenuButton<String>(
                tooltip: 'tooltip_more_options'.tr(),
                onSelected: (value) {
                  if (value == 'delete') _confirmDeleteCurrentTest();
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'menu_delete'.tr(),
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
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

  String _formatBirthDate(String? raw) {
    if (raw == null || raw.isEmpty) return 'label_na'.tr();
    try {
      final date = DateFormat('yyyy-MM-dd').parse(raw);
      final now = DateTime.now();
      int age = now.year - date.year;
      if (now.month < date.month ||
          (now.month == date.month && now.day < date.day)) {
        age--;
      }
      return '${DateFormat('dd/MM/yyyy').format(date)} ($age)';
    } catch (_) {
      return raw;
    }
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
            _formatBirthDate(widget.customer.birthDate),
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
            'nav_test'.tr(
              namedArgs: {
                'current': (_tests.length - _currentIndex).toString(),
                'total': _tests.length.toString(),
              },
            ),
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
            dropdownOptions: _dropdownOptions,
            blurChecks: _isEditing ? _blurChecks : const {},
            blurActions: _isEditing ? _blurActions : const {},
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
                _buildTextField('diagnosis', 'field_diagnosis'.tr()),
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
                _buildDropdownOrTextField(
                  'lenses_manufacturer',
                  'field_lenses_manufacturer'.tr(),
                ),
                const SizedBox(height: 16),
                _buildTextField('lenses_color', 'field_lenses_color'.tr()),
                const SizedBox(height: 16),
                _buildDropdownOrTextField(
                  'lenses_coated',
                  'field_lenses_coated'.tr(),
                ),
                const SizedBox(height: 16),
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
                _buildTextField(
                  'notes',
                  'field_notes'.tr(),
                  maxLines: _isEditing ? 5 : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Shows a DropdownField in edit mode (if options are loaded) or falls back
  /// to the regular text field. Passes the external controller so free-typed
  /// values are always saved, not just values selected from the list.
  ///
  /// When [displayMapper] is provided the dropdown uses value+onChanged
  /// instead of an external controller (stored value ≠ display text).
  Widget _buildDropdownOrTextField(
    String key,
    String label, {
    String Function(String)? displayMapper,
  }) {
    if (_isEditing && (_dropdownOptions[key]?.isNotEmpty ?? false)) {
      if (displayMapper != null) {
        return DropdownField(
          label: label,
          options: _dropdownOptions[key]!,
          value: _controllers[key]?.text.isEmpty ?? true
              ? null
              : _controllers[key]!.text,
          onChanged: (v) => setState(() => _controllers[key]!.text = v ?? ''),
          displayMapper: displayMapper,
        );
      }
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
      enabled: _isEditing,
      style: TextStyle(
        color: _isEditing ? AppColors.inputValue : AppColors.displayValue,
        fontWeight: _isEditing ? FontWeight.w600 : FontWeight.normal,
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
