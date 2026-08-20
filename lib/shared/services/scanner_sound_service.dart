import 'dart:io';

import 'package:app/shared/utils/log_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// App-scoped service that plays the short "tick" confirmation sound on a
/// successful QR scan.
///
/// It owns a single [AudioPlayer] that intentionally outlives the scan screen.
/// The scan screen pops roughly 100ms after detection, so a player owned by the
/// soon-disposed controller/screen could be torn down mid-playback and cut the
/// tick off. Keeping one long-lived player in this singleton lets the tick
/// reliably finish.
///
/// The tick is fire-and-forget: [playTick] always guards its body with a
/// try/catch, logs failures via [LogUtils], and never rethrows, so a sound
/// failure can never break detection or navigation. It also plays regardless of
/// the app "Enable sound" setting.
class ScannerSoundService {
  ScannerSoundService();

  /// Asset path for the tick sound. The path is prefixed with `assets/` to
  /// match the convention used in `AppSettingController.onChanged`.
  static const String _tickAsset = 'assets/o7lite/sound/tick_sound.mp3';

  /// The single long-lived audio player owned by this service.
  final AudioPlayer _player = AudioPlayer();

  /// Whether the tick asset has already been loaded onto [_player]. Guards the
  /// one-time [AudioPlayer.setAsset] so repeat scans only `seek` + `play`.
  bool _assetLoaded = false;

  /// The app-scoped singleton instance.
  static ScannerSoundService _instance = ScannerSoundService();

  /// The app-scoped singleton accessor.
  static ScannerSoundService get instance => _instance;

  /// Test seam: allows tests to swap in a fake subclass that overrides
  /// [playTick] to record invocations and optionally simulate a throw.
  @visibleForTesting
  static set instance(ScannerSoundService value) => _instance = value;

  /// Plays the tick sound once.
  ///
  /// Fire-and-forget by design: it always wraps its body in a try/catch that
  /// logs via [LogUtils] and never rethrows, and it always plays regardless of
  /// the app "Enable sound" setting (it does not read that setting).
  ///
  /// On Android the volume is lowered to 0.5. The asset is loaded once (guarded
  /// by [_assetLoaded]); every call then seeks back to the start and plays, so
  /// repeat scans restart the tick cleanly.
  Future<void> playTick() async {
    try {
      if (Platform.isAndroid) {
        await _player.setVolume(0.5);
      }
      if (!_assetLoaded) {
        await _player.setAsset(_tickAsset);
        _assetLoaded = true;
      }
      await _player.seek(Duration.zero);
      await _player.play();
    } catch (e, s) {
      // Swallow and log — a sound failure must never break detection/navigation.
      LogUtils.debugLog('ScannerSoundService.playTick failed: $e\n$s');
    }
  }
}
