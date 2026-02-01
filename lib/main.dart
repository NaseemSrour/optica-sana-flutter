import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
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
    // Initialize FFI for sqflite on desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await DatabaseHelper.instance.database; // Initialize the database

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Instantiate repositories
    final customerRepo = CustomerRepo();
    final glassesRepo = GlassesRepo();
    final lensesRepo = ContactLensesTestRepo();

    // Instantiate the service
    final customerService = CustomerService(
      customerRepo,
      glassesRepo,
      lensesRepo,
    );

    return MaterialApp(
      title: 'Optica Sana',
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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _onSearchChanged(); // Initial search
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.customerService
          .searchCustomersByNameOrSSN(_searchController.text)
          .then((customers) {
            setState(() {
              _customers = customers;
            });
          });
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by name or SSN',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _customers.length,
              itemBuilder: (context, index) {
                final customer = _customers[index];
                return ListTile(
                  title: Text("${customer.fname} ${customer.lname}"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomerDetailsScreen(
                          customer: customer,
                          customerService: widget.customerService,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddCustomerScreen(customerService: widget.customerService),
            ),
          ).then((_) {
            // Refresh the customer list after adding a new one
            _onSearchChanged();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
