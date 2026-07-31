import 'dart:math' as math;

import '../models/scheme_model.dart';
import 'intelligent_scheme_search.dart';
import 'private_ai_knowledge_base.dart';

enum EligibilityFactKey {
  age,
  state,
  district,
  annualIncome,
  gender,
  community,
  occupation,
  education,
  disability,
  maritalStatus,
  studentStatus,
  businessStage,
  businessSector,
  fundingNeed,
  landholding,
}

enum EligibilityFactSource { statement, profile, followUp, edited }

enum SchemeMatchState {
  strongMatch,
  likelyMatch,
  needsInformation,
  notSuitable,
  noConfidentMatch,
}

class EligibilityFact {
  const EligibilityFact({
    required this.key,
    required this.value,
    required this.confidence,
    required this.source,
    this.confirmed = false,
    this.conflictingValue,
  });

  final EligibilityFactKey key;
  final String value;
  final double confidence;
  final EligibilityFactSource source;
  final bool confirmed;
  final String? conflictingValue;

  bool get hasConflict => conflictingValue != null;

  EligibilityFact copyWith({
    String? value,
    double? confidence,
    EligibilityFactSource? source,
    bool? confirmed,
    String? conflictingValue,
    bool clearConflict = false,
  }) {
    return EligibilityFact(
      key: key,
      value: value ?? this.value,
      confidence: confidence ?? this.confidence,
      source: source ?? this.source,
      confirmed: confirmed ?? this.confirmed,
      conflictingValue: clearConflict
          ? null
          : conflictingValue ?? this.conflictingValue,
    );
  }
}

class FollowUpQuestion {
  const FollowUpQuestion({
    required this.factKey,
    required this.english,
    required this.tamil,
    this.options = const [],
  });

  final EligibilityFactKey factKey;
  final String english;
  final String tamil;
  final List<String> options;

  String text({required bool tamilLanguage}) => tamilLanguage ? tamil : english;
}

class SchemeRecommendation {
  const SchemeRecommendation({
    required this.scheme,
    required this.score,
    required this.state,
    required this.reasons,
    required this.unknownRequirements,
    required this.disqualifiers,
    required this.isTrusted,
  });

  final Scheme scheme;
  final double score;
  final SchemeMatchState state;
  final List<String> reasons;
  final List<String> unknownRequirements;
  final List<String> disqualifiers;
  final bool isTrusted;
}

class SchemeUnderstandingRequest {
  const SchemeUnderstandingRequest({
    required this.statement,
    required this.schemes,
    required this.knownFacts,
    required this.questionsAsked,
    this.latestAnswer,
    this.requestedFact,
    this.includeUncertain = false,
  });

  final String statement;
  final List<Scheme> schemes;
  final Map<EligibilityFactKey, EligibilityFact> knownFacts;
  final int questionsAsked;
  final String? latestAnswer;
  final EligibilityFactKey? requestedFact;
  final bool includeUncertain;
}

class SchemeUnderstandingResult {
  const SchemeUnderstandingResult({
    required this.isTamil,
    required this.concepts,
    required this.facts,
    required this.recommendations,
    required this.excludedUncertainCount,
    required this.elapsed,
    this.reply,
    this.followUpQuestion,
    this.noConfidentMatch = false,
  });

  final bool isTamil;
  final Set<String> concepts;
  final Map<EligibilityFactKey, EligibilityFact> facts;
  final List<SchemeRecommendation> recommendations;
  final int excludedUncertainCount;
  final Duration elapsed;
  final GroundedAssistantReply? reply;
  final FollowUpQuestion? followUpQuestion;
  final bool noConfidentMatch;
}

abstract interface class SchemeUnderstandingEngine {
  Future<SchemeUnderstandingResult> understand(
    SchemeUnderstandingRequest request,
  );
}

abstract interface class ClosableSchemeUnderstandingEngine {
  Future<void> close();
}

/// Offline English/Tamil/Tanglish statement understanding and scheme ranking.
///
/// The engine deliberately uses only bundled catalog data. It never performs a
/// network request or persists the user's statement.
class LocalSchemeUnderstandingEngine implements SchemeUnderstandingEngine {
  const LocalSchemeUnderstandingEngine();

  static const int maxFollowUpQuestions = 5;
  static final Expando<bool> _trustedSchemeCache = Expando<bool>(
    'trustedScheme',
  );
  static final Expando<String> _conceptTextCache = Expando<String>(
    'schemeConceptText',
  );

