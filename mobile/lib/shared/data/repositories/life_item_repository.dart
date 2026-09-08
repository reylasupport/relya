import '../../domain/life_item.dart';
import '../../domain/life_item_status.dart';

/// Reads and writes the user items. Implemented twice: against Supabase, and
/// against in-memory fixtures so the UI and the tests can run with no backend.
abstract interface class LifeItemRepository {
  /// Everything with a date, ordered by urgency. Used by Home and Upcoming.
  Future<List<LifeItem>> upcoming({DateTime? from, int limit = 100});

  Future<List<LifeItem>> byStatus(LifeItemStatus status);

  Future<List<LifeItem>> byCapture(String captureId);

  Future<List<LifeItem>> byEntity(String entityId);

  Future<LifeItem?> byId(String id);

  /// Universal search across title, description, organisation and location.
  Future<List<LifeItem>> search(String query);

  Future<LifeItem> create(LifeItem item);

  /// Accepting a whole confirmation screen in one transaction, so the user
  /// never ends up with half of what they tapped Add all for.
  Future<List<LifeItem>> createAll(List<LifeItem> items);

  Future<LifeItem> update(LifeItem item);

  Future<void> delete(String id);

  /// Emits whenever the set changes, so Home and Upcoming stay in step.
  Stream<void> get changes;
}
