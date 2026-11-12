/// Standardized error object emitted by `gt_audio`.
class GtAudioError implements Exception {
  const GtAudioError({
    required this.message,
    this.code = 'GT_AUDIO_ERROR',
    this.details,
  });

  /// Human-readable error description.
  final String message;

  /// Internal machine error code.
  final String code;

  /// Raw exception or stack trace details.
  final dynamic details;

  @override
  String toString() => 'GtAudioError[$code]: $message';
}
