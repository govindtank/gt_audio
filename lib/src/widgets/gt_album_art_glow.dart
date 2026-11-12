import 'dart:io';
import 'package:ambient_backdrop_glow/ambient_backdrop_glow.dart';
import 'package:flutter/material.dart';

import '../core/gt_player.dart';
import '../models/gt_track.dart';

/// Dynamic album artwork card enveloped in ambient mesh glow matching album colors.
class GtAlbumArtGlow extends StatelessWidget {
  const GtAlbumArtGlow({
    super.key,
    this.track,
    this.player,
    this.size = 280.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.glowIntensity = 0.85,
    this.glowSpread = 1.3,
  });

  final GtTrack? track;
  final GtPlayer? player;
  final double size;
  final BorderRadius borderRadius;
  final double glowIntensity;
  final double glowSpread;

  ImageProvider? _resolveImageProvider(Uri? uri) {
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

    return StreamBuilder<GtTrack?>(
      stream: activePlayer.currentTrackStream,
      initialData: track ?? activePlayer.currentTrack,
      builder: (context, snapshot) {
        final current = track ?? snapshot.data;
        final imageProvider = _resolveImageProvider(current?.artUri);

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ambient Backdrop Glow
                if (imageProvider != null)
                  Positioned.fill(
                    child: AmbientBackdropGlow(
                      image: imageProvider,
                      mode: AmbientGlowMode.aurora,
                      style: AmbientGlowStyle(
                        intensity: glowIntensity,
                        spread: glowSpread,
                        blurSigma: 32.0,
                        speed: 0.6,
                      ),
                      borderRadius: borderRadius,
                    ),
                  ),

                // Artwork Card
                Container(
                  width: size * 0.9,
                  height: size * 0.9,
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageProvider != null
                      ? Image(
                          image: imageProvider,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildPlaceholder(context),
                        )
                      : _buildPlaceholder(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: size * 0.35,
          color: theme.colorScheme.primary.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
