import 'dart:async';
import 'package:audio_session/audio_session.dart';

/// Manages platform audio focus, interruptions (calls, Siri), and headphone disconnects.
class GtSessionManager {
  GtSessionManager({
    required this.onPauseRequested,
    required this.onPlayRequested,
  });

  final void Function() onPauseRequested;
  final void Function() onPlayRequested;

  AudioSession? _session;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  StreamSubscription<void>? _becomingNoisySub;

  /// Configures and activates the platform audio session for music playback.
  Future<void> activate() async {
    _session = await AudioSession.instance;

    await _session!.configure(const AudioSessionConfiguration.music());

    // Listen for audio interruptions (e.g. phone calls, alarms)
    _interruptionSub = _session!.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            // Handled automatically or system lowers volume
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            onPauseRequested();
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            break;
          case AudioInterruptionType.pause:
            // Resume if interruption allowed resumption
            onPlayRequested();
            break;
          case AudioInterruptionType.unknown:
            break;
        }
      }
    });

    // Listen for headphone unplug / bluetooth disconnect (becoming noisy)
    _becomingNoisySub = _session!.becomingNoisyEventStream.listen((_) {
      onPauseRequested();
    });
  }

  /// Disposes session listeners.
  void dispose() {
    _interruptionSub?.cancel();
    _becomingNoisySub?.cancel();
  }
}
