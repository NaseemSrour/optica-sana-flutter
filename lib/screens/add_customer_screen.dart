import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db_flutter/bootstrap.dart';
import '../db_flutter/models.dart' as models;
import '../flutter_services/customer_service.dart';

class AddCustomerScreen extends StatefulWidget {
  final CustomerService customerService;
  const AddCustomerScreen({super.key, required this.customerService});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ssnController = TextEditingController();
  final _fnameController = TextEditingController();
  final _lnameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _sexController = TextEditingController();
  final _telHomeController = TextEditingController();
  final _telMobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _townController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _statusController = TextEditingController();
  final _orgController = TextEditingController();
  final _occupationController = TextEditingController();
  final _hobbiesController = TextEditingController();
  final _refererController = TextEditingController();
  final _notesController = TextEditingController();
  String _mailing = 'false';

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
  void dispose() {
    _ssnController.dispose();
    _fnameController.dispose();
    _lnameController.dispose();
    _birthDateController.dispose();
    _sexController.dispose();
    _telHomeController.dispose();
    _telMobileController.dispose();
    _addressController.dispose();
    _townController.dispose();
    _postalCodeController.dispose();
    _statusController.dispose();
    _orgController.dispose();
    _occupationController.dispose();
    _hobbiesController.dispose();
    _refererController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      final newCustomer = models.Customer(
        id: 0, // This is a dummy ID - it will be set by the database upon INSERTing.
        ssn: _ssnController.text,
        fname: _fnameController.text,
        lname: _lnameController.text,
        birthDate: _formatDateForDb(_birthDateController.text),
        sex: _sexController.text,
        telHome: _telHomeController.text,
        telMobile: _telMobileController.text,
        address: _addressController.text,
        town: _townController.text,
        postalCode: _postalCodeController.text,
        status: _statusController.text,
        org: _orgController.text,
        occupation: _occupationController.text,
        hobbies: _hobbiesController.text,
        referer: _refererController.text,
        notes: _notesController.text,
        mailing: _mailing,
      );

      try {
        await widget.customerService.addCustomer(newCustomer);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer added successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to add customer: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Customer')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _fnameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a first name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _lnameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a last name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _ssnController,
                  decoration: const InputDecoration(labelText: 'SSN'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a SSN';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _birthDateController,
                  decoration: const InputDecoration(
                    labelText: 'Birth Date',
                    hintText: 'DD/MM/YYYY',
                  ),
                ),
                TextFormField(
                  controller: _sexController,
                  decoration: const InputDecoration(labelText: 'Sex'),
                ),
                TextFormField(
                  controller: _telHomeController,
                  decoration: const InputDecoration(labelText: 'Home Phone'),
                ),
                TextFormField(
                  controller: _telMobileController,
                  decoration: const InputDecoration(labelText: 'Mobile Phone'),
                ),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                TextFormField(
                  controller: _townController,
                  decoration: const InputDecoration(labelText: 'Town'),
                ),
                TextFormField(
                  controller: _postalCodeController,
                  decoration: const InputDecoration(labelText: 'Postal Code'),
                ),
                TextFormField(
                  controller: _statusController,
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
                TextFormField(
                  controller: _orgController,
                  decoration: const InputDecoration(labelText: 'Organization'),
                ),
                TextFormField(
                  controller: _occupationController,
                  decoration: const InputDecoration(labelText: 'Occupation'),
                ),
                TextFormField(
                  controller: _hobbiesController,
                  decoration: const InputDecoration(labelText: 'Hobbies'),
                ),
                TextFormField(
                  controller: _refererController,
                  decoration: const InputDecoration(labelText: 'Referer'),
                ),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
                CheckboxListTile(
                  title: const Text('Mailing'),
                  value: _mailing == 'true',
                  onChanged: (bool? value) {
                    setState(() {
                      _mailing = (value ?? false).toString();
                    });
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveCustomer,
                  child: const Text('Save Customer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
