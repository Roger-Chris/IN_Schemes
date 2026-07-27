import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/voice_assistant_overlay.dart';

void main() {
  testWidgets(
    'voice assistant presents its panel and full-screen edge outline',
    (tester) async {
      var closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: VoiceAssistantOverlay(
            autoStart: false,
            onClose: () => closed = true,
            onSubmit: (_) {},
          ),
        ),
      );

      expect(find.byKey(const Key('voice-assistant-overlay')), findsOneWidget);
      expect(find.byKey(const Key('voice-edge-outline')), findsOneWidget);
      expect(find.byKey(const Key('voice-assistant-panel')), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.byType(RepaintBoundary), findsWidgets);
      expect(find.text('Ask IN AI'), findsOneWidget);
      expect(find.text('Tap the mic to speak'), findsOneWidget);

      await tester.tap(find.byKey(const Key('voice-close-button')));
      await tester.pump();

      expect(closed, isTrue);
    },
  );

  test('edge painter repaints when animation values change', () {
    const original = VoiceEdgePainter(progress: 0, intensity: 0.2, radius: 28);
    const changed = VoiceEdgePainter(progress: 0.5, intensity: 0.2, radius: 28);

    expect(changed.shouldRepaint(original), isTrue);
  });
}
