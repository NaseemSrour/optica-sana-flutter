import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db_flutter/models.dart';

class GlassesTestTable extends StatelessWidget {
  final GlassesTest? glassesTest;
  final bool isEditing;
  final Map<String, TextEditingController>? controllers;

  const GlassesTestTable({
    super.key,
    this.glassesTest,
    this.isEditing = false,
    this.controllers,
  });

  @override
  Widget build(BuildContext context) {
    if (glassesTest == null) {
      return const Center(child: Text("No glasses test data available."));
    }

    final examDate = glassesTest!.examDate != null
        ? DateFormat('dd/MM/yyyy').format(glassesTest!.examDate!)
        : 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last Glasses Test - $examDate',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (isEditing)
                SizedBox(
                  width: 200,
                  child: TextFormField(
                    controller: controllers!['examiner'],
                    decoration: const InputDecoration(
                      labelText: 'Examiner',
                      isDense: true,
                    ),
                  ),
                )
              else
                Text(
                  'Examiner: ${glassesTest!.examiner ?? 'N/A'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
            ],
          ),
        ),
        Table(
          border: TableBorder.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          columnWidths: const {0: IntrinsicColumnWidth()},
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
        const SizedBox(height: 20),
        if (isEditing)
          TextFormField(
            controller: controllers!['notes'],
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          )
        else
          Text(
            'Notes: ${glassesTest!.notes ?? 'N/A'}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
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
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: isSubHeader ? 12 : null,
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
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        ...data
            .take(7)
            .map(
              (d) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(d),
                ),
              ),
            )
            .toList(),
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
        ...List.generate(2, (index) {
          final dataIndex = index + 11;
          return isEditing
              ? _editableCell(keys[dataIndex])
              : _dataCell(data[dataIndex]);
        }),
      ],
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
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}
