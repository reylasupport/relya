/// How something arrived. Share sheet is the one that matters most (spec 17).
enum CaptureSource {
  shareSheet('share_sheet'),
  camera('camera'),
  photoLibrary('photo_library'),
  fileUpload('file_upload'),
  pastedText('pasted_text'),
  email('email'),
  manual('manual'),
  demo('demo');

  const CaptureSource(this.wire);

  final String wire;

  static CaptureSource fromWire(String? value) => values.firstWhere(
    (s) => s.wire == value,
    orElse: () => CaptureSource.manual,
  );
}

enum CaptureKind {
  image('image'),
  pdf('pdf'),
  text('text'),
  url('url');

  const CaptureKind(this.wire);

  final String wire;

  static CaptureKind fromWire(String? value) =>
      values.firstWhere((k) => k.wire == value, orElse: () => CaptureKind.text);
}

/// Inbox lifecycle (spec section 25).
enum CaptureStatus {
  /// Accepted locally, waiting for connectivity or for its turn.
  queued('queued'),
  processing('processing'),

  /// Extraction finished and the user has to look at it.
  needsConfirmation('needs_confirmation'),

  /// Everything extracted has been accepted or dismissed.
  completed('completed'),
  failed('failed'),
  archived('archived');

  const CaptureStatus(this.wire);

  final String wire;

  static CaptureStatus fromWire(String? value) => values.firstWhere(
    (s) => s.wire == value,
    orElse: () => CaptureStatus.queued,
  );

  bool get isTerminal =>
      this == completed || this == failed || this == archived;

  bool get isWorking => this == queued || this == processing;
}

/// One thing the user sent in. Holds the raw input and the pipeline state; the
/// meaning extracted from it lives in [LifeItem]s that point back here.
class Capture {
  const Capture({
    required this.id,
    required this.source,
    required this.kind,
    required this.status,
    required this.createdAt,
    this.title,
    this.rawText,
    this.sourceUrl,
    this.localFilePath,
    this.storagePath,
    this.contentHash,
    this.ocrText,
    this.detectedLanguage,
    this.itemCount = 0,
    this.errorMessage,
    this.processedAt,
  });

  final String id;
  final CaptureSource source;
  final CaptureKind kind;
  final CaptureStatus status;

  /// Short human label for the Inbox row, e.g. "Screenshot" or the URL host.
  final String? title;

  /// Text the user pasted, or the shared text payload.
  final String? rawText;
  final String? sourceUrl;

  /// Set while the file is still only on the device (offline, or the user
  /// chose not to keep the original in the cloud).
  final String? localFilePath;
  final String? storagePath;

  /// SHA-256 of the input. Guards against analysing the same screenshot twice,
  /// which is the single cheapest cost control we have.
  final String? contentHash;

  /// Text produced by on-device OCR, before anything is sent to the server.
  final String? ocrText;
  final String? detectedLanguage;

  final int itemCount;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? processedAt;

  Capture copyWith({
    CaptureStatus? status,
    String? title,
    String? rawText,
    String? storagePath,
    String? ocrText,
    String? detectedLanguage,
    String? contentHash,
    int? itemCount,
    String? errorMessage,
    DateTime? processedAt,
  }) {
    return Capture(
      id: id,
      source: source,
      kind: kind,
      status: status ?? this.status,
      title: title ?? this.title,
      rawText: rawText ?? this.rawText,
      sourceUrl: sourceUrl,
      localFilePath: localFilePath,
      storagePath: storagePath ?? this.storagePath,
      contentHash: contentHash ?? this.contentHash,
      ocrText: ocrText ?? this.ocrText,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      itemCount: itemCount ?? this.itemCount,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }

  factory Capture.fromJson(Map<String, dynamic> json) {
    DateTime? parse(String key) {
      final raw = json[key];
      return raw == null ? null : DateTime.parse(raw as String).toUtc();
    }

    return Capture(
      id: json['id'] as String,
      source: CaptureSource.fromWire(json['source'] as String?),
      kind: CaptureKind.fromWire(json['kind'] as String?),
      status: CaptureStatus.fromWire(json['status'] as String?),
      title: json['title'] as String?,
      rawText: json['raw_text'] as String?,
      sourceUrl: json['source_url'] as String?,
      storagePath: json['storage_path'] as String?,
      contentHash: json['content_hash'] as String?,
      ocrText: json['ocr_text'] as String?,
      detectedLanguage: json['detected_language'] as String?,
      itemCount: json['item_count'] as int? ?? 0,
      errorMessage: json['error_message'] as String?,
      createdAt: parse('created_at') ?? DateTime.now().toUtc(),
      processedAt: parse('processed_at'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source.wire,
    'kind': kind.wire,
    'status': status.wire,
    'title': title,
    'raw_text': rawText,
    'source_url': sourceUrl,
    'storage_path': storagePath,
    'content_hash': contentHash,
    'ocr_text': ocrText,
    'detected_language': detectedLanguage,
    'item_count': itemCount,
    'error_message': errorMessage,
  };

  @override
  bool operator ==(Object other) => other is Capture && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
