import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/services/intelligent_scheme_search.dart';
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
      expect(find.byKey(const Key('voice-level-bars')), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.byType(RepaintBoundary), findsWidgets);
      expect(find.text('Ask IN AI'), findsOneWidget);
      expect(find.text('Ready'), findsOneWidget);
      expect(find.text('EN'), findsOneWidget);
      expect(find.text('தமிழ்'), findsOneWidget);

      await tester.tap(find.byKey(const Key('voice-close-button')));
      await tester.pump();

      expect(closed, isTrue);
    },
  );

  testWidgets('voice assistant presents ranked results and opens a scheme', (
    tester,
  ) async {
    const scheme = Scheme(
      id: 'IN-VOICE',
      name: 'Women Entrepreneur Loan',
      targetBeneficiary: 'Women entrepreneurs',
    );
    Scheme? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: VoiceAssistantOverlay(
          autoStart: false,
          onClose: () {},
          onSubmit: (_) {},
          onSearch: (_) async => const [
            SchemeSearchMatch(
              scheme: scheme,
              score: 0.9,
              reasons: ['Who it supports'],
            ),
          ],
          onSchemeSelected: (value) => selected = value,
        ),
      ),
    );

    await tester.tap(find.text('Business loans'));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('voice-search-results')), findsOneWidget);
    expect(find.text('Women Entrepreneur Loan'), findsOneWidget);

    await tester.tap(find.byKey(const Key('voice-result-IN-VOICE')));
    expect(selected?.id, 'IN-VOICE');
  });

  test('edge painter repaints when animation values change', () {
    const original = VoiceEdgePainter(progress: 0, intensity: 0.2, radius: 28);
    const changed = VoiceEdgePainter(progress: 0.5, intensity: 0.2, radius: 28);

    expect(changed.shouldRepaint(original), isTrue);
  });

  test('voice level painter repaints for live audio changes', () {
    const original = VoiceLevelPainter(progress: 0, level: 0.2, active: true);
    const changed = VoiceLevelPainter(progress: 0.5, level: 0.8, active: true);

    expect(changed.shouldRepaint(original), isTrue);
  });
}
