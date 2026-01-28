import 'package:flutter/material.dart';
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
          text: value?.toString() ?? '',
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
        'id': null,
        'customer_id': widget.customer.id,
      };
      _controllers.forEach((key, controller) {
        // Simplified conversion
        newMap[key] = controller.text;
      });

      try {
        // More robust parsing would be needed here for a real app
        final newTest = GlassesTest.fromMap(
          newMap.map((key, value) {
            if (value is String) {
              if (key.contains('date')) return MapEntry(key, value);
              final asDouble = double.tryParse(value);
              if (asDouble != null) {
                if (asDouble == asDouble.toInt())
                  return MapEntry(key, asDouble.toInt());
                return MapEntry(key, asDouble);
              }
            }
            return MapEntry(key, value);
          }),
        );

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
        title: Text('Add New Glasses Test for ${widget.customer.fname}'),
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
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            );
          },
        ),
      ),
    );
  }
}
