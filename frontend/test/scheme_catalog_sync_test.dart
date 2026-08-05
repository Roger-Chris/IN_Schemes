import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/catalog_manifest.dart';
import 'package:frontend/services/scheme_catalog_store.dart';
import 'package:frontend/services/scheme_catalog_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temporaryDirectory;
  late String payload;
  late CatalogManifest manifest;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'scheme_catalog_sync_test_',
    );
    payload = _catalogPayload();
    manifest = _manifest(payload);
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('bundled catalog is used when no cached release exists', () async {
    final store = SchemeCatalogStore(
      rootDirectory: temporaryDirectory,
      assetLoader: () async => payload,
    );

    final stored = await store.loadBestAvailable();

    expect(stored.source, SchemeCatalogSource.bundled);
    expect(stored.manifest, isNull);
    expect(stored.catalog.schemes.single.schemeCode, 'IN001');
  });

  test('verified release is installed and preferred over the bundle', () async {
    final store = SchemeCatalogStore(
      rootDirectory: temporaryDirectory,
      assetLoader: () async => _catalogPayload(name: 'Bundled Scheme'),
    );

    await store.install(manifest, payload);
    final reloaded = SchemeCatalogStore(
      rootDirectory: temporaryDirectory,
      assetLoader: () async => _catalogPayload(name: 'Bundled Scheme'),
    );
    final stored = await reloaded.loadBestAvailable();

    expect(stored.source, SchemeCatalogSource.cached);
    expect(stored.manifest?.id, manifest.id);
    expect(stored.catalog.schemes.single.name, 'Test Scheme');
  });

  test(
    'invalid checksum is rejected without replacing active release',
    () async {
      final store = SchemeCatalogStore(
        rootDirectory: temporaryDirectory,
        assetLoader: () async => payload,
      );
      await store.install(manifest, payload);
      final invalid = CatalogManifest(
        id: '22222222-2222-4222-8222-222222222222',
        version: 2,
        schemaVersion: 1,
        sha256: List.filled(64, '0').join(),
        byteSize: utf8.encode(payload).length,
        schemeCount: 1,
        documentCount: 1,
        serviceCount: 1,
        publishedAt: DateTime.utc(2026, 7, 30, 1),
      );

      await expectLater(store.install(invalid, payload), throwsFormatException);
      expect((await store.readActiveManifest())?.id, manifest.id);
    },
  );

  test('corrupt newest release falls back to the previous activation', () async {
    final store = SchemeCatalogStore(
      rootDirectory: temporaryDirectory,
      assetLoader: () async => payload,
    );
    await store.install(manifest, payload);
    final secondPayload = _catalogPayload(name: 'Second Scheme');
    final secondManifest = _manifest(
      secondPayload,
      id: '44444444-4444-4444-8444-444444444444',
      version: 2,
    );
    await store.install(secondManifest, secondPayload);
    final newestFile = File(
      '${temporaryDirectory.path}${Platform.pathSeparator}scheme_catalog'
      '${Platform.pathSeparator}releases${Platform.pathSeparator}${secondManifest.id}'
      '${Platform.pathSeparator}government_schemes.json',
    );
    await newestFile.writeAsString('{corrupt', flush: true);

    final reloaded = SchemeCatalogStore(
      rootDirectory: temporaryDirectory,
      assetLoader: () async => payload,
    );
    final recovered = await reloaded.loadBestAvailable();

    expect(recovered.manifest?.id, manifest.id);
    expect(recovered.catalog.schemes.single.name, 'Test Scheme');

    final repair = SchemeCatalogSyncService(
      source: _FakeReleaseSource(
        manifest: secondManifest,
        payload: secondPayload,
      ),
      store: reloaded,
      throttle: Duration.zero,
    );
    expect((await repair.syncIfNeeded()).outcome, CatalogSyncOutcome.updated);
    expect(
      (await reloaded.loadBestAvailable()).catalog.schemes.single.name,
      'Second Scheme',
    );
  });

  test('sync downloads a changed release and skips the same release', () async {
    final store = SchemeCatalogStore(
      rootDirectory: temporaryDirectory,
      assetLoader: () async => payload,
    );
    final source = _FakeReleaseSource(manifest: manifest, payload: payload);
    final service = SchemeCatalogSyncService(
      source: source,
      store: store,
      throttle: Duration.zero,
    );

    final first = await service.syncIfNeeded();
    final second = await service.syncIfNeeded();

    expect(first.outcome, CatalogSyncOutcome.updated);
    expect(second.outcome, CatalogSyncOutcome.unchanged);
    expect(source.payloadRequests, 1);
  });

  test('sync keeps local data when remote payload is corrupt', () async {
    final store = SchemeCatalogStore(
      rootDirectory: temporaryDirectory,
      assetLoader: () async => payload,
    );
    await store.install(manifest, payload);
    final changedPayload = _catalogPayload(name: 'Changed Scheme');
    final changedManifest = _manifest(
      changedPayload,
      id: '33333333-3333-4333-8333-333333333333',
      version: 2,
    );
    final source = _FakeReleaseSource(
      manifest: changedManifest,
      payload: '{broken json',
    );
    final service = SchemeCatalogSyncService(
      source: source,
      store: store,
      throttle: Duration.zero,
    );

    final result = await service.syncIfNeeded();

    expect(result.outcome, CatalogSyncOutcome.rejected);
    expect((await store.readActiveManifest())?.id, manifest.id);
  });

  test(
    'unsupported schemas and network failures are non-destructive',
    () async {
      final store = SchemeCatalogStore(
        rootDirectory: temporaryDirectory,
        assetLoader: () async => payload,
      );
      final incompatible = CatalogManifest(
        id: manifest.id,
        version: manifest.version,
        schemaVersion: 99,
        sha256: manifest.sha256,
        byteSize: manifest.byteSize,
        schemeCount: manifest.schemeCount,
        documentCount: manifest.documentCount,
        serviceCount: manifest.serviceCount,
        publishedAt: manifest.publishedAt,
      );
      final incompatibleService = SchemeCatalogSyncService(
        source: _FakeReleaseSource(manifest: incompatible, payload: payload),
        store: store,
      );
      final offlineService = SchemeCatalogSyncService(
        source: _FakeReleaseSource(error: StateError('offline')),
        store: store,
      );

      expect(
        (await incompatibleService.syncIfNeeded()).outcome,
        CatalogSyncOutcome.incompatible,
      );
      expect(
        (await offlineService.syncIfNeeded()).outcome,
        CatalogSyncOutcome.offline,
      );
    },
  );
}