  static const Map<String, List<String>> _needAliases = {
    'agriculture': [
      'farmer',
      'farming',
      'crop',
      'agriculture',
      'irrigation',
      'vivasayam',
      'vivasayi',
      'ulavar',
      'uzhavar',
      'விவசாயம்',
      'விவசாயி',
      'உழவர்',
      'பயிர்',
    ],
    'education': [
      'student',
      'college',
      'school',
      'study',
      'education',
      'scholarship',
      'padippu',
      'padikka',
      'kalvi',
      'maanavar',
      'மாணவர்',
      'மாணவி',
      'கல்வி',
      'படிப்பு',
    ],
    'business': [
      'business',
      'startup',
      'enterprise',
      'entrepreneur',
      'msme',
      'self employment',
      'suyathozhil',
      'thozhil',
      'kadai',
      'தொழில்',
      'சுயதொழில்',
      'வியாபாரம்',
      'கடை',
    ],
    'housing': [
      'house',
      'home',
      'housing',
      'construction',
      'awas',
      'veedu',
      'வீடு',
      'குடியிருப்பு',
    ],
    'health': [
      'health',
      'medical',
      'hospital',
      'treatment',
      'insurance',
      'ayushman',
      'maruthuvam',
      'sigichai',
      'மருத்துவம்',
      'சிகிச்சை',
      'ஆரோக்கியம்',
    ],
    'employment': [
      'job',
      'employment',
      'unemployed',
      'training',
      'skill',
      'velai',
      'velaivaippu',
      'வேலை',
      'வேலைவாய்ப்பு',
      'பயிற்சி',
    ],
    'disability': [
      'disabled',
      'disability',
      'differently abled',
      'maatru thiranali',
      'மாற்றுத்திறனாளி',
    ],
    'senior': [
      'pension',
      'senior citizen',
      'old age',
      'elderly',
      'muthiyor',
      'முதியோர்',
      'ஓய்வூதியம்',
    ],
    'marriage': [
      'marriage',
      'wedding',
      'bride',
      'kalyana',
      'kalyanam',
      'thirumanam',
      'திருமணம்',
      'கல்யாணம்',
    ],
    'community': [
      'sc',
      'st',
      'obc',
      'minority',
      'scheduled caste',
      'scheduled tribe',
      'dalit',
      'tribal',
      'சிறுபான்மை',
      'பட்டியல் சாதி',
      'பழங்குடி',
    ],
    'fisheries': [
      'fish',
      'fisherman',
      'fisheries',
      'meenavar',
      'meenpidi',
      'மீனவர்',
      'மீன்பிடி',
    ],
    'livestock': [
      'cattle',
      'cow',
      'goat',
      'dairy',
      'poultry',
      'maadu',
      'aadu',
      'kozhi',
      'மாடு',
      'ஆடு',
      'கோழி',
      'கால்நடை',
    ],
    'food': [
      'food',
      'ration',
      'nutrition',
      'food security',
      'unavu',
      'ration card',
      'உணவு',
      'ரேஷன்',
      'ஊட்டச்சத்து',
    ],
  };

  static const Map<EligibilityFactKey, FollowUpQuestion> _questions = {
    EligibilityFactKey.state: FollowUpQuestion(
      factKey: EligibilityFactKey.state,
      english: 'Which state do you live in?',
      tamil: 'நீங்கள் எந்த மாநிலத்தில் வசிக்கிறீர்கள்?',
      options: ['Tamil Nadu', 'Other state'],
    ),
    EligibilityFactKey.age: FollowUpQuestion(
      factKey: EligibilityFactKey.age,
      english: 'What is your age?',
      tamil: 'உங்கள் வயது என்ன?',
    ),
    EligibilityFactKey.annualIncome: FollowUpQuestion(
      factKey: EligibilityFactKey.annualIncome,
      english: 'What is your family annual income?',
      tamil: 'உங்கள் குடும்ப ஆண்டு வருமானம் எவ்வளவு?',
    ),
    EligibilityFactKey.gender: FollowUpQuestion(
      factKey: EligibilityFactKey.gender,
      english: 'Which gender category should I use for this eligibility check?',
      tamil: 'இந்த தகுதி சரிபார்ப்புக்கு எந்த பாலினத்தை பயன்படுத்த வேண்டும்?',
      options: ['Female', 'Male', 'Transgender', 'Prefer not to say'],
    ),
    EligibilityFactKey.community: FollowUpQuestion(
      factKey: EligibilityFactKey.community,
      english: 'Does an SC, ST, OBC, EWS, or minority category apply to you?',
      tamil: 'SC, ST, OBC, EWS அல்லது சிறுபான்மை பிரிவு உங்களுக்கு பொருந்துமா?',
      options: ['SC', 'ST', 'OBC', 'EWS', 'Minority', 'General'],
    ),
    EligibilityFactKey.occupation: FollowUpQuestion(
      factKey: EligibilityFactKey.occupation,
      english: 'What best describes your current work or situation?',
      tamil: 'உங்கள் தற்போதைய வேலை அல்லது நிலை என்ன?',
      options: ['Student', 'Farmer', 'Self-employed', 'Unemployed'],
    ),
    EligibilityFactKey.education: FollowUpQuestion(
      factKey: EligibilityFactKey.education,
      english: 'What is your highest education level?',
      tamil: 'உங்கள் உயர்ந்த கல்வித் தகுதி என்ன?',
      options: ['School', 'Diploma', 'Undergraduate', 'Postgraduate'],
    ),
    EligibilityFactKey.disability: FollowUpQuestion(
      factKey: EligibilityFactKey.disability,
      english:
          'Do you have a disability category relevant to this application?',
      tamil: 'இந்த விண்ணப்பத்திற்கு பொருந்தும் மாற்றுத்திறன் பிரிவு உள்ளதா?',
      options: ['Yes', 'No', 'Prefer not to say'],
    ),
    EligibilityFactKey.maritalStatus: FollowUpQuestion(
      factKey: EligibilityFactKey.maritalStatus,
      english: 'Which marital status applies to this request?',
      tamil: 'இந்த கோரிக்கைக்கு பொருந்தும் திருமண நிலை என்ன?',
      options: ['Single', 'Married', 'Widowed', 'Prefer not to say'],
    ),
    EligibilityFactKey.studentStatus: FollowUpQuestion(
      factKey: EligibilityFactKey.studentStatus,
      english: 'Are you currently a student?',
      tamil: 'நீங்கள் தற்போது மாணவரா?',
      options: ['Yes', 'No'],
    ),
    EligibilityFactKey.businessStage: FollowUpQuestion(
      factKey: EligibilityFactKey.businessStage,
      english: 'Are you starting a new business or expanding an existing one?',
      tamil:
          'புதிய தொழில் தொடங்குகிறீர்களா அல்லது உள்ள தொழிலை விரிவுபடுத்துகிறீர்களா?',
      options: ['New business', 'Existing business', 'Expansion'],
    ),
    EligibilityFactKey.businessSector: FollowUpQuestion(
      factKey: EligibilityFactKey.businessSector,
      english: 'What type of business or activity is this for?',
      tamil: 'இது எந்த வகை தொழில் அல்லது செயல்பாட்டிற்காக?',
    ),
    EligibilityFactKey.fundingNeed: FollowUpQuestion(
      factKey: EligibilityFactKey.fundingNeed,
      english: 'Approximately how much funding do you need?',
      tamil: 'சுமார் எவ்வளவு நிதி தேவை?',
    ),
    EligibilityFactKey.landholding: FollowUpQuestion(
      factKey: EligibilityFactKey.landholding,
      english: 'How much agricultural land do you have?',
      tamil: 'உங்களிடம் எவ்வளவு விவசாய நிலம் உள்ளது?',
    ),
  };

