import 'package:audioplayers/audioplayers.dart';

class AudioAlertService {
  static final AudioAlertService _instance = AudioAlertService._internal();
  factory AudioAlertService() => _instance;
  AudioAlertService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool soundEnabled = true;

  Future<void> playTimerCompleteSound() async {
    if (!soundEnabled) return;
    try {
      await _player.play(AssetSource('sounds/bell.mp3'));
    } catch (_) {
      // Graceful fallback if asset is missing or platform sound is used
    }
  }

  Future<void> playStartSessionSound() async {
    if (!soundEnabled) return;
    try {
      await _player.play(AssetSource('sounds/start.mp3'));
    } catch (_) {}
  }

  Future<void> playBreakSound() async {
    if (!soundEnabled) return;
    try {
      await _player.play(AssetSource('sounds/chime.mp3'));
    } catch (_) {}
  }
}
