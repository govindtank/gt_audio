import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// Manages transparent audio streaming cache.
class GtCacheManager {
  GtCacheManager._();

  static final GtCacheManager instance = GtCacheManager._();

  Directory? _cacheDir;

  /// Initializes the cache directory.
  Future<void> init() async {
    final tempDir = await getTemporaryDirectory();
    _cacheDir = Directory('${tempDir.path}/gt_audio_cache');
    if (!_cacheDir!.existsSync()) {
      await _cacheDir!.create(recursive: true);
    }
  }

  /// Returns the cache directory.
  Directory get cacheDirectory {
    if (_cacheDir == null) {
      throw StateError('GtCacheManager must be initialized before use.');
    }
    return _cacheDir!;
  }

  /// Creates a cached audio source for [uri].
  ///
  /// This automatically downloads and caches audio chunks while playing,
  /// so subsequent plays of the same track consume zero network bandwidth.
  LockCachingAudioSource createCachingSource(Uri uri, {String? cacheKey}) {
    final key = cacheKey ?? _sanitizeKey(uri.toString());
    final cacheFile = File('${cacheDirectory.path}/$key.audio');
    return LockCachingAudioSource(
      uri,
      cacheFile: cacheFile,
    );
  }

  /// Calculates total bytes cached.
  Future<int> getCachedSizeBytes() async {
    if (_cacheDir == null || !_cacheDir!.existsSync()) return 0;
    int total = 0;
    await for (final file in _cacheDir!.list(recursive: false)) {
      if (file is File) {
        total += await file.length();
      }
    }
    return total;
  }

  /// Clears all transparently cached streaming chunks.
  Future<void> clearCache() async {
    if (_cacheDir == null || !_cacheDir!.existsSync()) return;
    await for (final file in _cacheDir!.list(recursive: false)) {
      if (file is File) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
  }

  String _sanitizeKey(String raw) {
    return raw.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }
}
