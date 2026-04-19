import '../db_flutter/repositories/dropdown_options_repo.dart';

class DropdownOptionsService {
  static final DropdownOptionsService instance =
      DropdownOptionsService._privateConstructor();
  DropdownOptionsService._privateConstructor();

  final DropdownOptionsRepo _repo = DropdownOptionsRepo();
  final Map<String, List<String>> _cache = {};

  Future<List<String>> getOptions(String fieldKey) async {
    if (_cache.containsKey(fieldKey)) return _cache[fieldKey]!;
    final options = await _repo.getOptions(fieldKey);
    _cache[fieldKey] = options;
    return options;
  }

  Future<void> addOption(String fieldKey, String value) async {
    await _repo.addOption(fieldKey, value.trim());
    _cache.remove(fieldKey);
  }

  Future<void> deleteOption(String fieldKey, String value) async {
    await _repo.deleteOption(fieldKey, value);
    _cache.remove(fieldKey);
  }

  Future<Map<String, List<String>>> getAllOptions() async {
    final all = await _repo.getAllOptions();
    _cache.addAll(all);
    return all;
  }

  void invalidateCache([String? fieldKey]) {
    if (fieldKey != null) {
      _cache.remove(fieldKey);
    } else {
      _cache.clear();
    }
  }
}
