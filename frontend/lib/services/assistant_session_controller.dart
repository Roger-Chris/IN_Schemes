import 'package:flutter/foundation.dart';

import '../models/scheme_model.dart';
import '../models/user_profile.dart';
import 'scheme_understanding_engine.dart';

enum AssistantSessionPhase {
  idle,
  listening,
  understanding,
  asking,
  results,
  noConfidentMatch,
  error,
  cancelled,
}

class AssistantSessionState {
  const AssistantSessionState({
    this.phase = AssistantSessionPhase.idle,
    this.statement = '',
    this.latestTranscript = '',
    this.isTamil = false,
    this.facts = const {},
    this.recommendations = const [],
    this.excludedUncertainCount = 0,
    this.includeUncertain = false,
    this.questionsAsked = 0,
    this.elapsed = Duration.zero,
    this.question,
    this.message,
  });

  final AssistantSessionPhase phase;
  final String statement;
  final String latestTranscript;
  final bool isTamil;
  final Map<EligibilityFactKey, EligibilityFact> facts;
  final List<SchemeRecommendation> recommendations;
  final int excludedUncertainCount;
  final bool includeUncertain;
  final int questionsAsked;
  final Duration elapsed;
  final FollowUpQuestion? question;
  final String? message;

  AssistantSessionState copyWith({
    AssistantSessionPhase? phase,
    String? statement,
    String? latestTranscript,
    bool? isTamil,
    Map<EligibilityFactKey, EligibilityFact>? facts,
    List<SchemeRecommendation>? recommendations,
    int? excludedUncertainCount,
    bool? includeUncertain,
    int? questionsAsked,
    Duration? elapsed,
    FollowUpQuestion? question,
    bool clearQuestion = false,
    String? message,
    bool clearMessage = false,
  }) {
    return AssistantSessionState(
      phase: phase ?? this.phase,
      statement: statement ?? this.statement,
      latestTranscript: latestTranscript ?? this.latestTranscript,
      isTamil: isTamil ?? this.isTamil,
      facts: facts ?? this.facts,
      recommendations: recommendations ?? this.recommendations,
      excludedUncertainCount:
          excludedUncertainCount ?? this.excludedUncertainCount,
      includeUncertain: includeUncertain ?? this.includeUncertain,
      questionsAsked: questionsAsked ?? this.questionsAsked,
      elapsed: elapsed ?? this.elapsed,
      question: clearQuestion ? null : question ?? this.question,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

/// Owns one private, in-memory assistant conversation.
class AssistantSessionController extends ChangeNotifier {
  AssistantSessionController({
    required SchemeUnderstandingEngine engine,
    required List<Scheme> schemes,
    required UserProfile profile,
  }) : _engine = engine,
       _schemes = List.unmodifiable(schemes),
       _profile = profile,
       _profileFacts = _factsFromProfile(profile);

  final SchemeUnderstandingEngine _engine;
  final List<Scheme> _schemes;
  final UserProfile _profile;
  final Map<EligibilityFactKey, EligibilityFact> _profileFacts;
  AssistantSessionState _state = const AssistantSessionState();
  int _generation = 0;

  AssistantSessionState get state => _state;

  void setListening({String transcript = ''}) {
    _state = _state.copyWith(
      phase: AssistantSessionPhase.listening,
      latestTranscript: transcript,
      clearMessage: true,
    );
    notifyListeners();
  }

  void updatePartialTranscript(String transcript) {
    if (_state.phase != AssistantSessionPhase.listening) return;
    _state = _state.copyWith(latestTranscript: transcript);
    notifyListeners();
  }

  Future<void> start(String statement, {bool? isTamil}) async {
    final value = statement.trim();
    if (value.isEmpty) return;
    _generation++;
    _state = AssistantSessionState(
      phase: AssistantSessionPhase.understanding,
      statement: value,
      latestTranscript: value,
      isTamil: isTamil ?? false,
      facts: Map.unmodifiable(_profileFacts),
    );
    notifyListeners();
    await _runUnderstanding();
  }

  Future<void> answer(String answer) async {
    final value = answer.trim();
    final question = _state.question;
    if (value.isEmpty || question == null) return;
    final generation = ++_generation;
    _state = _state.copyWith(
      phase: AssistantSessionPhase.understanding,
      latestTranscript: value,
      questionsAsked: _state.questionsAsked + 1,
      clearQuestion: true,
      clearMessage: true,
    );
    notifyListeners();
    await _runUnderstanding(
      generation: generation,
      answer: value,
      requestedFact: question.factKey,
    );
  }

  Future<void> editFact(EligibilityFactKey key, String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    final facts = Map<EligibilityFactKey, EligibilityFact>.of(_state.facts);
    facts[key] = EligibilityFact(
      key: key,
      value: trimmed,
      confidence: 1,
      source: EligibilityFactSource.edited,
      confirmed: true,
    );
    final generation = ++_generation;
    _state = _state.copyWith(
      phase: AssistantSessionPhase.understanding,
      facts: Map.unmodifiable(facts),
      clearQuestion: true,
      clearMessage: true,
    );
    notifyListeners();
    await _runUnderstanding(generation: generation);
  }

  void confirmFact(EligibilityFactKey key) {
    final fact = _state.facts[key];
    if (fact == null) return;
    final facts = Map<EligibilityFactKey, EligibilityFact>.of(_state.facts);
    facts[key] = fact.copyWith(confirmed: true, clearConflict: true);
    _state = _state.copyWith(facts: Map.unmodifiable(facts));
    notifyListeners();
  }

  Future<void> setIncludeUncertain(bool value) async {
    if (value == _state.includeUncertain || _state.statement.isEmpty) return;
    final generation = ++_generation;
    _state = _state.copyWith(
      includeUncertain: value,
      phase: AssistantSessionPhase.understanding,
      clearQuestion: true,
      clearMessage: true,
    );
    notifyListeners();
    await _runUnderstanding(generation: generation);
  }

  void fail(String message) {
    _state = _state.copyWith(
      phase: AssistantSessionPhase.error,
      message: message,
      clearQuestion: true,
    );
    notifyListeners();
  }

  void cancel() {
    _generation++;
    _state = _state.copyWith(
      phase: AssistantSessionPhase.cancelled,
      clearQuestion: true,
    );
    notifyListeners();
  }

  Future<void> _runUnderstanding({
    int? generation,
    String? answer,
    EligibilityFactKey? requestedFact,
  }) async {
    final activeGeneration = generation ?? _generation;
    try {
      final result = await _engine.understand(
        SchemeUnderstandingRequest(
          statement: _state.statement,
          schemes: _schemes,
          knownFacts: _state.facts,
          questionsAsked: _state.questionsAsked,
          latestAnswer: answer,
          requestedFact: requestedFact,
          includeUncertain: _state.includeUncertain,
        ),
      );
      if (activeGeneration != _generation) return;
      final phase = result.noConfidentMatch
          ? AssistantSessionPhase.noConfidentMatch
          : result.followUpQuestion != null
          ? AssistantSessionPhase.asking
          : AssistantSessionPhase.results;
      _state = _state.copyWith(
        phase: phase,
        isTamil: _state.isTamil || result.isTamil,
        facts: result.facts,
        recommendations: result.recommendations,
        excludedUncertainCount: result.excludedUncertainCount,
        elapsed: result.elapsed,
        question: result.followUpQuestion,
        clearQuestion: result.followUpQuestion == null,
        clearMessage: true,
      );
      notifyListeners();
    } catch (_) {
      if (activeGeneration != _generation) return;
      fail(
        _state.isTamil
            ? 'இப்போது திட்டங்களை பொருத்த முடியவில்லை. மீண்டும் முயற்சிக்கவும்.'
            : 'I could not match schemes right now. Please try again.',
      );
    }
  }

  List<EligibilityFact> get savableFacts => _state.facts.values
      .where(
        (fact) =>
            fact.confirmed &&
            fact.source != EligibilityFactSource.profile &&
            _isSavable(fact.key),
      )
      .toList(growable: false);

  UserProfile buildUpdatedProfile() {
    var updated = _profile;
    for (final fact in savableFacts) {
      switch (fact.key) {
        case EligibilityFactKey.state:
          updated = updated.copyWith(state: fact.value);
        case EligibilityFactKey.district:
          updated = updated.copyWith(district: fact.value);
        case EligibilityFactKey.annualIncome:
          updated = updated.copyWith(
            annualIncome: double.tryParse(fact.value) ?? updated.annualIncome,
          );
        case EligibilityFactKey.gender:
          updated = updated.copyWith(gender: fact.value);
        case EligibilityFactKey.community:
          updated = updated.copyWith(community: fact.value);
        case EligibilityFactKey.occupation:
          updated = updated.copyWith(employmentStatus: fact.value);
        case EligibilityFactKey.education:
          updated = updated.copyWith(
            educationLevel: fact.value,
            qualification: fact.value,
          );
        case EligibilityFactKey.disability:
          updated = updated.copyWith(
            disability: fact.value == 'Yes' ? 'Declared' : 'None',
          );
        case EligibilityFactKey.businessStage:
          updated = updated.copyWith(businessStage: fact.value);
        case EligibilityFactKey.businessSector:
          updated = updated.copyWith(businessIndustry: fact.value);
        case EligibilityFactKey.fundingNeed:
          updated = updated.copyWith(
            fundingRequired:
                double.tryParse(fact.value) ?? updated.fundingRequired,
          );
        case EligibilityFactKey.age:
        case EligibilityFactKey.maritalStatus:
        case EligibilityFactKey.studentStatus:
        case EligibilityFactKey.landholding:
          break;
      }
    }
    return updated.copyWith(profileCompleted: true);
  }

  static bool _isSavable(EligibilityFactKey key) => !{
    EligibilityFactKey.age,
    EligibilityFactKey.maritalStatus,
    EligibilityFactKey.studentStatus,
    EligibilityFactKey.landholding,
  }.contains(key);

  static Map<EligibilityFactKey, EligibilityFact> _factsFromProfile(
    UserProfile profile,
  ) {
    if (!profile.profileCompleted) return const {};
    final facts = <EligibilityFactKey, EligibilityFact>{};
    void add(EligibilityFactKey key, String value) {
      if (value.trim().isEmpty || value.toLowerCase() == 'none') return;
      facts[key] = EligibilityFact(
        key: key,
        value: value,
        confidence: 1,
        source: EligibilityFactSource.profile,
        confirmed: true,
      );
    }

    add(EligibilityFactKey.age, profile.age.toString());
    add(EligibilityFactKey.state, profile.state);
    add(EligibilityFactKey.district, profile.district);
    if (profile.annualIncome > 0) {
      add(
        EligibilityFactKey.annualIncome,
        profile.annualIncome.round().toString(),
      );
    }
    add(EligibilityFactKey.gender, profile.gender);
    add(EligibilityFactKey.community, profile.community);
    add(EligibilityFactKey.occupation, profile.employmentStatus);
    add(EligibilityFactKey.education, profile.educationLevel);
    add(EligibilityFactKey.disability, profile.disability);
    add(EligibilityFactKey.businessStage, profile.businessStage);
    add(EligibilityFactKey.businessSector, profile.businessIndustry);
    if (profile.fundingRequired > 0) {
      add(
        EligibilityFactKey.fundingNeed,
        profile.fundingRequired.round().toString(),
      );
    }
    return Map.unmodifiable(facts);
  }
}
