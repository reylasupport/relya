import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../../../services/supabase/supabase_service.dart';
import '../../domain/assistant_message.dart';
import '../../domain/life_entity.dart';
import '../../domain/reminder.dart';
import '../../domain/user_preferences.dart';
import '../../domain/user_profile.dart';
import '../repositories/assistant_repository.dart';
import '../repositories/entity_repository.dart';
import '../repositories/feedback_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/reminder_repository.dart';

class SupabaseReminderRepository implements ReminderRepository {
  SupabaseReminderRepository(this._supabase);

  static const String _table = 'reminders';

  final SupabaseService _supabase;

  @override
  Future<List<Reminder>> forItem(String itemId) async {
    final rows = await _supabase
        .table(_table)
        .select()
        .eq('item_id', itemId)
        .order('fire_at');
    return rows
        .map((r) => Reminder.fromJson((r as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<List<Reminder>> pending() async {
    final rows = await _supabase
        .table(_table)
        .select()
        .eq('status', 'scheduled')
        .gte('fire_at', DateTime.now().toUtc().toIso8601String())
        .order('fire_at');
    return rows
        .map((r) => Reminder.fromJson((r as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<Reminder> create(Reminder reminder) async {
    final row = await _supabase
        .table(_table)
        .insert({...reminder.toJson(), 'user_id': _supabase.requireUserId})
        .select()
        .single();
    return Reminder.fromJson(row);
  }

  @override
  Future<List<Reminder>> createAll(List<Reminder> reminders) async {
    if (reminders.isEmpty) return const [];
    final userId = _supabase.requireUserId;
    final rows = await _supabase
        .table(_table)
        .insert(
          reminders.map((r) => {...r.toJson(), 'user_id': userId}).toList(),
        )
        .select();
    return rows
        .map((r) => Reminder.fromJson((r as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<void> cancel(String reminderId) async {
    await _supabase
        .table(_table)
        .update({'status': 'cancelled'})
        .eq('id', reminderId);
  }

  @override
  Future<void> rescheduleForTimezone(String timezone) async {
    // The server recomputes wall-clock-anchored reminders; the device
    // reschedules its local notifications from the returned rows.
    await _supabase.invoke<dynamic>(
      'reschedule-reminders',
      body: {'timezone': timezone},
    );
  }
}

class SupabaseEntityRepository implements EntityRepository {
  SupabaseEntityRepository(this._supabase);

  static const String _table = 'entities';

  final SupabaseService _supabase;

  @override
  Future<List<LifeEntity>> all() async {
    final rows = await _supabase.table(_table).select().order('name');
    return rows
        .map((r) => LifeEntity.fromJson((r as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<LifeEntity?> byId(String id) async {
    final row = await _supabase
        .table(_table)
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : LifeEntity.fromJson(row);
  }

  @override
  Future<LifeEntity> create(LifeEntity entity) async {
    final row = await _supabase
        .table(_table)
        .insert({...entity.toJson(), 'user_id': _supabase.requireUserId})
        .select()
        .single();
    return LifeEntity.fromJson(row);
  }

  @override
  Future<LifeEntity> update(LifeEntity entity) async {
    final row = await _supabase
        .table(_table)
        .update(entity.toJson())
        .eq('id', entity.id)
        .select()
        .single();
    return LifeEntity.fromJson(row);
  }

  @override
  Future<void> delete(String id) async {
    await _supabase.table(_table).delete().eq('id', id);
  }
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._supabase);

  final SupabaseService _supabase;

  @override
  Future<UserProfile?> current() async {
    final id = _supabase.userId;
    if (id == null) return null;
    final row = await _supabase
        .table('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : UserProfile.fromJson(row);
  }

  @override
  Future<UserProfile> update(UserProfile profile) async {
    final row = await _supabase
        .table('profiles')
        .update(profile.toJson())
        .eq('id', profile.id)
        .select()
        .single();
    return UserProfile.fromJson(row);
  }

  @override
  Future<UserPreferences> preferences() async {
    final row = await _supabase
        .table('user_preferences')
        .select()
        .eq('user_id', _supabase.requireUserId)
        .maybeSingle();
    return row == null
        ? const UserPreferences()
        : UserPreferences.fromJson(row);
  }

  @override
  Future<UserPreferences> savePreferences(UserPreferences preferences) async {
    final row = await _supabase
        .table('user_preferences')
        .upsert({
          ...preferences.toJson(),
          'user_id': _supabase.requireUserId,
        }, onConflict: 'user_id')
        .select()
        .single();
    return UserPreferences.fromJson(row);
  }

  /// Runs server-side so it can delete storage objects and the auth user, both
  /// of which the client is not allowed to touch.
  @override
  Future<void> deleteAccount() async {
    await _supabase.invoke<dynamic>('delete-account');
    await _supabase.auth.signOut();
  }

  @override
  Future<String> exportData() async {
    final data = await _supabase.invoke<Map<String, dynamic>>('export-data');
    return const JsonEncoder.withIndent('  ').convert(data);
  }
}

class SupabaseAssistantRepository implements AssistantRepository {
  SupabaseAssistantRepository(this._supabase);

  final SupabaseService _supabase;

  final List<AssistantMessage> _local = [];

  @override
  Future<List<AssistantMessage>> history() async => _local.toList();

  @override
  Future<AssistantMessage> ask(String question) async {
    _local.add(
      AssistantMessage(
        id: 'q-${DateTime.now().microsecondsSinceEpoch}',
        role: AssistantRole.user,
        text: question,
        createdAt: DateTime.now(),
      ),
    );

    final Map<String, dynamic> data;
    try {
      data = await _supabase.invoke<Map<String, dynamic>>(
        'ask-assistant',
        body: {'question': question},
      );
    } on FunctionException catch (error) {
      if (error.status == 429) {
        throw QuotaExceeded('Daily assistant limit reached', cause: error);
      }
      rethrow;
    }

    final answer = AssistantMessage(
      id: 'a-${DateTime.now().microsecondsSinceEpoch}',
      role: AssistantRole.assistant,
      text: data['answer'] as String? ?? '',
      createdAt: DateTime.now(),
      citedItemIds:
          (data['cited_item_ids'] as List?)?.cast<String>() ?? const [],
    );
    _local.add(answer);
    return answer;
  }

  @override
  Future<void> clear() async => _local.clear();
}

class SupabaseFeedbackRepository implements FeedbackRepository {
  SupabaseFeedbackRepository(this._supabase);

  final SupabaseService _supabase;

  @override
  Future<void> record(List<ExtractionCorrection> corrections) async {
    if (corrections.isEmpty) return;
    final userId = _supabase.userId;
    if (userId == null) return;
    try {
      await _supabase.table('extraction_feedback').insert([
        for (final correction in corrections)
          {...correction.toJson(), 'user_id': userId},
      ]);
    } catch (error, stack) {
      // Telemetry, not user data. It must never be able to fail a save.
      AppLogger.error('Could not record extraction feedback', error, stack);
    }
  }
}
