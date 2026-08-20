// Audio Manager - Handles audio/sound diagnostics
import 'package:volume_controller/volume_controller.dart';
import 'package:just_audio/just_audio.dart';
import '../models/diagnostic_models.dart';
import 'package:app/shared/utils/log_utils.dart';

class AudioManager {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final VolumeController _volumeController = VolumeController();

  AudioManager() {
    // Don't show system UI when changing volume programmatically
    _volumeController.showSystemUI = false;
  }

  /// Get current volume level (0-100)
  Future<int> getVolumeLevel() async {
    try {
      final volume = await _volumeController.getVolume();
      return (volume * 100).round();
    } catch (e) {
      LogUtils.debugLog('Error getting volume level: $e');
      return 0;
    }
  }

  /// Check if device is muted
  Future<bool> isMuted() async {
    try {
      final volume = await _volumeController.getVolume();
      return volume <= 0.01; // Consider muted if volume is essentially 0
    } catch (e) {
      LogUtils.debugLog('Error checking mute status: $e');
      return false;
    }
  }

  /// Play a test sound
  Future<bool> playTestSound() async {
    try {
      await _audioPlayer.setAsset('assets/o7lite/sound/tick_sound.mp3');
      await _audioPlayer.play();
      return true;
    } catch (e) {
      LogUtils.debugLog('Error playing test sound: $e');
      // Try alternative approach
      try {
        // If asset fails, try a URL-based sound
        await _audioPlayer.setUrl(
          'https://www.soundjay.com/buttons/beep-01a.mp3',
        );
        await _audioPlayer.play();
        return true;
      } catch (e2) {
        LogUtils.debugLog('Error playing alternative sound: $e2');
        return false;
      }
    }
  }

  /// Get complete audio info
  Future<AudioInfo> getAudioInfo() async {
    try {
      final volume = await getVolumeLevel();
      final muted = await isMuted();

      DiagnosticStatus status;
      if (muted) {
        status = DiagnosticStatus.warning;
      } else if (volume < 20) {
        status = DiagnosticStatus.warning;
      } else {
        status = DiagnosticStatus.good;
      }

      return AudioInfo(
        volumeLevel: volume,
        isMuted: muted,
        status: status,
      );
    } catch (e) {
      LogUtils.debugLog('Error getting audio info: $e');
      return AudioInfo(
        volumeLevel: 0,
        isMuted: false,
        status: DiagnosticStatus.error,
      );
    }
  }

  /// Dispose resources
  void dispose() {
    _audioPlayer.dispose();
  }
}
