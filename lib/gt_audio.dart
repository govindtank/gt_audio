/// A production-ready, unified Flutter audio package with streaming, offline downloads,
/// background playback, lock screen controls, waveform scrubbing, Android Auto, and CarPlay.
library;

// Re-exports from audio_service needed by host apps
export 'package:audio_service/audio_service.dart'
    show MediaItem, MediaControl, AudioProcessingState;

// Automotive
export 'src/auto/gt_android_auto.dart';
export 'src/auto/gt_carplay.dart';

// Core
export 'src/core/gt_audio_handler.dart';
export 'src/core/gt_config.dart';
export 'src/core/gt_network_guard.dart';
export 'src/core/gt_player.dart';
export 'src/core/gt_session_manager.dart';

// Models
export 'src/models/gt_audio_error.dart';
export 'src/models/gt_download_state.dart';
export 'src/models/gt_playback_state.dart';
export 'src/models/gt_position_state.dart';
export 'src/models/gt_queue_state.dart';
export 'src/models/gt_track.dart';

// Storage
export 'src/storage/gt_cache_manager.dart';
export 'src/storage/gt_download_manager.dart';
export 'src/storage/gt_state_persistence.dart';

// Utils
export 'src/utils/gt_asset_resolver.dart';

// Widgets
export 'src/widgets/gt_album_art_glow.dart';
export 'src/widgets/gt_controls.dart';
export 'src/widgets/gt_mini_player.dart';
export 'src/widgets/gt_player_builder.dart';
export 'src/widgets/gt_queue_sheet.dart';
export 'src/widgets/gt_seek_bar.dart';
export 'src/widgets/gt_waveform_seek_bar.dart';
