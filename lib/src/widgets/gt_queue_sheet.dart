import 'package:flutter/material.dart';
import '../core/gt_player.dart';
import '../models/gt_queue_state.dart';

/// Bottom sheet displaying the current playing queue with tap-to-play, reorder, and remove.
class GtQueueSheet extends StatelessWidget {
  const GtQueueSheet({
    super.key,
    this.player,
  });

  final GtPlayer? player;

  /// Shows the queue bottom sheet modally.
  static Future<void> show(BuildContext context, {GtPlayer? player}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (context, scrollController) => GtQueueSheet(player: player),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activePlayer = player ?? GtPlayer.instance;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Playing Queue',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.clear_all_rounded, size: 20),
                  label: const Text('Clear'),
                  onPressed: () => activePlayer.clearQueue(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<GtQueueState>(
              stream: activePlayer.queueStateStream,
              initialData: activePlayer.queueState,
              builder: (context, snapshot) {
                final queueState = snapshot.data ?? activePlayer.queueState;
                final tracks = queueState.queue;

                if (tracks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.queue_music_rounded,
                          size: 48,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Queue is empty',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: tracks.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    final isCurrent = index == queueState.currentIndex;

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: isCurrent
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                        child: isCurrent
                            ? Icon(
                                Icons.graphic_eq_rounded,
                                size: 18,
                                color: theme.colorScheme.primary,
                              )
                            : Text(
                                '${index + 1}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      title: Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCurrent ? theme.colorScheme.primary : null,
                        ),
                      ),
                      subtitle: Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => activePlayer.removeTrackAt(index),
                      ),
                      onTap: () => activePlayer.skipToTrack(index),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
