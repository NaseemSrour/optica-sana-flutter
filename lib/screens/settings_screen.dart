import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:optica_sana/flutter_services/app_settings.dart';
import 'package:optica_sana/flutter_services/auth_service.dart';
import 'package:optica_sana/themes/app_theme.dart';
import 'package:optica_sana/widgets/app_notification.dart';

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
              const SizedBox(height: 16),
              // ── Security ──────────────────────────────────────────────────
              _SecurityCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityCard extends StatefulWidget {
  @override
  State<_SecurityCard> createState() => _SecurityCardState();
}

class _SecurityCardState extends State<_SecurityCard> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final hasPassword = AuthService.instance.hasPassword;
    if (hasPassword && !AuthService.instance.verify(_currentController.text)) {
      AppNotification.show(
        context,
        'settings_pwd_current_wrong'.tr(),
        type: NotificationType.error,
      );
      return;
    }
    final newPwd = _newController.text;
    if (newPwd != _confirmController.text) {
      AppNotification.show(
        context,
        'settings_pwd_mismatch'.tr(),
        type: NotificationType.error,
      );
      return;
    }
    if (newPwd.isNotEmpty && newPwd.length < 4) {
      AppNotification.show(
        context,
        'settings_pwd_too_short'.tr(),
        type: NotificationType.error,
      );
      return;
    }
    await AuthService.instance.setPassword(newPwd);
    _currentController.clear();
    _newController.clear();
    _confirmController.clear();
    if (!mounted) return;
    AppNotification.show(
      context,
      newPwd.isEmpty ? 'settings_pwd_cleared'.tr() : 'settings_pwd_saved'.tr(),
      type: NotificationType.success,
    );
    setState(() {});
  }

  Future<void> _clear() async {
    if (!AuthService.instance.hasPassword) return;
    if (!AuthService.instance.verify(_currentController.text)) {
      AppNotification.show(
        context,
        'settings_pwd_current_wrong'.tr(),
        type: NotificationType.error,
      );
      return;
    }
    await AuthService.instance.clearPassword();
    _currentController.clear();
    _newController.clear();
    _confirmController.clear();
    if (!mounted) return;
    AppNotification.show(
      context,
      'settings_pwd_cleared'.tr(),
      type: NotificationType.success,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasPassword = AuthService.instance.hasPassword;
    return Card(
      color: AppColors.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'settings_security_title'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              hasPassword
                  ? 'settings_pwd_change_hint'.tr()
                  : 'settings_pwd_set_hint'.tr(),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.label),
            ),
            const SizedBox(height: 12),
            if (hasPassword) ...[
              _pwdField(
                controller: _currentController,
                label: 'settings_pwd_current'.tr(),
                obscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              const SizedBox(height: 12),
            ],
            _pwdField(
              controller: _newController,
              label: 'settings_pwd_new'.tr(),
              obscure: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
            ),
            const SizedBox(height: 12),
            _pwdField(
              controller: _confirmController,
              label: 'settings_pwd_confirm'.tr(),
              obscure: _obscureConfirm,
              onToggle: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    hasPassword
                        ? 'settings_pwd_change_btn'.tr()
                        : 'settings_pwd_set_btn'.tr(),
                  ),
                ),
                if (hasPassword) ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.lock_open_outlined),
                    label: Text('settings_pwd_remove_btn'.tr()),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pwdField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: AppTextStyles.input(),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
