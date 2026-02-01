import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db_flutter/models.dart';
import '../flutter_services/customer_service.dart';

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
    // Initialize controllers for all fields of GlassesTest
    final sampleTest = GlassesTest(
      id: 465,
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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New glasses test saved successfully!')),
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
        title: Text(
          'Add New Glasses Test for ${widget.customer.fname} ${widget.customer.lname}',
        ),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveTest),
        ],
      ),
      body: Form(
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
    );
  }

  Widget _buildTopFields() {
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

  Widget _buildNotesField() {
    return TextFormField(
      controller: _controllers['notes'],
      decoration: const InputDecoration(labelText: 'NOTES', isDense: true),
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
              k != 'notes',
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
      itemCount: nonEyeDataKeys.length, // +1 for exam_date
      itemBuilder: (context, index) {
        final String key;
        key = nonEyeDataKeys[index];

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

  Widget _buildEyeDataTable() {
    return Table(
      border: TableBorder.all(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      ),
      columnWidths: const {0: IntrinsicColumnWidth()},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        _buildHeaders(context),
        _buildEyeDataRow('R', _getRightEyeKeys()),
        _buildEyeDataRow('L', _getLeftEyeKeys()),
      ],
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
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        ...keys.take(7).map((key) => _buildTextFormFieldCell(key)).toList(),
        TableCell(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: keys
                .sublist(7, 11)
                .map((key) => Expanded(child: _buildTextFormFieldCell(key)))
                .toList(),
          ),
        ),
        ...keys.sublist(11).map((key) => _buildTextFormFieldCell(key)).toList(),
      ],
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
}
