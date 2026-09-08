import '../../domain/extraction.dart';
import '../../domain/extraction_result.dart';
import '../../domain/life_item_type.dart';

/// The demo used by onboarding and by the empty-state "Try an example" button
/// (spec sections 63 and 64). It reproduces the ten-second experience from
/// section 58 without asking anyone to hand over a real document first.
abstract final class DemoAnalysis {
  const DemoAnalysis._();

  static const String sampleText =
      'Ola Joao, confirmamos a sua consulta de dentista no dia 17 de setembro '
      'as 15:30 na Clinica Central. O pagamento de 49,99 EUR vence a 20 de '
      'setembro. Prazo de devolucao ate 25 de setembro.';

  static AnalysisResult build(DateTime now) {
    DateTime at(int days, int hour, int minute) {
      final base = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: days));
      return DateTime(base.year, base.month, base.day, hour, minute).toUtc();
    }

    return AnalysisResult(
      captureId: 'cap-demo',
      detectedLanguage: 'pt',
      modelUsed: 'demo',
      processingMillis: 1800,
      items: [
        ExtractionResult(
          id: 'demo-appointment',
          type: LifeItemType.appointment,
          title: 'Dentist appointment',
          summary: 'Clinica Central',
          sourceLanguage: 'pt',
          confidence: 0.96,
          actionRequired: true,
          location: 'Clinica Central',
          organization: 'Clinica Central',
          dates: [
            ExtractedDate(
              raw: '17 de setembro as 15:30',
              kind: ExtractedDateKind.start,
              resolved: at(14, 15, 30),
              timezone: 'Europe/Lisbon',
              hasTime: true,
              confidence: 0.96,
            ),
          ],
          suggestedReminders: const [
            SuggestedReminder(
              label: '1 day before',
              leadSeconds: 86400,
              anchor: 'start',
            ),
            SuggestedReminder(
              label: '2 hours before',
              leadSeconds: 7200,
              anchor: 'start',
            ),
          ],
          suggestedActions: const [
            SuggestedAction(
              type: SuggestedActionType.addToCalendar,
              label: 'Add to calendar',
            ),
          ],
        ),
        ExtractionResult(
          id: 'demo-payment',
          type: LifeItemType.bill,
          title: 'Payment due',
          sourceLanguage: 'pt',
          confidence: 0.89,
          actionRequired: true,
          amount: 49.99,
          currency: 'EUR',
          dates: [
            ExtractedDate(
              raw: '20 de setembro',
              kind: ExtractedDateKind.deadline,
              resolved: at(17, 9, 0),
              timezone: 'Europe/Lisbon',
              confidence: 0.89,
            ),
          ],
          suggestedReminders: const [
            SuggestedReminder(
              label: '1 day before',
              leadSeconds: 86400,
              anchor: 'deadline',
            ),
          ],
          suggestedActions: const [
            SuggestedAction(
              type: SuggestedActionType.trackPayment,
              label: 'Track this payment',
            ),
          ],
        ),
        ExtractionResult(
          id: 'demo-return',
          type: LifeItemType.returnDeadline,
          title: 'Return deadline',
          sourceLanguage: 'pt',
          confidence: 0.72,
          actionRequired: true,
          unresolvedNote: 'I could not confirm which purchase this refers to.',
          dates: [
            ExtractedDate(
              raw: '25 de setembro',
              kind: ExtractedDateKind.deadline,
              resolved: at(22, 23, 59),
              timezone: 'Europe/Lisbon',
              confidence: 0.72,
            ),
          ],
          suggestedReminders: const [
            SuggestedReminder(
              label: '7 days before',
              leadSeconds: 604800,
              anchor: 'deadline',
            ),
            SuggestedReminder(
              label: '1 day before',
              leadSeconds: 86400,
              anchor: 'deadline',
              enabledByDefault: false,
            ),
          ],
        ),
      ],
    );
  }
}
