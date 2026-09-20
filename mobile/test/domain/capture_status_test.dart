import 'package:flutter_test/flutter_test.dart';
import 'package:relya/shared/domain/capture.dart';

/// Which rows in the Inbox lead somewhere.
///
/// This was a real dead end rather than a theoretical one: the Inbox opened
/// only needs_confirmation, so a forwarded email - which arrives queued,
/// created on the server, never analysed by any device - sat in the list
/// forever and could not be tapped. A failed capture was stuck the same way,
/// even though the screen it would have opened has always had a retry.
void main() {
  test('a capture with work left can be opened', () {
    expect(CaptureStatus.needsConfirmation.opensConfirmation, isTrue);
    // The forwarded email.
    expect(CaptureStatus.queued.opensConfirmation, isTrue);
    // The retry.
    expect(CaptureStatus.failed.opensConfirmation, isTrue);
  });

  test('a capture with nothing left to ask does not', () {
    expect(CaptureStatus.completed.opensConfirmation, isFalse);
    expect(CaptureStatus.archived.opensConfirmation, isFalse);
  });

  test('a capture already being worked on is left alone', () {
    // Opening this would start a second analysis of the same file, and pay
    // for it twice.
    expect(CaptureStatus.processing.opensConfirmation, isFalse);
  });

  test('every status answers, so a new one cannot be forgotten', () {
    for (final status in CaptureStatus.values) {
      expect(status.opensConfirmation, isA<bool>());
    }
  });

  group('the wire format is the contract with Postgres', () {
    test('every status round-trips through its wire value', () {
      for (final status in CaptureStatus.values) {
        expect(CaptureStatus.fromWire(status.wire), status);
      }
    });

    test('an unknown status is treated as queued, not dropped', () {
      // A row written by a newer build must not vanish from the Inbox.
      expect(CaptureStatus.fromWire('something_new'), CaptureStatus.queued);
      expect(CaptureStatus.fromWire(null), CaptureStatus.queued);
    });
  });
}
