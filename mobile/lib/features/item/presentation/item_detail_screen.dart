import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/concept/concept.dart';
import '../../../core/design/concept/concept_kit.dart';
import '../../../core/design/components/app_card.dart';
import '../../../core/design/components/empty_state.dart';
import '../../../core/design/tokens/app_semantic_colors.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/formatting/app_date_format.dart';
import '../../../core/design/tokens/type_palette.dart';
import '../../../core/formatting/app_money_format.dart';
import '../../../core/ids/ids.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../services/calendar/calendar_service.dart';
import '../../../shared/data/providers.dart';
import '../../../services/notifications/reminder_scheduler.dart';
import '../../../shared/domain/life_item.dart';
import '../../../shared/domain/life_item_status.dart';
import '../../../shared/widgets/category_label.dart';
import '../../../shared/widgets/recurrence_label.dart';
import '../../../shared/domain/reminder.dart';
import '../../../navigation/routes.dart';
import '../application/item_actions.dart';

final _itemProvider = FutureProvider.autoDispose.family((ref, String id) {
  final repository = ref.watch(lifeItemRepositoryProvider);
  // Snoozing, completing and editing all happen from this screen; without
  // this the screen keeps showing the state it was opened with.
  final subscription = repository.changes.listen((_) => ref.invalidateSelf());
  ref.onDispose(subscription.cancel);
  return repository.byId(id);
});

final _remindersProvider = FutureProvider.autoDispose.family((ref, String id) {
  ref.watch(lifeItemRepositoryProvider);
  return ref.watch(reminderRepositoryProvider).forItem(id);
});

