import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../db_flutter/bootstrap.dart';
import '../db_flutter/models.dart';
import '../flutter_services/customer_service.dart';
import '../themes/app_theme.dart';
import 'customer_details_screen.dart';

class BirthdaySearchScreen extends StatefulWidget {
  final CustomerService customerService;

  const BirthdaySearchScreen({super.key, required this.customerService});

  @override
  State<BirthdaySearchScreen> createState() => _BirthdaySearchScreenState();
}

class _BirthdaySearchScreenState extends State<BirthdaySearchScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  List<_BirthdayResult> _results = [];
  bool _isLoading = false;
  String? _selectedPreset = 'next30';

  @override
  void initState() {
    super.initState();
    final today = _today();
    _startDate = today;
    _endDate = today.add(const Duration(days: 30));
    _search();
  }

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  // ── Query ────────────────────────────────────────────────────────────────────

  Future<void> _search() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;

      // Use MMDD string for year-independent comparison
      final startMD = DateFormat('MMdd').format(_startDate);
      final endMD = DateFormat('MMdd').format(_endDate);

      final List<Map<String, Object?>> rows;
      if (startMD.compareTo(endMD) <= 0) {
        // Normal range, e.g. 0601 → 0831
        rows = await db.rawQuery(
          "SELECT * FROM customers"
          " WHERE birth_date IS NOT NULL AND birth_date != '' AND length(birth_date) >= 10"
          " AND strftime('%m%d', birth_date) >= ? AND strftime('%m%d', birth_date) <= ?",
          [startMD, endMD],
        );
      } else {
        // Wrapping range, e.g. 1215 → 0115 (spans year boundary)
        rows = await db.rawQuery(
          "SELECT * FROM customers"
          " WHERE birth_date IS NOT NULL AND birth_date != '' AND length(birth_date) >= 10"
          " AND (strftime('%m%d', birth_date) >= ? OR strftime('%m%d', birth_date) <= ?)",
          [startMD, endMD],
        );
      }

      final today = _today();
      final results = <_BirthdayResult>[];
      for (final row in rows) {
        final customer = Customer.fromMap(Map<String, dynamic>.from(row));
        final days = _daysUntilBirthday(customer.birthDate, today);
        if (days != null) results.add(_BirthdayResult(customer: customer, daysUntil: days));
      }
      results.sort((a, b) => a.daysUntil.compareTo(b.daysUntil));

      if (mounted) setState(() { _results = results; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int? _daysUntilBirthday(String? raw, DateTime today) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final birth = DateFormat('yyyy-MM-dd').parse(raw);
      var next = DateTime(today.year, birth.month, birth.day);
      if (next.isBefore(today)) next = DateTime(today.year + 1, birth.month, birth.day);
      return next.difference(today).inDays;
    } catch (_) {
      return null;
    }
  }

  // ── Presets ──────────────────────────────────────────────────────────────────

  void _applyPreset(String preset) {
    final today = _today();
    DateTime start, end;
    switch (preset) {
      case 'today':
        start = end = today;
      case 'next7':
        start = today;
        end = today.add(const Duration(days: 7));
      case 'thisMonth':
        start = DateTime(today.year, today.month, 1);
        // Last day of current month
        end = DateTime(today.year, today.month + 1, 0);
      default: // next30
        start = today;
        end = today.add(const Duration(days: 30));
    }
    setState(() {
      _startDate = start;
      _endDate = end;
      _selectedPreset = preset;
    });
    _search();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: isStart ? 'birthday_from'.tr() : 'birthday_to'.tr(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
      _selectedPreset = null;
    });
    _search();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('birthday_screen_title'.tr())),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Column(
          children: [
            _buildControls(),
            const Divider(height: 1, color: AppColors.borderDefault),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _buildDateButton(_startDate, isStart: true)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: const Icon(Icons.arrow_forward, color: AppColors.label, size: 18),
              ),
              Expanded(child: _buildDateButton(_endDate, isStart: false)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildPresetChip('today', 'birthday_preset_today'.tr()),
              _buildPresetChip('next7', 'birthday_preset_next7'.tr()),
              _buildPresetChip('thisMonth', 'birthday_preset_this_month'.tr()),
              _buildPresetChip('next30', 'birthday_preset_next30'.tr()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(DateTime date, {required bool isStart}) {
    final label = isStart ? 'birthday_from'.tr() : 'birthday_to'.tr();
    final dateStr = DateFormat('d MMM').format(date);
    return OutlinedButton.icon(
      icon: Icon(
        isStart ? Icons.calendar_today_outlined : Icons.event_outlined,
        size: 16,
        color: AppColors.primary,
      ),
      label: Text(
        '$label:  $dateStr',
        style: const TextStyle(color: AppColors.displayValue),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.borderDefault),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        alignment: Alignment.centerLeft,
      ),
      onPressed: () => _pickDate(isStart),
    );
  }

  Widget _buildPresetChip(String preset, String label) {
    final selected = _selectedPreset == preset;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _applyPreset(preset),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.label,
        fontSize: 12,
      ),
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.borderDefault,
      ),
      backgroundColor: AppColors.surfaceVariant,
    );
  }

  Widget _buildResults() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cake_outlined, size: 52, color: AppColors.label),
            const SizedBox(height: 12),
            Text(
              'birthday_no_results'.tr(),
              style: const TextStyle(color: AppColors.label),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Text(
            'birthday_results_count'.tr(namedArgs: {'count': _results.length.toString()}),
            style: const TextStyle(color: AppColors.label, fontSize: 12),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _results.length,
            itemBuilder: (context, index) => _buildResultTile(_results[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildResultTile(_BirthdayResult result) {
    final customer = result.customer;
    final days = result.daysUntil;

    final Color dayColor;
    final String dayLabel;
    if (days == 0) {
      dayColor = AppColors.success;
      dayLabel = 'birthday_today'.tr();
    } else if (days == 1) {
      dayColor = AppColors.accentOrange;
      dayLabel = 'birthday_tomorrow'.tr();
    } else {
      dayColor = AppColors.accentIndigo;
      dayLabel = 'birthday_in_days'.tr(namedArgs: {'days': days.toString()});
    }

    // Subtitle: formatted birthday + turning age
    String subtitle = '';
    String? turnsLabel;
    try {
      final birth = DateFormat('yyyy-MM-dd').parse(customer.birthDate!);
      subtitle = DateFormat('d MMM').format(birth);
      final today = _today();
      var next = DateTime(today.year, birth.month, birth.day);
      if (next.isBefore(today)) next = DateTime(today.year + 1, birth.month, birth.day);
      final turningAge = next.year - birth.year;
      turnsLabel = 'birthday_turns_age'.tr(namedArgs: {'age': turningAge.toString()});
    } catch (_) {}

    if (turnsLabel != null) subtitle = '$subtitle  ·  $turnsLabel';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: days == 0 ? AppColors.success : AppColors.borderDefault,
            width: days == 0 ? 1.5 : 1,
          ),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerDetailsScreen(
                customer: customer,
                customerService: widget.customerService,
              ),
            ),
          ),
          leading: CircleAvatar(
            backgroundColor: dayColor.withValues(alpha: 0.15),
            child: Icon(Icons.cake_outlined, color: dayColor, size: 20),
          ),
          title: Text(
            '${customer.fname} ${customer.lname}',
            style: const TextStyle(
              color: AppColors.displayValue,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: subtitle.isNotEmpty
              ? Text(subtitle, style: const TextStyle(color: AppColors.label, fontSize: 12))
              : null,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: dayColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: dayColor.withValues(alpha: 0.35)),
            ),
            child: Text(
              dayLabel,
              style: TextStyle(
                color: dayColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BirthdayResult {
  final Customer customer;
  final int daysUntil;
  const _BirthdayResult({required this.customer, required this.daysUntil});
}
