import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../models/catalog_manifest.dart';
import 'scheme_catalog.dart';

enum SchemeCatalogSource { bundled, cached }

class StoredSchemeCatalog {
  const StoredSchemeCatalog({
    required this.catalog,
    required this.source,
    this.manifest,
  });

  final SchemeCatalog catalog;
  final SchemeCatalogSource source;
  final CatalogManifest? manifest;
}

typedef CatalogAssetLoader = Future<String> Function();

class SchemeCatalogStore {
  SchemeCatalogStore({
    Directory? rootDirectory,
    CatalogAssetLoader? assetLoader,
  }) : _rootDirectory = rootDirectory,
       _assetLoader =
           assetLoader ??
           (() => rootBundle.loadString(SchemeCatalog.assetPath));

  static final SchemeCatalogStore instance = SchemeCatalogStore();
  static const int supportedSchemaVersion = 1;

  final Directory? _rootDirectory;
  final CatalogAssetLoader _assetLoader;
  StoredSchemeCatalog? _memoryCache;

  Future<StoredSchemeCatalog> loadBestAvailable() async {
    final memory = _memoryCache;
    if (memory != null) return memory;
    final cached = await _loadLatestCached();
    if (cached != null) {
      _memoryCache = cached;
      return cached;
    }
    final contents = await _assetLoader();
    final bundled = StoredSchemeCatalog(
      catalog: SchemeCatalog.fromJson(contents),
      source: SchemeCatalogSource.bundled,
    );
    _memoryCache = bundled;
    return bundled;
  }

  Future<CatalogManifest?> readActiveManifest() async =>
      _memoryCache?.manifest ?? (await _loadLatestCached())?.manifest;

  Future<StoredSchemeCatalog?> _loadLatestCached() async {
    final activationDirectory = await _activationDirectory();
    if (!await activationDirectory.exists()) return null;
    final pointers = await activationDirectory
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.json'))
        .cast<File>()
        .toList();
    pointers.sort((a, b) => b.path.compareTo(a.path));
    for (final pointer in pointers) {
      try {
        final manifest = CatalogManifest.fromJson(
          jsonDecode(await pointer.readAsString()) as Map<String, dynamic>,
        );
        final releaseFile = await _releaseFile(manifest.id);
        if (!await releaseFile.exists()) continue;
        final contents = await releaseFile.readAsString();
        final catalog = _validate(contents, manifest);
        return StoredSchemeCatalog(
          catalog: catalog,
          source: SchemeCatalogSource.cached,
          manifest: manifest,
        );
      } catch (_) {
        // Ignore an interrupted/corrupt activation and try the previous one.
      }
    }
    return null;
  }

  Future<StoredSchemeCatalog> install(
    CatalogManifest manifest,
    String payload,
  ) async {
    final catalog = _validate(payload, manifest);
    final releaseFile = await _releaseFile(manifest.id);
    await releaseFile.parent.create(recursive: true);

    var needsWrite = !await releaseFile.exists();
    if (!needsWrite) {
      try {
        _validate(await releaseFile.readAsString(), manifest);
      } catch (_) {
        needsWrite = true;
      }
    }
    if (needsWrite) {
      final partial = File('${releaseFile.path}.part');
      await partial.writeAsString(payload, flush: true);
      if (await releaseFile.exists()) await releaseFile.delete();
      await partial.rename(releaseFile.path);
    }

    final activations = await _activationDirectory();
    await activations.create(recursive: true);
    final stamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    final pointer = File(
      '${activations.path}${Platform.pathSeparator}$stamp-${manifest.id}.json',
    );
    final partialPointer = File('${pointer.path}.part');
    await partialPointer.writeAsString(
      jsonEncode(manifest.toJson()),
      flush: true,
    );
    await partialPointer.rename(pointer.path);

    final stored = StoredSchemeCatalog(
      catalog: catalog,
      source: SchemeCatalogSource.cached,
      manifest: manifest,
    );
    _memoryCache = stored;
    return stored;
  }

  SchemeCatalog _validate(String contents, CatalogManifest manifest) {
    if (!manifest.isStructurallyValid) {
      throw const FormatException('Catalog manifest is invalid.');
    }
    if (manifest.schemaVersion != supportedSchemaVersion) {
      throw UnsupportedError(
        'Catalog schema ${manifest.schemaVersion} is not supported.',
      );
    }
    final bytes = utf8.encode(contents);
    if (bytes.length != manifest.byteSize) {
      throw const FormatException('Catalog byte size does not match manifest.');
    }
    if (sha256.convert(bytes).toString() != manifest.sha256) {
      throw const FormatException('Catalog checksum does not match manifest.');
    }

    final root = jsonDecode(contents);
    if (root is! Map<String, dynamic>) {
      throw const FormatException('Catalog root must be an object.');
    }
    for (final section in const [
      'All Schemes',
      'Scheme Info',
      'Documents Required',
      'Services Required',
    ]) {
      if (root[section] is! List) {
        throw FormatException('Catalog section "$section" is missing.');
      }
    }
    final infoRows = (root['Scheme Info'] as List)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    if (infoRows.length != manifest.schemeCount) {
      throw const FormatException('Scheme count does not match manifest.');
    }
    final codes = infoRows
        .map((row) => row['Scheme Code']?.toString() ?? '')
        .toList(growable: false);
    if (codes.any((code) => !RegExp(r'^IN\d{3}$').hasMatch(code)) ||
        codes.toSet().length != codes.length) {
      throw const FormatException('Scheme codes are invalid or duplicated.');
    }
    if ((root['Documents Required'] as List).length != manifest.documentCount ||
        (root['Services Required'] as List).length != manifest.serviceCount) {
      throw const FormatException(
        'Document or service count does not match manifest.',
      );
    }
    final catalog = SchemeCatalog.fromJson(contents);
    if (catalog.schemes.length != manifest.schemeCount) {
      throw const FormatException(
        'Catalog parser rejected one or more schemes.',
      );
    }
    return catalog;
  }

  Future<File> _releaseFile(String releaseId) async {
    final root = await _catalogDirectory();
    return File(
      '${root.path}${Platform.pathSeparator}releases${Platform.pathSeparator}$releaseId${Platform.pathSeparator}government_schemes.json',
    );
  }

  Future<Directory> _activationDirectory() async {
    final root = await _catalogDirectory();
    return Directory('${root.path}${Platform.pathSeparator}activations');
  }

  Future<Directory> _catalogDirectory() async {
    final base = _rootDirectory ?? await getApplicationSupportDirectory();
    return Directory('${base.path}${Platform.pathSeparator}scheme_catalog');
  }
}
