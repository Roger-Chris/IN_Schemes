class CatalogManifest {
  const CatalogManifest({
    required this.id,
    required this.version,
    required this.schemaVersion,
    required this.sha256,
    required this.byteSize,
    required this.schemeCount,
    required this.documentCount,
    required this.serviceCount,
    required this.publishedAt,
  });

  final String id;
  final int version;
  final int schemaVersion;
  final String sha256;
  final int byteSize;
  final int schemeCount;
  final int documentCount;
  final int serviceCount;
  final DateTime publishedAt;

  factory CatalogManifest.fromSupabase(Map<String, dynamic> row) {
    return CatalogManifest(
      id: row['id']?.toString() ?? '',
      version: (row['version'] as num?)?.toInt() ?? 0,
      schemaVersion: (row['schema_version'] as num?)?.toInt() ?? 0,
      sha256: row['sha256']?.toString() ?? '',
      byteSize: (row['byte_size'] as num?)?.toInt() ?? 0,
      schemeCount: (row['scheme_count'] as num?)?.toInt() ?? 0,
      documentCount: (row['document_count'] as num?)?.toInt() ?? 0,
      serviceCount: (row['service_count'] as num?)?.toInt() ?? 0,
      publishedAt:
          DateTime.tryParse(row['published_at']?.toString() ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  factory CatalogManifest.fromJson(Map<String, dynamic> json) =>
      CatalogManifest.fromSupabase(json);

  Map<String, dynamic> toJson() => {
    'id': id,
    'version': version,
    'schema_version': schemaVersion,
    'sha256': sha256,
    'byte_size': byteSize,
    'scheme_count': schemeCount,
    'document_count': documentCount,
    'service_count': serviceCount,
    'published_at': publishedAt.toUtc().toIso8601String(),
  };

  bool get isStructurallyValid =>
      RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(id) &&
      version > 0 &&
      schemaVersion > 0 &&
      RegExp(r'^[0-9a-f]{64}$').hasMatch(sha256) &&
      byteSize > 0 &&
      schemeCount > 0;
}