class _FakeReleaseSource implements CatalogReleaseSource {
  _FakeReleaseSource({this.manifest, this.payload = '', this.error});

  final CatalogManifest? manifest;
  final String payload;
  final Object? error;
  int payloadRequests = 0;

  @override
  Future<CatalogManifest?> fetchCurrentManifest() async {
    if (error != null) throw error!;
    return manifest;
  }

  @override
  Future<String> fetchPayload(String releaseId) async {
    payloadRequests += 1;
    if (error != null) throw error!;
    return payload;
  }
}

CatalogManifest _manifest(
  String payload, {
  String id = '11111111-1111-4111-8111-111111111111',
  int version = 1,
}) {
  final bytes = utf8.encode(payload);
  return CatalogManifest(
    id: id,
    version: version,
    schemaVersion: 1,
    sha256: sha256.convert(bytes).toString(),
    byteSize: bytes.length,
    schemeCount: 1,
    documentCount: 1,
    serviceCount: 1,
    publishedAt: DateTime.utc(2026, 7, 30),
  );
}

String _catalogPayload({String name = 'Test Scheme'}) => jsonEncode({
  'All Schemes': [
    {
      'Scheme ID': 'IN001',
      'Scheme Name': name,
      'Verified Eligibility': 'Residents may apply.',
    },
  ],
  'Scheme Info': [
    {
      'Scheme Code': 'IN001',
      'Scheme Name': name,
      'Government Level': 'Central',
      'State': 'All India',
      'Target Sector': 'Education',
      'Target Beneficiary': 'Students',
      'Scheme Type': 'Grant',
      'Overview': 'Test overview',
      'Benefits Description': 'Test benefit',
      'Application Mode': 'Online',
      'Official Website': 'https://example.gov.in',
      'Application URL': 'https://example.gov.in/apply',
      'Status': 'Current',
      'Verified (Yes/No)': 'Yes',
    },
  ],
  'Documents Required': [
    {
      'Scheme Code': 'IN001',
      'Scheme Name': name,
      'Document': 'Identity card',
      'Mandatory': 'Yes',
    },
  ],
  'Services Required': [
    {
      'Service Name': 'IN001 - Application support',
      'Category': 'Support',
      'Mandatory (TRUE/FALSE)': true,
      'Description': 'Application assistance',
    },
  ],
});
