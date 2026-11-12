import 'dart:io' show File;
import 'package:audio_service/audio_service.dart';

/// Represents a playable audio track in `gt_audio`.
class GtTrack {
  const GtTrack({
    required this.id,
    required this.title,
    required this.audioUri,
    this.artist = 'Unknown Artist',
    this.album = 'Unknown Album',
    this.duration,
    this.artUri,
    this.localPath,
    this.extras,
  });

  /// Creates a [GtTrack] from an `audio_service.MediaItem`.
  factory GtTrack.fromMediaItem(MediaItem item) {
    final extras = item.extras;
    final audioUriStr = extras?['audioUri'] as String? ?? item.id;
    final localPath = extras?['localPath'] as String?;

    return GtTrack(
      id: item.id,
      title: item.title,
      artist: item.artist ?? 'Unknown Artist',
      album: item.album ?? 'Unknown Album',
      duration: item.duration,
      artUri: item.artUri,
      audioUri: Uri.parse(audioUriStr),
      localPath: localPath,
      extras: extras,
    );
  }

  /// Deserializes from JSON.
  factory GtTrack.fromJson(Map<String, dynamic> json) {
    return GtTrack(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String? ?? 'Unknown Artist',
      album: json['album'] as String? ?? 'Unknown Album',
      duration: json['durationMs'] != null
          ? Duration(milliseconds: json['durationMs'] as int)
          : null,
      audioUri: Uri.parse(json['audioUri'] as String),
      artUri:
          json['artUri'] != null ? Uri.parse(json['artUri'] as String) : null,
      localPath: json['localPath'] as String?,
      extras: json['extras'] as Map<String, dynamic>?,
    );
  }

  /// Unique identifier for the track.
  final String id;

  /// Display title of the track.
  final String title;

  /// Display artist or creator.
  final String artist;

  /// Album or collection name.
  final String album;

  /// Expected duration of the audio, if known.
  final Duration? duration;

  /// Remote or network streaming URI.
  final Uri audioUri;

  /// Local cached or downloaded filesystem path, if available.
  final String? localPath;

  /// Artwork URI (web URL, local file URI, or content URI).
  final Uri? artUri;

  /// Additional custom metadata.
  final Map<String, dynamic>? extras;

  /// Returns `true` if this track exists locally on disk.
  bool get isDownloaded {
    if (localPath == null || localPath!.isEmpty) return false;
    try {
      return File(localPath!).existsSync();
    } catch (_) {
      return false;
    }
  }

  /// The active URI used for playback.
  /// Automatically prefers local file path if present and verified on disk.
  Uri get effectiveUri {
    if (isDownloaded) {
      return Uri.file(localPath!);
    }
    return audioUri;
  }

  /// Converts this track to an `audio_service.MediaItem` for system controls and Android Auto.
  MediaItem toMediaItem() {
    return MediaItem(
      id: id,
      title: title,
      artist: artist,
      album: album,
      duration: duration,
      artUri: artUri,
      extras: {
        'audioUri': audioUri.toString(),
        if (localPath != null) 'localPath': localPath,
        if (extras != null) ...extras!,
      },
    );
  }

  /// Serializes to JSON for persistent storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'durationMs': duration?.inMilliseconds,
      'audioUri': audioUri.toString(),
      'artUri': artUri?.toString(),
      'localPath': localPath,
      'extras': extras,
    };
  }

  /// Creates a copy of this track with updated values.
  GtTrack copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    Uri? audioUri,
    String? localPath,
    Uri? artUri,
    Map<String, dynamic>? extras,
  }) {
    return GtTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      audioUri: audioUri ?? this.audioUri,
      localPath: localPath ?? this.localPath,
      artUri: artUri ?? this.artUri,
      extras: extras ?? this.extras,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GtTrack && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'GtTrack(id: $id, title: $title, artist: $artist)';
}
