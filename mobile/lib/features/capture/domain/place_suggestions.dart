import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/providers.dart';
import 'known_service.dart';

/// Names to offer while somebody is typing where they were, or who they were
/// with.
///
/// Two sources, in this order, because that is the order they are useful in:
///
/// 1. Places this person has already been. If last month's receipt says
///    "Cervejaria Ramiro", that is the spelling they use and the one worth
///    offering first.
/// 2. The brands the app already recognises for quick-add.
///
/// What this is not is a search of what is nearby. That needs a places
/// provider, an API key, a billing account and the location permission, and
/// the honest version of "restaurants near me" is a product decision with a
/// monthly cost attached - not something to fake with a hardcoded list. When
/// that provider exists it becomes a third source here and nothing else has
/// to change.
///
/// Nothing here is ever required. A suggestion is a shortcut past typing, and
/// a name the app has never heard of is the normal case, not an error.
final placeSuggestionsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(lifeItemRepositoryProvider);

  final seen = <String>{};
  final mine = <String>[];

  // Most recent first: what somebody used last is what they are most likely
  // to use again.
  final items = await repository.upcoming(limit: 200);
  for (final item in items.reversed) {
    for (final value in [item.organization, item.location]) {
      final name = value?.trim();
      if (name == null || name.isEmpty) continue;
      if (seen.add(name.toLowerCase())) mine.add(name);
    }
  }

  final brands = <String>[];
  for (final service in knownServices) {
    if (seen.add(service.name.toLowerCase())) brands.add(service.name);
  }

  return [...mine, ...brands];
});

/// The suggestions worth showing for what has been typed so far.
///
/// Nothing is offered for an empty field - a list of every brand the app
/// knows is noise, not help - and a name that already matches exactly is not
/// offered back to the person who just finished typing it.
List<String> matchingPlaces(List<String> all, String typed) {
  final query = typed.trim().toLowerCase();
  if (query.length < 2) return const [];

  final starts = <String>[];
  final contains = <String>[];

  for (final name in all) {
    final lower = name.toLowerCase();
    if (lower == query) continue;
    if (lower.startsWith(query)) {
      starts.add(name);
    } else if (lower.contains(query)) {
      contains.add(name);
    }
  }

  return [...starts, ...contains].take(6).toList();
}
