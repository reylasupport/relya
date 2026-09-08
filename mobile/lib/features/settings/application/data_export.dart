import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/branding/brand.dart';
import '../../../shared/data/providers.dart';

/// Hands the export the server builds to the person who asked for it.
///
/// The JSON on its own is worthless to that person: portability means leaving
/// with the file, so the bundle goes to the platform share sheet - save to
/// Files, mail it to yourself, drop it in a cloud folder. The bytes are passed
/// as data rather than written here, because the share plugin already writes
/// them to a temporary file the system cleans up, and because that path also
/// works on the web build, where there is no file system to write to.
class DataExporter {
  const DataExporter(this._ref);

  final Ref _ref;

  Future<void> run() async {
    final json = await _ref.read(profileRepositoryProvider).exportData();
    final now = DateTime.now();
    final stamp =
        '${now.year}-${_two(now.month)}-${_two(now.day)}-'
        '${_two(now.hour)}${_two(now.minute)}';

    await Share.shareXFiles(
      [
        XFile.fromData(
          utf8.encode(json),
          mimeType: 'application/json',
          name: 'relya-export-$stamp.json',
        ),
      ],
      fileNameOverrides: ['relya-export-$stamp.json'],
      subject: '${Brand.appName} export',
    );
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

final dataExporterProvider = Provider<DataExporter>(DataExporter.new);
