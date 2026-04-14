import 'dart:async';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:optica_sana/screens/add_customer_screen.dart';
import 'package:optica_sana/screens/customer_details_screen.dart';
import 'package:optica_sana/db_flutter/bootstrap.dart';
import 'package:optica_sana/db_flutter/models.dart';
import 'package:optica_sana/db_flutter/repositories/contact_lenses_repo.dart';
import 'package:optica_sana/db_flutter/repositories/customer_repo.dart';
import 'package:optica_sana/db_flutter/repositories/glasses_repo.dart';
import 'package:optica_sana/flutter_services/customer_service.dart';
import 'package:optica_sana/themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await EasyLocalization.ensureInitialized();
  await DatabaseHelper.instance.database;

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('he'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final customerRepo = CustomerRepo();
    final glassesRepo = GlassesRepo();
    final lensesRepo = ContactLensesTestRepo();
    final customerService = CustomerService(
      customerRepo,
      glassesRepo,
      lensesRepo,
    );

    return MaterialApp(
      title: 'app_title'.tr(),
      localizationsDelegates: [
        ...context.localizationDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppTheme.themeData,
      home: CustomerSearchScreen(customerService: customerService),
    );
  }
}

class CustomerSearchScreen extends StatefulWidget {
  final CustomerService customerService;

  const CustomerSearchScreen({Key? key, required this.customerService})
    : super(key: key);

  @override
  State<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen> {
  List<Customer> _customers = [];
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();
  late final FocusNode _searchFocusNode;
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode(onKeyEvent: _handleSearchKey);
    _searchController.addListener(_onSearchChanged);
    _onSearchChanged();
  }

  KeyEventResult _handleSearchKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      if (_customers.isNotEmpty) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1).clamp(0, _customers.length - 1);
        });
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedIndex = (_selectedIndex - 1).clamp(-1, _customers.length - 1);
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter) {
      final target = _selectedIndex >= 0
          ? _selectedIndex
          : (_customers.isNotEmpty ? 0 : -1);
      if (target >= 0) _openCustomer(_customers[target]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.customerService
          .searchCustomersByNameOrSSN(_searchController.text)
          .then((customers) {
            setState(() {
              _customers = customers;
              _selectedIndex = -1;
            });
          });
    });
  }

  void _openCustomer(Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailsScreen(
          customer: customer,
          customerService: widget.customerService,
        ),
      ),
    ).then((_) => _onSearchChanged());
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Optica Sana'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: Tooltip(
            message: 'search_tooltip'.tr(),
            child: const SizedBox.shrink(),
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (context, value, _) {
                  return TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    autofocus: true,
                    style: const TextStyle(color: AppColors.inputValue),
                    decoration: InputDecoration(
                      labelText: 'search_label'.tr(),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.label,
                      ),
                      suffixIcon: value.text.isNotEmpty
                          ? IconButton(
                              tooltip: 'tooltip_clear_search'.tr(),
                              icon: const Icon(
                                Icons.clear,
                                color: AppColors.label,
                              ),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      helperText: 'search_help'.tr(),
                      helperStyle: TextStyle(
                        color: AppColors.label.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: _customers.length,
                itemBuilder: (context, index) {
                  final customer = _customers[index];
                  final isSelected = index == _selectedIndex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: isSelected
                              ? [AppColors.primaryDeep, AppColors.primaryDeep.withValues(alpha: 0.85)]
                              : [AppColors.primaryDeep.withValues(alpha: 0.45), AppColors.surfaceVariant],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: AppColors.primary, width: 1.5)
                            : Border.all(color: AppColors.borderDefault.withValues(alpha: 0.4)),
                      ),
                      child: ListTile(
                        tileColor: Colors.transparent,
                        selectedTileColor: Colors.transparent,
                        selected: isSelected,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        title: Text(
                          '${customer.fname} ${customer.lname}',
                          style: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.displayValue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'ssn_prefix'.tr(
                            namedArgs: {'value': customer.ssn.toString()},
                          ),
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.8)
                                : AppColors.label,
                            fontSize: 13,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: isSelected ? AppColors.primary : AppColors.label,
                        ),
                        onTap: () => _openCustomer(customer),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'fab_add_customer'.tr(),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddCustomerScreen(customerService: widget.customerService),
            ),
          ).then((_) => _onSearchChanged());
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final currentLocale = context.locale;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Optica Sana',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // — Language —
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accentTeal,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'drawer_language'.tr(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.label,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          RadioGroup<Locale>(
            groupValue: currentLocale,
            onChanged: (locale) {
              if (locale != null) {
                context.setLocale(locale);
                Navigator.pop(context);
              }
            },
            child: Column(
              children: [
                RadioListTile<Locale>(
                  dense: true,
                  title: Text('lang_en'.tr()),
                  value: const Locale('en'),
                ),
                RadioListTile<Locale>(
                  dense: true,
                  title: Text('lang_he'.tr()),
                  value: const Locale('he'),
                ),
                RadioListTile<Locale>(
                  dense: true,
                  title: Text('lang_ar'.tr()),
                  value: const Locale('ar'),
                ),
              ],
            ),
          ),

          const Divider(height: 32),

          // — Database —
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accentIndigo,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Database',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.label,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            dense: true,
            enabled: false,
            leading: const Icon(Icons.backup_outlined),
            title: Text('drawer_backup_db'.tr()),
            subtitle: Text('drawer_coming_soon'.tr()),
          ),
          ListTile(
            dense: true,
            enabled: false,
            leading: const Icon(Icons.restore_outlined),
            title: Text('drawer_restore_db'.tr()),
            subtitle: Text('drawer_coming_soon'.tr()),
          ),
        ],
      ),
    );
  }
}
