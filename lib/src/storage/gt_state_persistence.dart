import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/gt_queue_state.dart';
import '../models/gt_track.dart';

/// Container for recovered playback state.
class GtSavedState {
  const GtSavedState({
    required this.tracks,
    required this.currentIndex,
    required this.position,
  });

  /// Recovered queue tracks.
  final List<GtTrack> tracks;

  /// Recovered queue index.
  final int currentIndex;

  /// Recovered playback position.
  final Duration position;
}

/// Automatically saves and restores queue state and position across app launches.
class GtStatePersistence {
  GtStatePersistence._();

  static final GtStatePersistence instance = GtStatePersistence._();

  static const String _keyQueue = 'gt_audio_saved_queue';
  static const String _keyIndex = 'gt_audio_saved_index';
  static const String _keyPosition = 'gt_audio_saved_position_ms';

  /// Saves the current queue and playback position to disk.
  Future<void> saveState({
    required GtQueueState queueState,
    required Duration position,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (queueState.isEmpty) {
      await clearSavedState();
      return;
    }

    final tracksJson = queueState.queue.map((t) => t.toJson()).toList();
    await prefs.setString(_keyQueue, jsonEncode(tracksJson));
    await prefs.setInt(_keyIndex, queueState.currentIndex);
    await prefs.setInt(_keyPosition, position.inMilliseconds);
  }

  /// Restores saved state from disk if available.
  Future<GtSavedState?> restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyQueue);
    if (raw == null || raw.isEmpty) return null;

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final tracks = list
          .map((item) => GtTrack.fromJson(item as Map<String, dynamic>))
          .toList();

      final index = prefs.getInt(_keyIndex) ?? 0;
      final posMs = prefs.getInt(_keyPosition) ?? 0;

      return GtSavedState(
        tracks: tracks,
        currentIndex: index.clamp(0, tracks.length - 1),
        position: Duration(milliseconds: posMs),
      );
    } catch (_) {
      return null;
    }
  }

  /// Clears saved state from disk.
  Future<void> clearSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyQueue);
    await prefs.remove(_keyIndex);
    await prefs.remove(_keyPosition);
  }
}
