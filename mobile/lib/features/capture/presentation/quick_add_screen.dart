import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../shared/domain/recurrence.dart';
import '../../../shared/widgets/recurrence_label.dart';
import '../domain/known_service.dart';
import 'generic_service_label.dart';

/// Adding what someone already pays for, without waiting for a document.
///
/// The cold start is the problem this solves: a new account has nothing in it,
/// and the whole product is a screen that answers "what is coming up". Ten
/// seconds here and the app has something to say before the first capture.
class QuickAddScreen extends ConsumerStatefulWidget {
  const QuickAddScreen({super.key});

  @override
  ConsumerState<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends ConsumerState<QuickAddScreen> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// Case- and accent-insensitive enough for a list of brand names. Someone
  /// typing "publico" must find "Público".
  static String _fold(String value) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const to = 'aaaaaeeeeiiiiooooouuuucn';
    final lower = value.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      final index = from.indexOf(char);
      buffer.write(index >= 0 ? to[index] : char);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final needle = _fold(_query.text.trim());

    final generic = GenericService.values
        .where(
          (s) =>
              needle.isEmpty ||
              _fold(genericLabel(context, s)).contains(needle),
        )
        .toList();
    final branded = knownServices
        .where((s) => needle.isEmpty || _fold(s.name).contains(needle))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.quickAddTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageInset,
              0,
              AppSpacing.pageInset,
              AppSpacing.md,
            ),
            child: TextField(
              controller: _query,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: l10n.quickAddHint,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              children: [
                if (generic.isNotEmpty) ...[
                  _Heading(l10n.quickAddCommon),
                  for (final service in generic)
                    ListTile(
                      leading: Icon(service.type.icon),
                      title: Text(genericLabel(context, service)),
                      onTap: () => _add(
                        name: genericLabel(context, service),
                        type: service.type,
                        frequency: service.frequency,
                      ),
                    ),
                ],
                if (branded.isNotEmpty) ...[
                  _Heading(l10n.quickAddServices),
                  for (final service in branded)
                    ListTile(
                      leading: Icon(service.type.icon),
                      title: Text(service.name),
                      onTap: () => _add(
                        name: service.name,
                        type: service.type,
                        frequency: service.frequency,
                        currency: service.currency,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _add({
    required String name,
    required LifeItemType type,
    required RecurrenceFrequency frequency,
    String? currency,
  }) async {
    final details = await showModalBottomSheet<_Details>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) =>
          _DetailsSheet(name: name, frequency: frequency, currency: currency),
    );
    if (details == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final confirmation = context.l10n.quickAddAdded(name);
    final failed = context.l10n.errorGeneric;

    try {
      await ref
          .read(lifeItemRepositoryProvider)
          .create(
            LifeItem(
              id: newId(),
              type: type,
              title: name,
              status: LifeItemStatus.active,
              deadlineAt: details.due.toUtc(),
              startTimezone: DateTime.now().timeZoneName,
              amount: details.amount,
              currency: details.currency,
              recurrence: RecurrenceRule(frequency: details.frequency),
              createdAt: DateTime.now().toUtc(),
            ),
          );
      messenger.showSnackBar(SnackBar(content: Text(confirmation)));
      router.pop();
    } catch (error, stack) {
      AppLogger.error('Could not quick-add a service', error, stack);
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.pageInset,
      AppSpacing.lg,
      AppSpacing.pageInset,
      AppSpacing.sm,
    ),
    child: Text(text.toUpperCase(), style: context.text.labelSmall),
  );
}

class _Details {
  const _Details({
    required this.due,
    required this.frequency,
    this.amount,
    this.currency,
  });

  final DateTime due;
  final RecurrenceFrequency frequency;
  final num? amount;
  final String? currency;
}

/// Two questions, both skippable: how much, and when is the next one.
class _DetailsSheet extends StatefulWidget {
  const _DetailsSheet({
    required this.name,
    required this.frequency,
    this.currency,
  });

  final String name;
  final RecurrenceFrequency frequency;
  final String? currency;

  @override
  State<_DetailsSheet> createState() => _DetailsSheetState();
}

class _DetailsSheetState extends State<_DetailsSheet> {
  late final TextEditingController _amount = TextEditingController();
  late final TextEditingController _currency = TextEditingController(
    text: widget.currency ?? '',
  );

  late RecurrenceFrequency _frequency = widget.frequency;
  late DateTime _due = _defaultDue();

  /// A month out for a monthly thing, a year for a yearly one. Close enough to
  /// be a starting point and never a date already in the past.
  DateTime _defaultDue() {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day, 9);
    return RecurrenceRule(frequency: widget.frequency).next(base);
  }

  @override
  void dispose() {
    _amount.dispose();
    _currency.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;
    setState(() => _due = DateTime(picked.year, picked.month, picked.day, 9));
  }

  num? _parsedAmount() {
    final raw = _amount.text.trim().replaceAll(',', '.');
    return raw.isEmpty ? null : num.tryParse(raw);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageInset,
        AppSpacing.lg,
        AppSpacing.pageInset,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.name, style: context.text.headlineSmall),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _amount,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
                  ],
                  decoration: InputDecoration(labelText: l10n.itemAmount),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
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
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _pickDue,
            icon: const Icon(Icons.event_rounded, size: 18),
            label: Text(
              '${l10n.quickAddNextDue} · '
              '${AppDateFormat.fullDate(_due, context.localeTag)}',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<RecurrenceFrequency>(
            initialValue: _frequency,
            decoration: InputDecoration(labelText: l10n.recurrenceLabel),
            items: [
              for (final frequency in RecurrenceFrequency.values)
                DropdownMenuItem(
                  value: frequency,
                  child: Text(recurrenceFrequencyLabel(context, frequency)),
                ),
            ],
            onChanged: (value) =>
                setState(() => _frequency = value ?? _frequency),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              _Details(
                due: _due,
                frequency: _frequency,
                amount: _parsedAmount(),
                currency: _currency.text.trim().isEmpty
                    ? null
                    : _currency.text.trim().toUpperCase(),
              ),
            ),
            child: Text(l10n.actionAdd),
          ),
        ],
      ),
    );
  }
}
