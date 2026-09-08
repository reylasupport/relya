import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/logging/app_logger.dart';
import '../../shared/data/repositories/capture_repository.dart';
import '../../shared/domain/capture.dart';

/// One capture waiting for a network.
///
/// The file is copied into the outbox directory rather than referenced where
/// the picker left it: a temporary camera file can be swept up by the OS
/// before the network comes back, and then the entry would point at nothing.
class OutboxEntry {
  const OutboxEntry({
    required this.id,
    required this.source,
    required this.kind,
    required this.createdAt,
    this.text,
    this.url,
    this.filePath,
    this.mimeType,
    this.title,
    this.attempts = 0,
  });

  factory OutboxEntry.fromJson(Map<String, dynamic> json) => OutboxEntry(
    id: json['id'] as String,
    source: CaptureSource.fromWire(json['source'] as String?),
    kind: CaptureKind.fromWire(json['kind'] as String?),
    createdAt: DateTime.parse(json['created_at'] as String),
    text: json['text'] as String?,
    url: json['url'] as String?,
    filePath: json['file_path'] as String?,
    mimeType: json['mime_type'] as String?,
    title: json['title'] as String?,
    attempts: (json['attempts'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final CaptureSource source;
  final CaptureKind kind;
  final DateTime createdAt;
  final String? text;
  final String? url;
  final String? filePath;
  final String? mimeType;
  final String? title;
  final int attempts;

  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source.wire,
    'kind': kind.wire,
    'created_at': createdAt.toIso8601String(),
    if (text != null) 'text': text,
    if (url != null) 'url': url,
    if (filePath != null) 'file_path': filePath,
    if (mimeType != null) 'mime_type': mimeType,
    if (title != null) 'title': title,
    'attempts': attempts,
  };

  OutboxEntry withAttempt() => OutboxEntry(
    id: id,
    source: source,
    kind: kind,
    createdAt: createdAt,
    text: text,
    url: url,
    filePath: filePath,
    mimeType: mimeType,
    title: title,
    attempts: attempts + 1,
  );

  CaptureDraft toDraft() => CaptureDraft(
    source: source,
    kind: kind,
    text: text,
    url: url,
    filePath: filePath,
    mimeType: mimeType,
    title: title,
  );
}

/// Captures that were taken while there was no network, kept until there is.
///
/// This exists because the main way into Relya is the system Share Sheet, and
/// people share things on the metro. Before this, a share without a connection
/// threw and the receipt was gone. Now the draft is written to disk first and
/// the upload is retried; nothing is lost because the phone was in a tunnel.
///
/// Deliberately a plain directory of JSON files plus copied originals rather
/// than a database: the queue is small, has to survive a cold start, and must
/// be inspectable when something goes wrong.
class CaptureOutbox {
  CaptureOutbox({Directory? root}) : _root = root;

  Directory? _root;

  /// Entries that failed this many times are kept but no longer retried on
  /// every reconnect, so one poisoned file cannot spin forever.
  static const int maxAttempts = 6;

  /// The outbox needs a filesystem, and the web has none - path_provider has
  /// no web implementation and throws MissingPluginException. There is also
  /// nothing to park there: the Share Sheet is a phone feature, and a browser
  /// tab that loses its connection is not going to be closed and reopened
  /// three days later with a receipt still waiting in it.
  static bool get supported => !kIsWeb;

  Future<Directory> _dir() async {
    final existing = _root;
    if (existing != null) {
      if (!await existing.exists()) await existing.create(recursive: true);
      return existing;
    }
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'outbox'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return _root = dir;
  }

  /// Parks a draft. Returns the entry so the caller can tell the user what
  /// is waiting, and copies any original alongside it.
  Future<OutboxEntry?> add(CaptureDraft draft) async {
    if (!supported) return null;
    final dir = await _dir();
    final id = DateTime.now().microsecondsSinceEpoch.toRadixString(36);

    String? storedPath;
    if (draft.filePath != null) {
      final source = File(draft.filePath!);
      if (await source.exists()) {
        final target = File(p.join(dir.path, '$id${p.extension(source.path)}'));
        await source.copy(target.path);
        storedPath = target.path;
      }
    } else if (draft.bytes != null) {
      final target = File(p.join(dir.path, '$id.bin'));
      await target.writeAsBytes(draft.bytes!);
      storedPath = target.path;
    }

    final entry = OutboxEntry(
      id: id,
      source: draft.source,
      kind: draft.kind,
      createdAt: DateTime.now().toUtc(),
      text: draft.text,
      url: draft.url,
      filePath: storedPath,
      mimeType: draft.mimeType,
      title: draft.title,
    );
    await _write(entry);
    AppLogger.info('Capture parked in the outbox');
    return entry;
  }

  Future<void> _write(OutboxEntry entry) async {
    final dir = await _dir();
    final file = File(p.join(dir.path, '${entry.id}.json'));
    await file.writeAsString(jsonEncode(entry.toJson()));
  }

  Future<List<OutboxEntry>> pending() async {
    if (!supported) return const [];
    final dir = await _dir();
    final entries = <OutboxEntry>[];
    // Async listing rather than listSync: this runs at boot, on the main
    // isolate, and a synchronous directory walk there is a dropped frame.
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final file = entity;
      if (p.extension(file.path) != '.json') continue;
      try {
        entries.add(
          OutboxEntry.fromJson(
            jsonDecode(await file.readAsString()) as Map<String, dynamic>,
          ),
        );
      } catch (error) {
        // A half-written manifest helps nobody. Drop it rather than blocking
        // the whole queue on one unreadable file.
        AppLogger.warn('Discarding an unreadable outbox entry');
        await file.delete();
      }
    }
    entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return entries;
  }

  Future<int> count() async => (await pending()).length;

  Future<void> remove(OutboxEntry entry) async {
    if (!supported) return;
    final dir = await _dir();
    final manifest = File(p.join(dir.path, '${entry.id}.json'));
    if (await manifest.exists()) await manifest.delete();
    final original = entry.filePath;
    if (original != null && await File(original).exists()) {
      await File(original).delete();
    }
  }

  /// Tries every parked entry once, oldest first.
  ///
  /// Returns how many made it. Failures stay in the queue with their attempt
  /// count raised; only a success or [maxAttempts] removes an entry, and even
  /// then the file is kept so the user can be told rather than the capture
  /// disappearing silently.
  Future<int> flush(CaptureRepository repository) async {
    if (!supported) return 0;
    final entries = await pending();
    if (entries.isEmpty) return 0;

    var sent = 0;
    for (final entry in entries) {
      if (entry.attempts >= maxAttempts) continue;
      try {
        await repository.enqueue(entry.toDraft());
        await remove(entry);
        sent++;
      } catch (error) {
        // Still no network, or the server said no. Either way the draft stays
        // on disk; the next reconnect will try again.
        await _write(entry.withAttempt());
        AppLogger.warn('Outbox entry still waiting', error);
      }
    }
    if (sent > 0) AppLogger.info('Outbox sent $sent capture(s)');
    return sent;
  }

  /// Entries that have exhausted their retries. Shown to the user, because a
  /// capture that will never leave the phone is worse as a secret.
  Future<List<OutboxEntry>> stuck() async =>
      (await pending()).where((e) => e.attempts >= maxAttempts).toList();
}
