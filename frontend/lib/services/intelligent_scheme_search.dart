import 'dart:math' as math;

import '../models/scheme_model.dart';

/// A ranked scheme match with short, user-facing explanations.
class SchemeSearchMatch {
  const SchemeSearchMatch({
    required this.scheme,
    required this.score,
    required this.reasons,
  });

  final Scheme scheme;
  final double score;
  final List<String> reasons;
}

/// Normalized meaning extracted from an English, Tamil, or Tanglish query.
class SchemeSearchIntent {
  const SchemeSearchIntent({
    required this.originalQuery,
    required this.terms,
    required this.concepts,
    required this.isTamil,
  });

  final String originalQuery;
  final Set<String> terms;
  final Set<String> concepts;
  final bool isTamil;
}

/// Lightweight multilingual retrieval for the bundled government-scheme data.
///
/// Tamil-script and colloquial Tanglish phrases are expanded into the English
/// concepts used by the source catalog, then every field is scored by relevance.
/// No query or catalog data leaves the device.
class IntelligentSchemeSearch {
  const IntelligentSchemeSearch._();

  // Catalog entries are immutable. Cache their normalized search document so
  // repeated conversational turns do not re-normalize the same 217 schemes.
  // User statements are intentionally never cached.
  static final Expando<_SchemeSearchDocument> _documentCache =
      Expando<_SchemeSearchDocument>('schemeSearchDocument');
  static final RegExp _asciiTokenPattern = RegExp(r'^[a-z0-9]+$');

