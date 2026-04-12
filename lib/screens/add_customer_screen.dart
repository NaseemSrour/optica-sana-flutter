import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _focusNode = FocusNode();
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
      final inputDate = DateFormat('d/M/yyyy').parse(date);
      return DateFormat('yyyy-MM-dd').format(inputDate);
    } catch (e) {
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
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      final newCustomer = models.Customer(
        id: 0,
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
            SnackBar(content: Text('msg_customer_added'.tr())),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'msg_customer_add_failed'.tr(namedArgs: {'error': e.toString()}),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      autofocus: true,
      focusNode: _focusNode,
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
            SaveIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): BackIntent(),
      },
      actions: {
        SaveIntent: CallbackAction<SaveIntent>(
          onInvoke: (_) => _saveCustomer(),
        ),
        BackIntent: CallbackAction<BackIntent>(
          onInvoke: (_) {
            Navigator.pop(context);
            return null;
          },
        ),
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('title_add_customer'.tr()),
          actions: [
            Tooltip(
              message: 'shortcut_hint'.tr(),
              child: const Icon(Icons.keyboard, color: Colors.white38, size: 18),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: _fnameController,
                    decoration: InputDecoration(labelText: 'field_fname'.tr()),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'err_fname'.tr();
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _lnameController,
                    decoration: InputDecoration(labelText: 'field_lname'.tr()),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'err_lname'.tr();
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _ssnController,
                    decoration: InputDecoration(labelText: 'field_ssn'.tr()),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'err_ssn'.tr();
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _birthDateController,
                    decoration: InputDecoration(
                      labelText: 'field_birth_date'.tr(),
                      hintText: 'hint_date'.tr(),
                    ),
                  ),
                  TextFormField(
                    controller: _sexController,
                    decoration: InputDecoration(labelText: 'field_sex'.tr()),
                  ),
                  TextFormField(
                    controller: _telHomeController,
                    decoration: InputDecoration(labelText: 'field_tel_home'.tr()),
                  ),
                  TextFormField(
                    controller: _telMobileController,
                    decoration: InputDecoration(labelText: 'field_tel_mobile'.tr()),
                  ),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(labelText: 'field_address'.tr()),
                  ),
                  TextFormField(
                    controller: _townController,
                    decoration: InputDecoration(labelText: 'field_town'.tr()),
                  ),
                  TextFormField(
                    controller: _postalCodeController,
                    decoration: InputDecoration(labelText: 'field_postal_code'.tr()),
                  ),
                  TextFormField(
                    controller: _statusController,
                    decoration: InputDecoration(labelText: 'field_status'.tr()),
                  ),
                  TextFormField(
                    controller: _orgController,
                    decoration: InputDecoration(labelText: 'field_org'.tr()),
                  ),
                  TextFormField(
                    controller: _occupationController,
                    decoration: InputDecoration(labelText: 'field_occupation'.tr()),
                  ),
                  TextFormField(
                    controller: _hobbiesController,
                    decoration: InputDecoration(labelText: 'field_hobbies'.tr()),
                  ),
                  TextFormField(
                    controller: _refererController,
                    decoration: InputDecoration(labelText: 'field_referer'.tr()),
                  ),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(labelText: 'field_notes'.tr()),
                  ),
                  CheckboxListTile(
                    title: Text('field_mailing'.tr()),
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
                    child: Text('btn_save_customer'.tr()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SaveIntent extends Intent {}

class BackIntent extends Intent {}
