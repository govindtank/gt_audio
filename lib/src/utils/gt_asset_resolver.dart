import 'dart:io' show Platform;
import 'package:flutter/services.dart';

/// Resolves artwork URIs to content URIs on Android for automotive & notification display.
class GtAssetResolver {
  GtAssetResolver._();

  static const MethodChannel _channel =
      MethodChannel('com.govindtank.gt_audio/channel');

  static String? _cachedAuthority;

  /// Retrieves the Android ContentProvider authority at runtime.
  static Future<String?> getAuthority() async {
    if (!Platform.isAndroid) return null;
    if (_cachedAuthority != null) return _cachedAuthority;

    try {
      final res = await _channel.invokeMethod<String>('getArtworkAuthority');
      _cachedAuthority = res;
      return res;
    } catch (_) {
      return null;
    }
  }

  /// Resolves an artwork URI for system media notifications and Android Auto.
  static Future<Uri?> resolveArtworkUri(Uri? artUri) async {
    if (artUri == null) return null;
    if (!Platform.isAndroid) return artUri;

    // Web URLs are handled directly by system image loaders
    if (artUri.scheme == 'http' || artUri.scheme == 'https') {
      return artUri;
    }

    final authority = await getAuthority();
    if (authority == null || authority.isEmpty) {
      return artUri;
    }

    if (artUri.scheme == 'file') {
      final path = artUri.path.replaceFirst(RegExp(r'^/'), '');
      return Uri.parse('content://$authority/$path');
    }

    return artUri;
  }
}
