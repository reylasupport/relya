import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/data/providers.dart';
import 'capture_outbox.dart';

final captureOutboxProvider = Provider<CaptureOutbox>((ref) => CaptureOutbox());

/// How many captures are waiting for a network.
///
/// A number rather than a list: the user needs to know nothing was lost, not
/// to manage a queue. Refreshed by the drainer below and after every park.
class OutboxCountController extends StateNotifier<int> {
  OutboxCountController(this._ref) : super(0) {
    refresh();
  }

  final Ref _ref;

  Future<void> refresh() async {
    final count = await _ref.read(captureOutboxProvider).count();
    if (mounted) state = count;
  }
}

final outboxCountProvider = StateNotifierProvider<OutboxCountController, int>(
  OutboxCountController.new,
);

/// Empties the outbox whenever the phone gets a connection back.
///
/// Kept alive for the life of the app rather than tied to a screen: the whole
/// point is that it works while the user is looking at something else, or at
/// nothing at all.
class OutboxDrainer {
  OutboxDrainer(this._ref);

  final Ref _ref;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _draining = false;

  void start() {
    if (!CaptureOutbox.supported) return;
    // One attempt at boot, for a capture parked before the app was killed.
    unawaited(drain());
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) unawaited(drain());
    });
  }

  Future<void> drain() async {
    // Overlapping drains would upload the same entry twice.
    if (_draining) return;
    _draining = true;
    try {
      final sent = await _ref
          .read(captureOutboxProvider)
          .flush(_ref.read(captureRepositoryProvider));
      if (sent > 0) await _ref.read(outboxCountProvider.notifier).refresh();
    } finally {
      _draining = false;
    }
  }

  void dispose() => _subscription?.cancel();
}

final outboxDrainerProvider = Provider<OutboxDrainer>((ref) {
  final drainer = OutboxDrainer(ref);
  ref.onDispose(drainer.dispose);
  return drainer;
});