  @override
  Future<SchemeUnderstandingResult> understand(
    SchemeUnderstandingRequest request,
  ) async {
    final stopwatch = Stopwatch()..start();
    final knowledgeMatch = PrivateAiKnowledgeBase.lookup(request.statement);
    final intent = IntelligentSchemeSearch.interpret(request.statement);
    final concepts = <String>{...intent.concepts};
    final normalizedStatement = _normalize(request.statement);
    for (final entry in _needAliases.entries) {
      if (entry.value.any((alias) => _contains(normalizedStatement, alias))) {
        concepts.add(entry.key);
      }
    }

    final facts = <EligibilityFactKey, EligibilityFact>{...request.knownFacts};
    _mergeExtractedFacts(
      facts,
      _extractFacts(request.statement, EligibilityFactSource.statement),
    );
    final answer = request.latestAnswer?.trim();
    if (answer != null && answer.isNotEmpty) {
      _mergeExtractedFacts(
        facts,
        _extractFacts(
          answer,
          EligibilityFactSource.followUp,
          requestedFact: request.requestedFact,
        ),
      );
    }

    final trusted = request.schemes.where(_isTrusted).toList(growable: false);
    final uncertain = request.schemes
        .where((scheme) => scheme.isActive && !_isTrusted(scheme))
        .toList(growable: false);
    final searchable = request.includeUncertain
        ? [...trusted, ...uncertain]
        : trusted;
    final expandedQuery = [
      request.statement,
      ...concepts.expand((concept) => _needAliases[concept] ?? [concept]),
    ].join(' ');
    final requiredConcepts = _requiredConcepts(concepts);
    final matchesByCode = <String, SchemeSearchMatch>{};
    // Curated answers own their recommendation set. Mixing a factual answer
    // with broad semantic hits caused generic MSME schemes to appear beside
    // unrelated answers such as tax definitions and investor guidance.
    if (knowledgeMatch == null) {
      for (final match
          in IntelligentSchemeSearch.rank(
            expandedQuery,
            searchable,
            limit: 40,
          ).where(
            (match) => _matchesRequiredConcepts(match.scheme, requiredConcepts),
          )) {
        matchesByCode[match.scheme.schemeCode.toUpperCase()] = match;
      }
    }
    if (knowledgeMatch != null) {
      final schemesByCode = {
        for (final scheme in searchable)
          scheme.schemeCode.toUpperCase(): scheme,
      };
      for (
        var index = 0;
        index < knowledgeMatch.relatedSchemeCodes.length;
        index++
      ) {
        final code = knowledgeMatch.relatedSchemeCodes[index].toUpperCase();
        final scheme = schemesByCode[code];
        if (scheme == null) continue;
        final preferredScore = 0.98 - index * 0.025;
        final existing = matchesByCode[code];
        if (existing == null || existing.score < preferredScore) {
          matchesByCode[code] = SchemeSearchMatch(
            scheme: scheme,
            score: preferredScore,
            reasons: const ['Directly relevant to your question'],
          );
        }
      }
    }
    if (knowledgeMatch != null &&
        knowledgeMatch.relatedSchemeCodes.isNotEmpty &&
        matchesByCode.isEmpty) {
      for (final match
          in IntelligentSchemeSearch.rank(
            expandedQuery,
            searchable,
            limit: 40,
          ).where(
            (match) => _matchesRequiredConcepts(match.scheme, requiredConcepts),
          )) {
        matchesByCode[match.scheme.schemeCode.toUpperCase()] = match;
      }
    }

    final ranked =
        matchesByCode.values
            .map(
              (match) =>
                  _evaluate(match, facts, isTrusted: _isTrusted(match.scheme)),
            )
            .toList(growable: false)
          ..sort((a, b) => b.score.compareTo(a.score));
    final usable = ranked
        .where(
          (recommendation) =>
              recommendation.state != SchemeMatchState.notSuitable &&
              recommendation.score >= 0.32,
        )
        .take(12)
        .toList(growable: false);

    FollowUpQuestion? followUp;
    if (usable.isNotEmpty &&
        request.questionsAsked < maxFollowUpQuestions &&
        usable.take(3).where(_isStableRecommendation).length < 3) {
      followUp = _chooseQuestion(usable, facts);
    }

    final reply =
        knowledgeMatch?.reply() ??
        _recommendationReply(
          statement: request.statement,
          isTamil: intent.isTamil,
          recommendations: usable,
          followUp: followUp,
        );

    stopwatch.stop();
    return SchemeUnderstandingResult(
      isTamil: intent.isTamil,
      concepts: Set.unmodifiable(concepts),
      facts: Map.unmodifiable(facts),
      recommendations: List.unmodifiable(usable),
      excludedUncertainCount: request.includeUncertain ? 0 : uncertain.length,
      elapsed: stopwatch.elapsed,
      reply: reply,
      followUpQuestion: followUp,
      noConfidentMatch: usable.isEmpty && knowledgeMatch == null,
    );
  }

