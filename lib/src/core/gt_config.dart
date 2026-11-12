/// Configuration options for initializing `gt_audio`.
class GtAudioConfig {
  const GtAudioConfig({
    this.androidNotificationChannelId = 'com.govindtank.gt_audio.channel',
    this.androidNotificationChannelName = 'Audio Playback',
    this.androidNotificationChannelDescription =
        'Music and media playback controls',
    this.androidNotificationIcon = 'mipmap/ic_launcher',
    this.autoPersistState = true,
    this.enableTransparentCaching = true,
    this.seekInterval = const Duration(seconds: 10),
    this.fastForwardInterval = const Duration(seconds: 30),
    this.rewindInterval = const Duration(seconds: 15),
    this.maxRetryAttempts = 3,
  });

  /// Android notification channel identifier.
  final String androidNotificationChannelId;

  /// Android notification channel display name.
  final String androidNotificationChannelName;

  /// Android notification channel description.
  final String androidNotificationChannelDescription;

  /// Android drawable / mipmap icon resource name.
  final String androidNotificationIcon;

  /// Whether to automatically persist queue and position across app sessions.
  final bool autoPersistState;

  /// Whether to cache streaming audio chunks automatically using `LockCachingAudioSource`.
  final bool enableTransparentCaching;

  /// Seek step for forward / rewind controls.
  final Duration seekInterval;

  /// Fast forward skip step.
  final Duration fastForwardInterval;

  /// Rewind skip step.
  final Duration rewindInterval;

  /// Maximum network retry attempts on connection drops before raising an error.
  final int maxRetryAttempts;
}
