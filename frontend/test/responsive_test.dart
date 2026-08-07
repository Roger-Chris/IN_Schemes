/// Unit + widget tests for the Stage 3 shared adaptive-fit helper
/// (lib/utils/responsive.dart), covering the exact formulas the OTP-screen
/// fix in Stage 2 established as the reference pattern.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/responsive.dart';

void main() {
  group('adaptiveRowItemWidth', () {
    test('matches the OTP pin-box formula at 320dp', () {
      // 320 screen - 80 fixed padding = 240 available.
      final w = adaptiveRowItemWidth(
        availableWidth: 240,
        count: 6,
        min: 30,
        max: 42,
      );
      expect(w, closeTo(34.4, 0.01));
    });

    test('caps at max on wide screens', () {
      final w = adaptiveRowItemWidth(
        availableWidth: 720, // 800 screen - 80 padding
        count: 6,
        min: 30,
        max: 42,
      );
      expect(w, 42.0);
    });

    test('floors at min on very narrow available width', () {
      final w = adaptiveRowItemWidth(
        availableWidth: 60,
        count: 6,
        min: 30,
        max: 42,
      );
      expect(w, 30.0);
    });
  });

  group('adaptiveSize', () {
    testWidgets('scales down below the reference width', (tester) async {
      double? result;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(320, 800)),
          child: Builder(
            builder: (context) {
              result = adaptiveSize(
                context,
                base: 42,
                min: 30,
                referenceWidth: 375,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      // 42 * (320/375) = 35.84
      expect(result, closeTo(35.84, 0.01));
    });

    testWidgets('clamps to max on a wider-than-reference screen', (
      tester,
    ) async {
      double? result;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 1000)),
          child: Builder(
            builder: (context) {
              result = adaptiveSize(
                context,
                base: 42,
                min: 30,
                max: 42,
                referenceWidth: 375,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, 42.0);
    });

    testWidgets('never drops below min on a very narrow screen', (
      tester,
    ) async {
      double? result;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(200, 800)),
          child: Builder(
            builder: (context) {
              result = adaptiveSize(
                context,
                base: 42,
                min: 30,
                referenceWidth: 375,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, 30.0);
    });
  });

  group('FitOneLine', () {
    testWidgets(
      'shrinks long text to fit a narrow bounded width without overflowing',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 60,
                child: FitOneLine(
                  child: Text(
                    'This is a much longer label than the available space',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(FittedBox), findsOneWidget);
      },
    );
  });

  group('FlexText', () {
    testWidgets(
      'lets a long label wrap inside a narrow Row instead of overflowing',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 100,
                child: Row(
                  children: [
                    FlexText(
                      child: Text(
                        'This is a much longer label than the available row width',
                        softWrap: true,
                      ),
                    ),
                    const Icon(Icons.edit, size: 12),
                  ],
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(Flexible), findsOneWidget);
      },
    );
  });
}
