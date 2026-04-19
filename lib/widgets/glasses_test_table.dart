import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../db_flutter/models.dart';
import '../themes/app_theme.dart';
import 'dropdown_field.dart';

class GlassesTestTable extends StatelessWidget {
  final GlassesTest? glassesTest;
  final bool isEditing;
  final Map<String, TextEditingController>? controllers;
  final Map<String, List<String>> dropdownOptions;

  const GlassesTestTable({
    super.key,
    this.glassesTest,
    this.isEditing = false,
    this.controllers,
    this.dropdownOptions = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (glassesTest == null) {
      return Center(child: Text('msg_no_glasses_data'.tr()));
    }

    final examDate = glassesTest!.examDate != null
        ? DateFormat('dd/MM/yyyy').format(glassesTest!.examDate!)
        : 'label_na'.tr();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  '${'label_last_glasses'.tr()} - $examDate',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (isEditing)
                SizedBox(
                  width: 200,
                  child: TextFormField(
                    controller: controllers!['examiner'],
                    decoration: InputDecoration(
                      labelText: 'field_examiner'.tr(),
                      isDense: true,
                    ),
                  ),
                )
              else
                Text(
                  'label_examiner_display'.tr(namedArgs: {'value': glassesTest!.examiner ?? 'label_na'.tr()}),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
            ],
          ),
        ),
        Directionality(
          textDirection: ui.TextDirection.ltr,
          child: Table(
            border: TableBorder.all(color: AppColors.tableBorder),
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              // Addition column (index 8) contains 4 sub-columns; give it 4× the
              // flex weight so each sub-column is as wide as any other column.
              8: FlexColumnWidth(4),
            },
            children: [
              _buildHeaders(context),
              _buildEyeDataRow(
                context,
                'R',
                _getRightEyeData(),
                _getRightEyeKeys(),
              ),
              _buildEyeDataRow(
                context,
                'L',
                _getLeftEyeData(),
                _getLeftEyeKeys(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // The notes field is now displayed in the main screen
        // if (isEditing)
        //   TextFormField(
        //     controller: controllers!['notes'],
        //     decoration: const InputDecoration(
        //       labelText: 'Notes',
        //       border: OutlineInputBorder(),
        //     ),
        //     maxLines: 3,
        //   )
        // else
        //   Text(
        //     'Notes: ${glassesTest!.notes ?? 'N/A'}',
        //     style: Theme.of(context).textTheme.bodyLarge,
        //   ),
      ],
    );
  }

  TableRow _buildHeaders(BuildContext context) {
    final headers = [
      '',
      'FV',
      'Sphere',
      'Cylinder',
      'Axis',
      'Prism',
      'Base',
      'VA',
      'Read',
      'Int.',
      'Bif.',
      'Mul.',
      'High',
      'PD',
    ];
    return TableRow(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
      children: [
        ...headers.take(8).map((h) => _headerCell(context, h)),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Column(
            children: [
              _headerCell(context, 'Addition', isSubHeader: false),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: headers
                    .sublist(8, 12)
                    .map(
                      (h) => Expanded(
                        child: _headerCell(context, h, isSubHeader: true),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        ...headers.sublist(12).map((h) => _headerCell(context, h)),
      ],
    );
  }

  Widget _headerCell(
    BuildContext context,
    String text, {
    bool isSubHeader = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.displayValue,
            fontWeight: FontWeight.bold,
            fontSize: isSubHeader ? 12 : 14,
          ),
        ),
      ),
    );
  }

  List<String> _getRightEyeData() {
    if (glassesTest == null) return List.filled(13, '');
    return [
      glassesTest!.rFv ?? '',
      glassesTest!.rSphere ?? '',
      glassesTest!.rCylinder ?? '',
      glassesTest!.rAxis ?? '',
      glassesTest!.rPrism ?? '',
      glassesTest!.rBase ?? '',
      glassesTest!.rVa ?? '',
      glassesTest!.rAddRead ?? '',
      glassesTest!.rAddInt ?? '',
      glassesTest!.rAddBif ?? '',
      glassesTest!.rAddMul ?? '',
      glassesTest!.rHigh ?? '',
      glassesTest!.rPd ?? '',
    ];
  }

  List<String> _getRightEyeKeys() {
    return [
      'r_fv',
      'r_sphere',
      'r_cylinder',
      'r_axis',
      'r_prism',
      'r_base',
      'r_va',
      'r_add_read',
      'r_add_int',
      'r_add_bif',
      'r_add_mul',
      'r_high',
      'r_pd',
    ];
  }

  List<String> _getLeftEyeData() {
    if (glassesTest == null) return List.filled(13, '');
    return [
      glassesTest!.lFv ?? '',
      glassesTest!.lSphere ?? '',
      glassesTest!.lCylinder ?? '',
      glassesTest!.lAxis ?? '',
      glassesTest!.lPrism ?? '',
      glassesTest!.lBase ?? '',
      glassesTest!.lVa ?? '',
      glassesTest!.lAddRead ?? '',
      glassesTest!.lAddInt ?? '',
      glassesTest!.lAddBif ?? '',
      glassesTest!.lAddMul ?? '',
      glassesTest!.lHigh ?? '',
      glassesTest!.lPd ?? '',
    ];
  }

  List<String> _getLeftEyeKeys() {
    return [
      'l_fv',
      'l_sphere',
      'l_cylinder',
      'l_axis',
      'l_prism',
      'l_base',
      'l_va',
      'l_add_read',
      'l_add_int',
      'l_add_bif',
      'l_add_mul',
      'l_high',
      'l_pd',
    ];
  }

  TableRow _buildEyeDataRow(
    BuildContext context,
    String eye,
    List<String> data,
    List<String> keys,
  ) {
    return TableRow(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              eye,
              style: const TextStyle(
                color: AppColors.label,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        // FV, Sphere, Cylinder, Axis, Prism, Base (indices 0–5)
        ...List.generate(6, (index) {
          return isEditing
              ? _editableCell(keys[index])
              : _dataCell(data[index]);
        }),
        // VA column (index 6): r_va + both_va stacked for R; l_va only for L
        _buildVaCell(eye, data[6], keys[6]),
        // Addition sub-columns (indices 7–10)
        TableCell(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              final dataIndex = index + 7;
              return Expanded(
                child: isEditing
                    ? _editableCell(keys[dataIndex])
                    : _dataCell(data[dataIndex]),
              );
            }),
          ),
        ),
        // High column (index 11)
        isEditing ? _editableCell(keys[11]) : _dataCell(data[11]),
        // PD column: sum_pd / near_pd for R; empty for L
        _buildPdCell(eye),
      ],
    );
  }

  Widget _buildVaCell(String eye, String vaData, String vaKey) {
    if (eye != 'R') {
      return isEditing ? _editableCell(vaKey) : _dataCell(vaData);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        isEditing ? _editableCell(vaKey) : _dataCell(vaData),
        Container(height: 1, color: AppColors.tableBorder),
        isEditing
            ? _editableCell('both_va')
            : _dataCell(glassesTest?.bothVa ?? ''),
      ],
    );
  }

  Widget _buildPdCell(String eye) {
    if (eye != 'R') return _dataCell('');
    if (isEditing) {
      return Row(
        children: [
          Expanded(child: _editableCell('sum_pd')),
          const Text(
            '/',
            style: TextStyle(color: AppColors.label, fontSize: 12),
          ),
          Expanded(child: _editableCell('near_pd')),
        ],
      );
    }
    final sumPd = glassesTest?.sumPd ?? '';
    final nearPd = glassesTest?.nearPd ?? '';
    return _dataCell(
      (sumPd.isNotEmpty || nearPd.isNotEmpty) ? '$sumPd / $nearPd' : '',
    );
  }

  Widget _dataCell(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          text,
          style: const TextStyle(color: AppColors.displayValue),
        ),
      ),
    );
  }

  Widget _editableCell(String fieldKey) {
    final opts = dropdownOptions[fieldKey];
    if (opts != null) {
      final ctrl = controllers![fieldKey];
      return DropdownField(
        compact: true,
        options: opts,
        value: (ctrl?.text.isEmpty ?? true) ? null : ctrl!.text,
        onChanged: (v) => ctrl?.text = v ?? '',
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextFormField(
        controller: controllers![fieldKey],
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
    );
  }
}
