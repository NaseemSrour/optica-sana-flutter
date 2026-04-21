import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class SoundOption {
  final String asset;
  final String label;
  const SoundOption({required this.asset, required this.label});
}

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  static const _prefKey = 'notification_sound';
  static const _soundsDir = 'assets/sounds/';
  static const _supportedExts = {'.mp3', '.wav', '.ogg', '.m4a', '.aac'};

  /// Discovered at [init] from the bundled asset manifest. Any audio file
  /// placed under `assets/sounds/` (and listed in pubspec.yaml via the
  /// folder include) is picked up automatically.
  static List<SoundOption> available = const [];

  final _player = AudioPlayer();
  final _previewPlayer = AudioPlayer();
  String? _selectedAsset;
  String? _loadedAsset;

  Future<void> init() async {
    available = await _discoverSounds();

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null && available.any((s) => s.asset == saved)) {
      _selectedAsset = saved;
    } else {
      _selectedAsset = available.isNotEmpty ? available.first.asset : null;
    }

    // Configure for low-latency replay: keep the native player alive between
    // plays so subsequent notifications fire instantly.
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setPlayerMode(PlayerMode.lowLatency);
    await _preload(_selectedAsset);
  }

  /// Re-scan the asset manifest. Useful if the list of bundled sounds ever
  /// needs to be refreshed at runtime (e.g. from the Sound Manager screen).
  Future<void> refresh() async {
    available = await _discoverSounds();
    if (_selectedAsset != null &&
        !available.any((s) => s.asset == _selectedAsset)) {
      _selectedAsset = available.isNotEmpty ? available.first.asset : null;
      final prefs = await SharedPreferences.getInstance();
      if (_selectedAsset == null) {
        await prefs.remove(_prefKey);
      } else {
        await prefs.setString(_prefKey, _selectedAsset!);
      }
      await _preload(_selectedAsset);
    }
  }

  Future<List<SoundOption>> _discoverSounds() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final keys =
          manifest
              .listAssets()
              .where((k) => k.startsWith('assets/sounds/'))
              .toList()
            ..sort();
      final seen = <String>{};
      final options = <SoundOption>[];
      for (final key in keys) {
        final lower = key.toLowerCase();
        final ext = _supportedExts.firstWhere(lower.endsWith, orElse: () => '');
        if (ext.isEmpty) continue;
        // audioplayers' AssetSource expects the path *without* the leading
        // "assets/" segment.
        final asset = key.substring('assets/'.length);
        if (!seen.add(asset)) continue;
        options.add(SoundOption(asset: asset, label: _labelFor(asset)));
      }
      return options;
    } catch (_) {
      return const [];
    }
  }

  String _labelFor(String asset) {
    // asset example: "sounds/wshukran.mp3" → "Wshukran".
    final file = asset.split('/').last;
    final dot = file.lastIndexOf('.');
    final base = dot > 0 ? file.substring(0, dot) : file;
    final cleaned = base.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
    if (cleaned.isEmpty) return file;
    return cleaned
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String? get selectedAsset => _selectedAsset;

  Future<void> setSound(String? asset) async {
    _selectedAsset = asset;
    final prefs = await SharedPreferences.getInstance();
    if (asset == null) {
      await prefs.remove(_prefKey);
    } else {
      await prefs.setString(_prefKey, asset);
    }
    await _preload(asset);
  }

  Future<void> playNotification() async {
    final asset = _selectedAsset;
    if (asset == null) return;
    try {
      if (_loadedAsset != asset) {
        await _preload(asset);
      }
      await _player.seek(Duration.zero);
      await _player.resume();
    } catch (_) {
      // Fallback if the preloaded source was lost.
      try {
        await _player.play(AssetSource(asset));
      } catch (_) {}
    }
  }

  Future<void> preview(String asset) async {
    try {
      await _previewPlayer.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> _preload(String? asset) async {
    if (asset == null || asset == _loadedAsset) return;
    try {
      await _player.setSource(AssetSource(asset));
      _loadedAsset = asset;
    } catch (_) {
      _loadedAsset = null;
    }
  }
}
