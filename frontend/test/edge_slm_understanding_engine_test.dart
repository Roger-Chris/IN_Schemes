import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/services/edge_model_pack.dart';
import 'package:frontend/services/edge_slm_runtime.dart';
import 'package:frontend/services/edge_slm_understanding_engine.dart';
import 'package:frontend/services/scheme_understanding_engine.dart';

void main() {
  const businessScheme = Scheme(
    id: 'IN-BUSINESS',
    schemeCode: 'IN-BUSINESS',
    name: 'Tamil Nadu Small Business Loan',
    state: 'Tamil Nadu',
    sector: 'Business MSME retail entrepreneurship',
    targetBeneficiary: 'New entrepreneurs and small shop owners',
    benefits: 'Loan and capital subsidy for a new shop',
    status: 'Current',
    verificationStatus: 'Verified official source',
    sourceUrl: 'https://example.gov.in/business',
  );

  test(
    'uses SLM concepts and facts without allowing it to rank schemes',
    () async {
      final runtime = _FakeRuntime(
        output: '''noise before JSON
{"language":"tanglish","concepts":["business"],"facts":[{"key":"businessStage","value":"New business","confidence":0.94,"negated":false},{"key":"businessSector","value":"Retail","confidence":0.88,"negated":false}]}''',
      );
      final engine = EdgeSlmUnderstandingEngine(
        modelPack: _ReadyPack(),
        runtime: runtime,
      );

      final result = await engine.understand(
        const SchemeUnderstandingRequest(
          statement: 'enakku oru kadai vaikkanum',
          schemes: [businessScheme],
          knownFacts: {},
          questionsAsked: 0,
        ),
      );

      expect(runtime.loadedPath, '/models/qwen.gguf');
      expect(result.isTamil, isTrue);
      expect(
        result.facts[EligibilityFactKey.businessStage]?.value,
        'New business',
      );
      expect(
        result.facts[EligibilityFactKey.businessStage]?.confirmed,
        isFalse,
      );
      expect(result.recommendations.first.scheme.id, 'IN-BUSINESS');
      await engine.close();
    },
  );

  test('rejects negated and low-confidence generated facts', () async {
    final engine = EdgeSlmUnderstandingEngine(
      modelPack: _ReadyPack(),
      runtime: _FakeRuntime(
        output:
            '{"language":"en","concepts":["business"],"facts":['
            '{"key":"disability","value":"Yes","confidence":0.99,"negated":true},'
            '{"key":"age","value":"44","confidence":0.3,"negated":false}]}',
      ),
    );

    final result = await engine.understand(
      const SchemeUnderstandingRequest(
        statement: 'I want to start a shop',
        schemes: [businessScheme],
        knownFacts: {},
        questionsAsked: 0,
      ),
    );

    expect(result.facts[EligibilityFactKey.disability], isNull);
    expect(result.facts[EligibilityFactKey.age], isNull);
    await engine.close();
  });

  test('does not accept an Indian state as a district', () async {
    final engine = EdgeSlmUnderstandingEngine(
      modelPack: _ReadyPack(),
      runtime: _FakeRuntime(
        output:
            '{"language":"en","concepts":["education"],"facts":['
            '{"key":"district","value":"Tamil Nadu","confidence":0.98,"negated":false}]}',
      ),
    );

    final result = await engine.understand(
      const SchemeUnderstandingRequest(
        statement: 'I am a student from Tamil Nadu looking for a scholarship',
        schemes: [businessScheme],
        knownFacts: {},
        questionsAsked: 0,
      ),
    );

    expect(result.facts[EligibilityFactKey.state]?.value, 'Tamil Nadu');
    expect(result.facts[EligibilityFactKey.district], isNull);
    await engine.close();
  });

  test('rejects unsafe generated community and marital values', () async {
    final engine = EdgeSlmUnderstandingEngine(
      modelPack: _ReadyPack(),
      runtime: _FakeRuntime(
        output:
            '{"language":"en","concepts":["community"],"facts":['
            '{"key":"community","value":"South Carolina","confidence":0.99,"negated":false},'
            '{"key":"maritalStatus","value":"Yes","confidence":0.99,"negated":false}]}',
      ),
    );

    final result = await engine.understand(
      const SchemeUnderstandingRequest(
        statement: 'I need community support',
        schemes: [businessScheme],
        knownFacts: {},
        questionsAsked: 0,
      ),
    );

    expect(result.facts[EligibilityFactKey.community], isNull);
    expect(result.facts[EligibilityFactKey.maritalStatus], isNull);
    await engine.close();
  });

  test(
    'malformed SLM output falls back to deterministic understanding',
    () async {
      final engine = EdgeSlmUnderstandingEngine(
        modelPack: _ReadyPack(),
        runtime: _FakeRuntime(output: 'not json'),
      );

      final result = await engine.understand(
        const SchemeUnderstandingRequest(
          statement: 'I want a business loan for a shop',
          schemes: [businessScheme],
          knownFacts: {},
          questionsAsked: 0,
        ),
      );

      expect(result.recommendations.first.scheme.id, 'IN-BUSINESS');
      await engine.close();
    },
  );

  test('rejects Tanglish classification for Tamil-script input', () async {
    final fallback = _RecordingFallback();
    final engine = EdgeSlmUnderstandingEngine(
      modelPack: _ReadyPack(),
      runtime: _FakeRuntime(
        output: '{"language":"tanglish","concepts":["health"],"facts":[]}',
      ),
      fallback: fallback,
    );

    await engine.understand(
      const SchemeUnderstandingRequest(
        statement: 'எனக்கு தொழில் தொடங்க கடன் வேண்டும்',
        schemes: [businessScheme],
        knownFacts: {},
        questionsAsked: 0,
      ),
    );

    expect(fallback.lastStatement, 'எனக்கு தொழில் தொடங்க கடன் வேண்டும்');
    await engine.close();
  });

  test(
    'missing model uses deterministic understanding without loading runtime',
    () async {
      final runtime = _FakeRuntime(output: '{}');
      final engine = EdgeSlmUnderstandingEngine(
        modelPack: _MissingPack(),
        runtime: runtime,
      );

      final result = await engine.understand(
        const SchemeUnderstandingRequest(
          statement: 'I want a business loan',
          schemes: [businessScheme],
          knownFacts: {},
          questionsAsked: 0,
        ),
      );

      expect(runtime.loadedPath, isNull);
      expect(result.recommendations.first.scheme.id, 'IN-BUSINESS');
      await engine.close();
    },
  );
}

