import 'dart:async';
import 'dart:io';

/// Handles network stream dropouts and backoff retry logic.
class GtNetworkGuard {
  GtNetworkGuard({this.maxRetries = 3});

  final int maxRetries;
  int _currentRetry = 0;

  /// Checks if an exception represents a recoverable network issue.
  bool isRecoverable(dynamic error) {
    if (error == null) return false;
    final str = error.toString().toLowerCase();
    return str.contains('socketexception') ||
        str.contains('connection closed') ||
        str.contains('connection refused') ||
        str.contains('connection timed out') ||
        str.contains('handshakeexception') ||
        str.contains('httpexception') ||
        str.contains('network is unreachable') ||
        error is SocketException ||
        error is HttpException;
  }

  /// Executes [action] with retry backoff if a network error occurs.
  Future<T> executeWithRetry<T>(
    Future<T> Function() action, {
    void Function(int attempt, dynamic error)? onRetry,
  }) async {
    _currentRetry = 0;
    while (true) {
      try {
        return await action();
      } catch (error) {
        if (!isRecoverable(error) || _currentRetry >= maxRetries) {
          rethrow;
        }

        _currentRetry++;
        final backoffMs = 500 * (1 << (_currentRetry - 1));
        onRetry?.call(_currentRetry, error);

        await Future.delayed(Duration(milliseconds: backoffMs));
      }
    }
  }

  /// Resets retry counter.
  void reset() {
    _currentRetry = 0;
  }
}
