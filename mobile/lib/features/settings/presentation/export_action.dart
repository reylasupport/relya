import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/logging/app_logger.dart';
import '../application/data_export.dart';

/// Shared by the two places that offer the export, so both behave the same.
///
/// The previous version announced success before anything had happened. A
/// failure has to say so: telling someone their data left the building when it
/// did not is the one outcome worse than an error.
Future<void> exportUserData(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final failed = context.l10n.errorGeneric;
  try {
    await ref.read(dataExporterProvider).run();
  } catch (error, stack) {
    AppLogger.error('Export failed', error, stack);
    messenger.showSnackBar(SnackBar(content: Text(failed)));
  }
}