class _ReadyPack extends ChangeNotifier implements EdgeModelPackStore {
  @override
  EdgeModelPackSnapshot get snapshot => const EdgeModelPackSnapshot(
    phase: EdgeModelPackPhase.ready,
    progress: 1,
    modelPath: '/models/qwen.gguf',
  );

  @override
  Future<EdgeModelPackSnapshot> initialize() async => snapshot;

  @override
  Future<EdgeModelPackSnapshot> download() async => snapshot;

  @override
  Future<void> cancel() async {}
}

class _MissingPack extends ChangeNotifier implements EdgeModelPackStore {
  @override
  EdgeModelPackSnapshot get snapshot =>
      const EdgeModelPackSnapshot(phase: EdgeModelPackPhase.missing);

  @override
  Future<EdgeModelPackSnapshot> initialize() async => snapshot;

  @override
  Future<EdgeModelPackSnapshot> download() async => snapshot;

  @override
  Future<void> cancel() async {}
}

class _FakeRuntime implements EdgeSlmRuntime {
  _FakeRuntime({required this.output});

  final String output;
  String? loadedPath;

  @override
  bool get isLoaded => loadedPath != null;

  @override
  Future<void> load(String modelPath) async => loadedPath = modelPath;

  @override
  Future<String> generateStructured({
    required String systemPrompt,
    required String userPrompt,
  }) async => output;

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class _RecordingFallback implements SchemeUnderstandingEngine {
  String? lastStatement;

  @override
  Future<SchemeUnderstandingResult> understand(
    SchemeUnderstandingRequest request,
  ) async {
    lastStatement = request.statement;
    return const SchemeUnderstandingResult(
      isTamil: true,
      concepts: {},
      facts: {},
      recommendations: [],
      excludedUncertainCount: 0,
      elapsed: Duration.zero,
      noConfidentMatch: true,
    );
  }
}
