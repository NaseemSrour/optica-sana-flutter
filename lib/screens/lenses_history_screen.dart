import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db_flutter/models.dart';
import '../flutter_services/customer_service.dart';
import '../flutter_services/dropdown_options_service.dart';
import '../themes/app_theme.dart';
import '../widgets/app_notification.dart';
import '../widgets/field_validation.dart';
import '../widgets/lenses_test_tables.dart';
import '../widgets/numeric_mask_formatter.dart';

class LensesHistoryScreen extends StatefulWidget {
  final Customer customer;
  final CustomerService customerService;

  const LensesHistoryScreen({
    Key? key,
    required this.customer,
    required this.customerService,
  }) : super(key: key);

  @override
  State<LensesHistoryScreen> createState() => _LensesHistoryScreenState();
}

class _LensesHistoryScreenState extends State<LensesHistoryScreen> {
  List<ContactLensesTest> _tests = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isEditing = false;

  final FocusNode _focusNode = FocusNode();
  late final Map<String, TextEditingController> _controllers;
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

  /// Input formatters for numeric fields with fixed digit shapes.
  /// Kept as fields (not getters) so the list identity is stable across
  /// rebuilds.
  static final _oneDotTwoMask = [
    NumericMaskFormatter(intDigits: 1, fracDigits: 2),
  ];
  static final _signedThreeDotTwoMask = [
    NumericMaskFormatter(intDigits: 3, fracDigits: 2, allowSign: true),
  ];
  static final _signedTwoDotTwoMask = [
    NumericMaskFormatter(intDigits: 2, fracDigits: 2, allowSign: true),
  ];

  late final Map<String, List<TextInputFormatter>> _inputFormatters = {
    'r_rH': _oneDotTwoMask,
    'r_rV': _oneDotTwoMask,
    'l_rH': _oneDotTwoMask,
    'l_rV': _oneDotTwoMask,
    'r_diameter': _oneDotTwoMask,
    'l_diameter': _oneDotTwoMask,
    'r_lens_sph': _signedThreeDotTwoMask,
    'l_lens_sph': _signedThreeDotTwoMask,
    'r_lens_cyl': _signedTwoDotTwoMask,
    'l_lens_cyl': _signedTwoDotTwoMask,
  };

  /// Maps field controller keys to the dropdown list key that supplies
  /// their suggestions. Free text is still allowed; suggestions come from
  /// user-managed lists.
  static const _fieldToListKey = {
    'r_lens_type': 'contact_lens_type',
    'l_lens_type': 'contact_lens_type',
    'r_manufacturer': 'contact_lens_manufacturer',
    'l_manufacturer': 'contact_lens_manufacturer',
    'r_brand': 'contact_lens_brand',
    'l_brand': 'contact_lens_brand',
  };

  /// Effective map passed to the table: each field’s options looked up by
  /// the corresponding list key. Rebuilds naturally because it reads from
  /// _dropdownOptions which is mutated inside setState.
  Map<String, List<String>> get _tableDropdownOptions {
    final out = <String, List<String>>{};
    _fieldToListKey.forEach((fieldKey, listKey) {
      final opts = _dropdownOptions[listKey];
      if (opts != null && opts.isNotEmpty) out[fieldKey] = opts;
    });
    // Examiner uses its own list key directly.
    final examiner = _dropdownOptions['examiner'];
    if (examiner != null) out['examiner'] = examiner;
    return out;
  }

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _loadHistory();
    const listKeys = {
      'examiner',
      'contact_lens_type',
      'contact_lens_manufacturer',
      'contact_lens_brand',
    };
    for (final key in listKeys) {
      DropdownOptionsService.instance.getOptions(key).then((opts) {
        if (mounted) setState(() => _dropdownOptions[key] = opts);
      });
    }
  }

  Future<void> _loadHistory() async {
    try {
      final tests = await widget.customerService.getContactLensesHistory(
        widget.customer.id!,
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

    _controllers.clear();
    testMap.forEach((key, value) {
      _controllers[key] = TextEditingController(text: value?.toString() ?? '');
    });

    _controllers['r_base_curve'] = TextEditingController(
      text:
          '${currentTest.rBaseCurveNumerator ?? ''}/${currentTest.rBaseCurveDenominator ?? ''}',
    );
    _controllers['l_base_curve'] = TextEditingController(
      text:
          '${currentTest.lBaseCurveNumerator ?? ''}/${currentTest.lBaseCurveDenominator ?? ''}',
    );
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
      'exam_date': DateFormat(
        'yyyy-MM-dd',
      ).format(_tests[_currentIndex].examDate),
    };

    _controllers.forEach((key, controller) {
      // Masked fields may still contain placeholder `_`s at save time if
      // the user hit Ctrl+S without ever blurring the field.
      final raw = _inputFormatters.containsKey(key)
          ? stripNumericMask(controller.text)
          : controller.text;
      if (key == 'r_base_curve') {
        final parts = raw.split('/');
        updatedValues['r_base_curve_numerator'] = parts.isNotEmpty
            ? parts[0]
            : '';
        updatedValues['r_base_curve_denominator'] = parts.length > 1
            ? parts[1]
            : '';
      } else if (key == 'l_base_curve') {
        final parts = raw.split('/');
        updatedValues['l_base_curve_numerator'] = parts.isNotEmpty
            ? parts[0]
            : '';
        updatedValues['l_base_curve_denominator'] = parts.length > 1
            ? parts[1]
            : '';
      } else {
        updatedValues[key] = raw;
      }
    });

    try {
      final updatedTest = ContactLensesTest.fromMap(updatedValues);
      await widget.customerService.updateContactLensesTest(updatedTest);
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
      await widget.customerService.deleteContactLensesTest(testId);
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
                ? 'title_lenses_history_editing'.tr()
                : 'title_lenses_history'.tr(),
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
              ? Center(child: Text('msg_no_lenses_history'.tr()))
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

  Widget _buildTestNavigationHeader(ContactLensesTest? test) {
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

  Widget _buildTestDataForm(ContactLensesTest test) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: LensesTestTables(
        lensesTest: test,
        isEditing: _isEditing,
        controllers: _controllers,
        dropdownOptions: _tableDropdownOptions,
        blurActions: _isEditing ? _blurActions : const {},
        inputFormatters: _isEditing ? _inputFormatters : const {},
      ),
    );
  }
}

class EditIntent extends Intent {}

class SaveIntent extends Intent {}

class BackIntent extends Intent {}

class NextIntent extends Intent {}

class PreviousIntent extends Intent {}
