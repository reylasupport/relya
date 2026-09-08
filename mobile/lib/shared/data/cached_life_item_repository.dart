import 'dart:async';

import '../../services/cache/item_cache.dart';
import '../domain/life_item.dart';
import '../domain/life_item_status.dart';
import 'repositories/life_item_repository.dart';

/// Wraps the real repository with a copy of the last successful read.
///
/// Reads fall back to that copy when the network is gone; writes do not fall
/// back at all. Pretending a save happened offline would mean showing the user
/// an item that no other device will ever see, which is worse than an error.
class CachedLifeItemRepository implements LifeItemRepository {
  CachedLifeItemRepository(this._inner, this._cache, this._userId);

  final LifeItemRepository _inner;
  final ItemCache _cache;

  /// Null before sign-in completes. With no owner there is nothing to key the
  /// cache by, so the wrapper simply passes everything through.
  final String? Function() _userId;

  /// True when the last read came off the disk rather than the network. Read
  /// by the screens to say so instead of showing a stale list as if it were
  /// current.
  bool get servedFromCache => _servedFromCache;
  bool _servedFromCache = false;

  @override
  Stream<void> get changes => _inner.changes;

  @override
  Future<List<LifeItem>> upcoming({DateTime? from, int limit = 100}) async {
    final user = _userId();
    try {
      final items = await _inner.upcoming(from: from, limit: limit);
      _servedFromCache = false;
      if (user != null) unawaited(_cache.save(user, items));
      return items;
    } on Object {
      if (user == null) rethrow;
      final cached = await _cache.read(user);
      if (cached.isEmpty) rethrow;
      _servedFromCache = true;
      final cutoff =
          from ?? DateTime.now().toUtc().subtract(const Duration(days: 7));
      return cached
          .where((i) => i.status.isVisibleInTimeline)
          .where(
            (i) =>
                i.primaryInstant == null || i.primaryInstant!.isAfter(cutoff),
          )
          .take(limit)
          .toList();
    }
  }

  @override
  Future<List<LifeItem>> byStatus(LifeItemStatus status) async {
    try {
      return await _inner.byStatus(status);
    } on Object {
      final user = _userId();
      if (user == null) rethrow;
      final cached = await _cache.read(user);
      if (cached.isEmpty) rethrow;
      _servedFromCache = true;
      return cached.where((i) => i.status == status).toList();
    }
  }

  @override
  Future<LifeItem?> byId(String id) async {
    try {
      return await _inner.byId(id);
    } on Object {
      final user = _userId();
      if (user == null) rethrow;
      final cached = await _cache.read(user);
      for (final item in cached) {
        if (item.id == id) return item;
      }
      rethrow;
    }
  }

  @override
  Future<List<LifeItem>> search(String query) async {
    try {
      return await _inner.search(query);
    } on Object {
      final user = _userId();
      if (user == null) rethrow;
      final cached = await _cache.read(user);
      if (cached.isEmpty) rethrow;
      _servedFromCache = true;
      // A plain contains, not the Postgres text search. Offline the honest
      // choice is a worse search, not no search.
      final needle = query.trim().toLowerCase();
      if (needle.isEmpty) return const [];
      return cached
          .where(
            (i) =>
                i.title.toLowerCase().contains(needle) ||
                (i.description ?? '').toLowerCase().contains(needle) ||
                (i.organization ?? '').toLowerCase().contains(needle) ||
                (i.location ?? '').toLowerCase().contains(needle),
          )
          .toList();
    }
  }

  @override
  Future<List<LifeItem>> byCapture(String captureId) =>
      _inner.byCapture(captureId);

  @override
  Future<List<LifeItem>> byEntity(String entityId) => _inner.byEntity(entityId);

  @override
  Future<LifeItem> create(LifeItem item) => _inner.create(item);

  @override
  Future<List<LifeItem>> createAll(List<LifeItem> items) =>
      _inner.createAll(items);

  @override
  Future<LifeItem> update(LifeItem item) => _inner.update(item);

  @override
  Future<void> delete(String id) => _inner.delete(id);
}
