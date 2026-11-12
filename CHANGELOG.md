## 1.0.0

- Initial stable release of `gt_audio`.
- Unified `GtPlayer` facade combining `just_audio` playback, `audio_service` background daemon, and `audio_session`.
- Built-in `GtDownloadManager` for offline file caching, streaming fallback, and download progress tracking.
- Transparent stream caching with `LockCachingAudioSource` via `GtCacheManager`.
- Persistent queue and playback position recovery on app restart (`GtStatePersistence`).
- Resilient network disconnection recovery (`GtNetworkGuard`).
- Android Auto integration via native `MediaBrowserServiceCompat` with `GtArtworkProvider` content URI handling.
- Apple CarPlay Now Playing integration and modular template browsing support.
- Drop-in UI widgets: `GtPlayerBuilder`, `GtSeekBar`, `GtWaveformSeekBar` (powered by `waveform_pro`), and `GtAlbumArtGlow` (powered by `ambient_backdrop_glow`).
