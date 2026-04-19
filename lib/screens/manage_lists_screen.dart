import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:optica_sana/flutter_services/dropdown_options_service.dart';
import 'package:optica_sana/themes/app_theme.dart';
import '../widgets/app_notification.dart';

class ManageListsScreen extends StatefulWidget {
  const ManageListsScreen({super.key});

  @override
  State<ManageListsScreen> createState() => _ManageListsScreenState();
}

class _ManageListsScreenState extends State<ManageListsScreen> {
  final _service = DropdownOptionsService.instance;

  /// Ordered list of (fieldKey, labelTranslationKey) pairs.
  static const _fields = [
    ('sex', 'field_sex'),
    ('examiner', 'field_examiner'),
    ('r_base', 'field_r_base'),
    ('l_base', 'field_l_base'),
    ('dominant_eye', 'field_dominant_eye'),
    ('glasses_role', 'field_glasses_role'),
    ('lenses_material', 'field_lenses_material'),
    ('segment_diameter', 'field_segment_diam'),
    ('lenses_manufacturer', 'field_lenses_manufacturer'),
    ('lenses_coated', 'field_lenses_coated'),
  ];

  Map<String, List<String>> _options = {};
  final Map<String, TextEditingController> _addControllers = {};

  @override
  void initState() {
    super.initState();
    for (final (key, _) in _fields) {
      _addControllers[key] = TextEditingController();
    }
    _loadAll();
  }

  @override
  void dispose() {
    for (final c in _addControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAll() async {
    final all = await _service.getAllOptions();
    if (mounted) setState(() => _options = all);
  }

  Future<void> _addOption(String fieldKey) async {
    final value = _addControllers[fieldKey]!.text.trim();
    if (value.isEmpty) return;
    try {
      await _service.addOption(fieldKey, value);
      _addControllers[fieldKey]!.clear();
      final updated = await _service.getOptions(fieldKey);
      if (mounted) {
        setState(() => _options[fieldKey] = updated);
        AppNotification.show(
          context,
          'manage_lists_added'.tr(),
          type: NotificationType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(
          context,
          e.toString(),
          type: NotificationType.error,
        );
      }
    }
  }

  Future<void> _deleteOption(String fieldKey, String value) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text('manage_lists_delete_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('btn_cancel'.tr()),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('btn_delete'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _service.deleteOption(fieldKey, value);
    final updated = await _service.getOptions(fieldKey);
    if (mounted) {
      setState(() => _options[fieldKey] = updated);
      AppNotification.show(
        context,
        'manage_lists_deleted'.tr(),
        type: NotificationType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('manage_lists_title'.tr())),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: _fields.map(((String, String) field) {
            final (key, labelKey) = field;
            final opts = _options[key] ?? [];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                title: Text(
                  labelKey.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${opts.length} ${'manage_lists_values_count'.tr()}',
                  style: const TextStyle(
                    color: AppColors.label,
                    fontSize: 12,
                  ),
                ),
                children: [
                  if (opts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'manage_lists_empty'.tr(),
                        style: const TextStyle(color: AppColors.label),
                      ),
                    )
                  else
                    ...opts.map(
                      (opt) => ListTile(
                        dense: true,
                        title: Text(opt),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: AppColors.error,
                          ),
                          onPressed: () => _deleteOption(key, opt),
                        ),
                      ),
                    ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _addControllers[key],
                            decoration: InputDecoration(
                              hintText: 'manage_lists_add_hint'.tr(),
                              isDense: true,
                            ),
                            onSubmitted: (_) => _addOption(key),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () => _addOption(key),
                          child: Text('manage_lists_add_btn'.tr()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
