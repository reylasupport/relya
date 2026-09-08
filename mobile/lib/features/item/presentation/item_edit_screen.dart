import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/components/empty_state.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/formatting/app_date_format.dart';
import '../../../core/logging/app_logger.dart';
import '../../../shared/data/providers.dart';
import '../../../shared/domain/life_item.dart';
import '../../../shared/domain/life_item_type.dart';
import '../../../shared/domain/recurrence.dart';
import '../../../shared/widgets/recurrence_label.dart';
import '../../../shared/widgets/category_label.dart';
import '../application/item_actions.dart';

final _editableProvider = FutureProvider.autoDispose.family(
  (ref, String id) => ref.watch(lifeItemRepositoryProvider).byId(id),
);

/// Correcting something the app already saved.
///
/// The confirmation screen catches most mistakes, but not the ones the user
/// only notices a week later: a wrong amount, a moved appointment, a title
/// that made sense inside the receipt and nowhere else.
class ItemEditScreen extends ConsumerWidget {
  const ItemEditScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(_editableProvider(itemId));

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.itemEditTitle)),
      body: item.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: context.l10n.errorGeneric,
          message: error.toString(),
        ),
        data: (value) => value == null
            ? EmptyState(
                icon: Icons.help_outline_rounded,
                title: context.l10n.errorGeneric,
                message: context.l10n.searchEmptyMessage,
              )
            : _Form(original: value),
      ),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.original});

  final LifeItem original;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _amount;
  late final TextEditingController _currency;
  late final TextEditingController _location;
  late final TextEditingController _organization;

  late LifeItemType _type;
  late DateTime? _start;
  late DateTime? _deadline;
  late bool _allDay;
  late RecurrenceFrequency? _repeats;
  late int _interval;

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final item = widget.original;
    _title = TextEditingController(text: item.title);
    _description = TextEditingController(text: item.description ?? '');
    _amount = TextEditingController(text: item.amount?.toString() ?? '');
    _currency = TextEditingController(text: item.currency ?? '');
    _location = TextEditingController(text: item.location ?? '');
    _organization = TextEditingController(text: item.organization ?? '');
    _type = item.type;
    _start = item.startAt?.toLocal();
    _deadline = item.deadlineAt?.toLocal();
    _allDay = item.allDay;
    _repeats = item.recurrence?.frequency;
    _interval = item.recurrence?.interval ?? 1;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _amount.dispose();
    _currency.dispose();
    _location.dispose();
    _organization.dispose();
    super.dispose();
  }

  bool get _hasDate => _start != null || _deadline != null;

  Future<DateTime?> _pick(DateTime? current, {required bool withTime}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 20),
    );
    if (date == null || !mounted) return null;
    if (!withTime) return DateTime(date.year, date.month, date.day);

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current ?? now),
    );
    return DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? 9,
      time?.minute ?? 0,
    );
  }

  num? _parseAmount() {
    final raw = _amount.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    return num.tryParse(raw);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);
    // The schema refuses a repeating item with nothing to repeat from, and it
    // is right to: with no date there is no next occurrence to compute.
    if (_repeats != null && !_hasDate) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.recurrenceNeedsDate)),
      );
      return;
    }

    setState(() => _busy = true);
    final router = GoRouter.of(context);
    final saved = context.l10n.itemSaved;
    final failed = context.l10n.errorGeneric;

    final original = widget.original;
    final edited = original.copyWith(
      title: _title.text.trim(),
      type: _type,
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      startAt: _start?.toUtc(),
      // An end without a start is not a range any more.
      endAt: _start == null ? null : original.endAt,
      deadlineAt: _deadline?.toUtc(),
      allDay: _allDay,
      amount: _parseAmount(),
      currency: _currency.text.trim().isEmpty
          ? null
          : _currency.text.trim().toUpperCase(),
      location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      organization: _organization.text.trim().isEmpty
          ? null
          : _organization.text.trim(),
      recurrence: _repeats == null
          ? null
          : RecurrenceRule(frequency: _repeats!, interval: _interval),
      // A field the user corrected by hand is not a guess any more.
      confidence: 1.0,
    );

    try {
      await ref.read(itemActionsProvider).save(edited, original: original);
      messenger.showSnackBar(SnackBar(content: Text(saved)));
      router.pop();
    } catch (error, stack) {
      AppLogger.error('Could not save the edited item', error, stack);
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeTag;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.pageInset),
        children: [
          TextFormField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l10n.itemTitleField),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? l10n.errorTitleRequired
                : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<LifeItemType>(
            initialValue: _type,
            decoration: InputDecoration(labelText: l10n.itemTypeField),
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
            onChanged: (value) => setState(() => _type = value ?? _type),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _description,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l10n.itemNotes),
          ),
          const SizedBox(height: AppSpacing.xl),
          _DateRow(
            label: l10n.itemWhen,
            value: _start,
            locale: locale,
            withTime: !_allDay,
            onPick: () async {
              final picked = await _pick(_start, withTime: !_allDay);
              if (picked != null) setState(() => _start = picked);
            },
            onClear: () => setState(() => _start = null),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.itemAllDay),
            value: _allDay,
            onChanged: _start == null
                ? null
                : (value) => setState(() => _allDay = value),
          ),
          _DateRow(
            label: l10n.itemDeadline,
            value: _deadline,
            locale: locale,
            withTime: false,
            onPick: () async {
              final picked = await _pick(_deadline, withTime: false);
              if (picked != null) setState(() => _deadline = picked);
            },
            onClear: () => setState(() => _deadline = null),
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<RecurrenceFrequency?>(
            initialValue: _repeats,
            decoration: InputDecoration(labelText: l10n.recurrenceLabel),
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.recurrenceNever)),
              for (final frequency in RecurrenceFrequency.values)
                DropdownMenuItem(
                  value: frequency,
                  child: Text(recurrenceFrequencyLabel(context, frequency)),
                ),
            ],
            onChanged: (value) => setState(() => _repeats = value),
          ),
          const SizedBox(height: AppSpacing.xl),
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
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
                  ],
                  decoration: InputDecoration(labelText: l10n.itemAmount),
                  validator: (value) {
                    final raw = value?.trim().replaceAll(',', '.') ?? '';
                    if (raw.isEmpty) return null;
                    return num.tryParse(raw) == null ? l10n.errorAmount : null;
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextFormField(
                  controller: _currency,
                  maxLength: 3,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: l10n.itemCurrency,
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _location,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l10n.itemWhere),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _organization,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l10n.itemOrganisation),
          ),
          const SizedBox(height: AppSpacing.xxl),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
  }
}

/// One date, with the word for what it is and a way to take it away again.
class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.locale,
    required this.withTime,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final String locale;
  final bool withTime;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final current = value;
    final when = current == null
        ? context.l10n.bucketUndated
        : withTime
        ? AppDateFormat.dateAndTime(current, locale)
        : AppDateFormat.fullDate(current, locale);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.schedule_rounded, size: 18),
              label: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  '$label · $when',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          if (current != null)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, size: 18),
              tooltip: context.l10n.itemClearDate,
            ),
        ],
      ),
    );
  }
}
