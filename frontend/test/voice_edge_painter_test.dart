import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/voice_assistant_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in [const Size(360, 800), const Size(412, 915)]) {
    test(
      'soft bloom reaches the side rails and bottom at ${size.width}x${size.height}',
      () async {
        final image = await _renderEdge(
          size: size,
          entranceProgress: 0.38,
          ambientProgress: 0.37,
          intensity: 0.7,
          activity: VoiceEdgeActivity.listening,
        );

        expect(image.maxRightAlpha, greaterThan(25));
        expect(image.maxBottomAlpha, greaterThan(25));
        expect(image.maxLeftAlpha, greaterThan(25));
        expect(image.topCenterAlpha, lessThan(image.bottomCenterAlpha));
      },
    );
  }

  test('opening bloom rises progressively from the lower edges', () async {
    final early = await _renderEdge(
      size: const Size(360, 800),
      entranceProgress: 0.03,
      ambientProgress: 0,
      intensity: 0.25,
      activity: VoiceEdgeActivity.idle,
    );
    final opened = await _renderEdge(
      size: const Size(360, 800),
      entranceProgress: 0.30,
      ambientProgress: 0.08,
      intensity: 0.25,
      activity: VoiceEdgeActivity.idle,
    );

    expect(opened.upperSideAlphaTotal, greaterThan(early.upperSideAlphaTotal));
    expect(opened.edgeAlphaTotal, greaterThan(early.edgeAlphaTotal));
  });

  test('bloom fades away instead of leaving a permanent border', () async {
    final image = await _renderEdge(
      size: const Size(360, 800),
      entranceProgress: 1,
      ambientProgress: 0.9,
      intensity: 1,
      activity: VoiceEdgeActivity.listening,
    );

    expect(image.edgeAlphaTotal, 0);
  });

  test('listening sound level strengthens the active bloom', () async {
    const size = Size(360, 800);
    final quiet = await _renderEdge(
      size: size,
      entranceProgress: 0.38,
      ambientProgress: 0.25,
      intensity: 0.25,
      activity: VoiceEdgeActivity.listening,
    );
    final loud = await _renderEdge(
      size: size,
      entranceProgress: 0.38,
      ambientProgress: 0.25,
      intensity: 1,
      activity: VoiceEdgeActivity.listening,
    );

    expect(loud.edgeAlphaTotal, greaterThan(quiet.edgeAlphaTotal));
  });

  test('reduced motion produces a static soft glow', () async {
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
  int get topCenterAlpha => _alphaAt(width ~/ 2, 1);
  int get bottomCenterAlpha => _alphaAt(width ~/ 2, height - 2);

  int get upperSideAlphaTotal {
    var total = 0;
    for (var y = 0; y < height ~/ 2; y++) {
      total += _alphaAt(1, y) + _alphaAt(width - 2, y);
    }
    return total;
  }

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
