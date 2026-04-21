import 'package:audioplayers/audioplayers.dart';
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

  // ── Add entries here after placing audio files in assets/sounds/ ────────────
  static const List<SoundOption> available = [
    SoundOption(asset: 'sounds/new.mp3', label: 'Chime'),
    SoundOption(asset: 'sounds/wshukran.mp3', label: 'ThankYou'),
  ];
  // ───────────────────────────────────────────────────────────────────────────

  final _player = AudioPlayer();
  final _previewPlayer = AudioPlayer();
  String? _selectedAsset;
  String? _loadedAsset;

  Future<void> init() async {
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

  Future<void> _preload(String? asset) async {
    if (asset == null || asset == _loadedAsset) return;
    try {
      await _player.setSource(AssetSource(asset));
      _loadedAsset = asset;
    } catch (_) {
      _loadedAsset = null;
    }
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
}
