import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service to handle game sound effects.
/// Implemented as a Singleton to be easily accessible throughout the app.
class SoundService {
  static final SoundService _instance = SoundService._internal();

  factory SoundService() => _instance;

  SoundService._internal() {
    _initialize();
  }

  // Individual players for each sound to allow overlapping if needed (e.g., buzzer)
  final AudioPlayer _buzzerPlayer = AudioPlayer();
  final AudioPlayer _correctPlayer = AudioPlayer();
  final AudioPlayer _wrongPlayer = AudioPlayer();
  final AudioPlayer _timeoutPlayer = AudioPlayer();

  bool _isInitialized = false;

  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      // Preload sounds to avoid delay on first play
      // In latest audioplayers, we can set the source ahead of time
      await Future.wait([
        _buzzerPlayer.setSource(AssetSource('sounds/buzzer.wav')),
        _correctPlayer.setSource(AssetSource('sounds/correct.mp3')),
        _wrongPlayer.setSource(AssetSource('sounds/wrong.mp3')),
        _timeoutPlayer.setSource(AssetSource('sounds/timeout.mp3')),
      ]);

      // Set player names/ids for easier debugging if needed
      _buzzerPlayer.setReleaseMode(ReleaseMode.stop);
      _correctPlayer.setReleaseMode(ReleaseMode.stop);
      _wrongPlayer.setReleaseMode(ReleaseMode.stop);
      _timeoutPlayer.setReleaseMode(ReleaseMode.stop);

      _isInitialized = true;
      debugPrint('SoundService: Sounds preloaded successfully.');
    } catch (e) {
      debugPrint('SoundService: Error preloading sounds: $e');
    }
  }

  /// Plays the buzzer sound.
  /// Uses a separate player to allow overlapping if multiple players buzz.
  Future<void> playBuzzer() async {
    await _playSound(_buzzerPlayer, 'sounds/buzzer.wav');
  }

  /// Plays the correct answer sound.
  Future<void> playCorrect() async {
    await _playSound(_correctPlayer, 'sounds/correct.mp3');
  }

  /// Plays the wrong answer sound.
  Future<void> playWrong() async {
    await _playSound(_wrongPlayer, 'sounds/wrong.mp3');
  }

  /// Plays the time's up sound.
  Future<void> playTimeUp() async {
    await _playSound(_timeoutPlayer, 'sounds/timeout.mp3');
  }

  /// Helper to play a sound and catch potential auto-play policy errors.
  Future<void> _playSound(AudioPlayer player, String assetPath) async {
    try {
      // For buzzer especially, we want to be able to play it again even if it's already playing
      // or just finished. stop() then resume() or just play().
      if (player.state == PlayerState.playing) {
        await player.stop();
      }
      
      // Ensure source is set (though preloaded, good to be safe)
      await player.play(AssetSource(assetPath));
    } catch (e) {
      // Catching errors like "NotAllowedError" on Web if user hasn't interacted yet.
      debugPrint('SoundService: Could not play $assetPath. This is common on Web if no user interaction has occurred. Error: $e');
    }
  }

  /// Dispose players when the service is no longer needed (though it's a singleton).
  void dispose() {
    _buzzerPlayer.dispose();
    _correctPlayer.dispose();
    _wrongPlayer.dispose();
    _timeoutPlayer.dispose();
  }
}
