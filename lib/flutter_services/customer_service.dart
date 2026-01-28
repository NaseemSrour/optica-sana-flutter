import '../db_flutter/models.dart';
import '../db_flutter/repositories/customer_repo.dart';
import '../db_flutter/repositories/glasses_repo.dart';
import '../db_flutter/repositories/contact_lenses_repo.dart';

class CustomerService {
  final CustomerRepo _customerRepo;
  final GlassesRepo _glassesRepo;
  final ContactLensesTestRepo _lensesRepo;

  CustomerService(this._customerRepo, this._glassesRepo, this._lensesRepo);

  // Customer Operations
  Future<Customer> addCustomer(Customer customer) async {
    _validateInputCustomer(customer);
    return await _customerRepo.addCustomer(customer);
  }

  Future<List<Customer>> searchCustomersByFullName(String query) async {
    return await _customerRepo.searchByName(query.trim());
  }

  Future<List<Customer>> searchCustomersByNameOrSSN(String query) async {
    return await _customerRepo.searchByNameOrSsn(query.trim());
  }

  Future<Customer?> getCustomerBySSN(String customerSSN) {
    if (customerSSN.isEmpty) {
      throw Exception("ID must be provided!");
    }
    if (customerSSN.length != 9) {
      throw Exception("Invalid ID provided!");
    }
    if (int.tryParse(customerSSN) == null) {
      throw Exception("ID must contain only numbers!");
    }
    return _customerRepo.getCustomerBySSN(int.parse(customerSSN));
  }

  Future<Customer?> getCustomer(int customerId) {
    if (customerId <= 0) {
      throw Exception("Customer internal ID must be a positive number!");
    }
    return _customerRepo.getCustomer(customerId);
  }

  Future<void> updateCustomer(Customer customer) async {
    if (customer.id == null) {
      throw Exception("Customer does not contain an ID!");
    }
    final existingCustomer = await _customerRepo.getCustomer(customer.id!);
    if (existingCustomer == null) {
      throw Exception("Customer does not exist in DB!");
    }
    _validateInputCustomer(customer);
    await _customerRepo.updateCustomer(customer);
  }

  Future<void> deleteCustomer(int customerId) async {
    await _customerRepo.deleteCustomer(customerId);
  }

  /* 
    -----------------------------------------
            'Glasses Test' Operations
    -----------------------------------------
    */
  Future<GlassesTest> addGlassesTest(GlassesTest test) async {
    await _validateInputGlassesTest(test);
    return await _glassesRepo.addTest(test);
  }

  Future<List<GlassesTest>> getGlassesHistory(int customerId) async {
    await _validateCustomerExists(customerId);
    return await _glassesRepo.listTestsForCustomer(customerId);
  }

  Future<GlassesTest?> getLatestGlasses(int customerId) async {
    await _validateCustomerExists(customerId);
    final history = await _glassesRepo.listTestsForCustomer(customerId);
    return history.isNotEmpty ? history.first : null;
  }

  Future<bool> updateGlassesTest(GlassesTest test) async {
    await _validateInputGlassesTest(test);
    return await _glassesRepo.updateTest(test);
  }

  Future<bool> deleteGlassesTest(int testId) async {
    return await _glassesRepo.deleteTest(testId);
  }

  /*
    -----------------------------------------
      'Contact Lenses Test' Operations
    -----------------------------------------
  */

  // Contact Lenses Test Operations
  Future<int> addContactLensesTest(ContactLensesTest test) async {
    await _validateInputContactLensesTest(test);
    return await _lensesRepo.addTest(test);
  }

  Future<List<ContactLensesTest>> getContactLensesHistory(
    int customerId,
  ) async {
    await _validateCustomerExists(customerId);
    return await _lensesRepo.listTestsForCustomer(customerId);
  }

  Future<ContactLensesTest?> getLatestContactLenses(int customerId) async {
    await _validateCustomerExists(customerId);
    final history = await _lensesRepo.listTestsForCustomer(customerId);
    return history.isNotEmpty ? history.first : null;
  }

  Future<bool> updateContactLensesTest(ContactLensesTest test) async {
    await _validateInputContactLensesTest(test);
    return await _lensesRepo.updateTest(test);
  }

  Future<bool> deleteContactLensesTest(int testId) async {
    return await _lensesRepo.deleteTest(testId);
  }

  // Validation helper functions
  void _validateInputCustomer(Customer customer) {
    if (customer.ssn.toString().length != 9) {
      throw Exception("ID should be 9 digits long!");
    }
    if (customer.fname.trim().isEmpty || customer.lname.trim().isEmpty) {
      throw Exception("First and last name are required!");
    }
    if (customer.telMobile != null &&
        (customer.telMobile!.length != 10 ||
            int.tryParse(customer.telMobile!) == null)) {
      throw Exception("Invalid phone number!");
    }
    // Add other validation checks as needed
  }

  Future<void> _validateInputGlassesTest(GlassesTest test) async {
    await _validateCustomerExists(test.customerId);

    if (test.rCylinder == null || test.rCylinder == 0) {
      if (test.rAxis != null) {
        throw Exception("R_Axis must be null when cylinder is 0.00");
      }
    } else if (test.rAxis == null || test.rAxis! < 0 || test.rAxis! > 180) {
      throw Exception("R_Axis must be an integer between 0 and 180");
    }

    if (test.lCylinder == null || test.lCylinder == 0) {
      if (test.lAxis != null) {
        throw Exception("L_Axis must be null when cylinder is 0.00");
      }
    } else if (test.lAxis == null || test.lAxis! < 0 || test.lAxis! > 180) {
      throw Exception("L_Axis must be an integer between 0 and 180");
    }
  }

  Future<void> _validateInputContactLensesTest(ContactLensesTest test) async {
    await _validateCustomerExists(test.customerId);

    if (test.examDate == null) {
      throw Exception("Exam date is required!");
    }

    if (test.rLensCyl == null || test.rLensCyl == 0) {
      if (test.rLensAxis != null) {
        throw Exception("R_lens_axis must be null when cylinder is null or 0");
      }
    } else if (test.rLensAxis == null ||
        test.rLensAxis! < 0 ||
        test.rLensAxis! > 180) {
      throw Exception("R_lens_Axis must be an integer between 0 and 180");
    }

    if (test.lLensCyl == null || test.lLensCyl == 0) {
      if (test.lLensAxis != null) {
        throw Exception("L_lens_axis must be null when cylinder is null or 0");
      }
    } else if (test.lLensAxis == null ||
        test.lLensAxis! < 0 ||
        test.lLensAxis! > 180) {
      throw Exception("L_lens_Axis must be an integer between 0 and 180");
    }
  }

  Future<void> _validateCustomerExists(int customerId) async {
    final customer = await _customerRepo.getCustomer(customerId);
    if (customer == null) {
      throw Exception("Customer with ID $customerId is not found");
    }
  }
}