  static GroundedAssistantReply _recommendationReply({
    required String statement,
    required bool isTamil,
    required List<SchemeRecommendation> recommendations,
    required FollowUpQuestion? followUp,
  }) {
    final tamilScript = RegExp(r'[\u0B80-\u0BFF]').hasMatch(statement);
    final language = tamilScript
        ? PrivateAiLanguage.tamil
        : isTamil
        ? PrivateAiLanguage.tanglish
        : PrivateAiLanguage.english;
    if (recommendations.isEmpty) {
      final text = switch (language) {
        PrivateAiLanguage.english =>
          'I could not find a verified catalog match for that yet. Tell me the type of help, your work or study situation, location, and approximate funding need; I will try again without guessing.',
        PrivateAiLanguage.tamil =>
          'இதற்கு நம்பகமாக சரிபார்க்கப்பட்ட திட்டம் இன்னும் கிடைக்கவில்லை. தேவையான உதவி வகை, வேலை அல்லது படிப்பு நிலை, இருப்பிடம் மற்றும் சுமார் நிதித் தேவையைச் சொல்லுங்கள்; ஊகிக்காமல் மீண்டும் தேடுகிறேன்.',
        PrivateAiLanguage.tanglish =>
          'Idhukku verified catalog match innum kedaikkala. Entha help, unga work/study situation, location, approximate funding need sollunga; guess pannama marubadiyum search panren.',
      };
      return GroundedAssistantReply(
        topic: 'no_verified_match',
        displayText: text,
        spokenText: text,
        languageTag: language == PrivateAiLanguage.tamil ? 'ta-IN' : 'en-IN',
        sourceLabel: 'Verified scheme catalog',
        sourceUrl: '',
      );
    }

    final top = recommendations.first;
    final count = math.min(3, recommendations.length);
    final needsMore = followUp != null || top.unknownRequirements.isNotEmpty;
    final text = switch (language) {
      PrivateAiLanguage.english =>
        'I found $count verified ${count == 1 ? 'possibility' : 'possibilities'}. The closest match is ${top.scheme.name}. ${needsMore ? 'I still need one eligibility detail before treating it as a strong match.' : 'The published details align with what you told me, but confirm final eligibility on the official source.'}',
      PrivateAiLanguage.tamil =>
        'சரிபார்க்கப்பட்ட $count வாய்ப்புகள் கிடைத்துள்ளன. மிக நெருக்கமான பொருத்தம் ${top.scheme.name}. ${needsMore ? 'வலுவான பொருத்தமாகக் கூற இன்னும் ஒரு தகுதி விவரம் தேவை.' : 'நீங்கள் கூறிய தகவலுடன் வெளியிடப்பட்ட விவரங்கள் பொருந்துகின்றன; இறுதி தகுதியை அதிகாரப்பூர்வ தளத்தில் உறுதி செய்யுங்கள்.'}',
      PrivateAiLanguage.tanglish =>
        'Verified-ah $count options kedaichirukku. Closest match ${top.scheme.name}. ${needsMore ? 'Strong match-nu solla innum oru eligibility detail venum.' : 'Neenga sonna details-oda align aaguthu; final eligibility official source-la confirm pannunga.'}',
    };
    return GroundedAssistantReply(
      topic: 'scheme_recommendation',
      displayText: text,
      spokenText: text,
      languageTag: language == PrivateAiLanguage.tamil ? 'ta-IN' : 'en-IN',
      sourceLabel: 'Official scheme source',
      sourceUrl: top.scheme.sourceUrl,
      relatedSchemeCodes: recommendations
          .take(3)
          .map((item) => item.scheme.schemeCode)
          .toList(growable: false),
    );
  }

  static bool _isStableRecommendation(SchemeRecommendation recommendation) =>
      recommendation.state == SchemeMatchState.strongMatch ||
      recommendation.state == SchemeMatchState.likelyMatch;

  static Set<String> _requiredConcepts(Set<String> concepts) {
    final required = concepts.where(_needAliases.containsKey).toSet();
    // Sector-specific requests must not degrade into generic startup results.
    // "Start a dairy farm", for example, still requires a livestock match.
    for (final specific in const ['livestock', 'fisheries', 'food']) {
      if (required.contains(specific)) return {specific};
    }
    if (required.length > 1) required.remove('business');
    return required;
  }

  static void _mergeExtractedFacts(
    Map<EligibilityFactKey, EligibilityFact> target,
    Map<EligibilityFactKey, EligibilityFact> extracted,
  ) {
    for (final entry in extracted.entries) {
      final previous = target[entry.key];
      if (previous != null &&
          previous.value.toLowerCase() != entry.value.value.toLowerCase() &&
          previous.source == EligibilityFactSource.profile) {
        target[entry.key] = entry.value.copyWith(
          confirmed: false,
          conflictingValue: previous.value,
        );
      } else {
        target[entry.key] = entry.value;
      }
    }
  }

