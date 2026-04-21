import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../flutter_services/sound_service.dart';
import '../themes/app_theme.dart';

class SoundManagerScreen extends StatefulWidget {
  const SoundManagerScreen({super.key});

  @override
  State<SoundManagerScreen> createState() => _SoundManagerScreenState();
}

class _SoundManagerScreenState extends State<SoundManagerScreen> {
  String? _selected;
  String? _previewing;

  @override
  void initState() {
    super.initState();
    _selected = SoundService.instance.selectedAsset;
  }

  Future<void> _select(String? asset) async {
    await SoundService.instance.setSound(asset);
    if (mounted) setState(() => _selected = asset);
  }

  Future<void> _preview(String asset) async {
    setState(() => _previewing = asset);
    await SoundService.instance.preview(asset);
    if (mounted) setState(() => _previewing = null);
  }

  String get _selectedLabel {
    if (_selected == null) return 'sound_manager_none'.tr();
    return SoundService.available
        .firstWhere(
          (s) => s.asset == _selected,
          orElse: () => const SoundOption(asset: '', label: '?'),
        )
        .label;
  }

  @override
  Widget build(BuildContext context) {
    final sounds = SoundService.available;
    return Scaffold(
      appBar: AppBar(title: Text('sound_manager_title'.tr())),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: sounds.isEmpty
            ? _buildEmpty()
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCurrentCard(),
                  const SizedBox(height: 16),
                  _buildRow(null, 'sound_manager_none'.tr()),
                  ...sounds.map((s) => _buildRow(s.asset, s.label)),
                ],
              ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.music_off_outlined,
              size: 56,
              color: AppColors.label,
            ),
            const SizedBox(height: 16),
            Text(
              'sound_manager_no_sounds'.tr(),
              style: const TextStyle(color: AppColors.label, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'sound_manager_current'.tr(namedArgs: {'name': _selectedLabel}),
                style: const TextStyle(
                  color: AppColors.displayValue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String? asset, String label) {
    final isSelected = _selected == asset;
    final isPreviewing = asset != null && _previewing == asset;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryDeep.withValues(alpha: 0.6)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.borderDefault,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          asset == null ? Icons.volume_off_outlined : Icons.music_note_outlined,
          color: isSelected ? AppColors.primary : AppColors.label,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.displayValue,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (asset != null)
              IconButton(
                tooltip: 'sound_manager_preview'.tr(),
                icon: Icon(
                  isPreviewing
                      ? Icons.stop_circle_outlined
                      : Icons.play_circle_outline,
                  color: AppColors.label,
                ),
                onPressed: isPreviewing ? null : () => _preview(asset),
              ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.check_circle, color: AppColors.primary),
              ),
          ],
        ),
        onTap: () => _select(asset),
      ),
    );
  }
}
