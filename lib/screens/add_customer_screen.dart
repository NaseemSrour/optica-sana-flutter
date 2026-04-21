import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../db_flutter/models.dart' as models;
import '../flutter_services/customer_service.dart';
import '../flutter_services/dropdown_options_service.dart';
import '../themes/app_theme.dart';
import '../widgets/app_notification.dart';
import '../widgets/date_mask_formatter.dart';
import '../widgets/dropdown_field.dart';
import '../widgets/field_validation.dart';

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
  final _birthDateFocusNode = FocusNode();
  String? _selectedSex;
  List<String> _sexOptions = [];
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

  @override
  void initState() {
    super.initState();
    _birthDateFocusNode.addListener(_onBirthDateFocus);
    DropdownOptionsService.instance.getOptions('sex').then((opts) {
      if (mounted) setState(() => _sexOptions = opts);
    });
  }

  void _onBirthDateFocus() {
    if (_birthDateFocusNode.hasFocus) {
      if (_birthDateController.text.isEmpty) {
        _birthDateController.value = const TextEditingValue(
          text: '__/__/____',
          selection: TextSelection.collapsed(offset: 0),
        );
      }
    } else {
      // If no digits were entered, clear back to empty
      final digits = _birthDateController.text.replaceAll(RegExp(r'[^\d]'), '');
      if (digits.isEmpty) _birthDateController.clear();
    }
  }

  String _formatDateForDb(String date) {
    if (date.isEmpty) return '';
    // Reject incomplete masks (less than 8 digits entered)
    final digits = date.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 8) return '';
    try {
      return DateFormat(
        'yyyy-MM-dd',
      ).format(DateFormat('dd/MM/yyyy').parse(date));
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    _ssnController.dispose();
    _fnameController.dispose();
    _lnameController.dispose();
    _birthDateController.dispose();
    _birthDateFocusNode.dispose();
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
        sex: _selectedSex ?? '',
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
          AppNotification.show(
            context,
            'msg_customer_added'.tr(),
            type: NotificationType.success,
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          AppNotification.show(
            context,
            'msg_customer_add_failed'.tr(namedArgs: {'error': e.toString()}),
            type: NotificationType.error,
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
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'tooltip_save'.tr(),
              onPressed: _saveCustomer,
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
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
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'err_fname'.tr() : null,
                blurCheck: simpleRequiredCheck(
                  controller: _fnameController,
                  errorTrKey: 'err_fname',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                controller: _lnameController,
                label: '👤  ${'field_lname'.tr()}',
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'err_lname'.tr() : null,
                blurCheck: simpleRequiredCheck(
                  controller: _lnameController,
                  errorTrKey: 'err_lname',
                ),
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
          blurCheck: simpleRequiredCheck(
            controller: _ssnController,
            errorTrKey: 'err_ssn',
          ),
        ),
        const SizedBox(height: 12),
        _field(
          controller: _birthDateController,
          focusNode: _birthDateFocusNode,
          label: '🎂  ${'field_birth_date'.tr()}',
          keyboardType: TextInputType.number,
          inputFormatters: [DateMaskFormatter()],
          textDirection: ui.TextDirection.ltr,
        ),
        const SizedBox(height: 12),
        DropdownField(
          label: '⚧️  ${'field_sex'.tr()}',
          options: _sexOptions,
          value: _selectedSex,
          onChanged: (v) => setState(() => _selectedSex = v),
        ),
        const SizedBox(height: 12),
        _field(
          controller: _telHomeController,
          label: '📞  ${'field_tel_home'.tr()}',
        ),
        const SizedBox(height: 12),
        _field(
          controller: _telMobileController,
          label: '📱  ${'field_tel_mobile'.tr()}',
        ),
      ],
    );
  }

  // Right column: address + miscellaneous
  Widget _buildAddressColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(
          controller: _addressController,
          label: '🏠  ${'field_address'.tr()}',
        ),
        const SizedBox(height: 12),
        _field(controller: _townController, label: '🏙️  ${'field_town'.tr()}'),
        const SizedBox(height: 12),
        _field(
          controller: _postalCodeController,
          label: '📮  ${'field_postal_code'.tr()}',
        ),
        const SizedBox(height: 12),
        _field(
          controller: _statusController,
          label: '🏷️  ${'field_status'.tr()}',
        ),
        const SizedBox(height: 12),
        _field(controller: _orgController, label: '🏢  ${'field_org'.tr()}'),
        const SizedBox(height: 12),
        _field(
          controller: _occupationController,
          label: '💼  ${'field_occupation'.tr()}',
        ),
        const SizedBox(height: 12),
        _field(
          controller: _hobbiesController,
          label: '🎨  ${'field_hobbies'.tr()}',
        ),
        const SizedBox(height: 12),
        _field(
          controller: _refererController,
          label: '🔗  ${'field_referer'.tr()}',
        ),
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
    FocusNode? focusNode,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    ui.TextDirection? textDirection,
    int? maxLines = 1,
    String? Function(String?)? validator,
    String? Function()? blurCheck,
  }) {
    final field = TextFormField(
      controller: controller,
      focusNode: focusNode,
      textDirection: textDirection,
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
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      validator: validator,
    );
    if (blurCheck == null) return field;
    return OnBlurValidator.simple(simpleCheck: blurCheck, child: field);
  }
}

class SaveIntent extends Intent {}

class BackIntent extends Intent {}
