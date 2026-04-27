import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:optica_sana/themes/app_theme.dart';
import 'package:optica_sana/screens/glasses_history_screen.dart';
import 'package:optica_sana/screens/add_glasses_test_screen.dart';
import 'package:optica_sana/screens/add_lenses_test_screen.dart';
import 'package:optica_sana/screens/lenses_history_screen.dart';
import 'package:optica_sana/features/progression/screens/progression_screen.dart';
import 'package:optica_sana/features/prescription_export/screens/prescription_export_screen.dart';
import 'package:optica_sana/features/optical_tools/screens/optical_tools_sheet.dart';
import '../flutter_services/customer_service.dart';
import '../flutter_services/dropdown_options_service.dart';
import 'package:optica_sana/db_flutter/models.dart';
import '../widgets/app_notification.dart';
import '../widgets/date_mask_formatter.dart';
import '../widgets/dropdown_field.dart';
import '../widgets/field_validation.dart';
import '../widgets/glasses_test_table.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final Customer customer;
  final CustomerService customerService;

  const CustomerDetailsScreen({
    super.key,
    required this.customer,
    required this.customerService,
  });

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  final FocusNode _focusNode = FocusNode();
  final FocusNode _birthDateFocusNode = FocusNode();
  GlassesTest? _latestGlassesTest;
  List<String> _sexOptions = [];

  /// On-blur validation rules. Keys match controller keys. Runs both as each
  /// field loses focus and again before saving so it cannot be bypassed.
  late final Map<String, FieldCheck> _blurChecks = {
    'fname': requiredFieldCheck(fieldKey: 'fname', errorTrKey: 'err_value'),
    'lname': requiredFieldCheck(fieldKey: 'lname', errorTrKey: 'err_value'),
  };

  // ── Date helpers ─────────────────────────────────────────────────────────────

  /// YYYY-MM-DD → DD/MM/YYYY (for display / edit)
  static String _toDisplayDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      return DateFormat(
        'dd/MM/yyyy',
      ).format(DateFormat('yyyy-MM-dd').parse(raw));
    } catch (_) {
      return '';
    }
  }

  /// DD/MM/YYYY → YYYY-MM-DD (for DB save)
  static String _toDbDate(String display) {
    if (display.isEmpty) return '';
    final digits = display.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 8) return '';
    try {
      return DateFormat(
        'yyyy-MM-dd',
      ).format(DateFormat('dd/MM/yyyy').parse(display));
    } catch (_) {
      return '';
    }
  }

  void _onBirthDateFocus() {
    if (_birthDateFocusNode.hasFocus) {
      if (_controllers['birth_date']!.text.isEmpty) {
        _controllers['birth_date']!.value = const TextEditingValue(
          text: '__/__/____',
          selection: TextSelection.collapsed(offset: 0),
        );
      }
    } else {
      final digits = _controllers['birth_date']!.text.replaceAll(
        RegExp(r'[^\d]'),
        '',
      );
      if (digits.isEmpty) _controllers['birth_date']!.clear();
    }
  }

  @override
  void initState() {
    super.initState();
    _birthDateFocusNode.addListener(_onBirthDateFocus);
    _controllers = {
      'ssn': TextEditingController(text: widget.customer.ssn.toString()),
      'fname': TextEditingController(text: widget.customer.fname),
      'lname': TextEditingController(text: widget.customer.lname),
      'birth_date': TextEditingController(
        text: _toDisplayDate(widget.customer.birthDate),
      ),
      'sex': TextEditingController(text: widget.customer.sex),
      'tel_home': TextEditingController(text: widget.customer.telHome),
      'tel_mobile': TextEditingController(text: widget.customer.telMobile),
      'tel_mobile_2': TextEditingController(text: widget.customer.telMobile2),
      'address': TextEditingController(text: widget.customer.address),
      'town': TextEditingController(text: widget.customer.town),
      'postal_code': TextEditingController(text: widget.customer.postalCode),
      'status': TextEditingController(text: widget.customer.status),
      'org': TextEditingController(text: widget.customer.org),
      'occupation': TextEditingController(text: widget.customer.occupation),
      'hobbies': TextEditingController(text: widget.customer.hobbies),
      'referer': TextEditingController(text: widget.customer.referer),
      'notes': TextEditingController(text: widget.customer.notes),
    };
    _fetchLatestGlassesTest();
    DropdownOptionsService.instance.getOptions('sex').then((opts) {
      if (mounted) setState(() => _sexOptions = opts);
    });
  }

  Future<void> _fetchLatestGlassesTest() async {
    try {
      final latestTest = await widget.customerService.getLatestGlasses(
        widget.customer.id!,
      );
      if (mounted) {
        setState(() {
          _latestGlassesTest = latestTest;
        });
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(
          context,
          'msg_glasses_fetched_error'.tr(namedArgs: {'error': e.toString()}),
          type: NotificationType.error,
        );
      }
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      final uniqueChecks = _blurChecks.values.toSet().toList();
      final err = runChecks(_controllers, uniqueChecks);
      if (err != null) {
        AppNotification.show(context, err, type: NotificationType.error);
        return;
      }
      _formKey.currentState!.save();

      final updatedCustomer = Customer(
        id: widget.customer.id,
        ssn: _controllers['ssn']!.text,
        fname: _controllers['fname']!.text,
        lname: _controllers['lname']!.text,
        birthDate: _toDbDate(_controllers['birth_date']!.text),
        sex: _controllers['sex']!.text,
        telHome: _controllers['tel_home']!.text,
        telMobile: _controllers['tel_mobile']!.text,
        telMobile2: _controllers['tel_mobile_2']!.text,
        address: _controllers['address']!.text,
        town: _controllers['town']!.text,
        postalCode: _controllers['postal_code']!.text,
        status: _controllers['status']!.text,
        org: _controllers['org']!.text,
        occupation: _controllers['occupation']!.text,
        hobbies: _controllers['hobbies']!.text,
        referer: _controllers['referer']!.text,
        notes: _controllers['notes']!.text,
        glassesNum: widget.customer.glassesNum,
        lensesNum: widget.customer.lensesNum,
        mailing: widget.customer.mailing,
      );

      try {
        await widget.customerService.updateCustomer(updatedCustomer);
        _toggleEditMode();
        if (mounted) {
          AppNotification.show(
            context,
            'msg_customer_saved'.tr(),
            type: NotificationType.success,
          );
        }
      } catch (e) {
        if (mounted) {
          AppNotification.show(
            context,
            'msg_customer_save_error'.tr(namedArgs: {'error': e.toString()}),
            type: NotificationType.error,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    _focusNode.dispose();
    _birthDateFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      autofocus: true,
      focusNode: _focusNode,
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
            SaveIntent(),
        LogicalKeySet(LogicalKeyboardKey.f2): EditIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): BackIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyG):
            ViewGlassesIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyL):
            ViewLensesIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyG,
        ): AddGlassesIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyL,
        ): AddLensesIntent(),
      },
      actions: {
        SaveIntent: CallbackAction<SaveIntent>(
          onInvoke: (intent) => _isEditing ? _saveCustomer() : null,
        ),
        EditIntent: CallbackAction<EditIntent>(
          onInvoke: (intent) => _toggleEditMode(),
        ),
        BackIntent: CallbackAction<BackIntent>(
          onInvoke: (intent) {
            if (_isEditing) {
              _toggleEditMode();
            } else {
              Navigator.pop(context);
            }
            return null;
          },
        ),
        ViewGlassesIntent: CallbackAction<ViewGlassesIntent>(
          onInvoke: (intent) => _navigateTo(
            GlassesHistoryScreen(
              customer: widget.customer,
              customerService: widget.customerService,
            ),
          ),
        ),
        ViewLensesIntent: CallbackAction<ViewLensesIntent>(
          onInvoke: (intent) => _navigateTo(
            LensesHistoryScreen(
              customer: widget.customer,
              customerService: widget.customerService,
            ),
          ),
        ),
        AddGlassesIntent: CallbackAction<AddGlassesIntent>(
          onInvoke: (intent) => _navigateTo(
            AddGlassesTestScreen(
              customer: widget.customer,
              customerService: widget.customerService,
            ),
          ),
        ),
        AddLensesIntent: CallbackAction<AddLensesIntent>(
          onInvoke: (intent) => _navigateTo(
            AddLensesTestScreen(
              customer: widget.customer,
              customerService: widget.customerService,
            ),
          ),
        ),
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isEditing
                    ? 'title_customer_details_editing'.tr()
                    : 'title_customer_details'.tr(),
              ),
              Text(
                () {
                  final age = _customerAge();
                  final name =
                      '${widget.customer.fname} ${widget.customer.lname}';
                  return age != null ? '$name  ·  $age' : name;
                }(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'tooltip_view_glasses'.tr(),
              icon: Image.asset(
                'assets/icons/glasses_history.png',
                width: 48,
                height: 48,
              ),
              onPressed: () => _navigateTo(
                GlassesHistoryScreen(
                  customer: widget.customer,
                  customerService: widget.customerService,
                ),
              ),
            ),
            IconButton(
              tooltip: 'tooltip_view_lenses'.tr(),
              icon: Image.asset(
                'assets/icons/lenses_history.png',
                width: 48,
                height: 48,
              ),
              onPressed: () => _navigateTo(
                LensesHistoryScreen(
                  customer: widget.customer,
                  customerService: widget.customerService,
                ),
              ),
            ),
            const VerticalDivider(),
            IconButton(
              tooltip: 'tooltip_add_glasses_test'.tr(),
              icon: Image.asset(
                'assets/icons/add_glasses.png',
                width: 48,
                height: 48,
              ),
              onPressed: () => _navigateTo(
                AddGlassesTestScreen(
                  customer: widget.customer,
                  customerService: widget.customerService,
                ),
              ),
            ),
            IconButton(
              tooltip: 'tooltip_add_lenses_test'.tr(),
              icon: Image.asset(
                'assets/icons/add_lenses.png',
                width: 48,
                height: 48,
              ),
              onPressed: () => _navigateTo(
                AddLensesTestScreen(
                  customer: widget.customer,
                  customerService: widget.customerService,
                ),
              ),
            ),
            const VerticalDivider(),
            IconButton(
              tooltip: 'prog_tooltip_open'.tr(),
              icon: Image.asset(
                'assets/icons/analysis_icon.png',
                width: 48,
                height: 48,
              ),
              onPressed: () => _navigateTo(
                ProgressionScreen(
                  customer: widget.customer,
                  customerService: widget.customerService,
                ),
              ),
            ),
            IconButton(
              tooltip: 'rx_pdf_tooltip_open'.tr(),
              icon: Image.asset(
                'assets/icons/pdf_icon.png',
                width: 48,
                height: 48,
              ),
              onPressed: () => _navigateTo(
                PrescriptionExportScreen(
                  customer: widget.customer,
                  customerService: widget.customerService,
                ),
              ),
            ),
            IconButton(
              tooltip: 'tooltip_optical_tools'.tr(),
              icon: Image.asset(
                'assets/icons/calculations_icon.png',
                width: 48,
                height: 48,
              ),
              onPressed: () => showOpticalToolsSheet(context),
            ),
            const VerticalDivider(),
            IconButton(
              tooltip: _isEditing ? 'tooltip_save'.tr() : 'tooltip_edit'.tr(),
              icon: Icon(
                _isEditing ? Icons.save : Icons.edit,
                color: _isEditing ? AppColors.inputValue : AppColors.primary,
              ),
              onPressed: _isEditing ? _saveCustomer : _toggleEditMode,
            ),
            PopupMenuButton<String>(
              tooltip: 'tooltip_more_options'.tr(),
              onSelected: (value) {
                if (value == 'delete') {
                  _confirmDeleteCustomer();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text(
                        'menu_delete'.tr(),
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ],
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildOtherDetailsGrid(),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _controllers['notes'],
                    enabled: _isEditing,
                    maxLines: _isEditing ? 5 : null,
                    style: TextStyle(
                      color: _isEditing
                          ? AppColors.inputValue
                          : AppColors.displayValue,
                      fontWeight: _isEditing
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    decoration: InputDecoration(
                      labelText: 'field_notes'.tr(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GlassesTestTable(glassesTest: _latestGlassesTest),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtherDetailsGrid() {
    final fields = {
      'field_ssn': 'ssn',
      'field_fname': 'fname',
      'field_lname': 'lname',
      'field_birth_date': 'birth_date',
      'field_sex': 'sex',
      'field_tel_home': 'tel_home',
      'field_tel_mobile': 'tel_mobile',
      'field_tel_mobile_2': 'tel_mobile_2',
      'field_address': 'address',
      'field_town': 'town',
      'field_postal_code': 'postal_code',
      'field_status': 'status',
      'field_org': 'org',
      'field_occupation': 'occupation',
      'field_hobbies': 'hobbies',
      'field_referer': 'referer',
    };

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        childAspectRatio: 4,
        crossAxisSpacing: 20,
        mainAxisSpacing: 10,
      ),
      itemCount: fields.length,
      itemBuilder: (context, index) {
        final entry = fields.entries.elementAt(index);
        if (entry.value == 'birth_date' && _isEditing) {
          return TextFormField(
            controller: _controllers['birth_date'],
            focusNode: _birthDateFocusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [DateMaskFormatter()],
            textDirection: ui.TextDirection.ltr,
            style: AppTextStyles.input(),
            decoration: InputDecoration(
              labelText: entry.key.tr(),
              isDense: true,
            ),
          );
        }
        if (entry.value == 'sex' && _isEditing) {
          return DropdownField(
            label: entry.key.tr(),
            options: _sexOptions,
            value: _controllers['sex']!.text.isEmpty
                ? null
                : _controllers['sex']!.text,
            onChanged: (v) =>
                setState(() => _controllers['sex']!.text = v ?? ''),
          );
        }
        final field = TextFormField(
          controller: _controllers[entry.value],
          enabled: _isEditing,
          textDirection: entry.value == 'birth_date'
              ? ui.TextDirection.ltr
              : null,
          style: _isEditing ? AppTextStyles.input() : AppTextStyles.display(),
          decoration: InputDecoration(labelText: entry.key.tr(), isDense: true),
          validator: (value) {
            if (['field_fname', 'field_lname'].contains(entry.key)) {
              if (value == null || value.isEmpty) {
                return 'err_value'.tr();
              }
            }
            return null;
          },
        );
        final blurCheck = _isEditing ? _blurChecks[entry.value] : null;
        if (blurCheck == null) return field;
        return OnBlurValidator(
          controllers: _controllers,
          check: blurCheck,
          child: field,
        );
      },
    );
  }

  Future<void> _confirmDeleteCustomer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('confirm_delete_title'.tr()),
        content: Text(
          'confirm_delete_customer_body'.tr(
            namedArgs: {
              'name': '${widget.customer.fname} ${widget.customer.lname}',
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('btn_cancel'.tr()),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('btn_delete'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.customerService.deleteCustomer(widget.customer.id);
      if (mounted) {
        Navigator.pop(context);
        AppNotification.show(
          context,
          'msg_customer_deleted'.tr(),
          type: NotificationType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(
          context,
          'msg_delete_error'.tr(namedArgs: {'error': e.toString()}),
          type: NotificationType.error,
        );
      }
    }
  }

  String? _customerAge() {
    final raw = widget.customer.birthDate;
    if (raw == null || raw.isEmpty) return null;
    try {
      final date = DateFormat('yyyy-MM-dd').parse(raw);
      final now = DateTime.now();
      int age = now.year - date.year;
      if (now.month < date.month ||
          (now.month == date.month && now.day < date.day)) {
        age--;
      }
      return '$age';
    } catch (_) {
      return null;
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
}

class SaveIntent extends Intent {}

class EditIntent extends Intent {}

class BackIntent extends Intent {}

class ViewGlassesIntent extends Intent {}

class ViewLensesIntent extends Intent {}

class AddGlassesIntent extends Intent {}

class AddLensesIntent extends Intent {}
