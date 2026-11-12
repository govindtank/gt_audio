import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import '../auto/gt_android_auto.dart';
import '../models/gt_audio_error.dart';
import '../models/gt_download_state.dart';
import '../models/gt_playback_state.dart';
import '../models/gt_position_state.dart';
import '../models/gt_queue_state.dart';
import '../models/gt_track.dart';
import '../storage/gt_cache_manager.dart';
import '../storage/gt_download_manager.dart';
import '../storage/gt_state_persistence.dart';
import 'gt_audio_handler.dart';
import 'gt_config.dart';
import 'gt_session_manager.dart';

/// The central controller and facade for `gt_audio`.
///
/// Provides single-point access to streaming audio playback, offline downloads,
/// persistent queues, lock screen notifications, Android Auto, and CarPlay.
class GtPlayer {
  GtPlayer._({
    required GtAudioHandler handler,
    required GtSessionManager sessionManager,
    required this.config,
  })  : _handler = handler,
        _sessionManager = sessionManager {
    _initStreams();
  }

  static GtPlayer? _instance;

  /// Returns the active singleton instance.
  /// Throws [StateError] if [GtPlayer.init] has not yet completed.
  static GtPlayer get instance {
    if (_instance == null) {
      throw StateError(
        'GtPlayer has not been initialized. Call await GtPlayer.init() first.',
      );
    }
    return _instance!;
  }

  /// Whether [GtPlayer] has been initialized.
  static bool get isInitialized => _instance != null;

  final GtAudioHandler _handler;
  final GtSessionManager _sessionManager;

  /// Active configuration parameters.
  final GtAudioConfig config;

  final BehaviorSubject<GtPlaybackState> _playbackStateSubject =
      BehaviorSubject<GtPlaybackState>.seeded(
    const GtPlaybackState(status: GtPlaybackStatus.idle),
  );

  final BehaviorSubject<GtPositionState> _positionStateSubject =
      BehaviorSubject<GtPositionState>.seeded(const GtPositionState());

  final BehaviorSubject<GtQueueState> _queueStateSubject =
      BehaviorSubject<GtQueueState>.seeded(const GtQueueState());

  final BehaviorSubject<GtTrack?> _currentTrackSubject =
      BehaviorSubject<GtTrack?>.seeded(null);

  final StreamController<GtAudioError> _errorController =
      StreamController<GtAudioError>.broadcast();

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Initializes the unified audio engine, background service, cache, and session manager.
  static Future<GtPlayer> init({
    GtAudioConfig config = const GtAudioConfig(),
    GtAndroidAutoDelegate? autoDelegate,
  }) async {
    if (_instance != null) {
      return _instance!;
    }

    // Initialize caching directory
    if (config.enableTransparentCaching) {
      await GtCacheManager.instance.init();
    }

    // Initialize offline downloads registry
    await GtDownloadManager.instance.init();

    // Start background audio handler
    final handler = await AudioService.init(
      builder: () => GtAudioHandler(
        config: config,
        autoDelegate: autoDelegate,
      ),
      config: AudioServiceConfig(
        androidNotificationChannelId: config.androidNotificationChannelId,
        androidNotificationChannelName: config.androidNotificationChannelName,
        androidNotificationChannelDescription:
            config.androidNotificationChannelDescription,
        androidNotificationIcon: config.androidNotificationIcon,
        androidShowNotificationBadge: true,
        androidStopForegroundOnPause: false,
      ),
    );

    late final GtSessionManager sessionManager;
    sessionManager = GtSessionManager(
      onPauseRequested: () => handler.pause(),
      onPlayRequested: () => handler.play(),
    );

    await sessionManager.activate();

    _instance = GtPlayer._(
      handler: handler,
      sessionManager: sessionManager,
      config: config,
    );

    return _instance!;
  }

