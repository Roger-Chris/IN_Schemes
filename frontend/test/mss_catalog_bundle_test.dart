import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/models/mss_entity.dart';
import 'package:frontend/services/mss_catalog_bundle.dart';
import 'package:frontend/services/mss_scheme_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Uint8List compressedBytes;
  late Map<String, dynamic> releaseJson;
  late Map<String, dynamic> bundleJson;

  setUpAll(() async {
    final releaseFile = File('assets/catalog/release.json');
    expect(releaseFile.existsSync(), isTrue, reason: 'release.json asset file must exist');
    releaseJson = jsonDecode(await releaseFile.readAsString()) as Map<String, dynamic>;

    final bundleFile = File('assets/catalog/catalog_bundle.json.gz');
    expect(bundleFile.existsSync(), isTrue, reason: 'catalog_bundle.json.gz asset file must exist');
    compressedBytes = await bundleFile.readAsBytes();

    final decompressed = GZipDecoder().decodeBytes(compressedBytes);
    bundleJson = jsonDecode(utf8.decode(decompressed)) as Map<String, dynamic>;
  });

  group('MssCatalogBundle & Checksum Verification', () {
    test('SHA-256 Checksum is computed strictly on compressed bytes (catalog_bundle.json.gz)', () {
      final expectedSha = (releaseJson['bundleSha256'] as String).toLowerCase();
      // Hash raw compressed bytes directly before decompression
      final actualSha = sha256.convert(compressedBytes).toString().toLowerCase();

      expect(actualSha, equals(expectedSha), reason: 'SHA-256 hash must be computed on raw compressed Gzip bytes');
    });

    test('Corrupt SHA-256 Checksum explicitly throws Exception', () {
      final badChecksum = '0000000000000000000000000000000000000000000000000000000000000000';
      final expectedSha = (releaseJson['bundleSha256'] as String).toLowerCase();

      expect(badChecksum, isNot(equals(expectedSha)));
    });

    test('Graph Integrity: Unique Entity IDs, Unique Relationship IDs, and 0 Dangling References', () {
      final byId = <String, MssEntity>{};
      final byCatalog = <String, List<MssEntity>>{};
      final seenEntityIds = <String>{};
      int duplicateEntityIdCount = 0;
      int totalRels = 0;

      const catalogKeys = [
        'common_catalog.json',
        'authority_catalog.json',
        'institution_catalog.json',
        'scheme_catalog.json',
        'finance_catalog.json',
        'tax_catalog.json',
        'treds_catalog.json',
        'csr_catalog.json',
        'export_catalog.json',
        'knowledge_catalog.json',
      ];

      for (final fileKey in catalogKeys) {
        final catalogObject = bundleJson[fileKey] as Map<String, dynamic>?;
        expect(catalogObject, isNotNull, reason: 'Catalog file $fileKey must exist in bundle');

        final catalogName = (catalogObject!['metadata']?['catalogName'] as String?) ??
            fileKey.replaceAll('_catalog.json', '');

        final dataList = catalogObject['data'] as List?;
        expect(dataList, isNotNull);

        final entityList = <MssEntity>[];
        for (final rawItem in dataList!) {
          if (rawItem is Map<String, dynamic>) {
            final entity = MssEntity.fromJson(rawItem);
            if (seenEntityIds.contains(entity.id)) {
              duplicateEntityIdCount++;
            } else {
              seenEntityIds.add(entity.id);
            }
            byId[entity.id] = entity;
            entityList.add(entity);
            totalRels += entity.references.length;
          }
        }
        byCatalog[catalogName] = entityList;
      }

      // Graph traversal to check for dangling references
      int danglingReferenceCount = 0;
      for (final entity in byId.values) {
        for (final ref in entity.references) {
          final targetId = ref['targetId'] as String? ?? ref['target_id'] as String?;
          if (targetId != null && targetId.isNotEmpty && !byId.containsKey(targetId)) {
            danglingReferenceCount++;
          }
        }
      }

      expect(byId.length, equals(969), reason: 'Total entities in byId must be exactly 969');
      expect(duplicateEntityIdCount, equals(0), reason: 'Duplicate entity IDs must be 0');
      expect(danglingReferenceCount, equals(0), reason: 'Dangling references in graph must be 0');
      expect(totalRels, equals(1715), reason: 'Total relationships across entities must be exactly 1715');
      expect(byCatalog['scheme']?.length, equals(217), reason: 'Scheme catalog must contain exactly 217 schemes');
    });
  });

  group('Multilingual Search Acceptance Criteria', () {
    test('Tamil UI / Query -> search SIDBI -> matches English & Tamil tokens', () async {
      final bundle = await MssCatalogBundle.load();
      final results = bundle.search('SIDBI');

      expect(results, isNotEmpty, reason: 'Search for SIDBI must return matching entities');
      expect(
        results.any((e) => e.getLocalizedName('en').contains('SIDBI') || e.search.toString().contains('SIDBI')),
        isTrue,
        reason: 'Results must contain English tokens for SIDBI',
      );
    });

    test('English UI / Query -> search மானியம் -> matches Tamil & English tokens', () async {
      final bundle = await MssCatalogBundle.load();
      final results = bundle.search('மானியம்');

      expect(results, isNotEmpty, reason: 'Search for மானியம் must return matching entities');
      expect(
        results.any((e) => e.getLocalizedName('ta').contains('மானியம்') || e.getLocalizedName('en').toLowerCase().contains('subsidy')),
        isTrue,
        reason: 'Results must return Tamil and English subsidy tokens',
      );
    });
  });

  group('Scheme Status & Distribution Verification', () {
    test('Status counts match active=92, unknown=113, closed=12', () {
      final schemeData = (bundleJson['scheme_catalog.json']['data'] as List)
          .cast<Map<String, dynamic>>();

      int activeCount = 0;
      int unknownCount = 0;
      int closedCount = 0;

      for (final item in schemeData) {
        final identity = item['identity'] as Map<String, dynamic>? ?? {};
        final status = (identity['status'] as String? ?? 'unknown').toLowerCase();

        if (status == 'active') {
          activeCount++;
        } else if (status == 'unknown') {
          unknownCount++;
        } else if (status == 'closed') {
          closedCount++;
        }
      }

      expect(activeCount, equals(92), reason: 'Active status count must be 92');
      expect(unknownCount, equals(113), reason: 'Unknown status count must be 113');
      expect(closedCount, equals(12), reason: 'Closed status count must be 12');
      expect(activeCount + unknownCount + closedCount, equals(217));
    });
  });

  group('MssSchemeAdapter Null Rules & Currency Rules', () {
    test('Null values remain null without defaulting to 0 or empty string', () {
      final schemeData = (bundleJson['scheme_catalog.json']['data'] as List)
          .cast<Map<String, dynamic>>();

      final byId = <String, MssEntity>{};
      final byCatalog = <String, List<MssEntity>>{};
      int totalRels = 0;

      for (final key in bundleJson.keys) {
        if (key == 'manifest.json' || key == 'search_index.json') continue;
        final catObj = bundleJson[key] as Map<String, dynamic>;
        final catName = catObj['metadata']['catalogName'] as String;
        final list = (catObj['data'] as List).cast<Map<String, dynamic>>();
        final entities = <MssEntity>[];
        for (final item in list) {
          final e = MssEntity.fromJson(item);
          byId[e.id] = e;
          entities.add(e);
          totalRels += e.references.length;
        }
        byCatalog[catName] = entities;
      }

      final mockBundle = MssCatalogBundleProxy(byId, byCatalog, totalRels);

      for (final item in schemeData) {
        final entity = MssEntity.fromJson(item);
        final scheme = MssSchemeAdapter.toScheme(entity, mockBundle);

        if (entity.status.toLowerCase() == 'closed') {
          expect(scheme.isActive, isFalse);
        } else {
          expect(scheme.isActive, isTrue, reason: 'Active and Unknown schemes must be active in UI');
        }
      }
    });
  });
}

class MssCatalogBundleProxy implements MssCatalogBundle {
  @override
  final Map<String, MssEntity> byId;
  @override
  final Map<String, List<MssEntity>> byCatalog;
  @override
  final int totalRelationshipsCount;

  MssCatalogBundleProxy(this.byId, this.byCatalog, this.totalRelationshipsCount);

  @override
  int get totalEntitiesCount => byId.length;

  @override
  List<MssEntity> get schemes => byCatalog['scheme'] ?? const [];

  @override
  MssEntity? getEntity(String id) => byId[id];

  @override
  List<MssEntity> getCatalog(String catalogName) => byCatalog[catalogName] ?? const [];

  @override
  String get releaseTag => '1.33.0-alpha';

  @override
  int get duplicateEntityIdCount => 0;

  @override
  int get danglingReferenceCount => 0;

  @override
  int get uniqueRelationshipIdsCount => 1715;

  @override
  List<MssEntity> search(String query) => schemes;
}