  static const Map<String, _Concept> _concepts = {
    'agriculture': _Concept(
      label: 'Agriculture',
      aliases: [
        'agriculture',
        'agricultural',
        'farmer',
        'farmers',
        'farming',
        'crop',
        'crops',
        'irrigation',
        'horticulture',
        'vivasayam',
        'vivasayi',
        'vivasaayi',
        'vivasaya',
        'ulavar',
        'uzhavar',
        'விவசாயம்',
        'விவசாயி',
        'விவசாய',
        'உழவர்',
        'பயிர்',
        'பாசனம்',
      ],
      expansion: [
        'agriculture',
        'farmer',
        'farming',
        'crop',
        'irrigation',
        'horticulture',
      ],
    ),
    'education': _Concept(
      label: 'Education',
      aliases: [
        'student',
        'students',
        'education',
        'study',
        'studies',
        'school',
        'college',
        'degree',
        'scholarship',
        'scholarships',
        'padippu',
        'padikka',
        'kalvi',
        'maanavar',
        'manavar',
        'மாணவர்',
        'மாணவி',
        'கல்வி',
        'படிப்பு',
        'படிக்க',
        'உதவித்தொகை',
      ],
      expansion: [
        'student',
        'education',
        'school',
        'college',
        'scholarship',
        'degree',
      ],
    ),
    'women': _Concept(
      label: 'Women',
      aliases: [
        'woman',
        'women',
        'female',
        'girl',
        'girls',
        'widow',
        'mother',
        'pengal',
        'pen',
        'ponnu',
        'magalir',
        'thaai',
        'பெண்',
        'பெண்கள்',
        'மகளிர்',
        'பெண் குழந்தை',
        'விதவை',
        'தாய்',
      ],
      expansion: ['women', 'woman', 'female', 'girl', 'widow', 'mother'],
    ),
    'business': _Concept(
      label: 'Business',
      aliases: [
        'business',
        'entrepreneur',
        'enterprise',
        'startup',
        'start up',
        'msme',
        'self employment',
        'own business',
        'thozhil',
        'business ku',
        'suyathozhil',
        'kadai',
        'vyabaram',
        'தொழில்',
        'சுயதொழில்',
        'வியாபாரம்',
        'கடை',
        'தொழில்முனைவோர்',
      ],
      expansion: [
        'business',
        'entrepreneur',
        'enterprise',
        'startup',
        'msme',
        'self employment',
      ],
    ),
    'loan': _Concept(
      label: 'Loans',
      aliases: [
        'loan',
        'loans',
        'credit',
        'finance',
        'funding',
        'bank loan',
        'kadan',
        'loan venum',
        'கடன்',
        'வங்கிக் கடன்',
        'நிதி',
      ],
      expansion: ['loan', 'credit', 'finance', 'funding', 'bank'],
    ),
    'subsidy': _Concept(
      label: 'Subsidies',
      aliases: [
        'subsidy',
        'subsidies',
        'grant',
        'financial assistance',
        'maaniyam',
        'maniyam',
        'udhavi thogai',
        'உதவி தொகை',
        'உதவித்தொகை',
        'மானியம்',
        'நிதியுதவி',
      ],
      expansion: ['subsidy', 'grant', 'financial assistance', 'incentive'],
    ),
    'housing': _Concept(
      label: 'Housing',
      aliases: [
        'house',
        'housing',
        'home',
        'construction',
        'veedu',
        'veetuku',
        'வீடு',
        'வீட்டுக்கு',
        'குடியிருப்பு',
      ],
      expansion: ['house', 'housing', 'home', 'construction'],
    ),
    'health': _Concept(
      label: 'Healthcare',
      aliases: [
        'health',
        'medical',
        'hospital',
        'treatment',
        'insurance',
        'doctor',
        'maruthuvam',
        'vaithiyam',
        'sigichai',
        'மருத்துவம்',
        'சிகிச்சை',
        'மருத்துவ காப்பீடு',
        'ஆரோக்கியம்',
      ],
      expansion: ['health', 'medical', 'hospital', 'treatment', 'insurance'],
    ),
    'disability': _Concept(
      label: 'Disability support',
      aliases: [
        'disabled',
        'disability',
        'differently abled',
        'handicapped',
        'maatru thiranali',
        'மாற்றுத்திறனாளி',
        'மாற்றுத் திறனாளி',
      ],
      expansion: ['disabled', 'disability', 'differently abled'],
    ),
    'senior': _Concept(
      label: 'Senior citizens',
      aliases: [
        'senior citizen',
        'senior citizens',
        'elderly',
        'old age',
        'pension',
        'muthiyor',
        'vayasanavanga',
        'முதியோர்',
        'மூத்த குடிமக்கள்',
        'ஓய்வூதியம்',
      ],
      expansion: ['senior citizen', 'elderly', 'old age', 'pension'],
    ),
    'employment': _Concept(
      label: 'Jobs and skills',
      aliases: [
        'job',
        'jobs',
        'employment',
        'unemployed',
        'skill',
        'training',
        'velai',
        'velaivaippu',
        'payirchi',
        'வேலை',
        'வேலைவாய்ப்பு',
        'பயிற்சி',
        'திறன் மேம்பாடு',
      ],
      expansion: ['job', 'employment', 'unemployed', 'skill', 'training'],
    ),
    'community': _Concept(
      label: 'Community support',
      aliases: [
        'sc',
        'st',
        'obc',
        'scheduled caste',
        'scheduled tribe',
        'dalit',
        'tribal',
        'minority',
        'sirupaanmai',
        'பட்டியல் சாதி',
        'பட்டியல் பழங்குடி',
        'சிறுபான்மை',
        'ஆதிதிராவிடர்',
      ],
      expansion: [
        'sc',
        'st',
        'obc',
        'scheduled caste',
        'scheduled tribe',
        'tribal',
        'minority',
      ],
    ),
    'artisan': _Concept(
      label: 'Artisans',
      aliases: [
        'artisan',
        'craft',
        'handicraft',
        'weaver',
        'potter',
        'tailor',
        'kaivinai',
        'nesavalar',
        'கைவினை',
        'கைவினைஞர்',
        'நெசவாளர்',
      ],
      expansion: ['artisan', 'craft', 'handicraft', 'weaver'],
    ),
    'fisheries': _Concept(
      label: 'Fisheries',
      aliases: [
        'fish',
        'fisherman',
        'fishermen',
        'fisheries',
        'fishing',
        'meenavar',
        'meenpidi',
        'மீனவர்',
        'மீன்பிடி',
        'மீன்வளம்',
      ],
      expansion: ['fish', 'fisherman', 'fisheries', 'fishing'],
    ),
    'livestock': _Concept(
      label: 'Livestock',
      aliases: [
        'cattle',
        'cow',
        'goat',
        'dairy',
        'poultry',
        'livestock',
        'maadu',
        'aadu',
        'kozhi',
        'மாடு',
        'ஆடு',
        'கோழி',
        'கால்நடை',
        'பால்பண்ணை',
      ],
      expansion: [
        'cattle',
        'dairy',
        'poultry',
        'livestock',
        'animal husbandry',
      ],
    ),
    'marriage': _Concept(
      label: 'Marriage assistance',
      aliases: [
        'marriage',
        'wedding',
        'bride',
        'kalyana',
        'kalyanam',
        'thirumanam',
        'கல்யாணம்',
        'திருமணம்',
        'மணப்பெண்',
      ],
      expansion: ['marriage', 'wedding', 'bride', 'marriage assistance'],
    ),
    'food': _Concept(
      label: 'Food processing',
      aliases: [
        'food processing',
        'food business',
        'bakery',
        'processing unit',
        'unavu',
        'உணவு',
        'உணவு பதப்படுத்துதல்',
      ],
      expansion: ['food', 'food processing', 'processing unit'],
    ),
    'energy': _Concept(
      label: 'Clean energy',
      aliases: [
        'solar',
        'renewable',
        'clean energy',
        'electric vehicle',
        'ev',
        'sooriya',
        'சூரிய',
        'சூரிய மின்சாரம்',
        'புதுப்பிக்கத்தக்க ஆற்றல்',
      ],
      expansion: ['solar', 'renewable', 'clean energy', 'electric vehicle'],
    ),
  };