  static Map<EligibilityFactKey, EligibilityFact> _extractFacts(
    String input,
    EligibilityFactSource source, {
    EligibilityFactKey? requestedFact,
  }) {
    final normalized = _normalize(input);
    final facts = <EligibilityFactKey, EligibilityFact>{};

    void add(EligibilityFactKey key, String value, [double confidence = 0.9]) {
      facts[key] = EligibilityFact(
        key: key,
        value: value,
        confidence: confidence,
        source: source,
        confirmed:
            source == EligibilityFactSource.followUp ||
            source == EligibilityFactSource.edited,
      );
    }

    final ageMatch = RegExp(
      r'(?:age\s*(?:is)?\s*)?(\d{1,2})\s*(?:years?\s*old|yrs?|vayasu|வயது)',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(input);
    if (ageMatch != null) add(EligibilityFactKey.age, ageMatch.group(1)!);

    final money = _extractMoney(input);
    if (money != null) {
      final isIncome = RegExp(
        r'income|salary|earn|varumanam|வருமானம்|சம்பளம்',
        caseSensitive: false,
        unicode: true,
      ).hasMatch(input);
      final isFunding = RegExp(
        r'loan|fund|capital|kadan|கடன்|நிதி|முதலீடு',
        caseSensitive: false,
        unicode: true,
      ).hasMatch(input);
      if (requestedFact == EligibilityFactKey.annualIncome || isIncome) {
        add(EligibilityFactKey.annualIncome, money.round().toString());
      } else if (requestedFact == EligibilityFactKey.fundingNeed || isFunding) {
        add(EligibilityFactKey.fundingNeed, money.round().toString());
      }
    }

    final state = _firstAlias(normalized, {
      'Tamil Nadu': ['tamil nadu', 'தமிழ்நாடு', 'தமிழ் நாடு', 'tn'],
      'Karnataka': ['karnataka', 'கர்நாடகா'],
      'Kerala': ['kerala', 'கேரளா'],
      'Andhra Pradesh': ['andhra pradesh', 'andhra'],
      'Telangana': ['telangana'],
      'Punjab': ['punjab'],
      'Maharashtra': ['maharashtra'],
      'Other state': ['other state', 'வேறு மாநிலம்'],
    });
    if (state != null) add(EligibilityFactKey.state, state);

    final district = _firstAlias(normalized, {
      'Chennai': ['chennai', 'சென்னை'],
      'Coimbatore': ['coimbatore', 'kovai', 'கோவை'],
      'Madurai': ['madurai', 'மதுரை'],
      'Tiruchirappalli': ['trichy', 'tiruchirappalli', 'திருச்சி'],
      'Salem': ['salem', 'சேலம்'],
      'Tirunelveli': ['tirunelveli', 'nellai', 'நெல்லை'],
    });
    if (district != null) add(EligibilityFactKey.district, district);

    final gender = _firstAlias(normalized, {
      'Female': [
        'female',
        'woman',
        'women',
        'girl',
        'mother',
        'daughter',
        'pengal',
        'magalir',
        'pen',
        'பெண்',
        'பெண்கள்',
        'மகளிர்',
        'தாய்',
      ],
      'Male': ['male', 'man', 'father', 'boy', 'ஆண்', 'தந்தை'],
      'Transgender': ['transgender', 'திருநங்கை', 'திருநம்பி'],
      'Prefer not to say': ['prefer not to say', 'சொல்ல விரும்பவில்லை'],
    });
    if (gender != null) add(EligibilityFactKey.gender, gender);

    final community = _firstAlias(normalized, {
      'SC': ['scheduled caste', 'sc', 'dalit', 'பட்டியல் சாதி', 'ஆதிதிராவிடர்'],
      'ST': ['scheduled tribe', 'st', 'tribal', 'பழங்குடி'],
      'OBC': ['obc', 'backward class', 'bc', 'பிற்படுத்தப்பட்டோர்'],
      'EWS': ['ews', 'economically weaker'],
      'Minority': ['minority', 'sirupaanmai', 'சிறுபான்மை'],
      'General': ['general category', 'general'],
    });
    if (community != null) add(EligibilityFactKey.community, community);

    final occupation = _firstAlias(normalized, {
      'Student': ['student', 'college student', 'maanavar', 'மாணவர்', 'மாணவி'],
      'Farmer': ['farmer', 'vivasayi', 'uzhavar', 'விவசாயி', 'உழவர்'],
      'Artisan': ['artisan', 'weaver', 'kaivinai', 'கைவினைஞர்', 'நெசவாளர்'],
      'Fisher': ['fisherman', 'fisher', 'meenavar', 'மீனவர்'],
      'Self-employed': [
        'self employed',
        'self-employed',
        'suyathozhil',
        'சுயதொழில்',
      ],
      'Business owner': ['business owner', 'entrepreneur', 'தொழில்முனைவோர்'],
      'Unemployed': ['unemployed', 'no job', 'velai illa', 'வேலை இல்லை'],
      'Homemaker': ['homemaker', 'housewife', 'இல்லத்தரசி'],
      'Retired': ['retired', 'pensioner', 'ஓய்வு பெற்ற'],
      'Salaried': ['salaried', 'employee', 'வேலையில்'],
    });
    if (occupation != null) add(EligibilityFactKey.occupation, occupation);

    if (RegExp(
      r'not\s+(?:a\s+)?student|student\s+illa|மாணவ(?:ர்|ி)?\s+இல்லை',
      caseSensitive: false,
      unicode: true,
    ).hasMatch(input)) {
      add(EligibilityFactKey.studentStatus, 'No');
      if (facts[EligibilityFactKey.occupation]?.value == 'Student') {
        facts.remove(EligibilityFactKey.occupation);
      }
    } else if (occupation == 'Student') {
      add(EligibilityFactKey.studentStatus, 'Yes');
    }

    final education = _firstAlias(normalized, {
      'School': ['school', '10th', '12th', 'பள்ளி'],
      'Diploma': ['diploma', 'iti', 'டிப்ளமோ', 'ஐடிஐ'],
      'Undergraduate': [
        'undergraduate',
        'degree',
        'bachelor',
        'ug',
        'பட்டப்படிப்பு',
      ],
      'Postgraduate': [
        'postgraduate',
        'masters',
        'master degree',
        'pg',
        'முதுகலை',
      ],
      'Ph.D.': ['phd', 'doctorate', 'முனைவர்'],
    });
    if (education != null) add(EligibilityFactKey.education, education);

    if (_containsAny(normalized, [
      'disabled',
      'disability',
      'differently abled',
      'maatru thiranali',
      'மாற்றுத்திறனாளி',
    ])) {
      add(EligibilityFactKey.disability, 'Yes');
    }

    final marital = _firstAlias(normalized, {
      'Widowed': ['widow', 'widowed', 'விதவை'],
      'Married': ['married', 'திருமணமான'],
      'Single': ['single', 'unmarried', 'திருமணமாகாத'],
    });
    if (marital != null) add(EligibilityFactKey.maritalStatus, marital);

    final businessStage = _firstAlias(normalized, {
      'New business': [
        'start a business',
        'new business',
        'starting business',
        'தொழில் தொடங்க',
      ],
      'Existing business': [
        'existing business',
        'running business',
        'உள்ள தொழில்',
      ],
      'Expansion': ['expand', 'expansion', 'scaling up', 'விரிவுபடுத்த'],
    });
    if (businessStage != null) {
      add(EligibilityFactKey.businessStage, businessStage);
    }

    final sector = _firstAlias(normalized, {
      'Manufacturing': ['manufacturing', 'factory', 'plant', 'உற்பத்தி'],
      'Food processing': ['food processing', 'bakery', 'உணவு பதப்படுத்துதல்'],
      'Technology': ['technology', 'software', 'tech', 'தொழில்நுட்பம்'],
      'Retail': ['retail', 'shop', 'store', 'kadai', 'கடை'],
      'Agriculture': ['agriculture', 'farming', 'விவசாயம்'],
    });
    if (sector != null) add(EligibilityFactKey.businessSector, sector);

    final landMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:acre|acres|ekkar|ஏக்கர்)',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(input);
    if (landMatch != null) {
      add(EligibilityFactKey.landholding, '${landMatch.group(1)} acres');
    }

    if (requestedFact != null && !facts.containsKey(requestedFact)) {
      final direct = input.trim();
      if (direct.isNotEmpty) {
        if ({
          EligibilityFactKey.disability,
          EligibilityFactKey.studentStatus,
        }.contains(requestedFact)) {
          final yes = _containsAny(normalized, [
            'yes',
            'ஆம்',
            'aama',
            'irukku',
          ]);
          final no = _containsAny(normalized, [
            'no',
            'இல்லை',
            'illa',
            'kidaiyathu',
          ]);
          if (yes || no) add(requestedFact, yes ? 'Yes' : 'No', 0.86);
        } else {
          add(requestedFact, direct, 0.72);
        }
      }
    }
    return facts;
  }

