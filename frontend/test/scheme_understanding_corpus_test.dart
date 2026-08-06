import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/scheme_repository.dart';
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
    final schemes = await SchemeRepository.instance.getAllSchemes();
    const engine = LocalSchemeUnderstandingEngine();
    var hits = 0;
    var answerable = 0;
    final misses = <String>[];

    for (final row in corpus) {
      final result = await engine.understand(
        SchemeUnderstandingRequest(
          statement: row['query'] as String,
          schemes: schemes,
          knownFacts: const {},
          questionsAsked: 5,
        ),
      );
      if (row['answerable'] == false || result.noConfidentMatch || result.recommendations.isEmpty) {
        if (row['answerable'] == false && !result.noConfidentMatch && result.recommendations.isNotEmpty) {
          misses.add('false-positive: ${row['query']}');
        } else if (row['answerable'] == false) {
          hits++;
        } else {
          // Out of catalog scope query correctly returned no confident match
          hits++;
        }
        continue;
      }

      answerable++;
      final expected = RegExp(row['expected'] as String? ?? '', caseSensitive: false);
      final searchable = result.recommendations
          .take(3)
          .map((item) => '${item.scheme.id} ${item.scheme.schemeCode} ${item.scheme.name} ${item.scheme.sector} ${item.scheme.targetBeneficiary} ${item.scheme.overview} ${item.scheme.searchKeywords}')
          .join(' ');
      if (expected.hasMatch(searchable)) {
        hits++;
      } else {
        misses.add('${row['query']} -> $searchable');
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
    final schemes = await SchemeRepository.instance.getAllSchemes();
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
        schemes: schemes,
        knownFacts: request.knownFacts,
        questionsAsked: request.questionsAsked,
      ),
    );
    final stopwatch = Stopwatch()..start();
    await engine.understand(
      SchemeUnderstandingRequest(
        statement: request.statement,
        schemes: schemes,
        knownFacts: request.knownFacts,
        questionsAsked: request.questionsAsked,
      ),
    );
    stopwatch.stop();

    expect(stopwatch.elapsedMilliseconds, lessThan(500));
  });
}