  void _initStreams() {
    // 1. Playback state stream mapping
    final playbackSub = Rx.combineLatest4<PlaybackState, double, LoopMode, bool,
        GtPlaybackState>(
      _handler.playbackState,
      _handler.player.speedStream,
      _handler.player.loopModeStream,
      _handler.player.shuffleModeEnabledStream,
      (serviceState, speed, loopMode, isShuffled) {
        GtPlaybackStatus status;
        switch (serviceState.processingState) {
          case AudioProcessingState.idle:
            status = GtPlaybackStatus.idle;
            break;
          case AudioProcessingState.loading:
            status = GtPlaybackStatus.loading;
            break;
          case AudioProcessingState.buffering:
            status = GtPlaybackStatus.buffering;
            break;
          case AudioProcessingState.ready:
            status = serviceState.playing
                ? GtPlaybackStatus.playing
                : GtPlaybackStatus.paused;
            break;
          case AudioProcessingState.completed:
            status = GtPlaybackStatus.completed;
            break;
          case AudioProcessingState.error:
            status = GtPlaybackStatus.error;
            break;
        }

        GtLoopMode gtLoop;
        switch (loopMode) {
          case LoopMode.off:
            gtLoop = GtLoopMode.off;
            break;
          case LoopMode.one:
            gtLoop = GtLoopMode.one;
            break;
          case LoopMode.all:
            gtLoop = GtLoopMode.all;
            break;
        }

        return GtPlaybackState(
          status: status,
          speed: speed,
          loopMode: gtLoop,
          isShuffled: isShuffled,
          errorMessage: serviceState.errorMessage,
        );
      },
    ).listen((state) {
      _playbackStateSubject.add(state);
    });
    _subscriptions.add(playbackSub);

    // 2. Position state stream mapping
    final positionSub =
        Rx.combineLatest3<Duration, Duration?, Duration, GtPositionState>(
      _handler.player.positionStream,
      _handler.player.durationStream,
      _handler.player.bufferedPositionStream,
      (pos, dur, buf) {
        return GtPositionState(
          position: pos,
          duration: dur ?? Duration.zero,
          bufferedPosition: buf,
        );
      },
    ).listen((state) {
      _positionStateSubject.add(state);
    });
    _subscriptions.add(positionSub);

    // 3. Current track mapping
    final trackSub = _handler.mediaItem.listen((item) {
      if (item == null) {
        _currentTrackSubject.add(null);
      } else {
        _currentTrackSubject.add(GtTrack.fromMediaItem(item));
      }
      _updateQueueSubject();
    });
    _subscriptions.add(trackSub);

    // 4. Error stream
    final errorSub = _handler.errorEvents.listen((err) {
      _errorController.add(GtAudioError(message: err));
    });
    _subscriptions.add(errorSub);
  }

  void _updateQueueSubject() {
    _queueStateSubject.add(
      GtQueueState(
        queue: _handler.gtQueue,
        currentIndex: _handler.currentTrackIndex,
      ),
    );
  }

  // --- Public Streams ---

  /// Emits updates whenever playback status, speed, loop mode, or shuffle changes.
  Stream<GtPlaybackState> get playbackStateStream =>
      _playbackStateSubject.stream.distinct();

  /// Synchronous snapshot of the latest playback state.
  GtPlaybackState get playbackState => _playbackStateSubject.value;

  /// Emits updates for current playback position, duration, and buffer progress.
  Stream<GtPositionState> get positionStateStream =>
      _positionStateSubject.stream;

  /// Synchronous snapshot of current position.
  GtPositionState get positionState => _positionStateSubject.value;

  /// Emits updates whenever the queue list or active index changes.
  Stream<GtQueueState> get queueStateStream =>
      _queueStateSubject.stream.distinct();

  /// Synchronous snapshot of current queue state.
  GtQueueState get queueState => _queueStateSubject.value;

  /// Emits the currently active playing track, or null if stopped.
  Stream<GtTrack?> get currentTrackStream =>
      _currentTrackSubject.stream.distinct();

  /// Synchronous snapshot of current track.
  GtTrack? get currentTrack => _currentTrackSubject.value;

  /// Stream of offline download tasks and progress.
  Stream<Map<String, GtDownloadTask>> get downloadTasksStream =>
      GtDownloadManager.instance.tasksStream;

  /// Stream of errors emitted during playback or background operations.
  Stream<GtAudioError> get errorStream => _errorController.stream;

  // --- Playback Controls ---

  /// Replaces the playlist with [tracks] and starts playback at [initialIndex].
  Future<void> setQueue(
    List<GtTrack> tracks, {
    int initialIndex = 0,
    bool autoPlay = true,
  }) async {
    await _handler.setGtQueue(
      tracks,
      index: initialIndex,
      autoPlay: autoPlay,
    );
    _updateQueueSubject();
  }

