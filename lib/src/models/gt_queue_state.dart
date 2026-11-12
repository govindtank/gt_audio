import 'gt_track.dart';

/// Immutable snapshot of the playlist queue.
class GtQueueState {
  const GtQueueState({
    this.queue = const <GtTrack>[],
    this.currentIndex = -1,
  });

  /// Ordered list of tracks in the queue.
  final List<GtTrack> queue;

  /// Index of the currently active track (-1 if empty or unset).
  final int currentIndex;

  /// The currently active track, or null if queue is empty or index is out of bounds.
  GtTrack? get currentTrack {
    if (currentIndex >= 0 && currentIndex < queue.length) {
      return queue[currentIndex];
    }
    return null;
  }

  /// Whether there is a subsequent track available to skip forward to.
  bool get hasNext => currentIndex >= 0 && currentIndex < queue.length - 1;

  /// Whether there is a previous track available to skip back to.
  bool get hasPrevious => currentIndex > 0;

  /// Total number of tracks in the queue.
  int get length => queue.length;

  /// Whether the queue contains any tracks.
  bool get isEmpty => queue.isEmpty;

  /// Whether the queue is non-empty.
  bool get isNotEmpty => queue.isNotEmpty;

  /// Creates a copy of [GtQueueState] with updated properties.
  GtQueueState copyWith({
    List<GtTrack>? queue,
    int? currentIndex,
  }) {
    return GtQueueState(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  @override
  String toString() =>
      'GtQueueState(items: ${queue.length}, currentIndex: $currentIndex, current: ${currentTrack?.title})';
}
