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
import '../../../shared/widgets/place_field.dart';

/// The escape hatch. Rarely the main path, but an assistant that cannot be
/// told something directly is not an assistant.
class ManualEntryScreen extends ConsumerStatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  final _amount = TextEditingController();
  final _currency = TextEditingController();
  final _location = TextEditingController();
  final _organization = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  LifeItemType _type = LifeItemType.task;

  /// Everything past the title, the kind and the date starts folded away.
  ///
  /// The edit screen has always offered the amount, the place and who it was
  /// with; this screen offered none of them, so adding something by hand and
  /// then giving it a price meant saving it and opening it again. The fields
  /// are the same fields now. What is different is that only the title is
  /// required - the rest is there when it is wanted and out of the way when
  /// it is not.
  bool _showMore = false;

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
    _notes.dispose();
    _amount.dispose();
    _currency.dispose();
    _location.dispose();
    _organization.dispose();
    super.dispose();
  }

  num? _parseAmount() {
    final raw = _amount.text.trim().replaceAll(',', '.');
    return raw.isEmpty ? null : num.tryParse(raw);
  }

  String? _trimmed(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
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
              description: _trimmed(_notes),
              status: LifeItemStatus.active,
              startAt: _when.toUtc(),
              startTimezone: DateTime.now().timeZoneName,
              amount: _parseAmount(),
              currency: _trimmed(_currency)?.toUpperCase(),
              location: _trimmed(_location),
              organization: _trimmed(_organization),
              // Typed by a person, not read by a model. Nothing downstream
              // should ever ask them to check it.
              confidence: 1,
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
              decoration: InputDecoration(labelText: l10n.itemTitleField),
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
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => setState(() => _showMore = !_showMore),
                icon: Icon(
                  _showMore
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 20,
                ),
                label: Text(l10n.manualMoreDetails),
              ),
            ),
            if (_showMore) ...[
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _notes,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.itemNotes),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(labelText: l10n.itemAmount),
                      validator: (value) {
                        final raw = (value ?? '').trim().replaceAll(',', '.');
                        if (raw.isEmpty) return null;
                        return num.tryParse(raw) == null
                            ? l10n.errorAmount
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _currency,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 3,
                      decoration: InputDecoration(
                        labelText: l10n.itemCurrency,
                        counterText: '',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              PlaceField(
                controller: _location,
                label: l10n.itemWhere,
                icon: Icons.place_outlined,
              ),
              const SizedBox(height: AppSpacing.lg),
              PlaceField(
                controller: _organization,
                label: l10n.itemOrganisation,
                icon: Icons.storefront_outlined,
              ),
            ],
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