class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(_itemProvider(itemId));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.itemDetailTitle),
        actions: [
          PopupMenuButton<void>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: context.l10n.actionMore,
            itemBuilder: (context) => [
              PopupMenuItem<void>(
                onTap: () => context.push(Routes.itemEdit(itemId)),
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 19),
                    const SizedBox(width: 10),
                    Text(context.l10n.actionEdit),
                  ],
                ),
              ),
              PopupMenuItem<void>(
                onTap: () => _confirmDelete(context, ref),
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 19,
                      color: context.semantic.danger,
                    ),
                    const SizedBox(width: 10),
                    Text(context.l10n.actionDelete),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
            : _Detail(item: value),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.actionDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(lifeItemRepositoryProvider).delete(itemId);
    if (context.mounted) context.pop();
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.item});

  final LifeItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = context.accentFor(item.type);
    final locale = context.localeTag;
    final reminders = ref.watch(_remindersProvider(item.id));
    final start = item.startAt?.toLocal();
    final deadline = item.deadlineAt?.toLocal();

    final kit = context.kit;
    final done = item.status == LifeItemStatus.done;
    // The two dark designs put the title on a band of its own colour; the two
    // light ones let it sit on the page. Same words, different confidence.
    final banded = context.concept == Concept.a || context.concept == Concept.f;

    final head = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            kit.glyph(context, type: item.type, size: 34),
            const SizedBox(width: AppSpacing.md),
            Text(
              categoryLabel(context, item.type).toUpperCase(),
              style: context.text.labelSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(item.title, style: kit.heading(context)),
        if (item.description != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(item.description!, style: context.text.bodyLarge),
        ],
      ],
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(kit.gutter, 0, kit.gutter, AppSpacing.xxl),
      children: [
        if (banded)
          kit.card(
            context,
            tint: accent.withValues(alpha: 0.16),
            padding: const EdgeInsets.all(18),
            child: head,
          )
        else
          head,
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          child: Column(
            children: [
              if (start != null)
                _Row(
                  icon: Icons.schedule_rounded,
                  label: context.l10n.itemWhen,
                  value:
                      "${AppDateFormat.fullDate(start, locale)}  ·  "
                      "${AppDateFormat.range(start, item.endAt?.toLocal(), locale)}",
                ),
              if (deadline != null)
                _Row(
                  icon: Icons.flag_outlined,
                  label: context.l10n.itemDeadline,
                  value: AppDateFormat.fullDate(deadline, locale),
                ),
              if (item.amount != null)
                _Row(
                  icon: Icons.payments_outlined,
                  label: context.l10n.itemAmount,
                  value: AppMoneyFormat.format(
                    item.amount!,
                    item.currency,
                    locale,
                  ),
                ),
              if (item.location != null)
                _Row(
                  icon: Icons.place_outlined,
                  label: context.l10n.itemWhere,
                  value: item.location!,
                ),
              if (item.organization != null)
                _Row(
                  icon: Icons.storefront_outlined,
                  label: context.l10n.itemOrganisation,
                  value: item.organization!,
                ),
              if (item.recurrence != null)
                _Row(
                  icon: Icons.repeat_rounded,
                  label: context.l10n.recurrenceLabel,
                  value: recurrenceFrequencyLabel(
                    context,
                    item.recurrence!.frequency,
                  ),
                ),
              if (item.snoozedUntil != null)
                _Row(
                  icon: Icons.snooze_rounded,
                  label: context.l10n.itemSnooze,
                  value: AppDateFormat.fullDate(
                    item.snoozedUntil!.toLocal(),
                    locale,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            if (start != null) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addToCalendar(context, ref),
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: Text(context.l10n.reminderAddToCalendar),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: OutlinedButton.icon(
                onPressed: done ? null : () => _markDone(context, ref),
                icon: Icon(
                  done
                      ? Icons.check_circle_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 18,
                  color: done ? context.semantic.success : null,
                ),
                label: Text(
                  done ? context.l10n.itemIsDone : context.l10n.itemMarkDone,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!done)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: item.status == LifeItemStatus.snoozed
                  ? () => _resume(context, ref)
                  : () => _snooze(context, ref),
              icon: Icon(
                item.status == LifeItemStatus.snoozed
                    ? Icons.undo_rounded
                    : Icons.snooze_rounded,
                size: 18,
              ),
              label: Text(
                item.status == LifeItemStatus.snoozed
                    ? context.l10n.itemResume
                    : context.l10n.itemSnooze,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        reminders.maybeWhen(
          data: (list) => _Reminders(reminders: list),
          orElse: () => const SizedBox.shrink(),
        ),
        reminders.maybeWhen(
          data: (list) => _AiNote(item: item, reminders: list),
          orElse: () => const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.xl),
        TextButton.icon(
          onPressed: () => _reportWrong(context),
          icon: const Icon(Icons.flag_outlined, size: 18),
          label: Text(context.l10n.analysisGotThisWrong),
        ),
      ],
    );
  }

  /// Marks the item done. Its reminders go with it: a notification for
  /// something already handled is the fastest way to teach someone to ignore
  /// notifications.
  Future<void> _markDone(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final locale = context.localeTag;
    final label = context.l10n.itemIsDone;
    final next = await ref.read(itemActionsProvider).complete(item);
    if (!context.mounted) return;
    // Completing a repeating item is also what creates the following one, so
    // say which date it landed on rather than leaving the user to go and look.
    final message = next?.primaryInstant == null
        ? label
        : context.l10n.recurrenceNextOn(
            AppDateFormat.fullDate(next!.primaryInstant!.toLocal(), locale),
          );
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  /// Snooze hides the item and moves the nudge; it never moves the date. A
  /// bill due on the 8th is still due on the 8th after "not now".
  Future<void> _snooze(BuildContext context, WidgetRef ref) async {
    final actions = ref.read(itemActionsProvider);
    final l10n = context.l10n;
    final now = DateTime.now();
    final choice = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.wb_twilight_rounded),
              title: Text(l10n.bucketTomorrow),
              onTap: () => Navigator.of(
                sheet,
              ).pop(DateTime(now.year, now.month, now.day + 1, 9)),
            ),
            ListTile(
              leading: const Icon(Icons.next_week_rounded),
              title: Text(l10n.itemSnoozeNextWeek),
              onTap: () => Navigator.of(
                sheet,
              ).pop(DateTime(now.year, now.month, now.day + 7, 9)),
            ),
            ListTile(
              leading: const Icon(Icons.event_rounded),
              title: Text(l10n.itemSnoozePick),
              onTap: () async {
                final picked = await showDatePicker(
                  context: sheet,
                  initialDate: now.add(const Duration(days: 1)),
                  firstDate: now,
                  lastDate: DateTime(now.year + 5),
                );
                if (!sheet.mounted) return;
                Navigator.of(sheet).pop(
                  picked == null
                      ? null
                      : DateTime(picked.year, picked.month, picked.day, 9),
                );
              },
            ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final confirmation = l10n.itemSnoozedUntil(
      AppDateFormat.fullDate(choice, context.localeTag),
    );
    await actions.snooze(item, choice, label: l10n.itemSnoozeNudge);
    if (!context.mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(confirmation)));
  }

  Future<void> _resume(BuildContext context, WidgetRef ref) async {
    await ref.read(itemActionsProvider).resume(item);
  }

  Future<void> _addToCalendar(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final added = await ref.read(calendarServiceProvider).addEvent(item);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          added ? context.l10n.actionDone : context.l10n.errorGeneric,
        ),
      ),
    );
  }

  /// Corrections are the training signal for everything the pipeline does
  /// wrong (spec section 51). Never hide the mistake, never make reporting it
  /// feel like a complaint.
  void _reportWrong(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pageInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.analysisGotThisWrong,
                style: context.text.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.l10n.analysisLowConfidence,
                style: context.text.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.l10n.actionClose),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// How far ahead of the item a reminder fires.
///
/// The interface used to offer exactly one of these, hardcoded to a day, in an
/// app whose whole promise is being reminded at the right moment - and the
/// card disappeared entirely for anything happening sooner than tomorrow,
/// which is precisely when a reminder is worth most. The labels have been
/// translated in four languages since the first release and nothing showed
/// them.
enum _ReminderLead {
  onTheDay,
  twoHours,
  oneDay,
  sevenDays,
  thirtyDays;

