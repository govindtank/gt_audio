# gt_audio

[![pub package](https://img.shields.io/pub/v/gt_audio.svg)](https://pub.dev/packages/gt_audio)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/govindtank/gt_audio/blob/main/LICENSE)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android-lightgrey)](https://pub.dev/packages/gt_audio)

A production-ready, unified audio player package for Flutter that combines **streaming**, **offline downloads**, **background playback**, **lock screen media controls**, **Android Auto**, and **Apple CarPlay** behind a clean, single-point API.

Built on top of `just_audio` + `audio_service` + `audio_session`, `gt_audio` eliminates boilerplate glue code and adds critical production capabilities like automatic stream-caching, state persistence across app kills, network retry guards, and drop-in UI widgets.

---

## Features

- 🎧 **Single-Facade Controller (`GtPlayer`)**: Full playback, queue management, volume, and speed control with zero state management ceremony.
- ⚡ **Transparent Stream Caching (`GtCacheManager`)**: Plays remote audio streams instantly while caching chunks to disk; repeat plays consume zero network bandwidth.
- 💾 **Built-in Offline Download Manager (`GtDownloadManager`)**: Download tracks and playlists to local storage with progress streams, pause/resume, and seamless auto-fallback from remote URLs to local files.
- 🔄 **Crash & App-Kill Resilience (`GtStatePersistence`)**: Automatically preserves the active queue, index, and playback head position across app restarts.
- 🚗 **First-Class Android Auto Support**: Native `MediaBrowserServiceCompat` integration with built-in content provider artwork serving.
- 🚘 **Apple CarPlay Ready**: Native `MPRemoteCommandCenter` and `MPNowPlayingInfoCenter` support out of the box, plus modular template delegates for apps with CarPlay entitlements.
- 📶 **Network Drop Guards (`GtNetworkGuard`)**: Automatically recovers and retries playback when switching from Wi-Fi to cellular or experiencing network dropouts.
- 🎨 **Drop-In Reactive Widgets**:
  - `GtPlayerBuilder`: Rebuild your custom UI reactively on state, position, or queue updates.
  - `GtSeekBar`: Smooth scrubbing with buffered progress visualization.
  - `GtWaveformSeekBar`: Interactive GPU-accelerated audio waveform scrubbing powered by [`waveform_pro`](https://pub.dev/packages/waveform_pro).
  - `GtAlbumArtGlow`: Spotify / Apple Music-style dynamic ambient backdrop glow powered by [`ambient_backdrop_glow`](https://pub.dev/packages/ambient_backdrop_glow).
  - `GtMiniPlayer`: Ready-to-use expandable bottom mini player.
  - `GtQueueSheet`: Modal draggable queue manager.

---

## Installation

Add `gt_audio` to your `pubspec.yaml`:

```yaml
dependencies:
  gt_audio: ^1.0.0
```

---

## Platform Setup

### Android

1. Open `android/app/src/main/AndroidManifest.xml` and ensure permissions and audio service are registered:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>

    <application>
        <!-- Audio Service Activity & Service -->
        <activity
            android:name="com.ryanheise.audioservice.AudioServiceActivity"
            android:exported="true">
        </activity>

        <service
            android:name="com.ryanheise.audioservice.AudioService"
            android:foregroundServiceType="mediaPlayback"
            android:exported="true">
            <intent-filter>
                <action android:name="android.media.browse.MediaBrowserService"/>
            </intent-filter>
        </service>

        <receiver
            android:name="androidx.media.session.MediaButtonReceiver"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MEDIA_BUTTON"/>
            </intent-filter>
        </receiver>
    </application>
</manifest>
```

### iOS

1. Open `ios/Runner/Info.plist` and add background audio execution:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

---

## Quickstart

### 1. Initialize Player

Initialize `gt_audio` once in your `main()` or app startup:

```dart
import 'package:flutter/material.dart';
import 'package:gt_audio/gt_audio.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GtPlayer.init(
    config: const GtAudioConfig(
      androidNotificationChannelName: 'My Music Player',
      autoPersistState: true,
      enableTransparentCaching: true,
    ),
  );

  runApp(const MyApp());
}
```

### 2. Set Queue & Play

```dart
final player = GtPlayer.instance;

await player.setQueue([
  GtTrack(
    id: 'track-1',
    title: 'Neon Nights',
    artist: 'Synthwave Prodigy',
    album: 'Future Horizon',
    audioUri: Uri.parse('https://example.com/audio/neon_nights.mp3'),
    artUri: Uri.parse('https://example.com/images/cover.jpg'),
  ),
  GtTrack(
    id: 'track-2',
    title: 'Midnight Drive',
    artist: 'Cyber Pulse',
    audioUri: Uri.parse('https://example.com/audio/midnight.mp3'),
  ),
]);

// Controls
await player.play();
await player.pause();
await player.skipToNext();
await player.seek(const Duration(seconds: 45));
```

### 3. Reactive UI with Waveform Scrubbing & Ambient Glow

```dart
GtPlayerBuilder(
  builder: (context, player, state) {
    return Column(
      children: [
        // Album art with dynamic ambient glow (powered by ambient_backdrop_glow)
        const GtAlbumArtGlow(size: 260),

        Text(state.currentTrack?.title ?? 'No Track Playing'),
        Text(state.currentTrack?.artist ?? ''),

        // Interactive Waveform Seek Bar (powered by waveform_pro)
        const GtWaveformSeekBar(height: 56),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const GtSkipButton.previous(),
            const GtPlayPauseButton(size: 64),
            const GtSkipButton.next(),
          ],
        ),
      ],
    );
  },
)
```

### 4. Offline Downloads

Download tracks with automatic local fallback:

```dart
// Start offline download
await GtPlayer.instance.downloadTrack(track);

// Observe download progress
GtPlayer.instance.downloadTasksStream.listen((tasks) {
  final task = tasks[track.id];
  if (task != null) {
    print('Progress: ${(task.progress * 100).toStringAsFixed(1)}%');
  }
});

// Check offline status
if (GtPlayer.instance.isDownloaded(track.id)) {
  print('Track is ready for offline listening!');
}
```

---

## Android Auto & Apple CarPlay

`gt_audio` includes a ready-to-use default delegate that exposes your current queue and downloaded music folders directly to Android Auto:

```dart
await GtPlayer.init(
  autoDelegate: GtDefaultAndroidAutoDelegate(
    getQueue: () => GtPlayer.instance.queueState.queue,
    getDownloads: () => myOfflineMusicList,
    onTrackSelected: (track) => GtPlayer.instance.setQueue([track]),
  ),
);
```

On iOS, lock screen controls and CarPlay Now Playing work out of the box through `MPRemoteCommandCenter`.

---

## License

MIT © [Govind Tank](https://github.com/govindtank)
