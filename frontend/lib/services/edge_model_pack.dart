import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

enum EdgeModelPackPhase {
  unknown,
  missing,
  downloading,
  verifying,
  ready,
  failed,
}

@immutable
class EdgeModelPackSnapshot {
  const EdgeModelPackSnapshot({
    this.phase = EdgeModelPackPhase.unknown,
    this.progress = 0,
    this.modelPath,
    this.message,
  });

  final EdgeModelPackPhase phase;
  final double progress;
  final String? modelPath;
  final String? message;

  bool get isReady => phase == EdgeModelPackPhase.ready && modelPath != null;
}

abstract interface class EdgeModelPackStore implements Listenable {
  EdgeModelPackSnapshot get snapshot;
  Future<EdgeModelPackSnapshot> initialize();
  Future<EdgeModelPackSnapshot> download();
  Future<void> cancel();
  void dispose();
}

/// Manages the optional on-device language model as a separately downloaded
/// asset. Keeping it outside the APK avoids forcing a ~378 MiB download on
/// users whose phones should remain on the deterministic low-memory path.
class EdgeModelPack extends ChangeNotifier implements EdgeModelPackStore {
  EdgeModelPack({
    http.Client? client,
    Directory? rootDirectory,
    Uri? modelUri,
    this.modelFileName = defaultModelFileName,
    this.modelBytes = defaultModelBytes,
    this.modelSha256 = defaultModelSha256,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _rootDirectory = rootDirectory,
       modelUri = modelUri ?? defaultModelUri;

  static const defaultModelFileName = 'namma-edge-parser-v1-q4-k-m.gguf';
  static const defaultModelBytes = 396704544;
  static const defaultModelSha256 =
      '6a1cd4ba12d7a45c6a4d87fc821e15915dc0408d57b0a19f546c035c59cc9cd4';
  static final Uri defaultModelUri = Uri.parse(
    'https://github.com/Roger-Chris/IN_Schemes/releases/download/'
    'edge-ai-v1/namma-edge-parser-v1-q4-k-m.gguf',
  );

  final http.Client _client;
  final bool _ownsClient;
  final Directory? _rootDirectory;
  final Uri modelUri;
  final String modelFileName;
  final int modelBytes;
  final String modelSha256;
  EdgeModelPackSnapshot _snapshot = const EdgeModelPackSnapshot();
  bool _cancelled = false;
  bool _disposed = false;

  @override
  EdgeModelPackSnapshot get snapshot => _snapshot;

  Future<Directory> _modelDirectory() async {
    final base = _rootDirectory ?? await getApplicationSupportDirectory();
    return Directory('${base.path}${Platform.pathSeparator}edge_models');
  }

  @override
  Future<EdgeModelPackSnapshot> initialize() async {
    if (_disposed) return _snapshot;
    final directory = await _modelDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}$modelFileName',
    );
    if (await file.exists() && await file.length() == modelBytes) {
      _setSnapshot(
        EdgeModelPackSnapshot(
          phase: EdgeModelPackPhase.ready,
          progress: 1,
          modelPath: file.path,
        ),
      );
    } else {
      _setSnapshot(
        const EdgeModelPackSnapshot(
          phase: EdgeModelPackPhase.missing,
          message: 'The optional Edge AI model is not installed.',
        ),
      );
    }
    return _snapshot;
  }

  @override
  Future<EdgeModelPackSnapshot> download() async {
    if (_disposed) return _snapshot;
    if (_snapshot.isReady) return _snapshot;
    _cancelled = false;
    final directory = await _modelDirectory();
    await directory.create(recursive: true);
    final target = File(
      '${directory.path}${Platform.pathSeparator}$modelFileName',
    );
    final partial = File('${target.path}.part');
    var downloaded = await partial.exists() ? await partial.length() : 0;
    if (downloaded > modelBytes) {
      await partial.delete();
      downloaded = 0;
    }

    _setSnapshot(
      EdgeModelPackSnapshot(
        phase: EdgeModelPackPhase.downloading,
        progress: downloaded / modelBytes,
      ),
    );

    try {
      final request = http.Request('GET', modelUri);
      if (downloaded > 0) request.headers['Range'] = 'bytes=$downloaded-';
      final response = await _client.send(request);
      if (response.statusCode != HttpStatus.ok &&
          response.statusCode != HttpStatus.partialContent) {
        throw HttpException('Model download failed (${response.statusCode}).');
      }
      if (downloaded > 0 && response.statusCode == HttpStatus.ok) {
        await partial.writeAsBytes(const []);
        downloaded = 0;
      }

      final sink = partial.openWrite(
        mode: downloaded > 0 ? FileMode.append : FileMode.write,
      );
      try {
        var lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);
        await for (final chunk in response.stream) {
          if (_cancelled) throw const _EdgeModelDownloadCancelled();
          sink.add(chunk);
          downloaded += chunk.length;
          final now = DateTime.now();
          if (now.difference(lastUpdate) >= const Duration(milliseconds: 120)) {
            lastUpdate = now;
            _setSnapshot(
              EdgeModelPackSnapshot(
                phase: EdgeModelPackPhase.downloading,
                progress: (downloaded / modelBytes).clamp(0, 1),
              ),
            );
          }
        }
        await sink.flush();
      } finally {
        await sink.close();
      }

      if (downloaded != modelBytes) {
        throw const FormatException('The downloaded model is incomplete.');
      }
      _setSnapshot(
        const EdgeModelPackSnapshot(
          phase: EdgeModelPackPhase.verifying,
          progress: 1,
        ),
      );
      final digest = await partial.openRead().transform(sha256).first;
      if (digest.toString() != modelSha256) {
        await partial.delete();
        throw const FormatException('The model checksum did not match.');
      }
      if (await target.exists()) await target.delete();
      await partial.rename(target.path);
      _setSnapshot(
        EdgeModelPackSnapshot(
          phase: EdgeModelPackPhase.ready,
          progress: 1,
          modelPath: target.path,
        ),
      );
    } on _EdgeModelDownloadCancelled {
      _setSnapshot(
        EdgeModelPackSnapshot(
          phase: EdgeModelPackPhase.missing,
          progress: downloaded / modelBytes,
          message: 'Edge AI download paused.',
        ),
      );
    } catch (error) {
      _setSnapshot(
        EdgeModelPackSnapshot(
          phase: EdgeModelPackPhase.failed,
          progress: downloaded / modelBytes,
          message: error.toString(),
        ),
      );
    }
    return _snapshot;
  }

  @override
  Future<void> cancel() async {
    _cancelled = true;
  }

  void _setSnapshot(EdgeModelPackSnapshot value) {
    if (_disposed) return;
    _snapshot = value;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _cancelled = true;
    if (_ownsClient) _client.close();
    super.dispose();
  }
}

class _EdgeModelDownloadCancelled implements Exception {
  const _EdgeModelDownloadCancelled();
}
