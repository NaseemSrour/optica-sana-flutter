import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../db_flutter/models.dart' as models;
import '../flutter_services/customer_service.dart';
import '../themes/app_theme.dart';

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
  bool _mailing = false;

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
        mailing: _mailing.toString(),
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
        SaveIntent: CallbackAction<SaveIntent>(onInvoke: (_) => _saveCustomer()),
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
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'tooltip_save'.tr(),
              onPressed: _saveCustomer,
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Two-column form ─────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildIdentityColumn()),
                      const SizedBox(width: 24),
                      Expanded(child: _buildAddressColumn()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── Notes (full width) ──────────────────────────────────
                  _field(
                    controller: _notesController,
                    label: '📝  ${'field_notes'.tr()}',
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Left column: personal identity + contact numbers
  Widget _buildIdentityColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _field(
                controller: _fnameController,
                label: '👤  ${'field_fname'.tr()}',
                validator: (v) => (v == null || v.isEmpty) ? 'err_fname'.tr() : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                controller: _lnameController,
                label: '👤  ${'field_lname'.tr()}',
                validator: (v) => (v == null || v.isEmpty) ? 'err_lname'.tr() : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _field(
          controller: _ssnController,
          label: '🪪  ${'field_ssn'.tr()}',
          keyboardType: TextInputType.number,
          validator: (v) => (v == null || v.isEmpty) ? 'err_ssn'.tr() : null,
        ),
        const SizedBox(height: 12),
        _field(
          controller: _birthDateController,
          label: '🎂  ${'field_birth_date'.tr()}',
          hint: 'hint_date'.tr(),
        ),
        const SizedBox(height: 12),
        _field(controller: _sexController, label: '⚧️  ${'field_sex'.tr()}'),
        const SizedBox(height: 12),
        _field(controller: _telHomeController, label: '📞  ${'field_tel_home'.tr()}'),
        const SizedBox(height: 12),
        _field(controller: _telMobileController, label: '📱  ${'field_tel_mobile'.tr()}'),
      ],
    );
  }

  // Right column: address + miscellaneous
  Widget _buildAddressColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(controller: _addressController, label: '🏠  ${'field_address'.tr()}'),
        const SizedBox(height: 12),
        _field(controller: _townController, label: '🏙️  ${'field_town'.tr()}'),
        const SizedBox(height: 12),
        _field(controller: _postalCodeController, label: '📮  ${'field_postal_code'.tr()}'),
        const SizedBox(height: 12),
        _field(controller: _statusController, label: '🏷️  ${'field_status'.tr()}'),
        const SizedBox(height: 12),
        _field(controller: _orgController, label: '🏢  ${'field_org'.tr()}'),
        const SizedBox(height: 12),
        _field(controller: _occupationController, label: '💼  ${'field_occupation'.tr()}'),
        const SizedBox(height: 12),
        _field(controller: _hobbiesController, label: '🎨  ${'field_hobbies'.tr()}'),
        const SizedBox(height: 12),
        _field(controller: _refererController, label: '🔗  ${'field_referer'.tr()}'),
        const SizedBox(height: 4),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('✉️  ${'field_mailing'.tr()}'),
          value: _mailing,
          onChanged: (v) => setState(() => _mailing = v ?? false),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int? maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(
        color: AppColors.inputValue,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }
}

class SaveIntent extends Intent {}

class BackIntent extends Intent {}