  static SchemeRecommendation _evaluate(
    SchemeSearchMatch match,
    Map<EligibilityFactKey, EligibilityFact> facts, {
    required bool isTrusted,
  }) {
    final scheme = match.scheme;
    final eligibilityRaw = [
      scheme.targetBeneficiary,
      scheme.eligibilityCriteria.join(' '),
      scheme.state,
    ].join(' ');
    final eligibility = _normalize(eligibilityRaw);
    final reasons = <String>[...match.reasons];
    final unknowns = <String>[];
    final unknownKeys = <EligibilityFactKey>[];
    final disqualifiers = <String>[];
    var passed = 0;
    var checked = 0;

    void requireFact(
      EligibilityFactKey key,
      String label,
      bool Function(String value) passes,
      String success,
      String failure,
    ) {
      checked++;
      final fact = facts[key];
      if (fact == null || fact.value.toLowerCase().contains('prefer not')) {
        unknowns.add(label);
        unknownKeys.add(key);
      } else if (passes(fact.value)) {
        passed++;
        reasons.add(success);
      } else {
        disqualifiers.add(failure);
      }
    }

    final schemeState = scheme.state.trim();
    if (schemeState.isNotEmpty &&
        !_containsAny(_normalize(schemeState), [
          'all india',
          'central',
          'nationwide',
        ])) {
      requireFact(
        EligibilityFactKey.state,
        'State of residence',
        (value) =>
            _normalize(value).contains(_normalize(schemeState)) ||
            _normalize(schemeState).contains(_normalize(value)),
        'Available in your state',
        'This scheme is limited to $schemeState residents.',
      );
    }

    if (_containsAny(eligibility, [
      'women',
      'woman',
      'female',
      'girl',
      'widow',
    ])) {
      requireFact(
        EligibilityFactKey.gender,
        'Gender/category requirement',
        (value) => _containsAny(_normalize(value), ['female', 'transgender']),
        'Matches the women-focused beneficiary group',
        'This scheme is restricted to women or the stated eligible category.',
      );
    }

    final communityOptions = <String>[];
    if (RegExp(r'\bsc\b|scheduled caste').hasMatch(eligibility)) {
      communityOptions.add('sc');
    }
    if (RegExp(r'\bst\b|scheduled tribe|tribal').hasMatch(eligibility)) {
      communityOptions.add('st');
    }
    if (RegExp(r'\bobc\b|backward class').hasMatch(eligibility)) {
      communityOptions.add('obc');
    }
    if (_containsAny(eligibility, ['minority', 'சிறுபான்மை'])) {
      communityOptions.add('minority');
    }
    if (communityOptions.isNotEmpty &&
        !_containsAny(eligibility, [
          'priority',
          'including',
          'women, sc',
          'women sc',
        ])) {
      requireFact(
        EligibilityFactKey.community,
        'Community/category',
        (value) => communityOptions.contains(_normalize(value)),
        'Matches the eligible community/category',
        'Your community/category does not match this restricted scheme.',
      );
    }

    final ageRange = _ageRange(eligibilityRaw.toLowerCase());
    if (ageRange != null) {
      requireFact(
        EligibilityFactKey.age,
        'Age',
        (value) {
          final age = int.tryParse(
            RegExp(r'\d+').firstMatch(value)?.group(0) ?? '',
          );
          return age != null && age >= ageRange.$1 && age <= ageRange.$2;
        },
        'Age is within the published range',
        'Age is outside the published ${ageRange.$1}-${ageRange.$2} range.',
      );
    }

    final incomeCeiling = _incomeCeiling(eligibilityRaw.toLowerCase());
    if (incomeCeiling != null) {
      requireFact(
        EligibilityFactKey.annualIncome,
        'Annual family income',
        (value) => (double.tryParse(value) ?? double.infinity) <= incomeCeiling,
        'Income is within the published ceiling',
        'Income appears above the published scheme ceiling.',
      );
    }

    if (_containsAny(eligibility, ['student', 'students', 'pupil'])) {
      requireFact(
        EligibilityFactKey.studentStatus,
        'Current student status',
        (value) => _normalize(value) == 'yes',
        'Matches the student beneficiary group',
        'This scheme requires the applicant to be a student.',
      );
    }
    if (_containsAny(eligibility, ['farmer', 'farmers', 'cultivator'])) {
      requireFact(
        EligibilityFactKey.occupation,
        'Farmer status',
        (value) => _normalize(value) == 'farmer',
        'Matches the farmer beneficiary group',
        'This scheme is intended for farmers or cultivators.',
      );
    }
    if (_containsAny(eligibility, ['artisan', 'weaver', 'craftsperson'])) {
      requireFact(
        EligibilityFactKey.occupation,
        'Artisan status',
        (value) => _containsAny(_normalize(value), ['artisan', 'weaver']),
        'Matches the artisan beneficiary group',
        'This scheme requires artisan or related occupational status.',
      );
    }
    if (_containsAny(eligibility, [
      'disabled',
      'disability',
      'differently abled',
    ])) {
      requireFact(
        EligibilityFactKey.disability,
        'Disability category',
        (value) => _normalize(value) == 'yes',
        'Matches the disability beneficiary category',
        'This scheme is restricted to applicants with the stated disability category.',
      );
    }
    if (_containsAny(eligibility, ['widow', 'widowed'])) {
      requireFact(
        EligibilityFactKey.maritalStatus,
        'Widow status',
        (value) => _normalize(value) == 'widowed',
        'Matches the widow beneficiary category',
        'This scheme is restricted to widowed applicants.',
      );
    }

    final eligibilityScore = checked == 0
        ? 0.68
        : (passed + unknownKeys.length * 0.52) / checked;
    var score = match.score * 0.72 + eligibilityScore * 0.28;
    if (!isTrusted) score *= 0.82;
    if (disqualifiers.isNotEmpty) score *= 0.2;

    final state = disqualifiers.isNotEmpty
        ? SchemeMatchState.notSuitable
        : score >= 0.80 && unknowns.isEmpty
        ? SchemeMatchState.strongMatch
        : score >= 0.58 && unknowns.length <= 1
        ? SchemeMatchState.likelyMatch
        : SchemeMatchState.needsInformation;
    return SchemeRecommendation(
      scheme: scheme,
      score: score.clamp(0, 1),
      state: state,
      reasons: List.unmodifiable(reasons.toSet().take(3)),
      unknownRequirements: List.unmodifiable(unknowns.toSet()),
      disqualifiers: List.unmodifiable(disqualifiers),
      isTrusted: isTrusted,
    );
  }

