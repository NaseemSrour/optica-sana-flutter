import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../db_flutter/bootstrap.dart';
import '../themes/app_theme.dart';

class _StatsData {
  final int totalCustomers;
  final int totalGlassesTests;
  final int totalLensesTests;
  final int glassesThisMonth;
  final int lensesThisMonth;
  final int glassesThisYear;
  final int lensesThisYear;
  final int sexM;
  final int sexF;
  final int sexOther;
  final double? avgAge;

  const _StatsData({
    required this.totalCustomers,
    required this.totalGlassesTests,
    required this.totalLensesTests,
    required this.glassesThisMonth,
    required this.lensesThisMonth,
    required this.glassesThisYear,
    required this.lensesThisYear,
    required this.sexM,
    required this.sexF,
    required this.sexOther,
    this.avgAge,
  });
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  _StatsData? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  int _count(List<Map<String, Object?>> rows) =>
      (rows.first.values.first as int?) ?? 0;

  Future<void> _loadStats() async {
    final db = await DatabaseHelper.instance.database;

    final totalCustomers =
        _count(await db.rawQuery('SELECT COUNT(*) FROM customers'));
    final totalGlasses =
        _count(await db.rawQuery('SELECT COUNT(*) FROM glasses_tests'));
    final totalLenses =
        _count(await db.rawQuery('SELECT COUNT(*) FROM contact_lenses_tests'));

    final glassesMonth = _count(await db.rawQuery(
        "SELECT COUNT(*) FROM glasses_tests WHERE strftime('%Y-%m', exam_date) = strftime('%Y-%m', 'now')"));
    final lensesMonth = _count(await db.rawQuery(
        "SELECT COUNT(*) FROM contact_lenses_tests WHERE strftime('%Y-%m', exam_date) = strftime('%Y-%m', 'now')"));

    final glassesYear = _count(await db.rawQuery(
        "SELECT COUNT(*) FROM glasses_tests WHERE strftime('%Y', exam_date) = strftime('%Y', 'now')"));
    final lensesYear = _count(await db.rawQuery(
        "SELECT COUNT(*) FROM contact_lenses_tests WHERE strftime('%Y', exam_date) = strftime('%Y', 'now')"));

    final sexRows = await db.rawQuery(
        'SELECT sex, COUNT(*) as cnt FROM customers GROUP BY sex');
    int sexM = 0, sexF = 0, sexOther = 0;
    for (final row in sexRows) {
      final sex = (row['sex'] as String? ?? '').toUpperCase().trim();
      final cnt = (row['cnt'] as int?) ?? 0;
      if (sex == 'M') {
        sexM = cnt;
      } else if (sex == 'F') {
        sexF = cnt;
      } else {
        sexOther += cnt;
      }
    }

    final ageResult = await db.rawQuery(
        "SELECT AVG((julianday('now') - julianday(birth_date)) / 365.25) as avg_age"
        " FROM customers WHERE birth_date IS NOT NULL AND birth_date != '' AND length(birth_date) >= 10");
    final avgAge = ageResult.isNotEmpty ? ageResult.first['avg_age'] as double? : null;

    if (mounted) {
      setState(() {
        _stats = _StatsData(
          totalCustomers: totalCustomers,
          totalGlassesTests: totalGlasses,
          totalLensesTests: totalLenses,
          glassesThisMonth: glassesMonth,
          lensesThisMonth: lensesMonth,
          glassesThisYear: glassesYear,
          lensesThisYear: lensesYear,
          sexM: sexM,
          sexF: sexF,
          sexOther: sexOther,
          avgAge: avgAge,
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('stats_screen_title'.tr())),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final s = _stats!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader('stats_section_overview'.tr(), AppColors.primary),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'stats_total_customers'.tr(),
                  s.totalCustomers,
                  Icons.people_outline,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'stats_total_glasses'.tr(),
                  s.totalGlassesTests,
                  Icons.visibility_outlined,
                  AppColors.accentIndigo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'stats_total_lenses'.tr(),
                  s.totalLensesTests,
                  Icons.lens_outlined,
                  AppColors.accentTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('stats_section_activity'.tr(), AppColors.accentOrange),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDualStatCard(
                  'stats_this_month'.tr(),
                  'stats_glasses_label'.tr(),
                  s.glassesThisMonth,
                  'stats_lenses_label'.tr(),
                  s.lensesThisMonth,
                  Icons.calendar_month_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDualStatCard(
                  'stats_this_year'.tr(),
                  'stats_glasses_label'.tr(),
                  s.glassesThisYear,
                  'stats_lenses_label'.tr(),
                  s.lensesThisYear,
                  Icons.calendar_today_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('stats_section_demographics'.tr(), AppColors.success),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildGenderCard(s)),
              if (s.avgAge != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'stats_avg_age'.tr(),
                    null,
                    Icons.cake_outlined,
                    AppColors.accentOrange,
                    valueStr: s.avgAge!.toStringAsFixed(1),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: accentColor, width: 3)),
      ),
      padding: const EdgeInsets.only(left: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _buildStatCard(
    String label,
    int? value,
    IconData icon,
    Color color, {
    String? valueStr,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: AppColors.label, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            valueStr ?? value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDualStatCard(
    String title,
    String label1,
    int val1,
    String label2,
    int val2,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.accentOrange, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(color: AppColors.label, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMiniStat(label1, val1, AppColors.accentIndigo)),
              const SizedBox(width: 12),
              Expanded(child: _buildMiniStat(label2, val2, AppColors.accentTeal)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            (val1 + val2).toString(),
            style: const TextStyle(
              color: AppColors.displayValue,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'stats_total_combined'.tr(),
            style: const TextStyle(color: AppColors.label, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.label, fontSize: 11)),
        Text(
          value.toString(),
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildGenderCard(_StatsData s) {
    final total = s.totalCustomers;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wc_outlined, color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              Text(
                'stats_gender_breakdown'.tr(),
                style: const TextStyle(color: AppColors.label, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildGenderRow('stats_sex_m'.tr(), s.sexM, total, AppColors.accentIndigo),
          const SizedBox(height: 8),
          _buildGenderRow('stats_sex_f'.tr(), s.sexF, total, AppColors.accentTeal),
          if (s.sexOther > 0) ...[
            const SizedBox(height: 8),
            _buildGenderRow('stats_sex_other'.tr(), s.sexOther, total, AppColors.label),
          ],
        ],
      ),
    );
  }

  Widget _buildGenderRow(String label, int count, int total, Color color) {
    final pct = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(label, style: const TextStyle(color: AppColors.label, fontSize: 12)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.borderDefault,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
