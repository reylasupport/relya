import 'package:flutter_test/flutter_test.dart';
import 'package:relya/features/capture/domain/place_suggestions.dart';

/// Suggestions that help and never insist.
///
/// The rule the whole thing is built around: whatever somebody types is the
/// answer. A restaurant the app has never heard of has to be exactly as easy
/// to enter as one it offers, so these tests are mostly about what the list
/// does *not* do.
void main() {
  const known = [
    'Cervejaria Ramiro',
    'Netflix',
    'Continente',
    'Cafe Central',
    'Clinica Central',
  ];

  test('nothing is offered until there is something to go on', () {
    // A dropdown of every brand the app knows, the moment a field is touched,
    // is noise wearing the clothes of help.
    expect(matchingPlaces(known, ''), isEmpty);
    expect(matchingPlaces(known, 'C'), isEmpty);
  });

  test('a name that starts with what was typed comes first', () {
    final matches = matchingPlaces(known, 'cer');

    expect(matches.first, 'Cervejaria Ramiro');
  });

  test('a match in the middle still counts, but ranks below', () {
    final matches = matchingPlaces(known, 'central');

    expect(matches, containsAll(['Cafe Central', 'Clinica Central']));
  });

  test('typing is not case work', () {
    expect(matchingPlaces(known, 'NETFLIX'), isEmpty);
    expect(matchingPlaces(known, 'netfl'), contains('Netflix'));
  });

  test('a name already typed in full is not offered back', () {
    // Finishing a word and being shown that word is a dropdown covering the
    // Save button for nothing.
    expect(matchingPlaces(known, 'Netflix'), isEmpty);
  });

  test('a place nobody has heard of simply has no suggestions', () {
    // Not an error, not a warning, not a "create new" row. The field already
    // holds the answer.
    expect(matchingPlaces(known, 'Tasca do Ze'), isEmpty);
  });

  test('the list stays short enough to sit above a keyboard', () {
    final many = List.generate(40, (i) => 'Cafe number $i');

    expect(matchingPlaces(many, 'cafe').length, lessThanOrEqualTo(6));
  });
}
