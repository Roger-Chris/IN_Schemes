import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/mss_entity.dart';

/// Top-level isolate function for async gzip decompression and JSON decoding.
/// Executed off the UI main thread via [compute] to prevent startup jank.
Map<String, dynamic> _decompressAndParseJson(Uint8List bytes) {
  final decompressedBytes = GZipDecoder().decodeBytes(bytes);
  final utf8String = utf8.decode(decompressedBytes);
  return jsonDecode(utf8String) as Map<String, dynamic>;
}

/// MssCatalogBundle
/// ─────────────────
/// Lazy Singleton loader and in-memory index for the offline catalog bundle.
/// Loads catalog_bundle.json.gz exactly once per app lifespan, verifies SHA-256 checksum,
/// and builds O(1) dual indexes (`byId` and `byCatalog`) along with a combined multilingual search index.
class MssCatalogBundle {
  MssCatalogBundle._({
    required Map<String, MssEntity> byId,
    required Map<String, List<MssEntity>> byCatalog,
    required Map<String, Set<String>> searchTokenMap,
    required this.releaseTag,
    required this.totalRelationshipsCount,
    this.duplicateEntityIdCount = 0,
    this.danglingReferenceCount = 0,
    this.uniqueRelationshipIdsCount = 0,
  })  : byId = UnmodifiableMapView(byId),
        byCatalog = UnmodifiableMapView(
          byCatalog.map((k, v) => MapEntry(k, UnmodifiableListView(v))),
        ),
        _searchTokenMap = searchTokenMap;

  static MssCatalogBundle? _instance;
  static Future<MssCatalogBundle>? _loadFuture;

  static const String releaseAssetPath = 'assets/catalog/release.json';
  static const String bundleAssetPath = 'assets/catalog/catalog_bundle.json.gz';

  final Map<String, MssEntity> byId;
  final Map<String, List<MssEntity>> byCatalog;
  final Map<String, Set<String>> _searchTokenMap;
  final String releaseTag;
  final int totalRelationshipsCount;
  final int duplicateEntityIdCount;
  final int danglingReferenceCount;
  final int uniqueRelationshipIdsCount;

  /// Total count of catalog entities across all catalogs (969).
  int get totalEntitiesCount => byId.length;

  /// Helper to get all scheme entities (217).
  List<MssEntity> get schemes => byCatalog['scheme'] ?? const [];

  /// Get a single entity by ID in O(1) time.
  MssEntity? getEntity(String id) => byId[id];

  /// Get all entities for a catalog type (e.g. 'scheme', 'authority', 'finance').
  List<MssEntity> getCatalog(String catalogName) =>
      byCatalog[catalogName] ?? const [];

  /// Asynchronous lazy singleton loader.
  /// Guarantees catalog_bundle.json.gz is loaded, verified, and decompressed ONCE.
  static Future<MssCatalogBundle> load({bool overrideChecksumForTest = false}) {
    if (_instance != null) return Future.value(_instance!);
    return _loadFuture ??= _loadInternal(overrideChecksumForTest: overrideChecksumForTest);
  }

  /// Reset instance (for testing checksum exceptions).
  @visibleForTesting
  static void resetForTesting() {
    _instance = null;
    _loadFuture = null;
  }

  static Future<MssCatalogBundle> _loadInternal({bool overrideChecksumForTest = false}) async {
    String releaseJsonStr;
    Uint8List compressedBytes;

    try {
      releaseJsonStr = await rootBundle.loadString(releaseAssetPath);
      final ByteData bundleByteData = await rootBundle.load(bundleAssetPath);
      compressedBytes = bundleByteData.buffer.asUint8List(
        bundleByteData.offsetInBytes,
        bundleByteData.lengthInBytes,
      );
    } catch (_) {
      // Fallback for Flutter unit test environment where rootBundle asset bundle is uninitialized
      final releaseFile = File(releaseAssetPath);
      releaseJsonStr = await releaseFile.readAsString();
      final bundleFile = File(bundleAssetPath);
      compressedBytes = await bundleFile.readAsBytes();
    }

    final releaseJson = jsonDecode(releaseJsonStr) as Map<String, dynamic>;
    final expectedChecksum = (releaseJson['bundleSha256'] as String?)?.toLowerCase() ?? '';
    final releaseTag = (releaseJson['releaseTag'] as String?) ?? 'unknown';

    // Verify SHA-256 Checksum
    final actualChecksum = sha256.convert(compressedBytes).toString().toLowerCase();
    if (!overrideChecksumForTest && actualChecksum != expectedChecksum) {
      throw Exception(
        'Catalog bundle SHA-256 checksum mismatch. Expected: $expectedChecksum, Got: $actualChecksum',
      );
    }

    // Offload gzip decompression & JSON decode to isolate via compute()
    final Map<String, dynamic> bundleJson = await compute(
      _decompressAndParseJson,
      compressedBytes,
    );

    final byId = <String, MssEntity>{};
    final byCatalog = <String, List<MssEntity>>{};
    final searchTokenMap = <String, Set<String>>{};
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
      if (catalogObject == null) continue;

      final catalogName = (catalogObject['metadata']?['catalogName'] as String?) ??
          fileKey.replaceAll('_catalog.json', '');

      final dataList = catalogObject['data'] as List?;
      if (dataList == null) continue;

      final entityList = <MssEntity>[];

      for (final rawItem in dataList) {
        if (rawItem is! Map<String, dynamic>) continue;
        final entity = MssEntity.fromJson(rawItem);
        if (entity.id.isEmpty) continue;

        if (seenEntityIds.contains(entity.id)) {
          duplicateEntityIdCount++;
        } else {
          seenEntityIds.add(entity.id);
        }

        byId[entity.id] = entity;
        entityList.add(entity);

        // Count relationships
        totalRels += entity.references.length;

        // Index multilingual search tokens
        _indexSearchTokens(entity, searchTokenMap);
      }

      byCatalog[catalogName] = entityList;
    }

