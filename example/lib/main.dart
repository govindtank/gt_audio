import 'package:flutter/material.dart';
import 'package:gt_audio/gt_audio.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize gt_audio with Android Auto delegate and transparent caching
  await GtPlayer.init(
    config: const GtAudioConfig(
      androidNotificationChannelName: 'GT Music Player',
      androidNotificationChannelDescription:
          'Background audio playback controls',
      autoPersistState: true,
      enableTransparentCaching: true,
    ),
    autoDelegate: GtDefaultAndroidAutoDelegate(
      getQueue: () => GtPlayer.instance.queueState.queue,
      getDownloads: () {
        return sampleCatalog
            .where((t) => GtPlayer.instance.isDownloaded(t.id))
            .map((t) => GtDownloadManager.instance.resolveTrack(t))
            .toList();
      },
      onTrackSelected: (track) async {
        await GtPlayer.instance.setQueue([track]);
      },
    ),
  );

  runApp(const GtMusicApp());
}

/// Curated royalty-free catalog for streaming and offline testing.
final List<GtTrack> sampleCatalog = [
  GtTrack(
    id: 'track-1',
    title: 'Starlight Acoustic',
    artist: 'Acoustic Horizon',
    album: 'Folk Reverie',
    duration: const Duration(minutes: 6, seconds: 12),
    audioUri: Uri.parse(
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    ),
    artUri: Uri.parse(
      'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&q=80',
    ),
  ),
  GtTrack(
    id: 'track-2',
    title: 'Cyber City Run',
    artist: 'Neon Matrix',
    album: 'Grid Runner',
    duration: const Duration(minutes: 7, seconds: 5),
    audioUri: Uri.parse(
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    ),
    artUri: Uri.parse(
      'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=600&q=80',
    ),
  ),
  GtTrack(
    id: 'track-3',
    title: 'Lo-Fi Midnight Study',
    artist: 'Chill Coffee',
    album: 'Late Night Beats',
    duration: const Duration(minutes: 5, seconds: 44),
    audioUri: Uri.parse(
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    ),
    artUri: Uri.parse(
      'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=600&q=80',
    ),
  ),
  GtTrack(
    id: 'track-4',
    title: 'Retro Wave Drive',
    artist: 'Synth Overdrive',
    album: 'Sunset Highway',
    duration: const Duration(minutes: 5, seconds: 2),
    audioUri: Uri.parse(
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    ),
    artUri: Uri.parse(
      'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&q=80',
    ),
  ),
  GtTrack(
    id: 'track-5',
    title: 'Ambient Deep Meditation',
    artist: 'Zenith Sound',
    album: 'Peaceful Skies',
    duration: const Duration(minutes: 5, seconds: 53),
    audioUri: Uri.parse(
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
    ),
    artUri: Uri.parse(
      'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600&q=80',
    ),
  ),
];

