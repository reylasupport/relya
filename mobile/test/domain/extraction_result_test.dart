import 'package:flutter_test/flutter_test.dart';
import 'package:relya/shared/domain/extraction.dart';
import 'package:relya/shared/domain/extraction_result.dart';
import 'package:relya/shared/domain/life_item_type.dart';

void main() {
  group('ExtractionResult', () {
    test('decodes the schema from the analyse function', () {
      final result = ExtractionResult.fromJson({
        'id': 'x1',
        'category': 'appointment',
        'title': 'Dentist',
        'confidence': 0.94,
        'action_required': true,
        'dates': [
          {
            'raw': '17 de setembro as 15:30',
            'kind': 'start',
            'resolved': '2026-09-17T14:30:00Z',
            'timezone': 'Europe/Lisbon',
            'has_time': true,
          },
        ],
        'suggested_reminders': [
          {'label': '1 day before', 'lead_seconds': 86400, 'anchor': 'start'},
        ],
        'sensitivity': 'personal',
      });

      expect(result.type, LifeItemType.appointment);
      expect(result.startAt, DateTime.utc(2026, 9, 17, 14, 30));
      expect(result.sensitivity, Sensitivity.personal);
      expect(result.suggestedReminders.single.leadTime.inHours, 24);
    });

    test('the saved item gets a UUID, not the id from the payload', () {
      // The analyse function names extractions "<capture id>-<n>". Every id
      // column in the schema is uuid, so reusing that name made every insert
      // fail with a type error and left the Add button looking dead.
      const result = ExtractionResult(
        id: 'a3f2b1c0-0000-4000-8000-000000000000-0',
        type: LifeItemType.appointment,
        title: 'Dentist',
        confidence: 0.9,
      );

      final item = result.toLifeItem(
        captureId: 'a3f2b1c0-0000-4000-8000-000000000000',
        now: DateTime.utc(2026),
      );

      expect(item.id, isNot(result.id));
      expect(item.id, matches(_uuidV4));
    });

    test('an unknown category degrades to other instead of throwing', () {
      final result = ExtractionResult.fromJson({
        'id': 'x2',
        'category': 'something_the_server_learned_later',
        'title': 'New thing',
        'confidence': 0.9,
      });
      expect(result.type, LifeItemType.other);
    });

    test('flags anything the user must look at', () {
      const low = ExtractionResult(
        id: 'x3',
        type: LifeItemType.bill,
        title: 'Bill',
        confidence: 0.4,
      );
      expect(low.needsUserAttention, isTrue);

      const ambiguous = ExtractionResult(
        id: 'x4',
        type: LifeItemType.bill,
        title: 'Bill',
        confidence: 0.99,
        dates: [
          ExtractedDate(
            raw: '04/05',
            kind: ExtractedDateKind.deadline,
            ambiguous: true,
          ),
        ],
      );
      expect(ambiguous.needsUserAttention, isTrue);

      const clear = ExtractionResult(
        id: 'x5',
        type: LifeItemType.bill,
        title: 'Bill',
        confidence: 0.95,
      );
      expect(clear.needsUserAttention, isFalse);
    });
  });
}

final RegExp _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);