  Duration get offset => switch (this) {
    _ReminderLead.onTheDay => Duration.zero,
    _ReminderLead.twoHours => const Duration(hours: 2),
    _ReminderLead.oneDay => const Duration(days: 1),
    _ReminderLead.sevenDays => const Duration(days: 7),
    _ReminderLead.thirtyDays => const Duration(days: 30),
  };

  String label(AppLocalizations l10n) => switch (this) {
    _ReminderLead.onTheDay => l10n.reminderOnTheDay,
    _ReminderLead.twoHours => l10n.reminder2HoursBefore,
    _ReminderLead.oneDay => l10n.reminder1DayBefore,
    _ReminderLead.sevenDays => l10n.reminder7DaysBefore,
    _ReminderLead.thirtyDays => l10n.reminder30DaysBefore,
  };

  /// Morning of, rather than the anchor itself, for [onTheDay]: a deadline
  /// carries no time of day, so the honest reading of "on the day" is when the
  /// person is awake and can still act on it.
  DateTime fireAt(DateTime anchor) {
    if (this != _ReminderLead.onTheDay) return anchor.subtract(offset);
    final local = anchor.toLocal();
    return DateTime(local.year, local.month, local.day, 9).toUtc();
  }
}

/// What the assistant noticed about this item, and the one thing it can do
/// about it.
///
/// Only ever an offer. The rule from the specification holds here as much as
/// in the pipeline: nothing enters the user's life without a tap, so this
/// proposes a reminder and never schedules one on its own.
class _AiNote extends ConsumerWidget {
  const _AiNote({required this.item, required this.reminders});

  final LifeItem item;
  final List<Reminder> reminders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anchor = item.deadlineAt ?? item.startAt;
    // Nothing useful to say about an item with no date, and nothing to add
    // when a reminder is already waiting.
    if (anchor == null || reminders.isNotEmpty) return const SizedBox.shrink();
    if (item.status == LifeItemStatus.done) return const SizedBox.shrink();

    final now = DateTime.now().toUtc();
    final available = _ReminderLead.values
        .where((lead) => lead.fireAt(anchor).isAfter(now))
        .toList();
    // Every option is already in the past: there is no reminder left to offer.
    if (available.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: context.kit.card(
        context,
        tint: context.colors.primary.withValues(
          alpha: context.isDark ? 0.14 : 0.07,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [context.colors.primary, context.colors.secondary],
                  ).createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.itemAiNoteTitle,
                  style: context.text.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(context.l10n.itemAiNoteBody, style: context.text.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.tonalIcon(
                onPressed: () => _choose(context, ref, anchor, available),
                icon: const Icon(Icons.notifications_active_outlined, size: 18),
                label: Text(context.l10n.itemSetReminder),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    DateTime anchor,
    List<_ReminderLead> available,
  ) async {
    final chosen = await showModalBottomSheet<_ReminderLead>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                sheet.l10n.itemSetReminder,
                style: sheet.text.titleMedium,
              ),
            ),
            for (final lead in available)
              ListTile(
                leading: const Icon(Icons.schedule_rounded),
                title: Text(lead.label(sheet.l10n)),
                subtitle: Text(
                  AppDateFormat.dateAndTime(
                    lead.fireAt(anchor).toLocal(),
                    sheet.localeTag,
                  ),
                ),
                onTap: () => Navigator.of(sheet).pop(lead),
              ),
          ],
        ),
      ),
    );
    if (chosen == null || !context.mounted) return;
    await _setReminder(context, ref, anchor, chosen);
  }

  Future<void> _setReminder(
    BuildContext context,
    WidgetRef ref,
    DateTime anchor,
    _ReminderLead lead,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final label = lead.label(context.l10n);
    final confirmation = context.l10n.reminderAdded(label);
    await ref
        .read(reminderSchedulerProvider)
        .scheduleAll(
          item: item,
          reminders: [
            Reminder(
              id: newId(),
              itemId: item.id,
              fireAt: lead.fireAt(anchor),
              timezone: DateTime.now().timeZoneName,
              anchor: item.deadlineAt != null
                  ? ReminderAnchor.deadline
                  : ReminderAnchor.start,
              status: ReminderStatus.scheduled,
              leadTime: lead.offset,
              label: label,
            ),
          ],
        );
    if (!context.mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(confirmation)));
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 18, color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: context.text.bodyMedium),
          const SizedBox(width: AppSpacing.lg),
          // Flexible, not fixed: a full date plus a time range is long, and a
          // fact row that overflows is worse than one that wraps.
          Expanded(
            child: Text(
              value,
              style: context.text.titleSmall,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _Reminders extends StatelessWidget {
  const _Reminders({required this.reminders});

  final List<Reminder> reminders;

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) return const SizedBox.shrink();
    final semantic = context.semantic;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.itemReminders.toUpperCase(),
          style: context.text.labelSmall?.copyWith(letterSpacing: 0.8),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final reminder in reminders)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  size: 17,
                  color: semantic.success,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    reminder.label ?? '',
                    style: context.text.bodyLarge,
                  ),
                ),
                Text(
                  AppDateFormat.dateAndTime(
                    reminder.fireAt.toLocal(),
                    context.localeTag,
                  ),
                  style: context.text.labelSmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