class GtMusicApp extends StatelessWidget {
  const GtMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GT Music Player',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF6366F1),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF818CF8),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    // Attempt auto-restoring previous queue if saved
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GtPlayer.instance.restoreSavedState(autoPlay: false);
    });
  }

  void _openFullPlayer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) => const FullPlayerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedTab,
          children: const [
            ExploreStreamTab(),
            DownloadsTab(),
            AutoDiagnosticsTab(),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drop-in Mini Player with tap to open full player
          GtMiniPlayer(
            onTap: () => _openFullPlayer(context),
          ),
          NavigationBar(
            selectedIndex: _selectedTab,
            onDestinationSelected: (i) => setState(() => _selectedTab = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.stream_rounded),
                label: 'Stream',
              ),
              NavigationDestination(
                icon: Icon(Icons.download_done_rounded),
                label: 'Offline',
              ),
              NavigationDestination(
                icon: Icon(Icons.directions_car_rounded),
                label: 'Car & Auto',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tab 1: Explore & Stream Catalog
class ExploreStreamTab extends StatelessWidget {
  const ExploreStreamTab({super.key});

  @override
  Widget build(BuildContext context) {
    final player = GtPlayer.instance;
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.headphones_rounded,
                  color: theme.colorScheme.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GT Audio',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Free streaming & instant offline downloads',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.playlist_play_rounded),
                label: const Text('Play All'),
                onPressed: () {
                  player.setQueue(sampleCatalog, initialIndex: 0);
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: sampleCatalog.length,
            padding: const EdgeInsets.symmetric(vertical: 12),
            separatorBuilder: (_, __) => const Divider(indent: 80, height: 1),
            itemBuilder: (context, index) {
              final track = sampleCatalog[index];

              return StreamBuilder<Map<String, GtDownloadTask>>(
                stream: player.downloadTasksStream,
                builder: (context, downloadSnap) {
                  final task = downloadSnap.data?[track.id];
                  final isDownloaded = player.isDownloaded(track.id);
                  final isDownloading = task?.isDownloading ?? false;
                  final progress = task?.progress ?? 0.0;

                  return StreamBuilder<GtTrack?>(
                    stream: player.currentTrackStream,
                    builder: (context, trackSnap) {
                      final isCurrent = trackSnap.data?.id == track.id;

                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.network(
                                track.artUri.toString(),
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 52,
                                  height: 52,
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.music_note_rounded),
                                ),
                              ),
                              if (isCurrent)
                                Container(
                                  width: 52,
                                  height: 52,
                                  color: Colors.black.withValues(alpha: 0.5),
                                  child: Icon(
                                    Icons.graphic_eq_rounded,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        title: Text(
                          track.title,
                          style: TextStyle(
                            fontWeight:
                                isCurrent ? FontWeight.bold : FontWeight.w600,
                            color: isCurrent ? theme.colorScheme.primary : null,
                          ),
                        ),
                        subtitle: Text(
                          '${track.artist} • ${track.album}',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Download button with live progress
                            if (isDownloading)
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(
                                    value: progress > 0 ? progress : null,
                                    strokeWidth: 3,
                                  ),
                                ),
                              )
                            else if (isDownloaded)
                              IconButton(
                                icon: const Icon(
                                  Icons.offline_pin_rounded,
                                  color: Colors.greenAccent,
                                ),
                                tooltip: 'Downloaded',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Song is ready offline!'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                              )
                            else
                              IconButton(
                                icon: const Icon(Icons.download_rounded),
                                tooltip: 'Download Track',
                                onPressed: () {
                                  player.downloadTrack(track);
                                },
                              ),

                            // Add to queue button
                            IconButton(
                              icon: const Icon(Icons.add_to_photos_rounded),
                              tooltip: 'Add to Queue',
                              onPressed: () {
                                player.addTrack(track);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Added "${track.title}" to queue'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          player.setQueue(sampleCatalog, initialIndex: index);
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Tab 2: Offline Downloads Manager
class DownloadsTab extends StatelessWidget {
  const DownloadsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final player = GtPlayer.instance;
    final theme = Theme.of(context);

    return StreamBuilder<Map<String, GtDownloadTask>>(
      stream: player.downloadTasksStream,
      builder: (context, snapshot) {
        final downloadedTracks = sampleCatalog
            .where((t) => player.isDownloaded(t.id))
            .map((t) => GtDownloadManager.instance.resolveTrack(t))
            .toList();

        if (downloadedTracks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_download_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Offline Music Yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the download button on any track to listen offline.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Downloaded Music',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${downloadedTracks.length} tracks stored on disk (0 KB streaming needed)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Play All'),
                    onPressed: () {
                      player.setQueue(downloadedTracks, initialIndex: 0);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: downloadedTracks.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final track = downloadedTracks[index];

                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.check, color: Colors.white, size: 20),
                    ),
                    title: Text(track.title),
                    subtitle: Text('Local file: ${track.localPath}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      tooltip: 'Delete download',
                      onPressed: () {
                        player.removeDownload(track.id);
                      },
                    ),
                    onTap: () {
                      player.setQueue(downloadedTracks, initialIndex: index);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Tab 3: Android Auto & CarPlay Diagnostics
class AutoDiagnosticsTab extends StatelessWidget {
  const AutoDiagnosticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final player = GtPlayer.instance;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          Row(
            children: [
              Icon(Icons.directions_car_filled_rounded,
                  color: theme.colorScheme.primary, size: 32),
              const SizedBox(width: 12),
              Text(
                'In-Car Media Hierarchy',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This simulates how Android Auto head units and CarPlay display your media tree via MediaBrowserServiceCompat and MPRemoteCommandCenter.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active Automotive Delegate',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 8),
                  const Text('✓ Root: "root"'),
                  const Text('✓ Folders: "folder_queue", "folder_downloads"'),
                  const Text(
                      '✓ Artwork: ContentProvider Uri authority resolved'),
                  const Text(
                      '✓ Voice Search: Google Assistant query mapping enabled'),
                  const Text(
                      '✓ CarPlay Now Playing: MPRemoteCommandCenter enabled'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Live In-Car Folders',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 10),
          ListTile(
            tileColor: theme.colorScheme.surfaceContainerHighest,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.queue_music_rounded),
            title: const Text('Current Queue Folder'),
            subtitle: StreamBuilder<GtQueueState>(
              stream: player.queueStateStream,
              builder: (context, snapshot) {
                final len = snapshot.data?.length ?? 0;
                return Text('$len tracks browsable in car display');
              },
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: theme.colorScheme.surfaceContainerHighest,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.download_for_offline_rounded),
            title: const Text('Downloaded Music Folder'),
            subtitle: StreamBuilder<Map<String, GtDownloadTask>>(
              stream: player.downloadTasksStream,
              builder: (context, snapshot) {
                final count = sampleCatalog
                    .where((t) => player.isDownloaded(t.id))
                    .length;
                return Text('$count offline tracks ready without cell data');
              },
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ),
        ],
      ),
    );
  }
}

/// Full screen player bottom sheet with Waveform & Ambient Glow
class FullPlayerSheet extends StatelessWidget {
  const FullPlayerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final player = GtPlayer.instance;

    return GtPlayerBuilder(
      builder: (context, activePlayer, snapshot) {
        final track = snapshot.currentTrack;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              track?.album ?? 'Now Playing',
              style: theme.textTheme.titleSmall,
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.queue_music_rounded),
                onPressed: () => GtQueueSheet.show(context),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // 1. Dynamic Ambient Artwork with Glow (powered by ambient_backdrop_glow)
                const GtAlbumArtGlow(
                  size: 270,
                  glowIntensity: 0.9,
                  glowSpread: 1.35,
                ),

                const Spacer(flex: 1),

                // 2. Track Title & Artist
                Text(
                  track?.title ?? 'No Track Playing',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  track?.artist ?? 'Unknown Artist',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),

                const Spacer(flex: 1),

                // 3. GPU-Accelerated Interactive Waveform Scrubber (powered by waveform_pro)
                const GtWaveformSeekBar(
                  height: 60,
                  barWidth: 3.5,
                  barSpacing: 2.0,
                ),

                const Spacer(flex: 1),

                // 4. Primary Playback Controls Row
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GtShuffleButton(),
                    GtSkipButton.previous(size: 52, iconSize: 32),
                    GtPlayPauseButton(size: 72, iconSize: 40),
                    GtSkipButton.next(size: 52, iconSize: 32),
                    GtLoopButton(),
                  ],
                ),

                const SizedBox(height: 16),

                // 5. Utility Controls (Speed & Offline status)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const GtSpeedButton(),
                    if (track != null)
                      StreamBuilder<Map<String, GtDownloadTask>>(
                        stream: player.downloadTasksStream,
                        builder: (context, _) {
                          final isDown = player.isDownloaded(track.id);
                          return TextButton.icon(
                            icon: Icon(
                              isDown
                                  ? Icons.check_circle_rounded
                                  : Icons.download_rounded,
                              size: 18,
                              color: isDown ? Colors.greenAccent : null,
                            ),
                            label: Text(isDown ? 'Downloaded' : 'Download'),
                            onPressed: () {
                              if (!isDown) {
                                player.downloadTrack(track);
                              }
                            },
                          );
                        },
                      ),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
