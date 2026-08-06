import '../models/catalog_manifest.dart';

enum SchemeCatalogSource { bundled, cached }

class StoredSchemeCatalog {
  const StoredSchemeCatalog({required this.source});
  final SchemeCatalogSource source;
}

/// Out-of-scope legacy store stub retained for backward compatibility with [SchemeCatalogSyncService].
class SchemeCatalogStore {
  SchemeCatalogStore();
  static final SchemeCatalogStore instance = SchemeCatalogStore();
  static const int supportedSchemaVersion = 1;

  Future<CatalogManifest?> readActiveManifest() async => null;
  Future<StoredSchemeCatalog?> install(CatalogManifest manifest, String payload) async => null;
}
