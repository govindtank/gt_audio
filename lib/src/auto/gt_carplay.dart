import 'package:flutter/foundation.dart';
import '../models/gt_track.dart';

/// Interface for optional Apple CarPlay template browsing.
///
/// Note: CarPlay Now Playing controls work automatically through iOS
/// `MPRemoteCommandCenter` and `MPNowPlayingInfoCenter` without special configuration.
/// Deep in-car template browsing requires Apple's `com.apple.developer.carplay-audio` entitlement.
abstract class GtCarPlayDelegate {
  /// Called when CarPlay initializes its template hierarchy.
  Future<void> onCarPlayConnected();

  /// Called when CarPlay disconnects.
  Future<void> onCarPlayDisconnected();

  /// Supplies root list items for the CarPlay display.
  Future<List<GtCarPlayItem>> getRootItems();

  /// Called when an item is selected on the car screen.
  Future<void> onItemTapped(GtCarPlayItem item);
}

/// Represents an item displayed on Apple CarPlay templates.
class GtCarPlayItem {
  const GtCarPlayItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUri,
    this.isPlayable = true,
    this.track,
  });

  final String id;
  final String title;
  final String? subtitle;
  final Uri? imageUri;
  final bool isPlayable;
  final GtTrack? track;
}

/// Default no-op CarPlay delegate when template browsing is not configured.
class GtDefaultCarPlayDelegate implements GtCarPlayDelegate {
  @override
  Future<void> onCarPlayConnected() async {
    debugPrint('GtAudio: CarPlay connected.');
  }

  @override
  Future<void> onCarPlayDisconnected() async {
    debugPrint('GtAudio: CarPlay disconnected.');
  }

  @override
  Future<List<GtCarPlayItem>> getRootItems() async => const [];

  @override
  Future<void> onItemTapped(GtCarPlayItem item) async {}
}
