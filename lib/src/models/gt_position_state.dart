/// Immutable snapshot of playback progress, duration, and buffered status.
class GtPositionState {
  const GtPositionState({
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.bufferedPosition = Duration.zero,
  });

  /// Current playback head position.
  final Duration position;

  /// Total duration of the current audio track.
  final Duration duration;

  /// Forward buffered position downloaded into memory/cache.
  final Duration bufferedPosition;

  /// Normalized playback progress between 0.0 and 1.0.
  double get progress {
    if (duration.inMilliseconds <= 0) return 0.0;
    final val = position.inMilliseconds / duration.inMilliseconds;
    return val.clamp(0.0, 1.0);
  }

  /// Normalized buffered progress between 0.0 and 1.0.
  double get bufferedProgress {
    if (duration.inMilliseconds <= 0) return 0.0;
    final val = bufferedPosition.inMilliseconds / duration.inMilliseconds;
    return val.clamp(0.0, 1.0);
  }

  /// Time remaining in the current track.
  Duration get remaining {
    if (duration <= position) return Duration.zero;
    return duration - position;
  }

  @override
  String toString() =>
      'GtPositionState(${position.inSeconds}s / ${duration.inSeconds}s, buffered: ${bufferedPosition.inSeconds}s)';
}
