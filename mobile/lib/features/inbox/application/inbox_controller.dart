import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/providers.dart';
import '../../../shared/domain/capture.dart';

final inboxProvider = FutureProvider.autoDispose<List<Capture>>((ref) async {
  final repository = ref.watch(captureRepositoryProvider);
  final subscription = repository.changes.listen((_) => ref.invalidateSelf());
  ref.onDispose(subscription.cancel);
  return repository.inbox();
});

/// Only captures that still want something from the user. Drives the badge on
/// the Inbox tab, which must never show a number for work already done.
final inboxPendingCountProvider = Provider.autoDispose<int>((ref) {
  return ref
      .watch(inboxProvider)
      .maybeWhen(
        data: (captures) => captures
            .where(
              (c) =>
                  c.status == CaptureStatus.needsConfirmation ||
                  c.status.isWorking,
            )
            .length,
        orElse: () => 0,
      );
});

/// The three ways to look at the inbox. Every design offers them; only the
/// poster design shows them as a segmented control at the top, which is why
/// this lives in the controller rather than inside one view.
enum InboxFilter { all, pending, done }

final inboxFilterProvider = StateProvider.autoDispose<InboxFilter>(
  (ref) => InboxFilter.all,
);

extension InboxFiltering on List<Capture> {
  List<Capture> matching(InboxFilter filter) => switch (filter) {
    InboxFilter.all => this,
    InboxFilter.pending => where(
      (c) => c.status == CaptureStatus.needsConfirmation || c.status.isWorking,
    ).toList(),
    InboxFilter.done => where(
      (c) =>
          c.status == CaptureStatus.completed ||
          c.status == CaptureStatus.archived,
    ).toList(),
  };
}
