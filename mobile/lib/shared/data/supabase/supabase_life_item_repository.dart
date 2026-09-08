import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase/supabase_service.dart';
import '../../domain/life_item.dart';
import '../../domain/life_item_status.dart';
import '../repositories/life_item_repository.dart';

/// Postgres-backed implementation.
///
/// No query filters by user_id: Row Level Security does that in the database,
/// which means a forgotten filter is a no-op rather than a data leak.
class SupabaseLifeItemRepository implements LifeItemRepository {
  SupabaseLifeItemRepository(this._supabase);

  static const String _table = 'life_items';

  final SupabaseService _supabase;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  List<LifeItem> _decode(List<dynamic> rows) => rows
      .map((row) => LifeItem.fromJson((row as Map).cast<String, dynamic>()))
      .toList();

  @override
  Future<List<LifeItem>> upcoming({DateTime? from, int limit = 100}) async {
    final cutoff =
        (from ?? DateTime.now().toUtc().subtract(const Duration(days: 7)))
            .toIso8601String();
    final rows = await _supabase
        .table(_table)
        .select()
        .inFilter('status', const ['active', 'snoozed'])
        // The third clause is what keeps a dated-nowhere item - a task, a
        // warranty the model found no date for - from disappearing entirely.
        .or(
          'start_at.gte.$cutoff,'
          'deadline_at.gte.$cutoff,'
          'and(start_at.is.null,deadline_at.is.null)',
        )
        .order('start_at', ascending: true, nullsFirst: false)
        .limit(limit);
    final items = _decode(rows);
    items.sort(_byUrgency);
    return items;
  }

  static int _byUrgency(LifeItem a, LifeItem b) {
    final ai = a.primaryInstant;
    final bi = b.primaryInstant;
    if (ai == null && bi == null) return b.createdAt.compareTo(a.createdAt);
    if (ai == null) return 1;
    if (bi == null) return -1;
    return ai.compareTo(bi);
  }

  @override
  Future<List<LifeItem>> byStatus(LifeItemStatus status) async {
    final rows = await _supabase
        .table(_table)
        .select()
        .eq('status', status.wire)
        .order('created_at', ascending: false);
    return _decode(rows);
  }

  @override
  Future<List<LifeItem>> byCapture(String captureId) async {
    final rows = await _supabase
        .table(_table)
        .select()
        .eq('capture_id', captureId);
    return _decode(rows);
  }

  @override
  Future<List<LifeItem>> byEntity(String entityId) async {
    final rows = await _supabase
        .table(_table)
        .select()
        .eq('entity_id', entityId)
        .order('start_at', ascending: true, nullsFirst: false);
    return _decode(rows);
  }

  @override
  Future<LifeItem?> byId(String id) async {
    final row = await _supabase
        .table(_table)
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return LifeItem.fromJson(row);
  }

  @override
  Future<List<LifeItem>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final rows = await _supabase
        .table(_table)
        .select()
        .textSearch(
          'search_vector',
          trimmed,
          config: 'simple',
          type: TextSearchType.websearch,
        )
        .limit(50);
    return _decode(rows);
  }

  @override
  Future<LifeItem> create(LifeItem item) async {
    final row = await _supabase
        .table(_table)
        .insert({...item.toJson(), 'user_id': _supabase.requireUserId})
        .select()
        .single();
    _changes.add(null);
    return LifeItem.fromJson(row);
  }

  @override
  Future<List<LifeItem>> createAll(List<LifeItem> items) async {
    if (items.isEmpty) return const [];
    final userId = _supabase.requireUserId;
    final rows = await _supabase
        .table(_table)
        .insert(items.map((i) => {...i.toJson(), 'user_id': userId}).toList())
        .select();
    _changes.add(null);
    return _decode(rows);
  }

  @override
  Future<LifeItem> update(LifeItem item) async {
    final row = await _supabase
        .table(_table)
        .update(item.toJson())
        .eq('id', item.id)
        .select()
        .single();
    _changes.add(null);
    return LifeItem.fromJson(row);
  }

  @override
  Future<void> delete(String id) async {
    await _supabase.table(_table).delete().eq('id', id);
    _changes.add(null);
  }
}
