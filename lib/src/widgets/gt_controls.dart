import 'package:flutter/material.dart';
import '../core/gt_player.dart';
import '../models/gt_playback_state.dart';
import '../models/gt_queue_state.dart';

/// Play/Pause button with automatic loading spinner when buffering or loading.
class GtPlayPauseButton extends StatelessWidget {
  const GtPlayPauseButton({
    super.key,
    this.player,
    this.size = 64.0,
    this.iconSize = 36.0,
    this.backgroundColor,
    this.iconColor,
  });

  final GtPlayer? player;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final activePlayer = player ?? GtPlayer.instance;
    final theme = Theme.of(context);

    return StreamBuilder<GtPlaybackState>(
      stream: activePlayer.playbackStateStream,
      initialData: activePlayer.playbackState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? activePlayer.playbackState;
        final isPlaying = state.isPlaying;
        final isBuffering = state.isBuffering;

        return SizedBox(
          width: size,
          height: size,
          child: Material(
            shape: const CircleBorder(),
            color: backgroundColor ?? theme.colorScheme.primary,
            elevation: 4,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: isBuffering ? null : () => activePlayer.playOrPause(),
              child: Center(
                child: isBuffering
                    ? SizedBox(
                        width: iconSize * 0.7,
                        height: iconSize * 0.7,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: iconColor ?? theme.colorScheme.onPrimary,
                        ),
                      )
                    : Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: iconSize,
                        color: iconColor ?? theme.colorScheme.onPrimary,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Skip to next or previous track button with disabled state when at boundary.
class GtSkipButton extends StatelessWidget {
  const GtSkipButton.next({
    super.key,
    this.player,
    this.size = 48.0,
    this.iconSize = 28.0,
    this.color,
  }) : isNext = true;

  const GtSkipButton.previous({
    super.key,
    this.player,
    this.size = 48.0,
    this.iconSize = 28.0,
    this.color,
  }) : isNext = false;

  final GtPlayer? player;
  final bool isNext;
  final double size;
  final double iconSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final activePlayer = player ?? GtPlayer.instance;
    final theme = Theme.of(context);

    return StreamBuilder<GtQueueState>(
      stream: activePlayer.queueStateStream,
      initialData: activePlayer.queueState,
      builder: (context, snapshot) {
        final queue = snapshot.data ?? activePlayer.queueState;
        final isEnabled = isNext ? queue.hasNext : queue.hasPrevious;
        final iconColor = color ?? theme.colorScheme.onSurface;

        return IconButton(
          iconSize: iconSize,
          icon: Icon(
            isNext ? Icons.skip_next_rounded : Icons.skip_previous_rounded,
          ),
          color: isEnabled ? iconColor : iconColor.withValues(alpha: 0.3),
          onPressed: isEnabled
              ? (isNext
                  ? () => activePlayer.skipToNext()
                  : () => activePlayer.skipToPrevious())
              : null,
        );
      },
    );
  }
}

/// Button to toggle playback speed (1.0x -> 1.25x -> 1.5x -> 2.0x -> 0.75x).
class GtSpeedButton extends StatelessWidget {
  const GtSpeedButton({
    super.key,
    this.player,
    this.color,
  });

  final GtPlayer? player;
  final Color? color;

  static const List<double> _speeds = [1.0, 1.25, 1.5, 2.0, 0.75];

  @override
  Widget build(BuildContext context) {
    final activePlayer = player ?? GtPlayer.instance;
    final theme = Theme.of(context);

    return StreamBuilder<GtPlaybackState>(
      stream: activePlayer.playbackStateStream,
      initialData: activePlayer.playbackState,
      builder: (context, snapshot) {
        final currentSpeed = snapshot.data?.speed ?? 1.0;

        return TextButton(
          onPressed: () {
            final currentIndex = _speeds.indexOf(currentSpeed);
            final nextIndex = (currentIndex + 1) % _speeds.length;
            activePlayer.setSpeed(_speeds[nextIndex]);
          },
          child: Text(
            '${currentSpeed}x',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color ?? theme.colorScheme.primary,
            ),
          ),
        );
      },
    );
  }
}

/// Repeat mode toggle button (Off -> All -> One).
class GtLoopButton extends StatelessWidget {
  const GtLoopButton({
    super.key,
    this.player,
    this.activeColor,
    this.inactiveColor,
  });

  final GtPlayer? player;
  final Color? activeColor;
  final Color? inactiveColor;

  @override
  Widget build(BuildContext context) {
    final activePlayer = player ?? GtPlayer.instance;
    final theme = Theme.of(context);

    return StreamBuilder<GtPlaybackState>(
      stream: activePlayer.playbackStateStream,
      initialData: activePlayer.playbackState,
      builder: (context, snapshot) {
        final loopMode = snapshot.data?.loopMode ?? GtLoopMode.off;

        IconData icon;
        bool isActive = false;
        switch (loopMode) {
          case GtLoopMode.off:
            icon = Icons.repeat_rounded;
            isActive = false;
            break;
          case GtLoopMode.all:
            icon = Icons.repeat_rounded;
            isActive = true;
            break;
          case GtLoopMode.one:
            icon = Icons.repeat_one_rounded;
            isActive = true;
            break;
        }

        return IconButton(
          icon: Icon(icon),
          color: isActive
              ? (activeColor ?? theme.colorScheme.primary)
              : (inactiveColor ??
                  theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          onPressed: () {
            switch (loopMode) {
              case GtLoopMode.off:
                activePlayer.setLoopMode(GtLoopMode.all);
                break;
              case GtLoopMode.all:
                activePlayer.setLoopMode(GtLoopMode.one);
                break;
              case GtLoopMode.one:
                activePlayer.setLoopMode(GtLoopMode.off);
                break;
            }
          },
        );
      },
    );
  }
}

/// Shuffle toggle button.
class GtShuffleButton extends StatelessWidget {
  const GtShuffleButton({
    super.key,
    this.player,
    this.activeColor,
    this.inactiveColor,
  });

  final GtPlayer? player;
  final Color? activeColor;
  final Color? inactiveColor;

  @override
  Widget build(BuildContext context) {
    final activePlayer = player ?? GtPlayer.instance;
    final theme = Theme.of(context);

    return StreamBuilder<GtPlaybackState>(
      stream: activePlayer.playbackStateStream,
      initialData: activePlayer.playbackState,
      builder: (context, snapshot) {
        final isShuffled = snapshot.data?.isShuffled ?? false;

        return IconButton(
          icon: const Icon(Icons.shuffle_rounded),
          color: isShuffled
              ? (activeColor ?? theme.colorScheme.primary)
              : (inactiveColor ??
                  theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          onPressed: () => activePlayer.setShuffle(!isShuffled),
        );
      },
    );
  }
}