  static const Set<String> _stopWords = {
    'a',
    'an',
    'and',
    'are',
    'can',
    'could',
    'find',
    'for',
    'give',
    'help',
    'i',
    'in',
    'is',
    'me',
    'my',
    'need',
    'of',
    'please',
    'scheme',
    'schemes',
    'show',
    'the',
    'to',
    'want',
    'what',
    'which',
    'with',
    'enakku',
    'enga',
    'enna',
    'ennoda',
    'iruka',
    'irukku',
    'kidaikuma',
    'kudunga',
    'ku',
    'naa',
    'naan',
    'oru',
    'pathi',
    'thevai',
    'venum',
    'வேண்டும்',
    'வேணும்',
    'எனக்கு',
    'என்ன',
    'ஒரு',
    'திட்டம்',
    'திட்டங்கள்',
    'காட்டுங்க',
    'உதவி',
    'இருக்கா',
    'கிடைக்குமா',
  };

  static const Set<String> _tanglishMarkers = {
    'enakku',
    'ennoda',
    'iruka',
    'irukku',
    'kidaikuma',
    'ku',
    'kudunga',
    'illa',
    'irukken',
    'naa',
    'naan',
    'panna',
    'pannalam',
    'pathi',
    'thevai',
    'venum',
  };

  static SchemeSearchIntent interpret(String query) {
    final normalized = _normalize(query);
    final concepts = <String>{};
    final terms = <String>{};

    for (final token in _tokens(normalized)) {
      if (!_stopWords.contains(token) && token.length > 1) terms.add(token);
    }

    for (final entry in _concepts.entries) {
      if (entry.value.aliases.any(
        (alias) => _containsAlias(normalized, alias),
      )) {
        concepts.add(entry.key);
        terms.addAll(entry.value.expansion.map(_normalize));
      }
    }

    return SchemeSearchIntent(
      originalQuery: query.trim(),
      terms: terms,
      concepts: concepts,
      isTamil:
          RegExp(r'[\u0B80-\u0BFF]').hasMatch(query) ||
          _tokens(normalized).any(_tanglishMarkers.contains),
    );
  }

  static List<SchemeSearchMatch> rank(
    String query,
    Iterable<Scheme> schemes, {
    int? limit,
  }) {
    final intent = interpret(query);
    if (intent.terms.isEmpty) return const [];

    final normalizedQuery = _normalize(query);
    final matches = <SchemeSearchMatch>[];
    for (final scheme in schemes) {
      final scored = _scoreScheme(scheme, intent, normalizedQuery);
      if (scored.$1 < 2.5) continue;
      matches.add(
        SchemeSearchMatch(
          scheme: scheme,
          score: 1 - math.exp(-scored.$1 / 24),
          reasons: scored.$2,
        ),
      );
    }

    matches.sort((a, b) {
      final scoreOrder = b.score.compareTo(a.score);
      return scoreOrder != 0
          ? scoreOrder
          : a.scheme.name.compareTo(b.scheme.name);
    });
    if (limit != null && matches.length > limit) {
      return List.unmodifiable(matches.take(limit));
    }
    return List.unmodifiable(matches);
  }

  static (double, List<String>) _scoreScheme(
    Scheme scheme,
    SchemeSearchIntent intent,
    String normalizedQuery,
  ) {
    final document = _documentFor(scheme);
    final fields = document.fields;

    var score = 0.0;
    final reasonScores = <String, double>{};
    final normalizedCode = document.normalizedCode;
    if (normalizedQuery == normalizedCode && normalizedCode.isNotEmpty) {
      score += 100;
      reasonScores['Exact scheme code'] = 100;
    }
    if (normalizedQuery.length > 3 &&
        fields.first.$2.contains(normalizedQuery)) {
      score += 28;
      reasonScores['Scheme name'] = 28;
    }

    for (final field in fields) {
      var fieldScore = 0.0;
      for (final term in intent.terms) {
        if (_containsAlias(field.$2, term, tokens: field.$4)) {
          fieldScore += field.$3;
        }
      }
      if (fieldScore == 0) continue;
      score += fieldScore;
      reasonScores[_reasonForField(field.$1)] = fieldScore;
    }

    for (final conceptKey in intent.concepts) {
      final concept = _concepts[conceptKey]!;
      final hits = concept.expansion
          .where(
            (term) => _containsAlias(
              document.searchable,
              term,
              tokens: document.searchableTokens,
            ),
          )
          .length;
      if (hits > 0) {
        final conceptScore = 2.5 + math.min(hits, 3) * 1.5;
        score += conceptScore;
        reasonScores[concept.label] = conceptScore;
      }
    }

    final reasons = reasonScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return (score, reasons.take(2).map((entry) => entry.key).toList());
  }