  /// Appends a new track to the end of the queue.
  Future<void> addTrack(GtTrack track) async {
    await _handler.addQueueItem(track.toMediaItem());
    _updateQueueSubject();
  }

  /// Removes a track from the queue at [index].
  Future<void> removeTrackAt(int index) async {
    await _handler.removeQueueItemAt(index);
    _updateQueueSubject();
  }

  /// Removes a track with matching [trackId] from the queue.
  Future<void> removeTrack(String trackId) async {
    final index = _handler.gtQueue.indexWhere((t) => t.id == trackId);
    if (index != -1) {
      await removeTrackAt(index);
    }
  }

  /// Clears the queue and stops playback.
  Future<void> clearQueue() async {
    await _handler.setGtQueue([], autoPlay: false);
    _updateQueueSubject();
  }

  /// Starts or resumes playback.
  Future<void> play() => _handler.play();

  /// Pauses playback.
  Future<void> pause() => _handler.pause();

  /// Toggles between play and pause.
  Future<void> playOrPause() async {
    if (playbackState.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Stops playback.
  Future<void> stop() => _handler.stop();

  /// Seeks to an absolute [position].
  Future<void> seek(Duration position) => _handler.seek(position);

  /// Seeks relative to the current position (positive forward, negative rewind).
  Future<void> seekRelative(Duration offset) async {
    final current = positionState.position;
    final total = positionState.duration;
    final targetMs = (current + offset).inMilliseconds;
    final clampedMs = targetMs.clamp(0, total.inMilliseconds);
    await seek(Duration(milliseconds: clampedMs));
  }

  /// Fast-forwards by configured interval.
  Future<void> fastForward() => seekRelative(config.fastForwardInterval);

  /// Rewinds by configured interval.
  Future<void> rewind() => seekRelative(-config.rewindInterval);

  /// Skips to the next track in the playlist.
  Future<void> skipToNext() => _handler.skipToNext();

  /// Skips to the previous track in the playlist.
  Future<void> skipToPrevious() => _handler.skipToPrevious();

  /// Skips directly to a specific track index in the queue.
  Future<void> skipToTrack(int index) => _handler.skipToQueueItem(index);

  /// Adjusts playback speed (e.g. 0.5, 1.0, 1.25, 1.5, 2.0).
  Future<void> setSpeed(double speed) => _handler.setSpeed(speed);

  /// Sets the repetition mode.
  Future<void> setLoopMode(GtLoopMode mode) async {
    AudioServiceRepeatMode svcMode;
    switch (mode) {
      case GtLoopMode.off:
        svcMode = AudioServiceRepeatMode.none;
        break;
      case GtLoopMode.one:
        svcMode = AudioServiceRepeatMode.one;
        break;
      case GtLoopMode.all:
        svcMode = AudioServiceRepeatMode.all;
        break;
    }
    await _handler.setRepeatMode(svcMode);
  }

  /// Toggles shuffle mode.
  Future<void> setShuffle(bool enable) async {
    await _handler.setShuffleMode(
      enable ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
    );
  }

  // --- Offline & Download Controls ---

  /// Downloads [track] to local device storage for offline playback.
  Future<void> downloadTrack(GtTrack track) =>
      GtDownloadManager.instance.downloadTrack(track);

  /// Cancels an active download.
  Future<void> cancelDownload(String trackId) =>
      GtDownloadManager.instance.cancelDownload(trackId);

  /// Deletes a downloaded track from storage.
  Future<void> removeDownload(String trackId) =>
      GtDownloadManager.instance.removeDownloadedTrack(trackId);

  /// Checks if [trackId] is available offline.
  bool isDownloaded(String trackId) =>
      GtDownloadManager.instance.isDownloaded(trackId);

  /// Restores saved queue and position from disk if previously saved.
  Future<bool> restoreSavedState({bool autoPlay = false}) async {
    final saved = await GtStatePersistence.instance.restoreState();
    if (saved == null || saved.tracks.isEmpty) return false;

    await setQueue(
      saved.tracks,
      initialIndex: saved.currentIndex,
      autoPlay: false,
    );

    if (saved.position > Duration.zero) {
      await seek(saved.position);
    }

    if (autoPlay) {
      await play();
    }

    return true;
  }

  /// Disposes resources and listeners.
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _sessionManager.dispose();
  }
}
