import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../db_flutter/models.dart';
import '../flutter_services/customer_service.dart';
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
          title: Text('Glasses History${_isEditing ? " (Editing)" : ""}'),
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
                child: Text('No glasses history found for this customer.'),
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

  Widget _buildTestNavigationHeader(GlassesTest? test) {
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
                  Expanded(child: _buildTextField('both_va', 'Both VA')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('sum_pd', 'Sum PD')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('near_pd', 'Near PD')),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('dominant_eye', 'Dominant Eye'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('r_iop', 'R IOP')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('l_iop', 'L IOP')),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField('glasses_role', 'Glasses Role'),
              const SizedBox(height: 16),
              _buildTextField('lenses_material', 'Lenses Material'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'lenses_diameter_1',
                      'Lenses Diameter 1',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      'lenses_diameter_2',
                      'Lenses Diameter 2',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'lenses_diameter_decentration_horizontal',
                      'Lenses Dia. Decent. H',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      'lenses_diameter_decentration_vertical',
                      'Lenses Dia. Decent. V',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField('segment_diameter', 'Segment Diameter'),
              const SizedBox(height: 16),
              _buildTextField('diagnosis', 'Diagnosis'),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              _buildTextField('lenses_manufacturer', 'Lenses Manufacturer'),
              const SizedBox(height: 16),
              _buildTextField('lenses_color', 'Lenses Color'),
              const SizedBox(height: 16),
              _buildTextField('lenses_coated', 'Lenses Coated'),
              const SizedBox(height: 16),
              _buildTextField('catalog_num', 'Catalog Num'),
              const SizedBox(height: 16),
              _buildTextField('frame_manufacturer', 'Frame Manufacturer'),
              const SizedBox(height: 16),
              _buildTextField('frame_supplier', 'Frame Supplier'),
              const SizedBox(height: 16),
              _buildTextField('frame_model', 'Frame Model'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField('frame_size', 'Frame Size')),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      'frame_bar_length',
                      'Frame Bar Length',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField('frame_color', 'Frame Color'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField('notes', 'Notes', maxLines: 5),
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
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  TableRow _buildEyeDataRow(String eyeLabel, List<String> fields) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            eyeLabel,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        ...fields.map((field) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: TextFormField(
              controller: _controllers[field],
              enabled: _isEditing,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          );
        }),
      ],
    );
  }
}

class EditIntent extends Intent {}

class SaveIntent extends Intent {}

class NextIntent extends Intent {}

class PreviousIntent extends Intent {}
