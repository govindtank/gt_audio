import 'package:flutter/material.dart';
import '../core/gt_player.dart';
import '../models/gt_position_state.dart';

/// Interactive slider with buffered progress indicator and timestamps.
class GtSeekBar extends StatefulWidget {
  const GtSeekBar({
    super.key,
    this.player,
    this.activeColor,
    this.bufferedColor,
    this.inactiveColor,
    this.thumbColor,
    this.textStyle,
    this.onSeekStarted,
    this.onSeekEnded,
  });

  final GtPlayer? player;
  final Color? activeColor;
  final Color? bufferedColor;
  final Color? inactiveColor;
  final Color? thumbColor;
  final TextStyle? textStyle;
  final VoidCallback? onSeekStarted;
  final ValueChanged<Duration>? onSeekEnded;

  @override
  State<GtSeekBar> createState() => _GtSeekBarState();
}

class _GtSeekBarState extends State<GtSeekBar> {
  double? _dragValue;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player ?? GtPlayer.instance;
    final theme = Theme.of(context);

    return StreamBuilder<GtPositionState>(
      stream: player.positionStateStream,
      initialData: player.positionState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? const GtPositionState();
        final maxMs = state.duration.inMilliseconds.toDouble();
        final currentMs =
            _dragValue ?? state.position.inMilliseconds.toDouble();
        final clampedMs = maxMs > 0 ? currentMs.clamp(0.0, maxMs) : 0.0;
        final bufferedFraction = state.bufferedProgress;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Inactive + Buffered background bar
                Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: widget.inactiveColor ??
                        theme.colorScheme.onSurface.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: bufferedFraction,
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.bufferedColor ??
                            theme.colorScheme.onSurface.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                // Interactive Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor:
                        widget.activeColor ?? theme.colorScheme.primary,
                    inactiveTrackColor: Colors.transparent,
                    thumbColor: widget.thumbColor ?? theme.colorScheme.primary,
                  ),
                  child: Slider(
                    min: 0.0,
                    max: maxMs > 0 ? maxMs : 1.0,
                    value: clampedMs,
                    onChangeStart: (val) {
                      widget.onSeekStarted?.call();
                    },
                    onChanged: (val) {
                      setState(() {
                        _dragValue = val;
                      });
                    },
                    onChangeEnd: (val) {
                      setState(() {
                        _dragValue = null;
                      });
                      final target = Duration(milliseconds: val.round());
                      player.seek(target);
                      widget.onSeekEnded?.call(target);
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(Duration(milliseconds: clampedMs.round())),
                    style: widget.textStyle ??
                        theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                  Text(
                    _formatDuration(state.duration),
                    style: widget.textStyle ??
                        theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
