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
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 250,
            childAspectRatio: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _controllers.length,
          itemBuilder: (context, index) {
            final key = _controllers.keys.elementAt(index);
            return TextFormField(
              controller: _controllers[key],
              decoration: InputDecoration(
                labelText: key.replaceAll('_', ' ').toUpperCase(),
                hintText: key.contains('date') ? 'DD/MM/YYYY' : null,
                isDense: true,
              ),
            );
          },
        ),
      ),
    );
  }
}
