import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:waveform_pro/waveform_pro.dart';

import '../core/gt_player.dart';
import '../models/gt_position_state.dart';

/// An interactive, GPU-accelerated audio waveform seek bar powered by `waveform_pro`.
class GtWaveformSeekBar extends StatefulWidget {
  const GtWaveformSeekBar({
    super.key,
    this.player,
    this.waveformData,
    this.height = 64.0,
    this.activeColor,
    this.inactiveColor,
    this.renderMode = WaveformRenderMode.bars,
    this.barWidth = 3.0,
    this.barSpacing = 2.0,
  });

  final GtPlayer? player;
  final WaveformData? waveformData;
  final double height;
  final Color? activeColor;
  final Color? inactiveColor;
  final WaveformRenderMode renderMode;
  final double barWidth;
  final double barSpacing;

  @override
  State<GtWaveformSeekBar> createState() => _GtWaveformSeekBarState();
}

class _GtWaveformSeekBarState extends State<GtWaveformSeekBar> {
  WaveformData? _syntheticData;

  WaveformData _getOrCreateData(Duration duration) {
    if (widget.waveformData != null) {
      return widget.waveformData!;
    }

    final durationSec =
        duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 180.0;
    if (_syntheticData == null ||
        (_syntheticData!.durationSeconds - durationSec).abs() > 1.0) {
      // Synthesize realistic acoustic profile
      const sampleCount = 120;
      final samples = List.generate(sampleCount, (i) {
        final norm = i / sampleCount;
        final wave = 0.3 * math.sin(norm * math.pi * 6) +
            0.2 * math.sin(norm * math.pi * 14) +
            0.15 * math.cos(norm * math.pi * 22) +
            0.35;
        return wave.clamp(0.08, 0.95);
      });
      _syntheticData = WaveformData(
        samples: samples,
        durationSeconds: durationSec,
      );
    }
    return _syntheticData!;
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player ?? GtPlayer.instance;
    final theme = Theme.of(context);

    return StreamBuilder<GtPositionState>(
      stream: player.positionStateStream,
      initialData: player.positionState,
      builder: (context, snapshot) {
        final positionState = snapshot.data ?? const GtPositionState();
        final currentSec = positionState.position.inMilliseconds / 1000.0;
        final data = _getOrCreateData(positionState.duration);

        final playedColor = widget.activeColor ?? theme.colorScheme.primary;
        final unplayedColor = widget.inactiveColor ??
            theme.colorScheme.onSurface.withValues(alpha: 0.2);

        return SizedBox(
          height: widget.height,
          child: WaveformTimeline(
            data: data,
            height: widget.height,
            showTimeRuler: false,
            enableZoom: false,
            enableRegionSelection: false,
            enableMarkers: false,
            playheadPosition: currentSec,
            playheadColor: playedColor,
            style: WaveformStyle(
              renderMode: widget.renderMode,
              barWidth: widget.barWidth,
              barSpacing: widget.barSpacing,
              playedWaveColor: playedColor,
              waveColor: unplayedColor,
              backgroundColor: Colors.transparent,
            ),
            onTap: (timeSeconds) {
              player.seek(Duration(milliseconds: (timeSeconds * 1000).round()));
            },
            onPlayheadChanged: (timeSeconds) {
              player.seek(Duration(milliseconds: (timeSeconds * 1000).round()));
            },
          ),
        );
      },
    );
  }
}
