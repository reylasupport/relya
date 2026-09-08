import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/formatting/app_date_format.dart';
import '../../../core/ids/ids.dart';
import '../../../core/logging/app_logger.dart';
import '../../../shared/data/providers.dart';
import '../../../shared/domain/life_item.dart';
import '../../../shared/domain/life_item_status.dart';
import '../../../shared/domain/life_item_type.dart';
import '../../../shared/widgets/category_label.dart';

/// The escape hatch. Rarely the main path, but an assistant that cannot be
/// told something directly is not an assistant.
class ManualEntryScreen extends ConsumerStatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  final _title = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  LifeItemType _type = LifeItemType.task;

  /// Today, not null. The button under the form has always read "Today", and
  /// an item saved with no date at all is dropped by every list on the way
  /// back: the user taps Save, the screen closes, and nothing appears.
  DateTime _when = _todayAtNine();
  bool _busy = false;

  static DateTime _todayAtNine() {
    final now = DateTime.now();
    // The same hour the time picker falls back to when it is skipped.
    return DateTime(now.year, now.month, now.day, 9);
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (!mounted) return;
    setState(() {
      _when = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 9,
        time?.minute ?? 0,
      );
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.l10n.errorGeneric;
    try {
      final now = DateTime.now().toUtc();
      await ref
          .read(lifeItemRepositoryProvider)
          .create(
            LifeItem(
              id: newId(),
              type: _type,
              title: _title.text.trim(),
              status: LifeItemStatus.active,
              startAt: _when.toUtc(),
              startTimezone: DateTime.now().timeZoneName,
              createdAt: now,
            ),
          );
      router.pop();
    } catch (error, stack) {
      // Without this the screen simply sat there on a failed write, which is
      // the one thing a save button must never do.
      AppLogger.error('Could not save a manual item', error, stack);
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.captureManual)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pageInset),
          children: [
            TextFormField(
              controller: _title,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Title'),
              // An empty string here failed the form with no visible reason,
              // so Save looked broken rather than refused.
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.errorTitleRequired
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<LifeItemType>(
              initialValue: _type,
              items: [
                for (final type in LifeItemType.values)
                  DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(type.icon, size: 18),
                        const SizedBox(width: AppSpacing.md),
                        Text(categoryLabel(context, type)),
                      ],
                    ),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => _type = value ?? LifeItemType.task),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.schedule_rounded, size: 18),
              label: Text(AppDateFormat.dateAndTime(_when, context.localeTag)),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(l10n.actionSave),
            ),
          ],
        ),
      ),
    );
  }
}
