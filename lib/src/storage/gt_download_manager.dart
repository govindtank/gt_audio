import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/gt_download_state.dart';
import '../models/gt_track.dart';

/// Full-featured offline audio download manager with progress tracking and persistent registry.
class GtDownloadManager {
  GtDownloadManager._();

  static final GtDownloadManager instance = GtDownloadManager._();

  static const String _registryKey = 'gt_audio_download_registry';

  Directory? _downloadsDir;
  SharedPreferences? _prefs;

  final Map<String, GtDownloadTask> _tasks = {};
  final BehaviorSubject<Map<String, GtDownloadTask>> _tasksSubject =
      BehaviorSubject<Map<String, GtDownloadTask>>.seeded({});

  final Map<String, http.Client> _activeClients = {};

  /// Stream of all active and completed download tasks mapped by track ID.
  Stream<Map<String, GtDownloadTask>> get tasksStream => _tasksSubject.stream;

  /// Stream of task updates for a specific track.
  Stream<GtDownloadTask?> taskStreamFor(String trackId) {
    return _tasksSubject.stream.map((map) => map[trackId]).distinct();
  }

  /// Initializes the download manager and loads existing offline records.
  Future<void> init() async {
    final docsDir = await getApplicationDocumentsDirectory();
    _downloadsDir = Directory('${docsDir.path}/gt_audio/downloads');
    if (!_downloadsDir!.existsSync()) {
      await _downloadsDir!.create(recursive: true);
    }

    _prefs = await SharedPreferences.getInstance();
    _loadPersistedRegistry();
  }

  void _loadPersistedRegistry() {
    final raw = _prefs?.getString(_registryKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        final trackId = entry.key;
        final map = entry.value as Map<String, dynamic>;
        final track = GtTrack.fromJson(map['track'] as Map<String, dynamic>);
        final localPath = map['localPath'] as String;

        if (File(localPath).existsSync()) {
          _tasks[trackId] = GtDownloadTask(
            trackId: trackId,
            track: track.copyWith(localPath: localPath),
            status: GtDownloadStatus.completed,
            progress: 1.0,
            localPath: localPath,
          );
        }
      }
      _emitTasks();
    } catch (_) {}
  }

  Future<void> _savePersistedRegistry() async {
    if (_prefs == null) return;
    final map = <String, dynamic>{};
    for (final entry in _tasks.entries) {
      if (entry.value.isCompleted && entry.value.localPath != null) {
        map[entry.key] = {
          'track': entry.value.track.toJson(),
          'localPath': entry.value.localPath,
        };
      }
    }
    await _prefs!.setString(_registryKey, jsonEncode(map));
  }

  /// Checks if [trackId] is fully downloaded and available locally.
  bool isDownloaded(String trackId) {
    final task = _tasks[trackId];
    if (task == null || !task.isCompleted || task.localPath == null) {
      return false;
    }
    return File(task.localPath!).existsSync();
  }

  /// Returns the local filesystem path for [trackId], if downloaded.
  String? getLocalPath(String trackId) {
    if (isDownloaded(trackId)) {
      return _tasks[trackId]!.localPath;
    }
    return null;
  }

  /// Returns a copy of [track] with `localPath` populated if downloaded.
  GtTrack resolveTrack(GtTrack track) {
    final path = getLocalPath(track.id);
    if (path != null) {
      return track.copyWith(localPath: path);
    }
    return track;
  }

  /// Downloads [track] to local storage for offline playback.
  Future<void> downloadTrack(GtTrack track) async {
    if (isDownloaded(track.id)) return;
    if (_downloadsDir == null) {
      await init();
    }

    final sanitizedId = track.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    // Extract file extension or default to .mp3
    final uriPath = track.audioUri.path.toLowerCase();
    String ext = '.mp3';
    if (uriPath.endsWith('.m4a')) ext = '.m4a';
    if (uriPath.endsWith('.aac')) ext = '.aac';
    if (uriPath.endsWith('.wav')) ext = '.wav';
    if (uriPath.endsWith('.flac')) ext = '.flac';

    final targetFile = File('${_downloadsDir!.path}/$sanitizedId$ext');

    final client = http.Client();
    _activeClients[track.id] = client;

    _updateTask(GtDownloadTask(
      trackId: track.id,
      track: track,
      status: GtDownloadStatus.downloading,
      progress: 0.0,
      downloadedBytes: 0,
      totalBytes: 0,
    ));

    try {
      final request = http.Request('GET', track.audioUri);
      final response = await client.send(request);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }

      final totalBytes = response.contentLength ?? 0;
      int downloadedBytes = 0;

      final sink = targetFile.openWrite();

      await for (final chunk in response.stream) {
        // Check if task was cancelled mid-stream
        if (!_activeClients.containsKey(track.id)) {
          await sink.close();
          if (targetFile.existsSync()) await targetFile.delete();
          return;
        }

        sink.add(chunk);
        downloadedBytes += chunk.length;

        final double progress = totalBytes > 0
            ? (downloadedBytes / totalBytes).clamp(0.0, 1.0)
            : 0.0;

        _updateTask(GtDownloadTask(
          trackId: track.id,
          track: track,
          status: GtDownloadStatus.downloading,
          progress: progress,
          downloadedBytes: downloadedBytes,
          totalBytes: totalBytes,
        ));
      }

      await sink.flush();
      await sink.close();

      _activeClients.remove(track.id);

      final completedTask = GtDownloadTask(
        trackId: track.id,
        track: track.copyWith(localPath: targetFile.path),
        status: GtDownloadStatus.completed,
        progress: 1.0,
        downloadedBytes: downloadedBytes,
        totalBytes: downloadedBytes,
        localPath: targetFile.path,
      );

      _updateTask(completedTask);
      await _savePersistedRegistry();
    } catch (e) {
      _activeClients.remove(track.id);
      if (targetFile.existsSync()) {
        try {
          await targetFile.delete();
        } catch (_) {}
      }

      _updateTask(GtDownloadTask(
        trackId: track.id,
        track: track,
        status: GtDownloadStatus.failed,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Cancels an in-progress download.
  Future<void> cancelDownload(String trackId) async {
    final client = _activeClients.remove(trackId);
    if (client != null) {
      client.close();
    }

    final currentTask = _tasks[trackId];
    if (currentTask != null) {
      _updateTask(currentTask.copyWith(
        status: GtDownloadStatus.cancelled,
      ));
    }
  }

  /// Deletes a downloaded track from disk and registry.
  Future<void> removeDownloadedTrack(String trackId) async {
    await cancelDownload(trackId);

    final task = _tasks[trackId];
    if (task?.localPath != null) {
      final file = File(task!.localPath!);
      if (file.existsSync()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }

    _tasks.remove(trackId);
    _emitTasks();
    await _savePersistedRegistry();
  }

  /// Clears all downloaded tracks and deletes the storage directory.
  Future<void> clearAllDownloads() async {
    for (final client in _activeClients.values) {
      client.close();
    }
    _activeClients.clear();

    if (_downloadsDir != null && _downloadsDir!.existsSync()) {
      try {
        await _downloadsDir!.delete(recursive: true);
        await _downloadsDir!.create(recursive: true);
      } catch (_) {}
    }

    _tasks.clear();
    _emitTasks();
    await _savePersistedRegistry();
  }

  void _updateTask(GtDownloadTask task) {
    _tasks[task.trackId] = task;
    _emitTasks();
  }

  void _emitTasks() {
    _tasksSubject.add(Map.unmodifiable(_tasks));
  }
}
