import 'package:flutter/material.dart';
import '../core/gt_player.dart';
import '../models/gt_playback_state.dart';
import '../models/gt_position_state.dart';
import '../models/gt_queue_state.dart';
import '../models/gt_track.dart';

/// Bundle of reactive audio states passed to [GtPlayerWidgetBuilder].
class GtPlayerStateSnapshot {
  const GtPlayerStateSnapshot({
    required this.playback,
    required this.position,
    required this.queue,
    required this.currentTrack,
  });

  final GtPlaybackState playback;
  final GtPositionState position;
  final GtQueueState queue;
  final GtTrack? currentTrack;
}

typedef GtPlayerWidgetBuilder = Widget Function(
  BuildContext context,
  GtPlayer player,
  GtPlayerStateSnapshot state,
);

/// A reactive widget that rebuilds whenever player state, position, or queue updates.
class GtPlayerBuilder extends StatelessWidget {
  const GtPlayerBuilder({
    super.key,
    required this.builder,
    this.player,
  });

  final GtPlayerWidgetBuilder builder;
  final GtPlayer? player;

  @override
  Widget build(BuildContext context) {
    final activePlayer = player ?? GtPlayer.instance;

    return StreamBuilder<GtPlaybackState>(
      stream: activePlayer.playbackStateStream,
      initialData: activePlayer.playbackState,
      builder: (context, playbackSnap) {
        return StreamBuilder<GtPositionState>(
          stream: activePlayer.positionStateStream,
          initialData: activePlayer.positionState,
          builder: (context, positionSnap) {
            return StreamBuilder<GtQueueState>(
              stream: activePlayer.queueStateStream,
              initialData: activePlayer.queueState,
              builder: (context, queueSnap) {
                return StreamBuilder<GtTrack?>(
                  stream: activePlayer.currentTrackStream,
                  initialData: activePlayer.currentTrack,
                  builder: (context, trackSnap) {
                    final snapshot = GtPlayerStateSnapshot(
                      playback: playbackSnap.data ?? activePlayer.playbackState,
                      position: positionSnap.data ?? activePlayer.positionState,
                      queue: queueSnap.data ?? activePlayer.queueState,
                      currentTrack: trackSnap.data ?? activePlayer.currentTrack,
                    );
                    return builder(context, activePlayer, snapshot);
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
