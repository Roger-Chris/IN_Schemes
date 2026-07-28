import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/voice_assistant_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in [const Size(360, 800), const Size(412, 915)]) {
    test(
      'ambient edge glow reaches every edge at ${size.width}x${size.height}',
      () async {
        final image = await _renderEdge(
          size: size,
          entranceProgress: 1,
          ambientProgress: 0.37,
          intensity: 0.7,
          activity: VoiceEdgeActivity.listening,
        );

        expect(image.maxTopAlpha, greaterThan(40));
        expect(image.maxRightAlpha, greaterThan(40));
        expect(image.maxBottomAlpha, greaterThan(40));
        expect(image.maxLeftAlpha, greaterThan(40));
      },
    );
  }

  test('entrance reveals bright sources around all four sides', () async {
    final image = await _renderEdge(
      size: const Size(360, 800),
      entranceProgress: 0.22,
      ambientProgress: 0,
      intensity: 0.25,
      activity: VoiceEdgeActivity.idle,
    );

    expect(image.maxTopAlpha, greaterThan(20));
    expect(image.maxRightAlpha, greaterThan(20));
    expect(image.maxBottomAlpha, greaterThan(20));
    expect(image.maxLeftAlpha, greaterThan(20));
  });

  test(
    'idle, listening, and processing states keep a full perimeter',
    () async {
      for (final activity in [
        VoiceEdgeActivity.idle,
        VoiceEdgeActivity.listening,
        VoiceEdgeActivity.processing,
      ]) {
        final image = await _renderEdge(
          size: const Size(360, 800),
          entranceProgress: 1,
          ambientProgress: 0.61,
          intensity: 0.5,
          activity: activity,
        );

        expect(image.maxTopAlpha, greaterThan(20), reason: '$activity top');
        expect(image.maxRightAlpha, greaterThan(20), reason: '$activity right');
        expect(
          image.maxBottomAlpha,
          greaterThan(20),
          reason: '$activity bottom',
        );
        expect(image.maxLeftAlpha, greaterThan(20), reason: '$activity left');
      }
    },
  );

  test(
    'listening sound level strengthens glow without changing geometry',
    () async {
      const size = Size(360, 800);
      final cache = VoiceEdgeGeometryCache();
      final originalGeometry = cache.resolve(size, 36);
      final quiet = await _renderEdge(
        size: size,
        entranceProgress: 1,
        ambientProgress: 0.25,
        intensity: 0.25,
        activity: VoiceEdgeActivity.listening,
        cache: cache,
      );
      final loud = await _renderEdge(
        size: size,
        entranceProgress: 1,
        ambientProgress: 0.25,
        intensity: 1,
        activity: VoiceEdgeActivity.listening,
        cache: cache,
      );

      expect(cache.resolve(size, 36), same(originalGeometry));
      expect(loud.edgeAlphaTotal, greaterThan(quiet.edgeAlphaTotal));
    },
  );

  test('reduced motion produces a static perimeter', () async {
    const size = Size(360, 800);
    final first = await _renderEdge(
      size: size,
      entranceProgress: 1,
      ambientProgress: 0,
      intensity: 0.5,
      activity: VoiceEdgeActivity.processing,
      reduceMotion: true,
    );
    final later = await _renderEdge(
      size: size,
      entranceProgress: 1,
      ambientProgress: 0.83,
      intensity: 0.5,
      activity: VoiceEdgeActivity.processing,
      reduceMotion: true,
    );

    expect(later.bytes, orderedEquals(first.bytes));
  });
}

Future<_RenderedEdge> _renderEdge({
  required Size size,
  required double entranceProgress,
  required double ambientProgress,
  required double intensity,
  required VoiceEdgeActivity activity,
  bool reduceMotion = false,
  VoiceEdgeGeometryCache? cache,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  VoiceEdgePainter(
    entranceProgress: entranceProgress,
    ambientProgress: ambientProgress,
    activityIntensity: intensity,
    activity: activity,
    radius: 36,
    reduceMotion: reduceMotion,
    geometryCache: cache ?? VoiceEdgeGeometryCache(),
  ).paint(canvas, size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.round(), size.height.round());
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  picture.dispose();
  return _RenderedEdge(
    bytes: data!.buffer.asUint8List(),
    width: size.width.round(),
    height: size.height.round(),
  );
}

class _RenderedEdge {
  const _RenderedEdge({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;

  int get maxTopAlpha => _maxHorizontalAlpha(1);
  int get maxRightAlpha => _maxVerticalAlpha(width - 2);
  int get maxBottomAlpha => _maxHorizontalAlpha(height - 2);
  int get maxLeftAlpha => _maxVerticalAlpha(1);

  int get edgeAlphaTotal =>
      _horizontalAlphaTotal(1) +
      _horizontalAlphaTotal(height - 2) +
      _verticalAlphaTotal(1) +
      _verticalAlphaTotal(width - 2);

  int _alphaAt(int x, int y) => bytes[(y * width + x) * 4 + 3];

  int _maxHorizontalAlpha(int y) {
    var maximum = 0;
    for (var x = 0; x < width; x++) {
      maximum = mathMax(maximum, _alphaAt(x, y));
    }
    return maximum;
  }

  int _maxVerticalAlpha(int x) {
    var maximum = 0;
    for (var y = 0; y < height; y++) {
      maximum = mathMax(maximum, _alphaAt(x, y));
    }
    return maximum;
  }

  int _horizontalAlphaTotal(int y) {
    var total = 0;
    for (var x = 0; x < width; x++) {
      total += _alphaAt(x, y);
    }
    return total;
  }

  int _verticalAlphaTotal(int x) {
    var total = 0;
    for (var y = 0; y < height; y++) {
      total += _alphaAt(x, y);
    }
    return total;
  }
}

int mathMax(int a, int b) => a > b ? a : b;
