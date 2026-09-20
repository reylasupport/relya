import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:relya/core/errors/app_exception.dart';
import 'package:relya/shared/data/supabase/supabase_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// What the user is told when the backend says no.
///
/// The Supabase implementations are the code that actually runs in a shipped
/// build - `USE_MOCK_DATA` means every other test exercises the fixtures
/// instead - and they were at zero coverage. The query builders are not worth
/// faking; this is the part that decides between "you have used this month's
/// allowance" and "something went wrong", which is worth pinning down exactly.
void main() {
  group('a spent allowance is not a failure', () {
    test(
      '429 from an edge function becomes a quota error, with its own copy',
      () {
        final mapped = SupabaseErrors.fromFunction(
          const FunctionException(status: 429),
          quotaMessage: 'Monthly capture limit reached',
        );

        expect(mapped, isA<QuotaExceeded>());
        expect(mapped.message, 'Monthly capture limit reached');
      },
    );

    test('the same status means a different thing to a different caller', () {
      final assistant = SupabaseErrors.fromFunction(
        const FunctionException(status: 429),
        quotaMessage: 'Daily assistant limit reached',
      );

      expect(assistant.message, 'Daily assistant limit reached');
    });

    test('every other status is a plain failure, never a quota one', () {
      for (final status in [400, 401, 404, 422, 500, 502, 503]) {
        final mapped = SupabaseErrors.fromFunction(
          FunctionException(status: status),
          quotaMessage: 'Monthly capture limit reached',
        );
        expect(
          mapped,
          isNot(isA<QuotaExceeded>()),
          reason: 'HTTP $status is not an allowance being spent',
        );
      }
    });
  });

  group('everything else keeps its meaning', () {
    test('a dropped connection is a network error, not an unknown one', () {
      expect(
        SupabaseErrors.fromAny(const SocketException('no route to host')),
        isA<NetworkException>(),
      );
      expect(
        SupabaseErrors.fromAny(TimeoutException('took too long')),
        isA<NetworkException>(),
      );
    });

    test(
      'an auth failure carries its message, which is written for people',
      () {
        final mapped = SupabaseErrors.fromAny(
          const AuthException('Invalid login credentials'),
        );

        expect(mapped, isA<AuthFailure>());
        expect(mapped.message, 'Invalid login credentials');
      },
    );

    test('a storage failure stays a storage failure', () {
      final mapped = SupabaseErrors.fromAny(
        const StorageException('object not found'),
      );

      expect(mapped, isA<StorageFailure>());
    });

    test('a Postgres error never reaches the screen verbatim', () {
      final mapped = SupabaseErrors.fromAny(
        const PostgrestException(
          message:
              'new row violates row-level security policy for table '
              '"life_items"',
        ),
      );

      // Column names, table names and constraints tell the user nothing and
      // tell somebody else too much.
      expect(mapped, isA<UnexpectedFailure>());
      expect(mapped.message, 'Request failed');
      expect(mapped.message, isNot(contains('life_items')));
    });

    test('an AppException is passed through rather than wrapped twice', () {
      const original = QuotaExceeded('Monthly capture limit reached');

      expect(SupabaseErrors.fromAny(original), same(original));
    });

    test('anything unrecognised still arrives as something sayable', () {
      final mapped = SupabaseErrors.fromAny(StateError('no signed-in user'));

      expect(mapped, isA<UnexpectedFailure>());
      expect(mapped.message, 'Request failed');
    });
  });
}
