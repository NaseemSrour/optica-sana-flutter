import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../db_flutter/models.dart';
import '../themes/app_theme.dart';
import 'dropdown_field.dart';
import 'field_validation.dart';

class LensesTestTables extends StatelessWidget {
  final ContactLensesTest? lensesTest;
  final bool isEditing;
  final Map<String, TextEditingController>? controllers;
  final Map<String, List<String>> dropdownOptions;
  final Map<String, FieldAction> blurActions;
  final Map<String, List<TextInputFormatter>> inputFormatters;

  const LensesTestTables({
    super.key,
    this.lensesTest,
    this.isEditing = false,
    this.controllers,
    this.dropdownOptions = const {},
    this.blurActions = const {},
    this.inputFormatters = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (lensesTest == null) {
      return Center(child: Text('msg_no_lenses_data'.tr()));
    }

    final examDate = DateFormat('dd/MM/yyyy').format(lensesTest!.examDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header: title + examiner ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppColors.primary, width: 3),
                  ),
                ),
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  '${'label_last_lenses'.tr()} - $examDate',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (isEditing)
                SizedBox(
                  width: 220,
                  child: DropdownField(
                    label: 'field_examiner'.tr(),
                    controller: controllers!['examiner'],
                    options: dropdownOptions['examiner'] ?? [],
                  ),
                )
              else
                Text(
                  'label_examiner_display'.tr(
                    namedArgs: {
                      'value': lensesTest!.examiner ?? 'label_na'.tr(),
                    },
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
            ],
          ),
        ),

        // ── Keratometry ───────────────────────────────────────────────────
        _buildKeratometryTable(context),
        const SizedBox(height: 20),

        // ── Prescription ─────────────────────────────────────────────────
        _buildPrescriptionTable(context),
        const SizedBox(height: 16),

        // ── Solution ──────────────────────────────────────────────────────
        TextFormField(
          controller: controllers?['solution'],
          enabled: isEditing,
          style: TextStyle(
            color: isEditing ? AppColors.inputValue : AppColors.displayValue,
            fontWeight: isEditing ? FontWeight.w600 : FontWeight.normal,
          ),
          decoration: InputDecoration(
            labelText: 'field_solution'.tr(),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),

        // ── Notes ─────────────────────────────────────────────────────────
        TextFormField(
          controller: controllers?['notes'],
          enabled: isEditing,
          maxLines: isEditing ? 3 : null,
          style: TextStyle(
            color: isEditing ? AppColors.inputValue : AppColors.displayValue,
            fontWeight: isEditing ? FontWeight.w600 : FontWeight.normal,
          ),
          decoration: InputDecoration(
            labelText: 'field_notes'.tr(),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildKeratometryTable(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: AppColors.success, width: 3),
            ),
          ),
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            'section_keratometry'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Directionality(
          textDirection: ui.TextDirection.ltr,
          child: Table(
            border: TableBorder.all(color: AppColors.tableBorder),
            columnWidths: const {0: IntrinsicColumnWidth()},
            children: [
              _buildKeratometryHeaders(context),
              _buildKeratometryRow(
                context,
                'R',
                _getRightKeratometryData(),
                _getRightKeratometryKeys(),
              ),
              _buildKeratometryRow(
                context,
                'L',
                _getLeftKeratometryData(),
                _getLeftKeratometryKeys(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  TableRow _buildKeratometryHeaders(BuildContext context) {
    final headers = ['rH', 'rV', 'Aver', 'Cyl.', 'AxH', 'rT', 'rN', 'rI', 'rS'];
    return TableRow(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
      children: [
        _headerCell(context, ''),
        ...headers.map((h) => _headerCell(context, h)),
      ],
    );
  }

  List<String> _getRightKeratometryData() => [
    lensesTest!.rRH ?? '',
    lensesTest!.rRV ?? '',
    lensesTest!.rAver ?? '',
    lensesTest!.rKCyl ?? '',
    lensesTest!.rAxH ?? '',
    lensesTest!.rRT ?? '',
    lensesTest!.rRN ?? '',
    lensesTest!.rRI ?? '',
    lensesTest!.rRS ?? '',
  ];

  // Keys must match ContactLensesTest.toMap() exactly
  List<String> _getRightKeratometryKeys() => [
    'r_rH',
    'r_rV',
    'r_aver',
    'r_k_cyl',
    'r_axH',
    'r_rT',
    'r_rN',
    'r_rI',
    'r_rS',
  ];

  List<String> _getLeftKeratometryData() => [
    lensesTest!.lRH ?? '',
    lensesTest!.lRV ?? '',
    lensesTest!.lAver ?? '',
    lensesTest!.lKCyl ?? '',
    lensesTest!.lAxH ?? '',
    lensesTest!.lRT ?? '',
    lensesTest!.lRN ?? '',
    lensesTest!.lRI ?? '',
    lensesTest!.lRS ?? '',
  ];

  List<String> _getLeftKeratometryKeys() => [
    'l_rH',
    'l_rV',
    'l_aver',
    'l_k_cyl',
    'l_axH',
    'l_rT',
    'l_rN',
    'l_rI',
    'l_rS',
  ];

  TableRow _buildKeratometryRow(
    BuildContext context,
    String eye,
    List<String> data,
    List<String> keys,
  ) {
    return TableRow(
      children: [
        _headerCell(context, eye, isRowHeader: true),
        ...List.generate(
          data.length,
          (i) => isEditing ? _editableCell(keys[i]) : _dataCell(data[i]),
        ),
      ],
    );
  }

  Widget _buildPrescriptionTable(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: AppColors.accentOrange, width: 3),
            ),
          ),
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            'section_lens_prescription'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Directionality(
          textDirection: ui.TextDirection.ltr,
          child: Table(
            border: TableBorder.all(color: AppColors.tableBorder),
            columnWidths: const {0: IntrinsicColumnWidth()},
            children: [
              _buildPrescriptionHeaders(context),
              _buildPrescriptionRow(
                context,
                'R',
                _getRightPrescriptionData(),
                _getRightPrescriptionKeys(),
              ),
              _buildPrescriptionRow(
                context,
                'L',
                _getLeftPrescriptionData(),
                _getLeftPrescriptionKeys(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  TableRow _buildPrescriptionHeaders(BuildContext context) {
    final headers = [
      'Type',
      'Manuf.',
      'Brand',
      'Diam',
      'B.C.',
      'Sph',
      'Cyl',
      'Ax.',
      'Mat.',
      'Tint',
      'VA',
    ];
    return TableRow(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
      children: [
        _headerCell(context, ''),
        ...headers.map((h) => _headerCell(context, h)),
      ],
    );
  }

  List<String> _getRightPrescriptionData() => [
    lensesTest!.rLensType ?? '',
    lensesTest!.rManufacturer ?? '',
    lensesTest!.rBrand ?? '',
    lensesTest!.rDiameter ?? '',
    '${lensesTest!.rBaseCurveNumerator ?? ''}/${lensesTest!.rBaseCurveDenominator ?? ''}',
    lensesTest!.rLensSph ?? '',
    lensesTest!.rLensCyl ?? '',
    lensesTest!.rLensAxis ?? '',
    lensesTest!.rMaterial ?? '',
    lensesTest!.rTint ?? '',
    lensesTest!.rVa ?? '',
  ];

  List<String> _getRightPrescriptionKeys() => [
    'r_lens_type',
    'r_manufacturer',
    'r_brand',
    'r_diameter',
    'r_base_curve',
    'r_lens_sph',
    'r_lens_cyl',
    'r_lens_axis',
    'r_material',
    'r_tint',
    'r_va',
  ];

  List<String> _getLeftPrescriptionData() => [
    lensesTest!.lLensType ?? '',
    lensesTest!.lManufacturer ?? '',
    lensesTest!.lBrand ?? '',
    lensesTest!.lDiameter ?? '',
    '${lensesTest!.lBaseCurveNumerator ?? ''}/${lensesTest!.lBaseCurveDenominator ?? ''}',
    lensesTest!.lLensSph ?? '',
    lensesTest!.lLensCyl ?? '',
    lensesTest!.lLensAxis ?? '',
    lensesTest!.lMaterial ?? '',
    lensesTest!.lTint ?? '',
    lensesTest!.lVa ?? '',
  ];

  List<String> _getLeftPrescriptionKeys() => [
    'l_lens_type',
    'l_manufacturer',
    'l_brand',
    'l_diameter',
    'l_base_curve',
    'l_lens_sph',
    'l_lens_cyl',
    'l_lens_axis',
    'l_material',
    'l_tint',
    'l_va',
  ];

  TableRow _buildPrescriptionRow(
    BuildContext context,
    String eye,
    List<String> data,
    List<String> keys,
  ) {
    final vaIndex = data.length - 1; // VA is always the last column
    return TableRow(
      children: [
        _headerCell(context, eye, isRowHeader: true),
        ...List.generate(data.length, (i) {
          if (i == vaIndex) return _buildVaCell(eye, data[i], keys[i]);
          return isEditing ? _editableCell(keys[i]) : _dataCell(data[i]);
        }),
      ],
    );
  }

  // R row: r_va left-aligned with 6/ prefix.
  // L row: both_va top-right, l_va bottom-left (staggered, DOS-style).
  // Tab order: l_va first, then both_va.
  Widget _buildVaCell(String eye, String vaData, String vaKey) {
    if (eye == 'R') {
      return _vaHalfCell(vaKey, vaData);
    }
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Spacer(),
              Expanded(
                child: FocusTraversalOrder(
                  order: const NumericFocusOrder(2),
                  child: _vaHalfCell('both_va', lensesTest?.bothVa ?? ''),
                ),
              ),
            ],
          ),
          Container(height: 1, color: AppColors.tableBorder),
          Row(
            children: [
              Expanded(
                child: FocusTraversalOrder(
                  order: const NumericFocusOrder(1),
                  child: _vaHalfCell(vaKey, vaData),
                ),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vaHalfCell(String key, String displayText) {
    if (isEditing) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          children: [
            const Text(
              '6/',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: controllers![key],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.inputValue,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  filled: false,
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '6/',
            style: AppTextStyles.display(
              weight: FontWeight.w600,
            ).copyWith(color: Colors.white70),
          ),
          Text(displayText, style: AppTextStyles.display()),
        ],
      ),
    );
  }

  Widget _headerCell(
    BuildContext context,
    String text, {
    bool isRowHeader = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: isRowHeader ? AppColors.label : AppColors.displayValue,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _dataCell(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(text, style: AppTextStyles.display()),
      ),
    );
  }

  Widget _editableCell(String fieldKey) {
    final opts = dropdownOptions[fieldKey];
    final action = blurActions[fieldKey];
    final Widget field;
    if (opts != null && opts.isNotEmpty) {
      // Combo dropdown: free-text allowed, list populates the suggestions.
      field = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: DropdownField(
          compact: true,
          options: opts,
          controller: controllers![fieldKey],
          inputFormatters: inputFormatters[fieldKey],
        ),
      );
    } else {
      field = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: TextFormField(
          controller: controllers![fieldKey],
          textAlign: TextAlign.center,
          inputFormatters: inputFormatters[fieldKey],
          style: const TextStyle(
            color: AppColors.inputValue,
            fontWeight: FontWeight.w600,
          ),
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            filled: false,
          ),
        ),
      );
    }
    if (action == null || controllers == null) return field;
    return OnBlurAction(
      controllers: controllers!,
      action: action,
      child: field,
    );
  }
}
