import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db_flutter/models.dart';

class LensesTestTables extends StatelessWidget {
  final ContactLensesTest? lensesTest;
  final bool isEditing;
  final Map<String, TextEditingController>? controllers;

  const LensesTestTables({
    super.key,
    this.lensesTest,
    this.isEditing = false,
    this.controllers,
  });

  @override
  Widget build(BuildContext context) {
    if (lensesTest == null) {
      return const Center(
        child: Text("No contact lenses test data available."),
      );
    }

    final examDate = lensesTest!.examDate != null
        ? DateFormat('dd/MM/yyyy').format(lensesTest!.examDate!)
        : 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Last Lenses Test - $examDate',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        _buildKeratometryTable(context),
        const SizedBox(height: 20),
        _buildPrescriptionTable(context),
      ],
    );
  }

  Widget _buildKeratometryTable(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Keratometry", style: Theme.of(context).textTheme.titleMedium),
        Table(
          border: TableBorder.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
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
      ],
    );
  }

  TableRow _buildKeratometryHeaders(BuildContext context) {
    final headers = [
      'rH',
      'rV',
      'Aver',
      'Cylinder',
      'AxH',
      'rT',
      'rN',
      'rI',
      'Rs',
    ];
    return TableRow(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
      children: [
        _headerCell(context, ''),
        ...headers.map((h) => _headerCell(context, h)).toList(),
      ],
    );
  }

  List<String> _getRightKeratometryData() {
    return [
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
  }

  List<String> _getRightKeratometryKeys() {
    return [
      'r_r_h',
      'r_r_v',
      'r_aver',
      'r_k_cyl',
      'r_ax_h',
      'r_r_t',
      'r_r_n',
      'r_r_i',
      'r_r_s',
    ];
  }

  List<String> _getLeftKeratometryData() {
    return [
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
  }

  List<String> _getLeftKeratometryKeys() {
    return [
      'l_r_h',
      'l_r_v',
      'l_aver',
      'l_k_cyl',
      'l_ax_h',
      'l_r_t',
      'l_r_n',
      'l_r_i',
      'l_r_s',
    ];
  }

  TableRow _buildKeratometryRow(
    BuildContext context,
    String eye,
    List<String> data,
    List<String> keys,
  ) {
    return TableRow(
      children: [
        _headerCell(context, eye, isRowHeader: true),
        ...List.generate(data.length, (index) {
          return isEditing
              ? _editableCell(keys[index])
              : _dataCell(data[index]);
        }),
      ],
    );
  }

  Widget _buildPrescriptionTable(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Contact Lens Prescription",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Table(
          border: TableBorder.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
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
      ],
    );
  }

  TableRow _buildPrescriptionHeaders(BuildContext context) {
    final headers = [
      'Type',
      'Brand',
      'Diameter',
      'Base Curve',
      'Sph',
      'Cyl',
      'Axis',
      'Material',
      'Tint',
      'V/A',
    ];
    return TableRow(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
      children: [
        _headerCell(context, ''),
        ...headers.map((h) => _headerCell(context, h)).toList(),
      ],
    );
  }

  List<String> _getRightPrescriptionData() {
    return [
      lensesTest!.rLensType ?? '',
      lensesTest!.rBrand ?? '',
      lensesTest!.rDiameter ?? '',
      '${lensesTest!.rBaseCurveNumerator ?? ''}/${lensesTest!.rBaseCurveDenominator ?? ''}',
      lensesTest!.rLensSph ?? '',
      lensesTest!.rLensCyl ?? '',
      lensesTest!.rLensAxis ?? '',
      lensesTest!.rMaterial ?? '',
      lensesTest!.rTint ?? '',
      '${lensesTest!.rLensVaNumerator ?? ''}/${lensesTest!.rLensVaDenominator ?? ''}',
    ];
  }

  List<String> _getRightPrescriptionKeys() {
    return [
      'r_lens_type',
      'r_brand',
      'r_diameter',
      'r_base_curve',
      'r_lens_sph',
      'r_lens_cyl',
      'r_lens_axis',
      'r_material',
      'r_tint',
      'r_lens_va',
    ];
  }

  List<String> _getLeftPrescriptionData() {
    return [
      lensesTest!.lLensType ?? '',
      lensesTest!.lBrand ?? '',
      lensesTest!.lDiameter ?? '',
      '${lensesTest!.lBaseCurveNumerator ?? ''}/${lensesTest!.lBaseCurveDenominator ?? ''}',
      lensesTest!.lLensSph ?? '',
      lensesTest!.lLensCyl ?? '',
      lensesTest!.lLensAxis ?? '',
      lensesTest!.lMaterial ?? '',
      lensesTest!.lTint ?? '',
      '${lensesTest!.lLensVaNumerator ?? ''}/${lensesTest!.lLensVaDenominator ?? ''}',
    ];
  }

  List<String> _getLeftPrescriptionKeys() {
    return [
      'l_lens_type',
      'l_brand',
      'l_diameter',
      'l_base_curve',
      'l_lens_sph',
      'l_lens_cyl',
      'l_lens_axis',
      'l_material',
      'l_tint',
      'l_lens_va',
    ];
  }

  TableRow _buildPrescriptionRow(
    BuildContext context,
    String eye,
    List<String> data,
    List<String> keys,
  ) {
    return TableRow(
      children: [
        _headerCell(context, eye, isRowHeader: true),
        ...List.generate(data.length, (index) {
          return isEditing
              ? _editableCell(keys[index])
              : _dataCell(data[index]);
        }),
      ],
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
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isRowHeader ? null : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _dataCell(String text) {
    return Center(
      child: Padding(padding: const EdgeInsets.all(8.0), child: Text(text)),
    );
  }

  Widget _editableCell(String fieldKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextFormField(
        controller: controllers![fieldKey],
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
