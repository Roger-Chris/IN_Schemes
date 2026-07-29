import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';

abstract interface class EdgeSlmRuntime {
  bool get isLoaded;
  Future<void> load(String modelPath);
  Future<String> generateStructured({
    required String systemPrompt,
    required String userPrompt,
  });
  Future<void> stop();
  Future<void> dispose();
}

/// CPU-first llama.cpp runtime for the Qwen3 0.6B model.
///
/// The 1536-token context and bounded output are intentional: the model only
/// extracts structured facts. Scheme ranking remains deterministic, which
/// keeps memory and latency bounded on older ARM64 devices.
class QwenEdgeSlmRuntime implements EdgeSlmRuntime {
  QwenEdgeSlmRuntime({LlamaController? controller})
    : _controller = controller ?? LlamaController();

  final LlamaController _controller;
  bool _loaded = false;
  bool _disposed = false;

  @override
  bool get isLoaded => _loaded;

  @override
  Future<void> load(String modelPath) async {
    if (_disposed) throw StateError('The Edge AI runtime is disposed.');
    if (_loaded) return;
    if (!Platform.isAndroid) {
      throw UnsupportedError('The Edge AI runtime currently targets Android.');
    }
    final capability = await _controller.detectGpu();
    const minimumFreeMemory = 850 * 1024 * 1024;
    if (capability.freeRamBytes > 0 &&
        capability.freeRamBytes < minimumFreeMemory) {
      throw StateError(
        'Not enough free memory for the optional model pack. '
        'The lightweight matcher will be used instead.',
      );
    }
    final threads = math.max(2, math.min(4, Platform.numberOfProcessors - 1));
    final stopwatch = Stopwatch()..start();
    await _controller.loadModel(
      modelPath: modelPath,
      threads: threads,
      contextSize: 1536,
      // CPU/NEON is the compatibility baseline. GPU offload is deliberately
      // deferred until it has been verified across Adreno, Mali and PowerVR.
      gpuLayers: 0,
    );
    _loaded = true;
    stopwatch.stop();
    if (kDebugMode) {
      debugPrint(
        '[EdgeAI] Model loaded in ${stopwatch.elapsedMilliseconds} ms; '
        'RSS ${ProcessInfo.currentRss ~/ (1024 * 1024)} MiB.',
      );
    }
  }

  @override
  Future<String> generateStructured({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    if (!_loaded) throw StateError('The Edge AI model is not loaded.');
    final output = StringBuffer();
    final stopwatch = Stopwatch()..start();
    try {
      await for (final token
          in _controller
              .generateChat(
                messages: [
                  ChatMessage(role: 'system', content: systemPrompt),
                  ChatMessage(role: 'user', content: '$userPrompt\n/no_think'),
                ],
                template: 'chatml',
                maxTokens: 192,
                temperature: 0.05,
                topP: 0.8,
                topK: 20,
                minP: 0.02,
                repeatPenalty: 1.08,
                seed: 7,
              )
              .timeout(const Duration(seconds: 25))) {
        output.write(token);
        if (output.length > 6000) {
          await _controller.stop();
          break;
        }
      }
      stopwatch.stop();
      if (kDebugMode) {
        debugPrint(
          '[EdgeAI] Structured extraction finished in '
          '${stopwatch.elapsedMilliseconds} ms; ${output.length} chars.',
        );
      }
      return output.toString();
    } on TimeoutException {
      await _controller.stop();
      rethrow;
    }
  }

  @override
  Future<void> stop() => _controller.stop();

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _loaded = false;
    await _controller.dispose();
  }
}
