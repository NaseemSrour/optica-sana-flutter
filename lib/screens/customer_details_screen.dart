import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:optica_sana/themes/app_theme.dart';
import 'package:optica_sana/screens/glasses_history_screen.dart';
import 'package:optica_sana/screens/add_glasses_test_screen.dart';
import 'package:optica_sana/screens/add_lenses_test_screen.dart';
import 'package:optica_sana/screens/lenses_history_screen.dart';
import '../flutter_services/customer_service.dart';
import 'package:optica_sana/db_flutter/models.dart';
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
  GlassesTest? _latestGlassesTest;

  @override
  void initState() {
    super.initState();
    _controllers = {
      'ssn': TextEditingController(text: widget.customer.ssn.toString()),
      'fname': TextEditingController(text: widget.customer.fname),
      'lname': TextEditingController(text: widget.customer.lname),
      'birth_date': TextEditingController(text: widget.customer.birthDate),
      'sex': TextEditingController(text: widget.customer.sex),
      'tel_home': TextEditingController(text: widget.customer.telHome),
      'tel_mobile': TextEditingController(text: widget.customer.telMobile),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'msg_glasses_fetched_error'.tr(namedArgs: {'error': e.toString()}),
            ),
          ),
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
      _formKey.currentState!.save();

      final updatedCustomer = Customer(
        id: widget.customer.id,
        ssn: _controllers['ssn']!.text,
        fname: _controllers['fname']!.text,
        lname: _controllers['lname']!.text,
        birthDate: _controllers['birth_date']!.text,
        sex: _controllers['sex']!.text,
        telHome: _controllers['tel_home']!.text,
        telMobile: _controllers['tel_mobile']!.text,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('msg_customer_saved'.tr())),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'msg_customer_save_error'.tr(namedArgs: {'error': e.toString()}),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    _focusNode.dispose();
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
          title: Text(
            _isEditing
                ? 'title_customer_details_editing'.tr()
                : 'title_customer_details'.tr(),
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
              tooltip: _isEditing ? 'tooltip_save'.tr() : 'tooltip_edit'.tr(),
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              onPressed: _isEditing ? _saveCustomer : _toggleEditMode,
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
      'field_address': 'address',
      'field_town': 'town',
      'field_postal_code': 'postal_code',
      'field_status': 'status',
      'field_org': 'org',
      'field_occupation': 'occupation',
      'field_hobbies': 'hobbies',
      'field_referer': 'referer',
      'field_notes': 'notes',
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
        return TextFormField(
          controller: _controllers[entry.value],
          enabled: _isEditing,
          style: TextStyle(
            color: _isEditing ? AppColors.inputValue : AppColors.displayValue,
            fontWeight: _isEditing ? FontWeight.w600 : FontWeight.normal,
          ),
          decoration: InputDecoration(
            labelText: entry.key.tr(),
            isDense: true,
          ),
          validator: (value) {
            if (['field_ssn', 'field_fname', 'field_lname'].contains(entry.key)) {
              if (value == null || value.isEmpty) {
                return 'err_value'.tr();
              }
            }
            return null;
          },
        );
      },
    );
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
