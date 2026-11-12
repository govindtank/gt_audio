/// High-level playback status.
enum GtPlaybackStatus {
  idle,
  loading,
  buffering,
  ready,
  playing,
  paused,
  completed,
  error,
}

/// Loop mode for queue and track repetition.
enum GtLoopMode {
  off,
  one,
  all,
}

/// Immutable snapshot of the current audio playback state.
class GtPlaybackState {
  const GtPlaybackState({
    required this.status,
    this.speed = 1.0,
    this.loopMode = GtLoopMode.off,
    this.isShuffled = false,
    this.volume = 1.0,
    this.errorMessage,
  });

  /// Current status of the player engine.
  final GtPlaybackStatus status;

  /// Current playback speed multiplier (e.g. 1.0, 1.25, 1.5, 2.0).
  final double speed;

  /// Active looping configuration.
  final GtLoopMode loopMode;

  /// Whether queue shuffle is currently active.
  final bool isShuffled;

  /// Volume level between 0.0 and 1.0.
  final double volume;

  /// Error description if [status] is [GtPlaybackStatus.error].
  final String? errorMessage;

  /// Convenience getter for active playback.
  bool get isPlaying => status == GtPlaybackStatus.playing;

  /// Convenience getter for buffering state.
  bool get isBuffering =>
      status == GtPlaybackStatus.buffering ||
      status == GtPlaybackStatus.loading;

  /// Creates a copy of [GtPlaybackState] with replaced values.
  GtPlaybackState copyWith({
    GtPlaybackStatus? status,
    double? speed,
    GtLoopMode? loopMode,
    bool? isShuffled,
    double? volume,
    String? errorMessage,
  }) {
    return GtPlaybackState(
      status: status ?? this.status,
      speed: speed ?? this.speed,
      loopMode: loopMode ?? this.loopMode,
      isShuffled: isShuffled ?? this.isShuffled,
      volume: volume ?? this.volume,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() =>
      'GtPlaybackState(status: $status, playing: $isPlaying, speed: ${speed}x)';
}
