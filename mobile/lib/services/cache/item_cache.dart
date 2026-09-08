import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/logging/app_logger.dart';
import '../../shared/domain/life_item.dart';

/// The last set of items this device saw, kept on disk so the app has
/// something to show with no network.
///
/// Application support rather than documents: it is app-private on both
/// platforms, excluded from iCloud backup, and removed with the app. The file
/// still holds appointments and amounts, so it is written per user and deleted
/// on sign-out - a shared phone must not show the previous account's life.
class ItemCache {
  ItemCache();

  static const String _directory = 'relya-cache';

  Future<File?> _file(String userId) async {
    try {
      final base = await getApplicationSupportDirectory();
      final folder = Directory('${base.path}/$_directory');
      if (!await folder.exists()) await folder.create(recursive: true);
      return File('${folder.path}/items-$userId.json');
    } on Object catch (error) {
      // A platform with no application support directory (the web preview) is
      // simply a platform with no cache.
      AppLogger.warn('No cache directory available', error);
      return null;
    }
  }

  Future<void> save(String userId, List<LifeItem> items) async {
    final file = await _file(userId);
    if (file == null) return;
    try {
      final payload = items
          .map(
            (item) => {
              ...item.toJson(),
              // toJson is shaped for an insert, where the server owns these.
              'created_at': item.createdAt.toIso8601String(),
              'updated_at': item.updatedAt?.toIso8601String(),
            },
          )
          .toList();
      await file.writeAsString(jsonEncode(payload), flush: true);
    } on Object catch (error, stack) {
      // A cache that cannot be written must never break the screen that was
      // successfully loaded from the network.
      AppLogger.error('Could not write the item cache', error, stack);
    }
  }

  Future<List<LifeItem>> read(String userId) async {
    final file = await _file(userId);
    if (file == null || !await file.exists()) return const [];
    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return const [];
      return raw
          .map((row) => LifeItem.fromJson((row as Map).cast<String, dynamic>()))
          .toList();
    } on Object catch (error, stack) {
      AppLogger.error('Could not read the item cache', error, stack);
      return const [];
    }
  }

  /// Called on sign-out and on account deletion.
  Future<void> clear() async {
    try {
      final base = await getApplicationSupportDirectory();
      final folder = Directory('${base.path}/$_directory');
      if (await folder.exists()) await folder.delete(recursive: true);
    } on Object catch (error, stack) {
      AppLogger.error('Could not clear the item cache', error, stack);
    }
  }
}

final itemCacheProvider = Provider<ItemCache>((ref) => ItemCache());
