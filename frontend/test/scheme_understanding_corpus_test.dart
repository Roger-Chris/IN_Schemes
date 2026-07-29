import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/scheme_catalog.dart';
import 'package:frontend/services/scheme_understanding_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('locked multilingual corpus reaches Recall@3 >= 0.92', () async {
    final corpus =
        (jsonDecode(
                  File(
                    'test/fixtures/scheme_understanding_corpus.json',
                  ).readAsStringSync(),
                )
                as List)
            .cast<Map<String, dynamic>>();
    final catalog = await SchemeCatalog.load();
    const engine = LocalSchemeUnderstandingEngine();
    var hits = 0;
    var answerable = 0;
    final misses = <String>[];

    for (final row in corpus) {
      final result = await engine.understand(
        SchemeUnderstandingRequest(
          statement: row['query'] as String,
          schemes: catalog.schemes,
          knownFacts: const {},
          questionsAsked: 5,
        ),
      );
      if (row['answerable'] == false) {
        expect(
          result.noConfidentMatch,
          isTrue,
          reason:
              'The catalog has no verified answer for: ${row['query']}. '
              'Returned: ${result.recommendations.map((item) => '${item.scheme.schemeCode}:${item.scheme.name}').join(' / ')}',
        );
        continue;
      }
      answerable++;
      final expected = RegExp(row['expected'] as String, caseSensitive: false);
      final searchable = result.recommendations
          .take(3)
          .map((item) {
            final scheme = item.scheme;
            return '${scheme.name} ${scheme.sector} ${scheme.targetBeneficiary} '
                '${scheme.overview} ${scheme.searchKeywords}';
          })
          .join(' ');
      if (expected.hasMatch(searchable)) {
        hits++;
      } else {
        misses.add(
          '${row['mode']}: ${row['query']} => '
          '${result.recommendations.take(3).map((item) => item.scheme.name).join(' / ')}',
        );
      }
    }

    final recall = hits / answerable;
    expect(
      recall,
      greaterThanOrEqualTo(0.92),
      reason:
          'Recall@3 ${recall.toStringAsFixed(3)}; misses: ${misses.join(' || ')}',
    );
  });

  test('real-catalog understanding stays below 250 ms after warm-up', () async {
    final catalog = await SchemeCatalog.load();
    const engine = LocalSchemeUnderstandingEngine();
    const request = SchemeUnderstandingRequest(
      statement:
          'I am a woman in Tamil Nadu and need a loan to start a manufacturing business',
      schemes: [],
      knownFacts: {},
      questionsAsked: 5,
    );
    await engine.understand(
      SchemeUnderstandingRequest(
        statement: request.statement,
        schemes: catalog.schemes,
        knownFacts: request.knownFacts,
        questionsAsked: request.questionsAsked,
      ),
    );
    final stopwatch = Stopwatch()..start();
    await engine.understand(
      SchemeUnderstandingRequest(
        statement: request.statement,
        schemes: catalog.schemes,
        knownFacts: request.knownFacts,
        questionsAsked: request.questionsAsked,
      ),
    );
    stopwatch.stop();

    expect(stopwatch.elapsedMilliseconds, lessThan(250));
  });
}
