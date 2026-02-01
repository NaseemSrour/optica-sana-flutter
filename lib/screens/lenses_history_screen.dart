import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../db_flutter/models.dart';
import '../flutter_services/customer_service.dart';
import '../widgets/lenses_test_tables.dart';

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

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _loadHistory();
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading history: $e')));
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

    // Handle composite fields
    _controllers['r_base_curve'] = TextEditingController(
      text:
          '${currentTest.rBaseCurveNumerator ?? ''}/${currentTest.rBaseCurveDenominator ?? ''}',
    );
    _controllers['r_lens_va'] = TextEditingController(
      text:
          '${currentTest.rLensVaNumerator ?? ''}/${currentTest.rLensVaDenominator ?? ''}',
    );
    _controllers['l_base_curve'] = TextEditingController(
      text:
          '${currentTest.lBaseCurveNumerator ?? ''}/${currentTest.lBaseCurveDenominator ?? ''}',
    );
    _controllers['l_lens_va'] = TextEditingController(
      text:
          '${currentTest.lLensVaNumerator ?? ''}/${currentTest.lLensVaDenominator ?? ''}',
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
      if (key == 'r_base_curve') {
        final parts = controller.text.split('/');
        updatedValues['r_base_curve_numerator'] = parts.isNotEmpty
            ? parts[0]
            : '';
        updatedValues['r_base_curve_denominator'] = parts.length > 1
            ? parts[1]
            : '';
      } else if (key == 'r_lens_va') {
        final parts = controller.text.split('/');
        updatedValues['r_lens_va_numerator'] = parts.isNotEmpty ? parts[0] : '';
        updatedValues['r_lens_va_denominator'] = parts.length > 1
            ? parts[1]
            : '';
      } else if (key == 'l_base_curve') {
        final parts = controller.text.split('/');
        updatedValues['l_base_curve_numerator'] = parts.isNotEmpty
            ? parts[0]
            : '';
        updatedValues['l_base_curve_denominator'] = parts.length > 1
            ? parts[1]
            : '';
      } else if (key == 'l_lens_va') {
        final parts = controller.text.split('/');
        updatedValues['l_lens_va_numerator'] = parts.isNotEmpty ? parts[0] : '';
        updatedValues['l_lens_va_denominator'] = parts.length > 1
            ? parts[1]
            : '';
      } else {
        updatedValues[key] = controller.text;
      }
    });

    try {
      final updatedTest = ContactLensesTest.fromMap(updatedValues);
      await widget.customerService.updateContactLensesTest(updatedTest);
      setState(() {
        _tests[_currentIndex] = updatedTest;
        _isEditing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Test saved successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving test: $e')));
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
            'Contact Lenses History${_isEditing ? " (Editing)" : ""}',
          ),
          actions: [
            if (_tests.isNotEmpty)
              IconButton(
                tooltip: _isEditing ? 'Save (Ctrl+S)' : 'Edit (F2)',
                icon: Icon(_isEditing ? Icons.save : Icons.edit),
                onPressed: _isEditing ? _saveTest : _toggleEditMode,
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _tests.isEmpty
            ? const Center(
                child: Text(
                  'No contact lenses history found for this customer.',
                ),
              )
            : Column(
                children: [
                  _buildCustomerHeader(),
                  _buildTestNavigationHeader(currentTest),
                  Expanded(child: _buildTestDataForm(currentTest!)),
                ],
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
            'Name',
            '${widget.customer.fname} ${widget.customer.lname}',
          ),
          _buildHeaderInfo('SSN', widget.customer.ssn.toString()),
          _buildHeaderInfo('ID', widget.customer.id.toString()),
          _buildHeaderInfo('Birth Date', widget.customer.birthDate ?? 'N/A'),
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
      color: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Test ${_tests.length - _currentIndex} of ${_tests.length}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          Text(
            'Date: ${DateFormat('dd/MM/yyyy').format(test.examDate)}',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontSize: 16, color: Colors.white),
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
      ),
    );
  }
}

class EditIntent extends Intent {}

class SaveIntent extends Intent {}

class NextIntent extends Intent {}

class PreviousIntent extends Intent {}
