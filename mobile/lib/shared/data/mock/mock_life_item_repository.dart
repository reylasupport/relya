import 'dart:async';

import '../../domain/life_item.dart';
import '../../domain/life_item_status.dart';
import '../repositories/life_item_repository.dart';
import 'mock_fixtures.dart';

/// In-memory implementation. Deliberately behaves like a real backend: it is
/// asynchronous, it emits change events, and it sorts the same way the SQL
/// version does, so switching implementations does not change the UI.
class MockLifeItemRepository implements LifeItemRepository {
  /// [items] lets a caller seed an empty or bespoke set, which is how the
  /// empty states get tested and screenshotted.
  MockLifeItemRepository({DateTime? now, List<LifeItem>? items})
    : _items = [...(items ?? MockFixtures.items(now ?? DateTime.now()))];

  final List<LifeItem> _items;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  static const Duration _latency = Duration(milliseconds: 120);

  @override
  Stream<void> get changes => _changes.stream;

  void _notify() => _changes.add(null);

  int _byUrgency(LifeItem a, LifeItem b) {
    final ai = a.primaryInstant;
    final bi = b.primaryInstant;
    if (ai == null && bi == null) return b.createdAt.compareTo(a.createdAt);
    if (ai == null) return 1;
    if (bi == null) return -1;
    return ai.compareTo(bi);
  }

  @override
  Future<List<LifeItem>> upcoming({DateTime? from, int limit = 100}) async {
    await Future<void>.delayed(_latency);
    final cutoff =
        from ?? DateTime.now().toUtc().subtract(const Duration(days: 7));
    final result =
        _items
            .where((i) => i.status.isVisibleInTimeline)
            // Undated items are kept, the same way the SQL query keeps them.
            .where(
              (i) =>
                  i.primaryInstant == null || i.primaryInstant!.isAfter(cutoff),
            )
            .toList()
          ..sort(_byUrgency);
    return result.take(limit).toList();
  }

  @override
  Future<List<LifeItem>> byStatus(LifeItemStatus status) async {
    await Future<void>.delayed(_latency);
    return _items.where((i) => i.status == status).toList()..sort(_byUrgency);
  }

  @override
  Future<List<LifeItem>> byCapture(String captureId) async {
    await Future<void>.delayed(_latency);
    return _items.where((i) => i.captureId == captureId).toList();
  }

  @override
  Future<List<LifeItem>> byEntity(String entityId) async {
    await Future<void>.delayed(_latency);
    return _items.where((i) => i.entityId == entityId).toList()
      ..sort(_byUrgency);
  }

  @override
  Future<LifeItem?> byId(String id) async {
    await Future<void>.delayed(_latency);
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<List<LifeItem>> search(String query) async {
    await Future<void>.delayed(_latency);
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    bool matches(String? value) =>
        value != null && value.toLowerCase().contains(q);
    return _items
        .where(
          (i) =>
              matches(i.title) ||
              matches(i.description) ||
              matches(i.organization) ||
              matches(i.location) ||
              matches(i.type.wire),
        )
        .toList()
      ..sort(_byUrgency);
  }

  @override
  Future<LifeItem> create(LifeItem item) async {
    await Future<void>.delayed(_latency);
    _items.add(item);
    _notify();
    return item;
  }

  @override
  Future<List<LifeItem>> createAll(List<LifeItem> items) async {
    await Future<void>.delayed(_latency);
    _items.addAll(items);
    _notify();
    return items;
  }

  @override
  Future<LifeItem> update(LifeItem item) async {
    await Future<void>.delayed(_latency);
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      _items[index] = item;
    } else {
      _items.add(item);
    }
    _notify();
    return item;
  }

  @override
  Future<void> delete(String id) async {
    await Future<void>.delayed(_latency);
    _items.removeWhere((i) => i.id == id);
    _notify();
  }
}
