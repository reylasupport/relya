import 'package:flutter/widgets.dart';

import '../../core/extensions/context_extensions.dart';
import '../domain/recurrence.dart';

/// The word for a frequency, in the interface language.
///
/// Shared rather than local to a screen: the edit form, the item detail and
/// the quick-add sheet all say the same thing, and they live in different
/// features.
String recurrenceFrequencyLabel(
  BuildContext context,
  RecurrenceFrequency frequency,
) => switch (frequency) {
  RecurrenceFrequency.daily => context.l10n.recurrenceDaily,
  RecurrenceFrequency.weekly => context.l10n.recurrenceWeekly,
  RecurrenceFrequency.monthly => context.l10n.recurrenceMonthly,
  RecurrenceFrequency.yearly => context.l10n.recurrenceYearly,
};