  static FollowUpQuestion? _chooseQuestion(
    List<SchemeRecommendation> recommendations,
    Map<EligibilityFactKey, EligibilityFact> facts,
  ) {
    final scores = <EligibilityFactKey, double>{};
    for (var index = 0; index < math.min(5, recommendations.length); index++) {
      final recommendation = recommendations[index];
      for (final unknown in recommendation.unknownRequirements) {
        final key = _keyForUnknown(unknown);
        if (key != null && !facts.containsKey(key)) {
          scores.update(
            key,
            (score) => score + recommendation.score / (index + 1),
            ifAbsent: () => recommendation.score / (index + 1),
          );
        }
      }
    }
    if (scores.isEmpty) return null;
    final selected = scores.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    return _questions[selected.key];
  }

  static EligibilityFactKey? _keyForUnknown(String unknown) {
    final value = unknown.toLowerCase();
    if (value.contains('state')) return EligibilityFactKey.state;
    if (value.contains('age')) return EligibilityFactKey.age;
    if (value.contains('income')) return EligibilityFactKey.annualIncome;
    if (value.contains('gender')) return EligibilityFactKey.gender;
    if (value.contains('community')) return EligibilityFactKey.community;
    if (value.contains('student')) return EligibilityFactKey.studentStatus;
    if (value.contains('farmer') || value.contains('artisan')) {
      return EligibilityFactKey.occupation;
    }
    if (value.contains('disability')) return EligibilityFactKey.disability;
    if (value.contains('widow')) return EligibilityFactKey.maritalStatus;
    return null;
  }

  static bool _isTrusted(Scheme scheme) {
    final cached = _trustedSchemeCache[scheme];
    if (cached != null) return cached;
    final trusted = _computeTrust(scheme);
    _trustedSchemeCache[scheme] = trusted;
    return trusted;
  }

