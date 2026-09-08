import 'dart:io';

/// What on-device text recognition produced.
class OcrResult {
  const OcrResult({required this.text, required this.blockCount});

  final String text;
  final int blockCount;

  /// Below this, the image is probably a photo rather than a document and the
  /// server should look at the pixels instead of at our transcription.
  bool get isUsable => text.trim().length >= 24;
}

/// Reads text from an image on the device.
///
/// Doing this locally before anything is uploaded is the single biggest lever
/// we have (spec section 40): it removes a network round trip, cuts the model
/// bill because a text prompt is far cheaper than a multimodal one, and means
/// most screenshots never leave the phone as pixels at all.
abstract interface class OcrService {
  Future<OcrResult?> recognise(File image);

  Future<void> dispose();
}

/// Used on platforms without ML Kit, and in tests. Returning null makes the
/// pipeline fall back to sending the image, which is correct but costlier.
class NoopOcrService implements OcrService {
  const NoopOcrService();

  @override
  Future<OcrResult?> recognise(File image) async => null;

  @override
  Future<void> dispose() async {}
}