    // Graph integrity verification pass: check dangling references
    int danglingReferenceCount = 0;
    final seenRelIds = <String>{};
    for (final entity in byId.values) {
      for (final ref in entity.references) {
        final relId = ref['relationshipId'] as String? ?? ref['id'] as String?;
        if (relId != null && relId.isNotEmpty) {
          seenRelIds.add(relId);
        }
        final targetId = ref['targetId'] as String? ?? ref['target_id'] as String?;
        if (targetId != null && targetId.isNotEmpty && !byId.containsKey(targetId)) {
          danglingReferenceCount++;
        }
      }
    }

    _instance = MssCatalogBundle._(
      byId: byId,
      byCatalog: byCatalog,
      searchTokenMap: searchTokenMap,
      releaseTag: releaseTag,
      totalRelationshipsCount: totalRels,
      duplicateEntityIdCount: duplicateEntityIdCount,
      danglingReferenceCount: danglingReferenceCount,
      uniqueRelationshipIdsCount: seenRelIds.length,
    );

    return _instance!;
  }

  static void _indexSearchTokens(
    MssEntity entity,
    Map<String, Set<String>> tokenMap,
  ) {
    final searchObj = entity.raw['search'] as Map<String, dynamic>?;
    final tokensObj = searchObj?['tokens'] as Map<String, dynamic>?;
    final keywordsObj = searchObj?['keywords'] as Map<String, dynamic>?;

    final tokenSet = <String>{};

    void addTokens(dynamic list) {
      if (list is List) {
        for (final item in list) {
          if (item is String && item.trim().isNotEmpty) {
            tokenSet.add(item.toLowerCase().trim());
          }
        }
      }
    }

    if (tokensObj != null) {
      addTokens(tokensObj['en']);
      addTokens(tokensObj['ta']);
    }
    if (keywordsObj != null) {
      addTokens(keywordsObj['en']);
      addTokens(keywordsObj['ta']);
    }

    // Add name tokens as fallback
    final nameEn = entity.getLocalizedName('en');
    final nameTa = entity.getLocalizedName('ta');
    for (final word in nameEn.split(RegExp(r'\s+'))) {
      if (word.trim().isNotEmpty) tokenSet.add(word.toLowerCase().trim());
    }
    for (final word in nameTa.split(RegExp(r'\s+'))) {
      if (word.trim().isNotEmpty) tokenSet.add(word.toLowerCase().trim());
    }

    for (final token in tokenSet) {
      tokenMap.putIfAbsent(token, () => <String>{}).add(entity.id);
    }
  }

  /// O(token lookup) Multilingual search across English and Tamil tokens.
  /// UI language controls display only, never matching.
  List<MssEntity> search(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return schemes;

    final matchingIds = <String>{};
    final queryTokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);

    for (final token in queryTokens) {
      for (final entry in _searchTokenMap.entries) {
        if (entry.key.contains(token)) {
          matchingIds.addAll(entry.value);
        }
      }
    }

    final results = <MssEntity>[];
    for (final id in matchingIds) {
      final entity = byId[id];
      if (entity != null && entity.entityType == 'scheme') {
        results.add(entity);
      }
    }

    return results;
  }

  // ── Graph Relationship Resolution Extensions ───────────────────────

  /// Resolves all forward linked entities declared in [entity.references]
  /// with optional filtering by [targetType] and [relationType].
  List<MssEntity> getLinkedEntities(
    MssEntity entity, {
    String? targetType,
    String? relationType,
  }) {
    final results = <MssEntity>[];
    final seenIds = <String>{};

    for (final ref in entity.references) {
      final tId = (ref['entityId'] ?? ref['targetId'] ?? ref['target_id'] ?? ref['id'])?.toString();
      if (tId == null || tId.isEmpty || seenIds.contains(tId)) continue;

      final relType = (ref['relationType'] ?? ref['type'] ?? '').toString().toLowerCase();
      final refType = (ref['entityType'] ?? ref['targetType'] ?? '').toString().toLowerCase();

      if (relationType != null && relationType.isNotEmpty) {
        if (!relType.contains(relationType.toLowerCase())) continue;
      }

      final target = getEntity(tId);
      if (target == null) continue;

      final actualType = target.entityType.toLowerCase();
      if (targetType != null && targetType.isNotEmpty) {
        final expectedType = targetType.toLowerCase();
        if (actualType != expectedType && refType != expectedType) continue;
      }

      seenIds.add(tId);
      results.add(target);
    }

    return results;
  }

  /// Resolves reverse linked entities in [catalogName] pointing to [targetSchemeId].
  List<MssEntity> getReverseLinkedEntities(
    String targetSchemeId,
    String catalogName,
  ) {
    final results = <MssEntity>[];
    final entities = getCatalog(catalogName);

    for (final e in entities) {
      bool matches = false;
      final content = e.content;
      if (content['schemeId']?.toString() == targetSchemeId) {
        matches = true;
      }
      if (!matches && content['evidencedInSchemes'] is List) {
        final list = (content['evidencedInSchemes'] as List).map((x) => x.toString());
        if (list.contains(targetSchemeId)) matches = true;
      }
      if (!matches) {
        for (final ref in e.references) {
          final tId = (ref['entityId'] ?? ref['targetId'] ?? ref['target_id'] ?? ref['id'])?.toString();
          if (tId == targetSchemeId) {
            matches = true;
            break;
          }
        }
      }
      if (matches) results.add(e);
    }
    return results;
  }

  /// Resolve authorities administering or linked to a scheme entity.
  List<MssEntity> getAuthoritiesForScheme(MssEntity scheme) {
    return getLinkedEntities(scheme, targetType: 'authority');
  }

  /// Resolve institutions implementing or linked to a scheme entity.
  List<MssEntity> getInstitutionsForScheme(MssEntity scheme) {
    return getLinkedEntities(scheme, targetType: 'institution');
  }

  /// Resolve finance products linked forward or reverse to a scheme entity.
  List<MssEntity> getFinanceProductsForScheme(MssEntity scheme) {
    final forward = getLinkedEntities(scheme, targetType: 'finance_product');
    final reverse = getReverseLinkedEntities(scheme.id, 'finance');
    final map = <String, MssEntity>{};
    for (final e in [...forward, ...reverse]) {
      map[e.id] = e;
    }
    return map.values.toList();
  }

  /// Resolve tax provisions linked forward or reverse to a scheme entity.
  List<MssEntity> getTaxProvisionsForScheme(MssEntity scheme) {
    final forward = getLinkedEntities(scheme, targetType: 'tax_provision');
    final reverse = getReverseLinkedEntities(scheme.id, 'tax');
    final map = <String, MssEntity>{};
    for (final e in [...forward, ...reverse]) {
      map[e.id] = e;
    }
    return map.values.toList();
  }

  /// Resolve export benefits linked forward or reverse to a scheme entity.
  List<MssEntity> getExportBenefitsForScheme(MssEntity scheme) {
    final forward = getLinkedEntities(scheme, targetType: 'export_benefit');
    final reverse = getReverseLinkedEntities(scheme.id, 'export');
    final map = <String, MssEntity>{};
    for (final e in [...forward, ...reverse]) {
      map[e.id] = e;
    }
    return map.values.toList();
  }

  /// Resolve CSR provisions linked forward or reverse to a scheme entity.
  List<MssEntity> getCsrProvisionsForScheme(MssEntity scheme) {
    final forward = getLinkedEntities(scheme, targetType: 'csr_provision');
    final reverse = getReverseLinkedEntities(scheme.id, 'csr');
    final map = <String, MssEntity>{};
    for (final e in [...forward, ...reverse]) {
      map[e.id] = e;
    }
    return map.values.toList();
  }

  /// Resolve TReDS platforms linked forward or reverse to a scheme entity.
  List<MssEntity> getTredsPlatformsForScheme(MssEntity scheme) {
    final forward = getLinkedEntities(scheme, targetType: 'treds_platform');
    final reverse = getReverseLinkedEntities(scheme.id, 'treds');
    final map = <String, MssEntity>{};
    for (final e in [...forward, ...reverse]) {
      map[e.id] = e;
    }
    return map.values.toList();
  }

  /// Resolve knowledge items linked forward or reverse to a scheme entity.
  List<MssEntity> getKnowledgeItemsForScheme(MssEntity scheme) {
    final forward = getLinkedEntities(scheme, targetType: 'knowledge_item');
    final reverse = getReverseLinkedEntities(scheme.id, 'knowledge');
    final map = <String, MssEntity>{};
    for (final e in [...forward, ...reverse]) {
      map[e.id] = e;
    }
    return map.values.toList();
  }
}