  static bool _computeTrust(Scheme scheme) {
    if (!scheme.isActive) return false;
    final status = _normalize('${scheme.status} ${scheme.verificationStatus}');
    if (_containsAny(status, [
      'historical',
      'closed',
      'withdrawn',
      'discontinued',
      'expired',
      'needs final',
      'needs further',
      'pending verification',
      'not verified',
    ])) {
      return false;
    }
    return scheme.sourceUrl.isNotEmpty &&
        _containsAny(status, [
          'verified',
          'official',
          'current',
          'active',
          'yes',
        ]);
  }

  static bool _matchesRequiredConcepts(
    Scheme scheme,
    Set<String> requiredConcepts,
  ) {
    if (requiredConcepts.isEmpty) return true;
    final searchable =
        _conceptTextCache[scheme] ??
        _normalize(
          '${scheme.name} ${scheme.sector} ${scheme.targetBeneficiary} '
          '${scheme.category} ${scheme.overview} ${scheme.searchKeywords}',
        );
    _conceptTextCache[scheme] = searchable;
    // A statement may contain independent needs (for example, a widow asking
    // about pension and general financial help). A scheme only needs to serve
    // one explicit need; relevance scoring decides which candidates lead.
    return requiredConcepts.any(
      (concept) => (_needAliases[concept] ?? [concept]).any(
        (alias) => _containsCatalogAlias(searchable, alias),
      ),
    );
  }

  static bool _containsCatalogAlias(String text, String alias) {
    final normalizedAlias = _normalize(alias);
    if (normalizedAlias.isEmpty) return false;
    if (' $text '.contains(' $normalizedAlias ')) return true;
    if (normalizedAlias.contains(' ') || normalizedAlias.length < 4) {
      return false;
    }
    return text
        .split(' ')
        .any(
          (token) =>
              token.startsWith(normalizedAlias) ||
              (token.length >= 4 && normalizedAlias.startsWith(token)),
        );
  }

  static (int, int)? _ageRange(String eligibility) {
    if (!_containsAny(eligibility, [
      'age',
      'aged',
      'years old',
      'years of age',
    ])) {
      return null;
    }
    final between = RegExp(
      r'(\d{1,2})\s*(?:-|to|–)\s*(\d{1,2})',
    ).firstMatch(eligibility);
    if (between != null) {
      return (int.parse(between.group(1)!), int.parse(between.group(2)!));
    }
    final minimum = RegExp(
      r'(?:above|at least|minimum)\s*(\d{1,2})',
    ).firstMatch(eligibility);
    if (minimum != null) return (int.parse(minimum.group(1)!), 120);
    final maximum = RegExp(
      r'(?:up to|below|maximum)\s*(\d{1,2})',
    ).firstMatch(eligibility);
    if (maximum != null) return (0, int.parse(maximum.group(1)!));
    return null;
  }

  static double? _incomeCeiling(String eligibility) {
    if (!_containsAny(eligibility, ['income', 'annual family income'])) {
      return null;
    }
    final match = RegExp(
      r'(?:below|less than|up to|not exceed(?:ing)?)\s*(?:rs\.?|₹)?\s*(\d+(?:\.\d+)?)\s*(lakh|lakhs|crore|thousand)?',
    ).firstMatch(eligibility.replaceAll(',', ''));
    if (match == null) return null;
    return _scaledMoney(match.group(1)!, match.group(2));
  }

  static double? _extractMoney(String input) {
    final match =
        RegExp(
          r'(?:₹|rs\.?|rupees?)?\s*(\d+(?:\.\d+)?)\s*(crore|crores|lakh|lakhs|lac|thousand|k|லட்சம்|கோடி)?',
          caseSensitive: false,
          unicode: true,
        ).allMatches(input.replaceAll(',', '')).where((candidate) {
          final suffix = candidate.group(2);
          final prefix = input.substring(0, candidate.start).toLowerCase();
          return suffix != null ||
              RegExp(r'₹|rs\.?|rupees?').hasMatch(candidate.group(0)!) ||
              RegExp(r'income|salary|loan|fund|வருமானம்|கடன்|நிதி').hasMatch(
                prefix.split(' ').reversed.take(3).toList().reversed.join(' '),
              );
        }).firstOrNull;
    if (match == null) return null;
    return _scaledMoney(match.group(1)!, match.group(2));
  }

  static double _scaledMoney(String amountText, String? unitText) {
    final amount = double.parse(amountText);
    final unit = _normalize(unitText ?? '');
    if (_containsAny(unit, ['crore', 'கோடி'])) return amount * 10000000;
    if (_containsAny(unit, ['lakh', 'lac', 'லட்சம்'])) return amount * 100000;
    if (_containsAny(unit, ['thousand', 'k'])) return amount * 1000;
    return amount;
  }

  static String? _firstAlias(
    String normalized,
    Map<String, List<String>> values,
  ) {
    for (final entry in values.entries) {
      if (entry.value.any((alias) => _contains(normalized, alias))) {
        return entry.key;
      }
    }
    return null;
  }

  static bool _containsAny(String text, Iterable<String> aliases) =>
      aliases.any((alias) => _contains(text, alias));

  static bool _contains(String text, String alias) {
    final normalizedAlias = _normalize(alias);
    if (normalizedAlias.isEmpty) return false;
    if (' $text '.contains(' $normalizedAlias ')) return true;
    if (normalizedAlias.contains(' ') || normalizedAlias.length < 5) {
      return false;
    }
    if (!RegExp(r'^[a-z0-9]+$').hasMatch(normalizedAlias)) return false;
    return text
        .split(' ')
        .any(
          (token) =>
              RegExp(r'^[a-z0-9]+$').hasMatch(token) &&
              token.length >= 5 &&
              IntelligentSchemeSearch.withinOneEdit(token, normalizedAlias),
        );
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\u0B80-\u0BFF]+', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
