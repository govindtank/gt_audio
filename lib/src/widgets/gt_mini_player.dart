import 'dart:io';
import 'package:flutter/material.dart';
import '../core/gt_player.dart';
import '../models/gt_position_state.dart';
import '../models/gt_track.dart';
import 'gt_controls.dart';

/// Drop-in bottom mini-player bar showing active track, top progress bar, and playback controls.
class GtMiniPlayer extends StatelessWidget {
  const GtMiniPlayer({
    super.key,
    this.player,
    this.onTap,
    this.height = 68.0,
    this.backgroundColor,
  });

  final GtPlayer? player;
  final VoidCallback? onTap;
  final double height;
  final Color? backgroundColor;

  ImageProvider? _resolveImage(Uri? uri) {
    if (uri == null) return null;
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return NetworkImage(uri.toString());
    }
    if (uri.scheme == 'file') {
      return FileImage(File(uri.toFilePath()));
    }
    return AssetImage(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final activePlayer = player ?? GtPlayer.instance;
    final theme = Theme.of(context);

    return StreamBuilder<GtTrack?>(
      stream: activePlayer.currentTrackStream,
      initialData: activePlayer.currentTrack,
      builder: (context, trackSnap) {
        final track = trackSnap.data;
        if (track == null) return const SizedBox.shrink();

        final image = _resolveImage(track.artUri);

        return Material(
          color: backgroundColor ?? theme.colorScheme.surfaceContainerHigh,
          elevation: 8,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: height,
              child: Stack(
                children: [
                  // Progress line at top
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: StreamBuilder<GtPositionState>(
                      stream: activePlayer.positionStateStream,
                      initialData: activePlayer.positionState,
                      builder: (context, posSnap) {
                        final progress = posSnap.data?.progress ?? 0.0;
                        return LinearProgressIndicator(
                          value: progress,
                          minHeight: 2.5,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation(
                            theme.colorScheme.primary,
                          ),
                        );
                      },
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Artwork Thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 48,
                            height: 48,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: image != null
                                ? Image(
                                    image: image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.music_note_rounded,
                                      size: 24,
                                    ),
                                  )
                                : const Icon(
                                    Icons.music_note_rounded,
                                    size: 24,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title & Artist
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                track.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Controls
                        GtPlayPauseButton(
                          player: activePlayer,
                          size: 42,
                          iconSize: 24,
                        ),
                        const SizedBox(width: 4),
                        GtSkipButton.next(
                          player: activePlayer,
                          size: 40,
                          iconSize: 24,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