  static _SchemeSearchDocument _documentFor(Scheme scheme) {
    final cached = _documentCache[scheme];
    if (cached != null) return cached;
    final normalizedFields = <(String, String, double)>[
      ('name', _normalize(scheme.name), 9),
      ('beneficiary', _normalize(scheme.targetBeneficiary), 6.5),
      ('category', _normalize('${scheme.category} ${scheme.sector}'), 6),
      ('keywords', _normalize(scheme.searchKeywords), 5),
      (
        'benefits',
        _normalize('${scheme.benefits} ${scheme.subsidyAmount}'),
        3.5,
      ),
      ('overview', _normalize('${scheme.overview} ${scheme.objectives}'), 2.5),
      ('eligibility', _normalize(scheme.eligibilityCriteria.join(' ')), 3),
      (
        'documents',
        _normalize(
          '${scheme.requiredDocuments.join(' ')} '
          '${scheme.requiredServices.map((service) => service.name).join(' ')}',
        ),
        1.5,
      ),
    ];
    final fields = normalizedFields
        .map(
          (field) => (
            field.$1,
            field.$2,
            field.$3,
            _tokens(field.$2).toList(growable: false),
          ),
        )
        .toList(growable: false);
    final searchable = normalizedFields.map((field) => field.$2).join(' ');
    final document = _SchemeSearchDocument(
      fields: fields,
      normalizedCode: _normalize(scheme.schemeCode),
      searchable: searchable,
      searchableTokens: _tokens(searchable).toList(growable: false),
    );
    _documentCache[scheme] = document;
    return document;
  }

  static String _reasonForField(String field) => switch (field) {
    'name' => 'Scheme name',
    'beneficiary' => 'Who it supports',
    'category' => 'Relevant sector',
    'benefits' => 'Matching benefits',
    'eligibility' => 'Eligibility match',
    'documents' => 'Application needs',
    _ => 'Scheme details',
  };

  static bool _containsAlias(
    String text,
    String alias, {
    Iterable<String>? tokens,
  }) {
    final normalizedAlias = _normalize(alias);
    if (normalizedAlias.isEmpty) return false;
    if (' $text '.contains(' $normalizedAlias ')) return true;
    if (normalizedAlias.contains(' ') || normalizedAlias.length < 4) {
      return false;
    }
    final allowSpellingTolerance = _asciiTokenPattern.hasMatch(normalizedAlias);
    return (tokens ?? _tokens(text)).any(
      (token) =>
          token.startsWith(normalizedAlias) ||
          (token.length >= 4 && normalizedAlias.startsWith(token)) ||
          (allowSpellingTolerance &&
              _asciiTokenPattern.hasMatch(token) &&
              token.length >= 5 &&
              normalizedAlias.length >= 5 &&
              withinOneEdit(token, normalizedAlias)),
    );
  }

  static bool withinOneEdit(String left, String right) {
    if ((left.length - right.length).abs() > 1) return false;
    var leftIndex = 0;
    var rightIndex = 0;
    var edits = 0;
    while (leftIndex < left.length && rightIndex < right.length) {
      if (left.codeUnitAt(leftIndex) == right.codeUnitAt(rightIndex)) {
        leftIndex++;
        rightIndex++;
        continue;
      }
      if (++edits > 1) return false;
      if (left.length > right.length) {
        leftIndex++;
      } else if (right.length > left.length) {
        rightIndex++;
      } else {
        leftIndex++;
        rightIndex++;
      }
    }
    if (leftIndex < left.length || rightIndex < right.length) edits++;
    return edits <= 1;
  }

  static Iterable<String> _tokens(String value) =>
      value.split(' ').where((token) => token.isNotEmpty);

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\u0B80-\u0BFF]+', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class _Concept {
  const _Concept({
    required this.label,
    required this.aliases,
    required this.expansion,
  });

  final String label;
  final List<String> aliases;
  final List<String> expansion;
}

class _SchemeSearchDocument {
  const _SchemeSearchDocument({
    required this.fields,
    required this.normalizedCode,
    required this.searchable,
    required this.searchableTokens,
  });

  final List<(String, String, double, List<String>)> fields;
  final String normalizedCode;
  final String searchable;
  final List<String> searchableTokens;
}
