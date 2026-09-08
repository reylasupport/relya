import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../core/logging/app_logger.dart';
import 'ocr_service.dart';

/// ML Kit text recognition. Runs entirely on the device, offline, free.
class MlKitOcrService implements OcrService {
  MlKitOcrService({TextRecognitionScript script = TextRecognitionScript.latin})
    : _recogniser = TextRecognizer(script: script);

  final TextRecognizer _recogniser;

  @override
  Future<OcrResult?> recognise(File image) async {
    try {
      final input = InputImage.fromFile(image);
      final recognised = await _recogniser.processImage(input);
      final text = recognised.text.trim();
      if (text.isEmpty) return null;
      return OcrResult(text: text, blockCount: recognised.blocks.length);
    } catch (error, stack) {
      // Never fatal: the pipeline falls back to server-side reading.
      AppLogger.error(
        'On-device OCR failed, falling back to the server',
        error,
        stack,
      );
      return null;
    }
  }

  @override
  Future<void> dispose() => _recogniser.close();
}
