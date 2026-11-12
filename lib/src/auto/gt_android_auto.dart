import 'package:audio_service/audio_service.dart';
import '../models/gt_track.dart';

/// Delegate for handling Android Auto MediaBrowserService hierarchy and playback requests.
abstract class GtAndroidAutoDelegate {
  /// Root media ID exposed to Android Auto.
  String get rootMediaId => 'root';

  /// Called when Android Auto requests items under [parentMediaId].
  Future<List<MediaItem>> getChildren(
    String parentMediaId, {
    Map<String, dynamic>? options,
  });

  /// Called when Android Auto requests a single media item by ID.
  Future<MediaItem?> getMediaItem(String mediaId);

  /// Called when user selects a playable item in Android Auto.
  Future<void> onPlayFromMediaId(
    String mediaId, {
    Map<String, dynamic>? extras,
  });

  /// Called when user executes a voice search via Google Assistant in the car.
  Future<List<MediaItem>> onSearch(
    String query, {
    Map<String, dynamic>? extras,
  });
}

/// Ready-to-use default Android Auto delegate that exposes the active queue and downloaded tracks.
class GtDefaultAndroidAutoDelegate implements GtAndroidAutoDelegate {
  GtDefaultAndroidAutoDelegate({
    required this.getQueue,
    required this.getDownloads,
    required this.onTrackSelected,
  });

  final List<GtTrack> Function() getQueue;
  final List<GtTrack> Function() getDownloads;
  final Future<void> Function(GtTrack track) onTrackSelected;

  static const String rootId = 'root';
  static const String queueFolderId = 'folder_queue';
  static const String downloadsFolderId = 'folder_downloads';

  @override
  String get rootMediaId => rootId;

  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, {
    Map<String, dynamic>? options,
  }) async {
    if (parentMediaId == rootId) {
      return [
        const MediaItem(
          id: queueFolderId,
          title: 'Current Queue',
          playable: false,
        ),
        const MediaItem(
          id: downloadsFolderId,
          title: 'Downloaded Music',
          playable: false,
        ),
      ];
    }

    if (parentMediaId == queueFolderId) {
      return getQueue().map((t) => t.toMediaItem()).toList();
    }

    if (parentMediaId == downloadsFolderId) {
      return getDownloads().map((t) => t.toMediaItem()).toList();
    }

    return const [];
  }

  @override
  Future<MediaItem?> getMediaItem(String mediaId) async {
    final all = [...getQueue(), ...getDownloads()];
    final match = all.where((t) => t.id == mediaId).firstOrNull;
    return match?.toMediaItem();
  }

  @override
  Future<void> onPlayFromMediaId(
    String mediaId, {
    Map<String, dynamic>? extras,
  }) async {
    final all = [...getQueue(), ...getDownloads()];
    final match = all.where((t) => t.id == mediaId).firstOrNull;
    if (match != null) {
      await onTrackSelected(match);
    }
  }

  @override
  Future<List<MediaItem>> onSearch(
    String query, {
    Map<String, dynamic>? extras,
  }) async {
    final lower = query.toLowerCase();
    final all = [...getQueue(), ...getDownloads()];
    final matches = all
        .where((t) {
          return t.title.toLowerCase().contains(lower) ||
              t.artist.toLowerCase().contains(lower);
        })
        .map((t) => t.toMediaItem())
        .toList();

    if (matches.isNotEmpty) {
      final first = all.where((t) => t.id == matches.first.id).firstOrNull;
      if (first != null) {
        await onTrackSelected(first);
      }
    }

    return matches;
  }
}
