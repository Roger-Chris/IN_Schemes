import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'edge_model_pack.dart';
import 'edge_slm_runtime.dart';
import 'scheme_understanding_engine.dart';

enum EdgeSlmPhase {
  checking,
  modelMissing,
  downloading,
  loading,
  ready,
  failed,
}

@immutable
class EdgeSlmSnapshot {
  const EdgeSlmSnapshot({
    this.phase = EdgeSlmPhase.checking,
    this.progress = 0,
    this.message,
  });

  final EdgeSlmPhase phase;
  final double progress;
  final String? message;

  bool get isReady => phase == EdgeSlmPhase.ready;
}

/// Adds a small, quantized local language model in front of the trusted
/// deterministic scheme matcher.
///
/// The SLM may interpret language and extract unconfirmed facts, but it never
/// selects schemes or decides eligibility. Invalid, incomplete, or timed-out
/// output is discarded and the deterministic engine runs unchanged.
class EdgeSlmUnderstandingEngine extends ChangeNotifier
    implements SchemeUnderstandingEngine, ClosableSchemeUnderstandingEngine {
  EdgeSlmUnderstandingEngine({
    required EdgeModelPackStore modelPack,
    required EdgeSlmRuntime runtime,
    SchemeUnderstandingEngine fallback = const LocalSchemeUnderstandingEngine(),
  }) : _modelPack = modelPack,
       _runtime = runtime,
       _fallback = fallback {
    _modelPack.addListener(_handlePackChanged);
  }

  factory EdgeSlmUnderstandingEngine.standard() => EdgeSlmUnderstandingEngine(
    modelPack: EdgeModelPack(),
    runtime: QwenEdgeSlmRuntime(),
  );

  static const _allowedConcepts = <String>{
    'agriculture',
    'education',
    'business',
    'housing',
    'health',
    'employment',
    'disability',
    'senior',
    'marriage',
    'community',
    'fisheries',
    'livestock',
    'food',
  };

  static const _indianStates = <String>{
    'andhra pradesh',
    'arunachal pradesh',
    'assam',
    'bihar',
    'chhattisgarh',
    'goa',
    'gujarat',
    'haryana',
    'himachal pradesh',
    'jharkhand',
    'karnataka',
    'kerala',
    'madhya pradesh',
    'maharashtra',
    'manipur',
    'meghalaya',
    'mizoram',
    'nagaland',
    'odisha',
    'punjab',
    'rajasthan',
    'sikkim',
    'tamil nadu',
    'telangana',
    'tripura',
    'uttar pradesh',
    'uttarakhand',
    'west bengal',
    'andaman and nicobar islands',
    'chandigarh',
    'dadra and nagar haveli and daman and diu',
    'delhi',
    'jammu and kashmir',
    'ladakh',
    'lakshadweep',
    'puducherry',
  };

  static const _systemPrompt = '''
Parse an Indian government-scheme request in English, Tamil, Tanglish, or mixed language. Return JSON only with language, concepts, and explicitly stated facts. Never guess. Valid concepts: agriculture, education, business, housing, health, employment, disability, senior, marriage, community, fisheries, livestock, food. Valid fact keys: age, state, district, annualIncome, gender, community, occupation, education, disability, maritalStatus, studentStatus, businessStage, businessSector, fundingNeed, landholding.
''';

  final EdgeModelPackStore _modelPack;
  final EdgeSlmRuntime _runtime;
  final SchemeUnderstandingEngine _fallback;
  EdgeSlmSnapshot _snapshot = const EdgeSlmSnapshot();
  Future<void>? _preparing;
  bool _closed = false;

  EdgeSlmSnapshot get snapshot => _snapshot;

  Future<void> prepare({bool downloadIfMissing = false}) async {
    if (_closed || _snapshot.isReady) return;
    final active = _preparing;
    if (active != null) await active;
    if (_closed || _snapshot.isReady) return;
    _preparing = _prepare(downloadIfMissing);
    try {
      await _preparing;
    } finally {
      _preparing = null;
    }
  }

  Future<void> _prepare(bool downloadIfMissing) async {
    _setSnapshot(const EdgeSlmSnapshot(phase: EdgeSlmPhase.checking));
    var pack = await _modelPack.initialize();
    if (!pack.isReady && downloadIfMissing) {
      pack = await _modelPack.download();
    }
    if (!pack.isReady) {
      _setSnapshot(
        EdgeSlmSnapshot(
          phase: pack.phase == EdgeModelPackPhase.failed
              ? EdgeSlmPhase.failed
              : EdgeSlmPhase.modelMissing,
          progress: pack.progress,
          message: pack.message,
        ),
      );
      return;
    }
    _setSnapshot(
      const EdgeSlmSnapshot(
        phase: EdgeSlmPhase.loading,
        progress: 1,
        message: 'Loading the private Edge AI model…',
      ),
    );
    try {
      await _runtime.load(pack.modelPath!);
      _setSnapshot(
        const EdgeSlmSnapshot(
          phase: EdgeSlmPhase.ready,
          progress: 1,
          message: 'Private Edge AI ready',
        ),
      );
    } catch (error) {
      debugPrint('[EdgeAI] Model load failed: $error');
      _setSnapshot(
        EdgeSlmSnapshot(
          phase: EdgeSlmPhase.failed,
          progress: 1,
          message:
              'Private Edge AI could not start. The lightweight matcher is still active.',
        ),
      );
    }
  }

  @override
  Future<SchemeUnderstandingResult> understand(
    SchemeUnderstandingRequest request,
  ) async {
    if (!_snapshot.isReady) await prepare();
    if (!_snapshot.isReady) return _fallback.understand(request);

    final stopwatch = Stopwatch()..start();
    try {
      final requestedKey = request.requestedFact?.name;
      final input = request.latestAnswer?.trim().isNotEmpty == true
          ? 'Original situation: ${request.statement}\n'
                'Question fact: $requestedKey\n'
                'Latest answer: ${request.latestAnswer}'
          : request.statement;
      final raw = await _runtime.generateStructured(
        systemPrompt: _systemPrompt,
        userPrompt: input,
      );
      final parsed = _parse(raw);
      final inputContainsTamil = RegExp(r'[\u0B80-\u0BFF]').hasMatch(input);
      if (inputContainsTamil && !parsed.acceptsTamilScript) {
        throw const FormatException(
          'Tamil language detection was inconsistent.',
        );
      }
      final facts = Map<EligibilityFactKey, EligibilityFact>.of(
        request.knownFacts,
      );
      for (final entry in parsed.facts.entries) {
        final previous = facts[entry.key];
        if (previous != null &&
            previous.source == EligibilityFactSource.profile &&
            previous.value.toLowerCase() != entry.value.value.toLowerCase()) {
          facts[entry.key] = entry.value.copyWith(
            confirmed: false,
            conflictingValue: previous.value,
          );
        } else {
          facts[entry.key] = entry.value;
        }
      }
      final enrichedStatement = [
        request.statement,
        ...parsed.concepts,
      ].join(' ');
      final result = await _fallback.understand(
        SchemeUnderstandingRequest(
          statement: enrichedStatement,
          schemes: request.schemes,
          knownFacts: facts,
          questionsAsked: request.questionsAsked,
          latestAnswer: request.latestAnswer,
          requestedFact: request.requestedFact,
          includeUncertain: request.includeUncertain,
        ),
      );
      stopwatch.stop();
      return SchemeUnderstandingResult(
        isTamil: result.isTamil || parsed.usesTamilPresentation,
        concepts: result.concepts,
        facts: result.facts,
        recommendations: result.recommendations,
        excludedUncertainCount: result.excludedUncertainCount,
        elapsed: stopwatch.elapsed,
        followUpQuestion: result.followUpQuestion,
        noConfidentMatch: result.noConfidentMatch,
      );
    } catch (_) {
      // A tiny model is advisory. Malformed output must never break discovery.
      return _fallback.understand(request);
    }
  }

  static _ParsedUnderstanding _parse(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw const FormatException('Edge AI did not return JSON.');
    }
    final decoded = jsonDecode(raw.substring(start, end + 1));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Edge AI JSON must be an object.');
    }
    final concepts = <String>{};
    final rawConcepts = decoded['concepts'];
    if (rawConcepts is List) {
      for (final value in rawConcepts) {
        final concept = value.toString().trim().toLowerCase();
        if (_allowedConcepts.contains(concept)) concepts.add(concept);
      }
    }

    final facts = <EligibilityFactKey, EligibilityFact>{};
    final rawFacts = decoded['facts'];
    if (rawFacts is List) {
      for (final item in rawFacts) {
        if (item is! Map) continue;
        if (item['negated'] == true) continue;
        final keyName = item['key']?.toString();
        final value = item['value']?.toString().trim() ?? '';
        final confidence = (item['confidence'] as num?)?.toDouble() ?? 0;
        if (keyName == null ||
            value.isEmpty ||
            value.length > 80 ||
            confidence < 0.55) {
          continue;
        }
        EligibilityFactKey key;
        try {
          key = EligibilityFactKey.values.byName(keyName);
        } on ArgumentError {
          continue;
        }
        if (!_validFactValue(key, value)) continue;
        facts[key] = EligibilityFact(
          key: key,
          value: value,
          confidence: confidence.clamp(0, 1),
          source: EligibilityFactSource.statement,
          confirmed: false,
        );
      }
    }
    final language = decoded['language']?.toString().toLowerCase() ?? '';
    return _ParsedUnderstanding(
      language: language,
      concepts: concepts,
      facts: facts,
    );
  }

  static bool _validFactValue(EligibilityFactKey key, String value) {
    switch (key) {
      case EligibilityFactKey.age:
        final age = int.tryParse(
          RegExp(r'\d{1,3}').firstMatch(value)?.group(0) ?? '',
        );
        return age != null && age >= 1 && age <= 120;
      case EligibilityFactKey.annualIncome:
      case EligibilityFactKey.fundingNeed:
      case EligibilityFactKey.landholding:
        return RegExp(r'\d').hasMatch(value);
      case EligibilityFactKey.gender:
        return const {
          'female',
          'male',
          'transgender',
          'prefer not to say',
        }.contains(value.toLowerCase());
      case EligibilityFactKey.studentStatus:
      case EligibilityFactKey.disability:
        return const {
          'yes',
          'no',
          'declared',
          'none',
        }.contains(value.toLowerCase());
      case EligibilityFactKey.community:
        return const {
          'sc',
          'scheduled caste',
          'st',
          'scheduled tribe',
          'obc',
          'ews',
          'minority',
          'general',
        }.contains(value.toLowerCase());
      case EligibilityFactKey.maritalStatus:
        return const {
          'single',
          'unmarried',
          'married',
          'widowed',
          'prefer not to say',
        }.contains(value.toLowerCase());
      case EligibilityFactKey.state:
        return _indianStates.contains(_normalizeLocation(value));
      case EligibilityFactKey.district:
        final normalized = _normalizeLocation(value);
        return normalized.length >= 2 &&
            normalized != 'india' &&
            !_indianStates.contains(normalized);
      default:
        return true;
    }
  }

  static String _normalizeLocation(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  void _handlePackChanged() {
    final pack = _modelPack.snapshot;
    if (pack.phase == EdgeModelPackPhase.downloading ||
        pack.phase == EdgeModelPackPhase.verifying) {
      _setSnapshot(
        EdgeSlmSnapshot(
          phase: pack.phase == EdgeModelPackPhase.downloading
              ? EdgeSlmPhase.downloading
              : EdgeSlmPhase.loading,
          progress: pack.progress,
          message: pack.phase == EdgeModelPackPhase.verifying
              ? 'Verifying the private model…'
              : 'Downloading private Edge AI…',
        ),
      );
    }
  }

  void _setSnapshot(EdgeSlmSnapshot value) {
    if (_closed) return;
    _snapshot = value;
    notifyListeners();
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _modelPack.removeListener(_handlePackChanged);
    await _modelPack.cancel();
    await _runtime.stop();
    await _runtime.dispose();
    _modelPack.dispose();
    super.dispose();
  }
}

class _ParsedUnderstanding {
  const _ParsedUnderstanding({
    required this.language,
    required this.concepts,
    required this.facts,
  });

  final String language;
  final Set<String> concepts;
  final Map<EligibilityFactKey, EligibilityFact> facts;

  bool get usesTamilPresentation =>
      language == 'ta' || language == 'tanglish' || language == 'mixed';

  // Tamil-script input must not be accepted as merely romanized Tanglish. Tiny
  // models sometimes copy a valid-looking Tanglish example while failing to
  // understand the actual Tamil sentence.
  bool get acceptsTamilScript => language == 'ta' || language == 'mixed';
}
