import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/scheme_repository.dart';
import 'package:frontend/services/scheme_understanding_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('different needs produce different recommendation sets', () async {
    final schemes = await SchemeRepository.instance.getAllSchemes();
    const engine = LocalSchemeUnderstandingEngine();
    const statements = <String>[
      'I need help paying college fees for my daughter',
      'I want to open a small tailoring business',
      'I am unemployed and need job skill training',
    ];
    final leadingCodes = <String>{};
    for (final statement in statements) {
      final result = await engine.understand(
        SchemeUnderstandingRequest(
          statement: statement,
          schemes: schemes,
          knownFacts: const {},
          questionsAsked: LocalSchemeUnderstandingEngine.maxFollowUpQuestions,
        ),
      );
      expect(result.recommendations, isNotEmpty, reason: statement);
      final topScheme = result.recommendations.first.scheme;
      leadingCodes.add(topScheme.id);
    }
    expect(leadingCodes.length, greaterThan(1));
  });
}
