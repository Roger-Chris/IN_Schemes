import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/edge_model_pack.dart';

void main() {
  test(
    'downloads, resumes, verifies and installs a model atomically',
    () async {
      final bytes = utf8.encode('small deterministic edge model fixture');
      final root = await Directory.systemTemp.createTemp('edge-model-pack-');
      final modelDirectory = Directory(
        '${root.path}${Platform.pathSeparator}edge_models',
      );
      await modelDirectory.create(recursive: true);
      final partial = File(
        '${modelDirectory.path}${Platform.pathSeparator}fixture.gguf.part',
      );
      await partial.writeAsBytes(bytes.take(7).toList());

      String? receivedRange;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        receivedRange = request.headers.value(HttpHeaders.rangeHeader);
        request.response.statusCode = HttpStatus.partialContent;
        request.response.add(bytes.skip(7).toList());
        await request.response.close();
      });
      final pack = EdgeModelPack(
        rootDirectory: root,
        modelUri: Uri.parse('http://127.0.0.1:${server.port}/model'),
        modelFileName: 'fixture.gguf',
        modelBytes: bytes.length,
        modelSha256: sha256.convert(bytes).toString(),
      );

      final snapshot = await pack.download();

      expect(receivedRange, 'bytes=7-');
      expect(snapshot.phase, EdgeModelPackPhase.ready);
      expect(await File(snapshot.modelPath!).readAsBytes(), bytes);
      expect(await partial.exists(), isFalse);

      pack.dispose();
      await server.close(force: true);
      await root.delete(recursive: true);
    },
  );

  test('does not install a model with a bad checksum', () async {
    final bytes = utf8.encode('corrupt fixture');
    final root = await Directory.systemTemp.createTemp('edge-model-pack-');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response.add(bytes);
      await request.response.close();
    });
    final pack = EdgeModelPack(
      rootDirectory: root,
      modelUri: Uri.parse('http://127.0.0.1:${server.port}/model'),
      modelFileName: 'fixture.gguf',
      modelBytes: bytes.length,
      modelSha256: sha256.convert(utf8.encode('different')).toString(),
    );

    final snapshot = await pack.download();

    expect(snapshot.phase, EdgeModelPackPhase.failed);
    expect(
      await File(
        '${root.path}${Platform.pathSeparator}edge_models'
        '${Platform.pathSeparator}fixture.gguf',
      ).exists(),
      isFalse,
    );

    pack.dispose();
    await server.close(force: true);
    await root.delete(recursive: true);
  });
}
