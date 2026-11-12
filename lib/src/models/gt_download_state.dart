import 'gt_track.dart';

/// Status of an offline audio download task.
enum GtDownloadStatus {
  idle,
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

/// Represents an offline download task and its live progress.
class GtDownloadTask {
  const GtDownloadTask({
    required this.trackId,
    required this.track,
    this.status = GtDownloadStatus.idle,
    this.progress = 0.0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.localPath,
    this.errorMessage,
  });

  /// Identifier of the target track.
  final String trackId;

  /// Full metadata of the target track.
  final GtTrack track;

  /// Current lifecycle status.
  final GtDownloadStatus status;

  /// Progress fraction between 0.0 and 1.0.
  final double progress;

  /// Number of bytes downloaded so far.
  final int downloadedBytes;

  /// Total expected file size in bytes (0 if unknown / chunked).
  final int totalBytes;

  /// Absolute file path on disk once completed.
  final String? localPath;

  /// Error message if download failed.
  final String? errorMessage;

  /// Whether the file is successfully downloaded and ready for offline playback.
  bool get isCompleted => status == GtDownloadStatus.completed;

  /// Whether the task is currently transferring bytes.
  bool get isDownloading => status == GtDownloadStatus.downloading;

  /// Creates a copy of [GtDownloadTask] with replaced fields.
  GtDownloadTask copyWith({
    String? trackId,
    GtTrack? track,
    GtDownloadStatus? status,
    double? progress,
    int? downloadedBytes,
    int? totalBytes,
    String? localPath,
    String? errorMessage,
  }) {
    return GtDownloadTask(
      trackId: trackId ?? this.trackId,
      track: track ?? this.track,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      localPath: localPath ?? this.localPath,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() =>
      'GtDownloadTask(id: $trackId, status: $status, ${(progress * 100).toStringAsFixed(1)}%)';
}
