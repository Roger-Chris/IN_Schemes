import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/scheme_catalog.dart';
import 'package:frontend/services/scheme_understanding_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('different needs produce different recommendation sets', () async {
    final catalog = await SchemeCatalog.load();
    const engine = LocalSchemeUnderstandingEngine();
    const statements = <String, Set<String>>{
      'I need help paying college fees for my daughter': {'IN098', 'IN185'},
      'I want to open a small tailoring business': {'IN124'},
      'I am unemployed and need job skill training': {'IN179', 'IN095'},
    };
    final leadingCodes = <String>{};
    for (final entry in statements.entries) {
      final result = await engine.understand(
        SchemeUnderstandingRequest(
          statement: entry.key,
          schemes: catalog.schemes,
          knownFacts: const {},
          questionsAsked: LocalSchemeUnderstandingEngine.maxFollowUpQuestions,
        ),
      );
      final codes = result.recommendations
          .take(3)
          .map((item) => item.scheme.schemeCode)
          .toSet();
      expect(codes.intersection(entry.value), isNotEmpty, reason: entry.key);
      leadingCodes.add(result.recommendations.first.scheme.schemeCode);
    }
    expect(leadingCodes, hasLength(statements.length));
  });
}
