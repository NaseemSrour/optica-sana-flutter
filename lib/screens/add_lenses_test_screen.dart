import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db_flutter/models.dart';
import '../flutter_services/customer_service.dart';

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
  final _controllers = <String, TextEditingController>{};

  String _formatDateForDb(String date) {
    if (date.isEmpty) return '';
    try {
      // Parse with d/M/yyyy to allow for single-digit day/month
      final inputDate = DateFormat('d/M/yyyy').parse(date);
      // Format to yyyy-MM-dd to ensure leading zeros for DB sorting
      return DateFormat('yyyy-MM-dd').format(inputDate);
    } catch (e) {
      // If parsing fails, return original string.
      return date;
    }
  }

  @override
  void initState() {
    super.initState();
    final sampleTest = ContactLensesTest(
      id: 65454,
      customerId: widget.customer.id!,
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
    super.dispose();
  }

  Future<void> _saveTest() async {
    if (_formKey.currentState!.validate()) {
      final newMap = <String, dynamic>{
        'id': 0,
        'customer_id': widget.customer.id,
      };
      _controllers.forEach((key, controller) {
        if (key == 'exam_date') {
          newMap[key] = _formatDateForDb(controller.text);
        } else {
          newMap[key] = controller.text;
        }
      });

      try {
        final newTest = ContactLensesTest.fromMap(newMap);

        await widget.customerService.addContactLensesTest(newTest);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New contact lenses test saved successfully!'),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving test: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Lenses Test for ${widget.customer.fname}'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveTest),
        ],
      ),
      body: Form(
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
    );
  }

  Widget _buildNonTableFields() {
    final keys = ['exam_date', 'examiner'];
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
          decoration: InputDecoration(
            labelText: key.replaceAll('_', ' ').toUpperCase(),
            hintText: key.contains('date') ? 'DD/MM/YYYY' : null,
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
        Text("Keratometry", style: Theme.of(context).textTheme.titleMedium),
        Table(
          border: TableBorder.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          columnWidths: const {0: IntrinsicColumnWidth()},
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            _buildKeratometryHeaders(context),
            _buildKeratometryRow(context, 'R', _getRightKeratometryKeys()),
            _buildKeratometryRow(context, 'L', _getLeftKeratometryKeys()),
          ],
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
        ...headers.map((h) => _headerCell(context, h)).toList(),
      ],
    );
  }

  List<String> _getRightKeratometryKeys() {
    return [
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
  }

  List<String> _getLeftKeratometryKeys() {
    return [
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
  }

  TableRow _buildKeratometryRow(
    BuildContext context,
    String eye,
    List<String> keys,
  ) {
    return TableRow(
      children: [
        _headerCell(context, eye, isRowHeader: true),
        ...keys.map((key) => _buildTextFormFieldCell(key)).toList(),
      ],
    );
  }

  Widget _buildPrescriptionTable(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Contact Lens Prescription",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Table(
          border: TableBorder.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          columnWidths: const {0: IntrinsicColumnWidth()},
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            _buildPrescriptionHeaders(context),
            _buildPrescriptionRow(context, 'R', _getRightPrescriptionKeys()),
            _buildPrescriptionRow(context, 'L', _getLeftPrescriptionKeys()),
          ],
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
        ...headers.map((h) => _headerCell(context, h)).toList(),
      ],
    );
  }

  List<String> _getRightPrescriptionKeys() {
    return [
      'r_lens_type',
      'r_manufacturer',
      'r_brand',
      'r_diameter',
      'r_base_curve_numerator', // Special handling for BC
      'r_lens_sph',
      'r_lens_cyl',
      'r_lens_axis',
      'r_material',
      'r_tint',
      'r_lens_va_numerator', // Special handling for VA
    ];
  }

  List<String> _getLeftPrescriptionKeys() {
    return [
      'l_lens_type',
      'l_manufacturer',
      'l_brand',
      'l_diameter',
      'l_base_curve_numerator', // Special handling for BC
      'l_lens_sph',
      'l_lens_cyl',
      'l_lens_axis',
      'l_material',
      'l_tint',
      'l_lens_va_numerator', // Special handling for VA
    ];
  }

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
          if (key.contains('lens_va')) {
            final denKey = key.replaceFirst('numerator', 'denominator');
            return _buildDoubleInputCell(key, denKey);
          }
          return _buildTextFormFieldCell(key);
        }).toList(),
      ],
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _controllers['notes'],
      decoration: const InputDecoration(labelText: 'NOTES', isDense: true),
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
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isRowHeader ? null : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormFieldCell(String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextFormField(
        controller: _controllers[key],
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildDoubleInputCell(String numKey, String denKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _controllers[numKey],
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const Text('/'),
          Expanded(
            child: TextFormField(
              controller: _controllers[denKey],
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
