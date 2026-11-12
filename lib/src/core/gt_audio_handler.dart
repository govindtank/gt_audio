import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import '../auto/gt_android_auto.dart';
import '../models/gt_queue_state.dart';
import '../models/gt_track.dart';
import '../storage/gt_cache_manager.dart';
import '../storage/gt_download_manager.dart';
import '../storage/gt_state_persistence.dart';
import '../utils/gt_asset_resolver.dart';
import 'gt_config.dart';

/// The background audio service handler powering playback, notifications, and automotive connections.
class GtAudioHandler extends BaseAudioHandler {
  GtAudioHandler({
    required this.config,
    this.autoDelegate,
  }) {
    _init();
  }

  final GtAudioConfig config;
  final GtAndroidAutoDelegate? autoDelegate;

  final AudioPlayer _player = AudioPlayer();
  final List<GtTrack> _gtQueue = [];
  int _currentIndex = -1;

  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  Stream<String> get errorEvents => _errorController.stream;

  void _init() {
    // Pipe just_audio playback state into audio_service playbackState
    _player.playbackEventStream.listen((event) {
      _broadcastPlaybackState();
    });

    // Pipe player state transitions
    _player.playerStateStream.listen((state) {
      _broadcastPlaybackState();
      if (state.processingState == ProcessingState.completed) {
        unawaited(onPlaybackCompleted());
      }
    });

    // Handle audio track errors
    _player.playbackEventStream.handleError((error) {
      _errorController.add(error.toString());
      _broadcastPlaybackState(errorMessage: error.toString());
    });

    // Auto-persist state periodically or on change if enabled
    if (config.autoPersistState) {
      _player.positionStream
          .throttleTime(const Duration(seconds: 3))
          .listen((pos) {
        _persistCurrentState();
      });
    }
  }

  void _persistCurrentState() {
    if (_gtQueue.isEmpty || _currentIndex < 0) return;
    GtStatePersistence.instance.saveState(
      queueState: _toGtQueueState(),
      position: _player.position,
    );
  }

  Future<void> _broadcastPlaybackState({String? errorMessage}) async {
    final playing = _player.playing;
    final processingState = _player.processingState;

    AudioProcessingState audioProcessingState;
    switch (processingState) {
      case ProcessingState.idle:
        audioProcessingState = AudioProcessingState.idle;
        break;
      case ProcessingState.loading:
        audioProcessingState = AudioProcessingState.loading;
        break;
      case ProcessingState.buffering:
        audioProcessingState = AudioProcessingState.buffering;
        break;
      case ProcessingState.ready:
        audioProcessingState = AudioProcessingState.ready;
        break;
      case ProcessingState.completed:
        audioProcessingState = AudioProcessingState.completed;
        break;
    }

    final hasNext = _currentIndex >= 0 && _currentIndex < _gtQueue.length - 1;
    final hasPrev = _currentIndex > 0;

    final controls = [
      if (hasPrev) MediaControl.skipToPrevious,
      if (playing) MediaControl.pause else MediaControl.play,
      MediaControl.stop,
      if (hasNext) MediaControl.skipToNext,
    ];

    playbackState.add(
      PlaybackState(
        controls: controls,
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.setSpeed,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: audioProcessingState,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _currentIndex >= 0 ? _currentIndex : null,
        errorMessage: errorMessage,
      ),
    );
  }

  /// Sets the active queue and starts playback at [index].
  Future<void> setGtQueue(
    List<GtTrack> tracks, {
    int index = 0,
    bool autoPlay = true,
  }) async {
    _gtQueue.clear();
    _gtQueue.addAll(tracks);
    queue.add(tracks.map((t) => t.toMediaItem()).toList());

    if (tracks.isEmpty) {
      _currentIndex = -1;
      mediaItem.add(null);
      await _player.stop();
      return;
    }

    _currentIndex = index.clamp(0, tracks.length - 1);
    await _loadTrack(_gtQueue[_currentIndex], autoPlay: autoPlay);
  }

