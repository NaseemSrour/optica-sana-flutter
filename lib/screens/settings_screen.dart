import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:optica_sana/flutter_services/app_settings.dart';
import 'package:optica_sana/themes/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _fontSize;

  @override
  void initState() {
    super.initState();
    _fontSize = AppSettings.instance.inputFontSize;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('settings_title'.tr())),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Input font size ────────────────────────────────────────────
              Card(
                color: AppColors.surfaceVariant,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'settings_input_font_size'.tr(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'settings_input_font_size_hint'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.label,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _fontSize,
                              min: AppSettings.minInputFontSize,
                              max: AppSettings.maxInputFontSize,
                              divisions:
                                  (AppSettings.maxInputFontSize -
                                          AppSettings.minInputFontSize)
                                      .round(),
                              label: _fontSize.round().toString(),
                              onChanged: (v) => setState(() => _fontSize = v),
                              onChangeEnd: (v) async {
                                await AppSettings.instance.setInputFontSize(v);
                              },
                            ),
                          ),
                          SizedBox(
                            width: 48,
                            child: Text(
                              '${_fontSize.round()}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.displayValue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'settings_reset'.tr(),
                            icon: const Icon(Icons.refresh),
                            onPressed: () async {
                              await AppSettings.instance.resetInputFontSize();
                              setState(() {
                                _fontSize = AppSettings.instance.inputFontSize;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Live preview of how the input text will look.
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.borderDefault),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'settings_preview_label'.tr(),
                              style: const TextStyle(color: AppColors.label),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'settings_preview_sample'.tr(),
                              style: TextStyle(
                                color: AppColors.inputValue,
                                fontWeight: FontWeight.w600,
                                fontSize: _fontSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
