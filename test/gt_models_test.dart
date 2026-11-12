import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_audio/gt_audio.dart';

void main() {
  group('GtPositionState Tests', () {
    test('calculates normalized progress and remaining time correctly', () {
      const state = GtPositionState(
        position: Duration(seconds: 30),
        duration: Duration(seconds: 120),
        bufferedPosition: Duration(seconds: 60),
      );

      expect(state.progress, closeTo(0.25, 0.001));
      expect(state.bufferedProgress, closeTo(0.5, 0.001));
      expect(state.remaining, equals(const Duration(seconds: 90)));
    });

    test('handles zero duration gracefully without dividing by zero', () {
      const state = GtPositionState();
      expect(state.progress, 0.0);
      expect(state.bufferedProgress, 0.0);
      expect(state.remaining, Duration.zero);
    });
  });

  group('GtQueueState Tests', () {
    final tracks = [
      GtTrack(id: '1', title: 'Song 1', audioUri: Uri.parse('https://a.com')),
      GtTrack(id: '2', title: 'Song 2', audioUri: Uri.parse('https://b.com')),
      GtTrack(id: '3', title: 'Song 3', audioUri: Uri.parse('https://c.com')),
    ];

    test('detects hasNext and hasPrevious boundaries', () {
      final q0 = GtQueueState(queue: tracks, currentIndex: 0);
      expect(q0.hasPrevious, false);
      expect(q0.hasNext, true);
      expect(q0.currentTrack?.title, 'Song 1');

      final q1 = GtQueueState(queue: tracks, currentIndex: 1);
      expect(q1.hasPrevious, true);
      expect(q1.hasNext, true);
      expect(q1.currentTrack?.title, 'Song 2');

      final q2 = GtQueueState(queue: tracks, currentIndex: 2);
      expect(q2.hasPrevious, true);
      expect(q2.hasNext, false);
      expect(q2.currentTrack?.title, 'Song 3');
    });

    test('handles empty queue', () {
      const q = GtQueueState();
      expect(q.isEmpty, true);
      expect(q.currentTrack, isNull);
      expect(q.hasNext, false);
      expect(q.hasPrevious, false);
    });
  });

  group('GtNetworkGuard Tests', () {
    test('retries on recoverable socket errors and succeeds', () async {
      final guard = GtNetworkGuard(maxRetries: 3);
      int attempts = 0;

      final result = await guard.executeWithRetry(() async {
        attempts++;
        if (attempts < 3) {
          throw const SocketException('Connection reset by peer');
        }
        return 'success';
      });

      expect(result, 'success');
      expect(attempts, 3);
    });

    test('fails immediately on non-recoverable error', () async {
      final guard = GtNetworkGuard(maxRetries: 3);
      int attempts = 0;

      expect(
        () => guard.executeWithRetry(() async {
          attempts++;
          throw ArgumentError('Invalid argument');
        }),
        throwsA(isA<ArgumentError>()),
      );

      expect(attempts, 1);
    });
  });
}