  Future<void> _loadTrack(GtTrack track, {bool autoPlay = true}) async {
    try {
      // Resolve track with local path if downloaded
      final resolved = GtDownloadManager.instance.resolveTrack(track);
      _gtQueue[_currentIndex] = resolved;

      // Resolve artwork content URI for Android Auto / notification
      final resolvedArtUri =
          await GtAssetResolver.resolveArtworkUri(resolved.artUri);
      final media = resolved.copyWith(artUri: resolvedArtUri).toMediaItem();
      mediaItem.add(media);

      AudioSource source;
      if (resolved.isDownloaded) {
        source = AudioSource.uri(resolved.effectiveUri);
      } else if (config.enableTransparentCaching) {
        source = GtCacheManager.instance.createCachingSource(
          resolved.audioUri,
          cacheKey: resolved.id,
        );
      } else {
        source = AudioSource.uri(resolved.audioUri);
      }

      await _player.setAudioSource(source);

      if (autoPlay) {
        await _player.play();
      }
    } catch (e) {
      _errorController.add(e.toString());
      await _broadcastPlaybackState(errorMessage: e.toString());
    }
  }

  /// Called when current track finishes playing.
  Future<void> onPlaybackCompleted() async {
    final loopMode = _player.loopMode;
    if (loopMode == LoopMode.one) {
      await _player.seek(Duration.zero);
      await _player.play();
      return;
    }

    if (_currentIndex < _gtQueue.length - 1) {
      await skipToNext();
    } else if (loopMode == LoopMode.all && _gtQueue.isNotEmpty) {
      await skipToQueueItem(0);
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_currentIndex < _gtQueue.length - 1) {
      _currentIndex++;
      await _loadTrack(_gtQueue[_currentIndex], autoPlay: true);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position.inSeconds > 3) {
      // If played more than 3 seconds, restart current track
      await _player.seek(Duration.zero);
      return;
    }
    if (_currentIndex > 0) {
      _currentIndex--;
      await _loadTrack(_gtQueue[_currentIndex], autoPlay: true);
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index >= 0 && index < _gtQueue.length) {
      _currentIndex = index;
      await _loadTrack(_gtQueue[_currentIndex], autoPlay: true);
    }
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    final track = GtTrack.fromMediaItem(mediaItem);
    _gtQueue.add(track);
    queue.add(_gtQueue.map((t) => t.toMediaItem()).toList());
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    if (index >= 0 && index < _gtQueue.length) {
      _gtQueue.removeAt(index);
      queue.add(_gtQueue.map((t) => t.toMediaItem()).toList());
      if (_currentIndex == index) {
        if (_gtQueue.isEmpty) {
          await stop();
        } else {
          _currentIndex = _currentIndex.clamp(0, _gtQueue.length - 1);
          await _loadTrack(_gtQueue[_currentIndex], autoPlay: _player.playing);
        }
      } else if (_currentIndex > index) {
        _currentIndex--;
      }
    }
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        await _player.setLoopMode(LoopMode.all);
        break;
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enable = shuffleMode != AudioServiceShuffleMode.none;
    await _player.setShuffleModeEnabled(enable);
  }

  // --- Android Auto MediaBrowserService Hooks ---

  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
    if (autoDelegate != null) {
      return autoDelegate!.getChildren(parentMediaId, options: options);
    }

    if (parentMediaId == AudioService.recentRootId) {
      return queue.value;
    }

    return queue.value;
  }

  @override
  Future<MediaItem?> getMediaItem(String mediaId) async {
    if (autoDelegate != null) {
      return autoDelegate!.getMediaItem(mediaId);
    }
    return queue.value.where((item) => item.id == mediaId).firstOrNull;
  }

  @override
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) async {
    if (autoDelegate != null) {
      await autoDelegate!.onPlayFromMediaId(mediaId, extras: extras);
      return;
    }

    final index = _gtQueue.indexWhere((t) => t.id == mediaId);
    if (index != -1) {
      await skipToQueueItem(index);
    }
  }

  @override
  Future<List<MediaItem>> search(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {
    if (autoDelegate != null) {
      return autoDelegate!.onSearch(query, extras: extras);
    }

    final lower = query.toLowerCase();
    final matches = _gtQueue.where((t) =>
        t.title.toLowerCase().contains(lower) ||
        t.artist.toLowerCase().contains(lower));
    return matches.map((t) => t.toMediaItem()).toList();
  }

  // Internal accessors
  AudioPlayer get player => _player;
  List<GtTrack> get gtQueue => List.unmodifiable(_gtQueue);
  int get currentTrackIndex => _currentIndex;
  GtTrack? get currentTrack =>
      _currentIndex >= 0 && _currentIndex < _gtQueue.length
          ? _gtQueue[_currentIndex]
          : null;

  GtQueueState _toGtQueueState() {
    return GtQueueState(
      queue: List.unmodifiable(_gtQueue),
      currentIndex: _currentIndex,
    );
  }
}
