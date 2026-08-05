import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/catalog_manifest.dart';
import 'scheme_catalog_store.dart';

enum CatalogSyncOutcome {
  unchanged,
  updated,
  offline,
  incompatible,
  rejected,
  throttled,
}

class CatalogSyncResult {
  const CatalogSyncResult(this.outcome, {this.manifest, this.message});

  final CatalogSyncOutcome outcome;
  final CatalogManifest? manifest;
  final String? message;

  bool get changed => outcome == CatalogSyncOutcome.updated;
}

abstract class CatalogReleaseSource {
  Future<CatalogManifest?> fetchCurrentManifest();
  Future<String> fetchPayload(String releaseId);
}

class SupabaseCatalogReleaseSource implements CatalogReleaseSource {
  SupabaseCatalogReleaseSource(this._client);

  final SupabaseClient _client;

  @override
  Future<CatalogManifest?> fetchCurrentManifest() async {
    final rows = await _client
        .from('catalog_releases')
        .select(
          'id,version,schema_version,sha256,byte_size,scheme_count,document_count,service_count,published_at',
        )
        .eq('is_current', true)
        .eq('status', 'published')
        .limit(1);
    if (rows.isEmpty) return null;
    return CatalogManifest.fromSupabase(rows.first);
  }

  @override
  Future<String> fetchPayload(String releaseId) async {
    final row = await _client
        .from('catalog_releases')
        .select('payload')
        .eq('id', releaseId)
        .eq('is_current', true)
        .single();
    final payload = row['payload'];
    if (payload is! String) {
      throw const FormatException('Published catalog payload is missing.');
    }
    return payload;
  }
}

class SchemeCatalogSyncService {
  SchemeCatalogSyncService({
    CatalogReleaseSource? source,
    SchemeCatalogStore? store,
    Duration timeout = const Duration(seconds: 8),
    Duration throttle = const Duration(minutes: 15),
    DateTime Function()? clock,
  }) : _source = source,
       _store = store ?? SchemeCatalogStore.instance,
       _timeout = timeout,
       _throttle = throttle,
       _clock = clock ?? DateTime.now;

  static final SchemeCatalogSyncService instance = SchemeCatalogSyncService();

  CatalogReleaseSource? _source;
  final SchemeCatalogStore _store;
  final Duration _timeout;
  final Duration _throttle;
  final DateTime Function() _clock;
  DateTime? _lastCheck;
  Future<CatalogSyncResult>? _inFlight;

  CatalogReleaseSource get _releaseSource =>
      _source ??= SupabaseCatalogReleaseSource(Supabase.instance.client);

  Future<CatalogSyncResult> syncIfNeeded({bool force = false}) {
    final running = _inFlight;
    if (running != null) return running;
    final operation = _sync(force: force);
    _inFlight = operation;
    return operation.whenComplete(() {
      if (identical(_inFlight, operation)) _inFlight = null;
    });
  }

  Future<CatalogSyncResult> _sync({required bool force}) async {
    final now = _clock();
    if (!force &&
        _lastCheck != null &&
        now.difference(_lastCheck!) < _throttle) {
      return CatalogSyncResult(
        CatalogSyncOutcome.throttled,
        manifest: await _store.readActiveManifest(),
      );
    }
    _lastCheck = now;

    CatalogManifest? remote;
    try {
      remote = await _releaseSource.fetchCurrentManifest().timeout(_timeout);
    } catch (error) {
      return CatalogSyncResult(
        CatalogSyncOutcome.offline,
        manifest: await _store.readActiveManifest(),
        message: error.toString(),
      );
    }
    if (remote == null) {
      return CatalogSyncResult(
        CatalogSyncOutcome.unchanged,
        manifest: await _store.readActiveManifest(),
      );
    }
    if (remote.schemaVersion != SchemeCatalogStore.supportedSchemaVersion) {
      return CatalogSyncResult(
        CatalogSyncOutcome.incompatible,
        manifest: remote,
        message: 'A newer app version is required for this catalog.',
      );
    }

    final local = await _store.readActiveManifest();
    if (local?.id == remote.id && local?.sha256 == remote.sha256) {
      return CatalogSyncResult(CatalogSyncOutcome.unchanged, manifest: local);
    }

    try {
      final payload = await _releaseSource
          .fetchPayload(remote.id)
          .timeout(_timeout);
      await _store.install(remote, payload);
      return CatalogSyncResult(CatalogSyncOutcome.updated, manifest: remote);
    } on UnsupportedError catch (error) {
      return CatalogSyncResult(
        CatalogSyncOutcome.incompatible,
        manifest: remote,
        message: error.toString(),
      );
    } catch (error) {
      return CatalogSyncResult(
        CatalogSyncOutcome.rejected,
        manifest: local,
        message: error.toString(),
      );
    }
  }
}
