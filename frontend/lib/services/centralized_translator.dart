import 'dart:core';

/// CentralizedTranslator
/// ─────────────────────
/// Centralized translation engine converting English catalog text, categories,
/// chips, badges, document names, service items, eligibility rules, and timeline steps
/// into accurate, natural Tamil when Tamil mode is active.
///
/// Priority Pipeline:
/// 1. Catalog JSON Tamil values (preferred if available).
/// 2. Centralized Flutter translation dictionary & sentence converter.
/// 3. Protected fields (URLs, emails, phone numbers, IDs, codes, dates, currency values) preserved.
class CentralizedTranslator {
  CentralizedTranslator._();

  static final CentralizedTranslator instance = CentralizedTranslator._();

  static final RegExp _urlRegex = RegExp(
    r'(https?:\/\/[^\s]+|www\.[^\s]+|[a-zA-Z0-9.-]+\.(gov|in|org|com|net|edu)(\/[^\s]*)?)',
    caseSensitive: false,
  );

  static final RegExp _emailRegex = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );

  static final RegExp _phoneRegex = RegExp(
    r'(\+91[\s-]?)?(\(?\d{3,5}\)?[\s-]?)?\d{6,8}',
  );

  static final RegExp _codeIdRegex = RegExp(r'^[A-Z0-9_]{3,20}$');

  /// Check if a given string should be preserved without translation.
  bool isProtectedText(String? input) {
    if (input == null) return true;
    final trimmed = input.trim();
    if (trimmed.isEmpty) return true;

    // Preserve URLs
    if (_urlRegex.hasMatch(trimmed)) return true;
    // Preserve Emails
    if (_emailRegex.hasMatch(trimmed)) return true;
    // Preserve Scheme Codes / IDs
    if (_codeIdRegex.hasMatch(trimmed) && !trimmed.contains(' ')) return true;
    // Preserve Phone numbers
    if (_phoneRegex.hasMatch(trimmed) &&
        RegExp(r'^\+?[0-9\s-]{7,15}$').hasMatch(trimmed)) {
      return true;
    }

    return false;
  }

  /// Translate short tags, categories, levels, and chip labels.
  String translateTag(String? rawTag) {
    if (rawTag == null) return '';
    final trimmed = rawTag.trim();
    if (trimmed.isEmpty || isProtectedText(trimmed)) return rawTag;

    final lower = trimmed.toLowerCase();
    if (_tagMap.containsKey(lower)) {
      return _tagMap[lower] ?? rawTag;
    }

    // Substring or fallback phrase map lookup
    if (_phraseMap.containsKey(lower)) {
      return _phraseMap[lower] ?? rawTag;
    }

    return translate(rawTag);
  }

  /// Translate dynamic text, descriptions, eligibility criteria, document items, services, or process steps.
  String translate(String? input) {
    if (input == null) return '';
    final trimmed = input.trim();
    if (trimmed.isEmpty || isProtectedText(trimmed)) return input;

    final lower = trimmed.toLowerCase();
    if (_phraseMap.containsKey(lower)) {
      return _phraseMap[lower] ?? input;
    }
    if (_tagMap.containsKey(lower)) {
      return _tagMap[lower] ?? input;
    }

    String translated = trimmed;

    // 1. Pattern-based sentence transformations (runs on full original sentence)
    _sentencePatterns.forEach((pattern, replacement) {
      translated = translated.replaceAllMapped(pattern, (m) {
        return replacement(m);
      });
    });

    // 2. Step prefix replacements (e.g. "Step 1:", "Step 2:")
    translated = translated.replaceAllMapped(
      RegExp(r'\bStep\s+(\d+):?', caseSensitive: false),
      (m) => 'படி ${m.group(1) ?? ''}:',
    );

    // 3. Phrase replacements (sorted by length descending)
    final sortedPhrases = _phraseMap.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final enPhrase in sortedPhrases) {
      final taPhrase = _phraseMap[enPhrase]!;
      final reg = RegExp(
        r'\b' + RegExp.escape(enPhrase) + r'\b',
        caseSensitive: false,
      );
      if (reg.hasMatch(translated)) {
        translated = translated.replaceAll(reg, taPhrase);
      }
    }

    // 4. Term replacements (sorted by length descending)
    final sortedTerms = _termMap.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final enTerm in sortedTerms) {
      final taTerm = _termMap[enTerm]!;
      final reg = RegExp(
        r'\b' + RegExp.escape(enTerm) + r'\b',
        caseSensitive: false,
      );
      if (reg.hasMatch(translated)) {
        translated = translated.replaceAll(reg, taTerm);
      }
    }

    return translated;
  }

  // ── Sentence Patterns ──────────────────────────────────────────────────

  static final Map<RegExp, String Function(Match)> _sentencePatterns = {
    RegExp(r'\bprovides?\s+capital\s+subsidy\b', caseSensitive: false): (m) =>
        'மூலதன மானிய நிதி உதவி வழங்குகிறது',
    RegExp(r'\bfinancial\s+assistance\s+for\b', caseSensitive: false): (m) =>
        'க்கான நிதி உதவி',
    RegExp(r'\bcredit\s+guarantee\s+cover\b', caseSensitive: false): (m) =>
        'கடன் உத்தரவாத பாதுகாப்பு',
    RegExp(r'\binterest\s+subvention\b', caseSensitive: false): (m) =>
        'வட்டி மானியம்',
    RegExp(r'\bmargin\s+money\s+assistance\b', caseSensitive: false): (m) =>
        'முன்பண நிதி உதவி',
    RegExp(
      r'\bfor\s+micro\s+and\s+small\s+enterprises\b',
      caseSensitive: false,
    ): (m) =>
        'குறு மற்றும் சிறு தொழில்களுக்காக',
    RegExp(r'\bin\s+tamil\s+nadu\b', caseSensitive: false): (m) =>
        'தமிழ்நாட்டில்',
    RegExp(
      r'\b(all\s+over\s+india|pan-india|across\s+india)\b',
      caseSensitive: false,
    ): (m) =>
        'இந்தியா முழுவதும்',
    RegExp(r'\btarget\s+beneficiaries:\s*', caseSensitive: false): (m) =>
        'பயனாளிகள்: ',
    RegExp(r'\bissued\s+by:\s*', caseSensitive: false): (m) => 'வழங்கியவர்: ',
    RegExp(r'\bestimated\s+cost:\s*', caseSensitive: false): (m) =>
        'மதிப்பிடப்பட்ட செலவு: ',
    RegExp(
      r'\bno\s+educational\s+qualification\s+required\b',
      caseSensitive: false,
    ): (m) =>
        'கல்வித் தகுதி தேவையில்லை',
    RegExp(r'\b8th\s+standard\s+pass\b', caseSensitive: false): (m) =>
        '8-ஆம் வகுப்பு தேர்ச்சி',
    RegExp(
      r'\baged?\s+between\s+(\d+)\s+and\s+(\d+)\s+years?\b',
      caseSensitive: false,
    ): (m) =>
        'வயது ${m.group(1) ?? ''} முதல் ${m.group(2) ?? ''} வரை',
    RegExp(
      r'\brolling\s+intake\s+throughout\s+(financial|fiscal|நிதி)\s+year\b',
      caseSensitive: false,
    ): (m) =>
        'நிதி ஆண்டு முழுவதும் தொடர் விண்ணப்ப ஏற்பு',
    RegExp(
      r'\bstep\s+1:\s*register\s+and\s+fill\s+online\s+application\s+via\s+(.*?)\s+portal\b',
      caseSensitive: false,
    ): (m) =>
        'படி 1: ${m.group(1) ?? ''} இணையதளம் மூலம் ஆன்லைன் விண்ணப்பத்தைப் பதிவு செய்து பூர்த்தி செய்யவும்',
    RegExp(
      r'\bstep\s+2:\s*submit\s+application\s+copy\s+and\s+checklist\s+documents\s+to\s+(.*?)\b',
      caseSensitive: false,
    ): (m) =>
        'படி 2: விண்ணப்ப நகல் மற்றும் சரிபார்ப்பு ஆவணங்களை ${m.group(1) ?? ''} இடம் சமர்ப்பிக்கவும்',
    RegExp(
      r'\bstep\s+3:\s*verification\s+&\s+field\s+inspection\s+by\s+(.*?)\b',
      caseSensitive: false,
    ): (m) =>
        'படி 3: ${m.group(1) ?? ''} மூலம் சரிபார்ப்பு மற்றும் கள ஆய்வு',
    RegExp(
      r'\bstep\s+4:\s*approval\s+and\s+direct\s+benefit\s+transfer\s*\(dbt\)\s*\/\s*subsidy\s+credit\s+to\s+bank\s+account\b',
      caseSensitive: false,
    ): (m) =>
        'படி 4: ஒப்புதல் மற்றும் நேரடி பயன் பரிமாற்றம் (DBT) / மானிய கடன் தொகையை வங்கி கணக்கில் செலுத்துதல்',
    RegExp(
      r'\badditional\s+capital\s+subsidy\s+for\s+micro\s+manufacturing\s+enterprises\b',
      caseSensitive: false,
    ): (m) =>
        'குறு உற்பத்தி நிறுவனங்களுக்கான கூடுதல் மூலதன மானியம்',
    RegExp(
      r'\bno\s+aadhaar,?\s*pan,?\s*udyam,?\s*bank,?\s*income,?\s*invoice,?\s*certificate,?\s*dpr\s+or\s+other\s+document\s+is\s+assumed\s+as\s+mandatory\b',
      caseSensitive: false,
    ): (m) =>
        'அதிகாரப்பூர்வ வழிகாட்டுதலின்றி எந்த ஆவணமும் கட்டாயமானதாகக் கருதப்படாது.',
    RegExp(
      r'\bno\s+amount,?\s*rate,?\s*eligibility\s+condition\s+or\s+subsidy\s+is\s+asserted\s+without\s+exact\s+current\s+official\s+source\b',
      caseSensitive: false,
    ): (m) =>
        'துல்லியமான அதிகாரப்பூர்வ ஆதாரம் இன்றி தொகை, வீதம், தகுதி நிபந்தனை அல்லது மானியம் உறுதிப்படுத்தப்படாது.',
    RegExp(
      r'\bexact\s+current\s+eligibility,?\s*support\s+amount\s+and\s+application\s+conditions\s+are\s+not\s+entered\b',
      caseSensitive: false,
    ): (m) =>
        'துல்லியமான தகுதி, உதவித் தொகை மற்றும் விண்ணப்ப நிபந்தனைகள் இன்னும் சரிபார்க்கப்பட வேண்டியுள்ளது.',
    RegExp(
      r'\bexact\s+current\s+application\s+document\s+checklist\s+pending\s+verification\b',
      caseSensitive: false,
    ): (m) =>
        'தற்போதைய துல்லியமான விண்ணப்ப ஆவணங்களின் பட்டியல் சரிபார்ப்பில் உள்ளது',
    RegExp(
      r'\bnot\s+specified\s+in\s+a\s+current\s+official\s+source\s+located\b',
      caseSensitive: false,
    ): (m) =>
        'தற்போதைய அதிகாரப்பூர்வ ஆதாரத்தில் குறிப்பிடப்படவில்லை',
    RegExp(
      r'\bprovides?\s+financial\s+assistance,?\s*subsidies,?\s*or\s+institutional\s+support\s+for\s+eligible\s+applicants\.?\b',
      caseSensitive: false,
    ): (m) =>
        'தகுதியான விண்ணப்பதாரர்களுக்கு நிதி உதவி, மானியங்கள் அல்லது நிறுவன ஆதரவை வழங்குகிறது.',
    RegExp(
      r'\blender\s+charges\s+as\s+applicable\b',
      caseSensitive: false,
    ): (m) =>
        'கடன் வழங்கும் நிறுவனக் கட்டணங்கள் பொருந்தும்',
  };

  // ── Dictionary Mappings ────────────────────────────────────────────────

  static final Map<String, String> _tagMap = {
    'central': 'மத்திய அரசு',
    'central level': 'மத்திய அரசு',
    'central scheme': 'மத்திய அரசு திட்டம்',
    'state': 'மாநில அரசு',
    'state level': 'மாநில அரசு',
    'state scheme': 'மாநில அரசு திட்டம்',
    'district': 'மாவட்ட நிலை',
    'district level': 'மாவட்ட நிலை',
    'pan india': 'அகில இந்திய அளவில்',
    'all india': 'அகில இந்திய அளவில்',
    'tamil nadu': 'தமிழ்நாடு',

    'msme': 'MSME',
    'msmes': 'MSME',
    'loan': 'கடன்',
    'loans': 'கடன்கள்',
    'subsidy': 'மானியம்',
    'subsidies': 'மானியங்கள்',
    'grant': 'உதவித் தொகை',
    'grants': 'உதவித் தொகைகள்',
    'credit': 'கடன் உதவி',
    'collateral-free': 'பிணையமற்ற கடன்',
    'collateral free': 'பிணையமற்ற கடன்',
    'udyam': 'உத்யம்',
    'startup': 'ஸ்டார்ட்அப்',
    'startups': 'ஸ்டார்ட்அப்',

    'women': 'மகளிர்',
    'women entrepreneurs': 'பெண் தொழில்முனைவோர்',
    'women entrepreneur': 'பெண் தொழில்முனைவோர்',
    'youth': 'இளைஞர்கள்',
    'farmer': 'விவசாயி',
    'farmers': 'விவசாயிகள்',
    'artisan': 'கைவினைஞர்',
    'artisans': 'கைவினைஞர்கள்',
    'self help group': 'சுய உதவிக்குழு',
    'self help groups': 'சுய உதவிக்குழுக்கள்',
    'agriculture': 'வேளாண்மை',
    'manufacturing': 'உற்பத்தித் துறை',
    'technology': 'தொழில்நுட்பம்',
    'tech': 'தொழில்நுட்பம்',
    'export': 'ஏற்றுமதி',
    'export promotion': 'ஏற்றுமதி ஊக்குவிப்பு',
    'export & trade promotion': 'ஏற்றுமதி & வர்த்தக ஊக்குவிப்பு',
    'business loans & credit': 'தொழில் கடன்கள் & கடன் உதவி',
    'shg & artisan': 'சுய உதவிக்குழு & கைவினைஞர்',
    'women entrepreneurship': 'பெண் தொழில்முனைவு',
    'business & msme': 'தொழில் & MSME',
    'agriculture & farming': 'வேளாண்மை & விவசாயம்',
    'education & student': 'கல்வி & மாணவர்கள்',
    'employment & skill': 'வேலைவாய்ப்பு & திறன்',
    'social welfare & pension': 'சமூக நலன் & ஓய்வூதியம்',
    'innovation': 'புதுமை',
    'equipment': 'உபகரணங்கள்',
    'training': 'பயிற்சி',
    'entrepreneurship': 'தொழில்முனைவு',
    'skill development': 'திறன் மேம்பாடு',

    'required': 'தேவையானவை',
    'conditional': 'நிபந்தனைக்குட்பட்டது',
    'optional': 'விருப்பத்தேர்வு',
    'mandatory': 'கட்டாயமானது',
    'active': 'செயலில்',
    'closed': 'முடிவடைந்தது',
    'verified': 'சரிபார்க்கப்பட்டது',
    'financing': 'நிதி உதவி',

    'capital subsidy': 'மூலதன மானியம்',
    'capital subsidy (capitalsubsidy)': 'மூலதன மானியம்',
    'capitalsubsidy': 'மூலதன மானியம்',
    'interestsubvention': 'வட்டி மானியம்',
    'trainingsupport': 'பயிற்சி உதவி',
    'marketsupport': 'சந்தைப்படுத்தல் உதவி',
    'general': 'பொது',

    'finance': 'நிதி',
    'tax & gst': 'வரி & ஜிஎஸ்டி',
    'treds': 'TReDS',
    'csr support': 'CSR ஆதரவு',
    'govt. authorities': 'அரசு அமைப்புகள்',
    'institutions': 'நிறுவனங்கள்',
  };

  static final Map<String, String> _phraseMap = {
    'government of india': 'இந்திய அரசு',
    'government of tamil nadu': 'தமிழ்நாடு அரசு',
    'not applicable (state scheme)': 'பொருந்தாது (மாநில அரசு திட்டம்)',
    'not applicable (central scheme)': 'பொருந்தாது (மத்திய அரசு திட்டம்)',
    'ministry of msme': 'MSME அமைச்சகம்',
    'social welfare and women empowerment department, government of tamil nadu':
        'சமூக நலன் மற்றும் மகளிர் உரிமைத் துறை, தமிழ்நாடு அரசு',
    'department of social welfare and women empowerment':
        'சமூக நலன் மற்றும் மகளிர் உரிமைத் துறை',
    'tamil nadu social welfare administration': 'தமிழ்நாடு சமூக நல நிர்வாகம்',
    'department of micro, small & medium enterprises, government of tamil nadu':
        'குறு, சிறு மற்றும் நடுத்தரத் தொழில்கள் துறை, தமிழ்நாடு அரசு',
    'district industries centres / tamil nadu msme department':
        'மாவட்ட தொழில் மையங்கள் / தமிழ்நாடு MSME துறை',
    'district industries centres': 'மாவட்ட தொழில் மையங்கள்',
    'district industries centre': 'மாவட்ட தொழில் மையம்',
    'ministry of women and child development':
        'பெண்கள் மற்றும் குழந்தைகள் மேம்பாட்டு அமைச்சகம்',
    'ministry of commerce & industry': 'வர்த்தகம் மற்றும் தொழில் அமைச்சகம்',
    'ministry of finance': 'நிதி அமைச்சகம்',
    'ministry of agriculture & farmers welfare':
        'வேளாண்மை மற்றும் விவசாயிகள் நல அமைச்சகம்',
    'ministry of rural development': 'ஊரக வளர்ச்சி அமைச்சகம்',
    'ministry of skill development and entrepreneurship':
        'திறன் மேம்பாடு மற்றும் தொழில்முனைவு அமைச்சகம்',
    'ministry of social justice and empowerment':
        'சமூக நீதி மற்றும் அதிகாரமளித்தல் அமைச்சகம்',
    'ministry of textiles': 'ஜவுளி அமைச்சகம்',
    'ministry of electronics and information technology':
        'எலக்ட்ரானிக்ஸ் மற்றும் தகவல் தொழில்நுட்ப அமைச்சகம்',
    'ministry of new and renewable energy':
        'புதிய மற்றும் புதுப்பிக்கத்தக்க ஆற்றல் அமைச்சகம்',
    'ministry of housing and urban affairs':
        'வீட்டுவசதி மற்றும் நகர்ப்புற விவகாரங்கள் அமைச்சகம்',
    'department of biotechnology, ministry of science & technology':
        'உயிர்தொழில்நுட்பவியல் துறை, அறிவியல் மற்றும் தொழில்நுட்ப அமைச்சகம்',
    'department of biotechnology': 'உயிர்தொழில்நுட்பவியல் துறை',
    'ministry of science & technology':
        'அறிவியல் மற்றும் தொழில்நுட்ப அமைச்சகம்',
    'small industries development bank of india (sidbi)':
        'இந்திய சிறு தொழில்கள் மேம்பாட்டு வங்கி (SIDBI)',
    'small industries development bank of india':
        'இந்திய சிறு தொழில்கள் மேம்பாட்டு வங்கி',
    'khadi and village industries commission (kvic)':
        'கதி மற்றும் கிராமத் தொழில்கள் ஆணையம் (KVIC)',
    'coir board': 'கயிறு வாரியம்',
    'spices board india': 'இந்திய நறுமணப் பொருட்கள் வாரியம்',
    'office of development commissioner (msme)':
        'வளர்ச்சி ஆணையர் அலுவலகம் (MSME)',
    'atal innovation mission, niti aayog': 'அடல் இன்னோவேஷன் மிஷன், நிதி ஆயோக்',
    'niti aayog': 'நிதி ஆயோக்',
    'wise-kiran division, dst':
        'WISE-KIRAN பிரிவு, அறிவியல் மற்றும் தொழில்நுட்பத் துறை',
    'dgft regional authorities': 'DGFT மண்டல அதிகாரிகள்',
    'startuptn': 'ஸ்டார்ட்அப் தமிழ்நாடு (StartupTN)',
    'edii-tn': 'EDII-TN (தொழில்முனைவோர் மேம்பாடு மற்றும் புத்தாக்க நிறுவனம்)',
    'tangedco / electricity authority':
        'டாங்கெட்கோ (TANGEDCO) / மின்சார வாரியம்',
    'member lending institutions': 'உறுப்பினர் கடன் வழங்கும் நிறுவனங்கள்',
    'member lending institution': 'உறுப்பினர் கடன் வழங்கும் நிறுவனம்',
    'government of rajasthan': 'ராஜஸ்தான் அரசு',
    'government of nagaland': 'நாகாலாந்து அரசு',
    'government of punjab': 'பஞ்சாப் அரசு',
    'government of maharashtra': 'மகாராஷ்டிரா அரசு',
    'government of karnataka': 'கர்நாடகா அரசு',
    'government of kerala': 'கேரளா அரசு',
    'government of gujarat': 'குஜராத் அரசு',
    'government of andhra pradesh': 'ஆந்திரப் பிரதேச அரசு',
    'government of telangana': 'தெலுங்கானா அரசு',
    'government of uttar pradesh': 'உத்தரப் பிரதேச அரசு',
    'government of west bengal': 'மேற்கு வங்க அரசு',
    'step 3: verification & field inspection by district msme officer / competent authority':
        'படி 3: மாவட்ட MSME அதிகாரி / தகுதியான அதிகாரியால் சரிபார்ப்பு மற்றும் கள ஆய்வு',
    'step 4: approval and direct benefit transfer / subsidy credit to bank account':
        'படி 4: ஒப்புதல் மற்றும் நேரடி பயன் பரிமாற்றம் (DBT) / மானிய கடன் தொகையை வங்கி கணக்கில் செலுத்துதல்',
    'step 4: approval and direct benefit transfer (dbt) / subsidy credit to bank account':
        'படி 4: ஒப்புதல் மற்றும் நேரடி பயன் பரிமாற்றம் (DBT) / மானிய கடன் தொகையை வங்கி கணக்கில் செலுத்துதல்',
    'udyam registration number': 'உத்யம் பதிவு எண்',
    'professional / bank costs vary': 'தொழில்முறை / வங்கி செலவுகள் மாறுபடும்',
    'government authorities / sidbi': 'அரசு அமைப்புகள் / SIDBI',
    'lender charges as applicable':
        'கடன் வழங்கும் நிறுவனக் கட்டணங்கள் பொருந்தும்',
    'registrar / partners / company': 'பதிவாளர் / பங்காளிகள் / நிறுவனம்',
    'yes / conditional': 'ஆம் / நிபந்தனைக்குட்பட்டது',
    'yes / நிபந்தனைக்குட்பட்டது': 'ஆம் / நிபந்தனைக்குட்பட்டது',
    'preparation cost varies': 'தயாரிப்பு செலவு மாறுபடும்',
    'statutory cost varies': 'சட்டப்பூர்வ செலவு மாறுபடும்',
    'professional fee varies': 'தொழில்முறை கட்டணம் மாறுபடும்',
    'no application fee identified': 'விண்ணப்பக் கட்டணம் எதுவும் இல்லை',
    'free official registration': 'இலவச அதிகாரப்பூர்வ பதிவு',
    'fixed assets certificate': 'நிலையான சொத்துக்கள் சான்றிதழ்',
    'block / area certificate': 'வட்டார சான்றிதழ்',
    'loan sanction letter': 'கடன் ஒப்புதல் கடிதம்',
    'first sale invoice / first delivery challan':
        'முதல் விற்பனை இன்வாய்ஸ் / முதல் டெலிவரி சலான்',
    'commercial production commencement certificate':
        'வணிக உற்பத்தி தொடக்க சான்றிதழ்',
    'partnership deed / memorandum & articles of association':
        'பங்குதாரர் ஒப்பந்தம் / நினைவுக்குறிப்பு மற்றும் அமைப்புக் கட்டுரைகள்',
    'land purchase deed': 'நில கொள்முதல் பத்திரம்',
    'lease agreement': 'குத்தகை ஒப்பந்தம்',
    'machinery invoices / cash bills / receipts':
        'இயந்திரங்களின் இன்வாய்ஸ்கள் / பணப் ரசீதுகள்',
    'detailed project report / business plan and funding requirement':
        'விரிவான திட்ட அறிக்கை / தொழில் திட்டம் மற்றும் நிதித் தேவை',
    'quotations / invoices for eligible assets or expenditure':
        'தகுதியான சொத்துக்கள் அல்லது செலவினங்களுக்கான மேற்கோள்கள் / இன்வாய்ஸ்கள்',
    'kyc of promoters / authorised persons':
        'நிறுவனர்கள் / அதிகாரமளிக்கப்பட்ட நபர்களின் KYC',
    'udyam registration / msme status proof': 'உத்யம் பதிவு / MSME நிலை சான்று',
    'power sanction & meter card': 'மின்சார அனுமதி மற்றும் மீட்டர் கார்டு',
    'goods and services tax (gst)': 'சரக்கு மற்றும் சேவை வரி (GST)',
    'income tax (income_tax)': 'வருமான வரி',
    'income tax return (income_tax_return)': 'வருமான வரி தாக்கல் அறிக்கை',
    'income tax': 'வருமான வரி',
    'marriage assistance': 'திருமண உதவி',
    'monthly educational assistance': 'மாதாந்திர கல்வி உதவி',
    'actual transaction cost': 'உண்மையான பரிவர்த்தனை செலவு',
    'actual expenditure': 'உண்மையான செலவு',
    'chartered accountant': 'சார்ட்டர்ட் அக்கவுண்டன்ட்',
    'lender-specific': 'கடன் வழங்கும் நிறுவனத்தைப் பொறுத்தது',
    'bank charges vary': 'வங்கி கட்டணங்கள் மாறுபடும்',
    'business loan': 'தொழில் கடன்',
    'credit guarantee': 'கடன் உத்தரவாதம்',
    'reimbursement': 'மறுசெலுத்துகை / திரும்பப் பெறுதல்',
    'government small-savings scheme': 'அரசு சிறுகமிப்புத் திட்டம்',
    'women entrepreneurship': 'பெண் தொழில்முனைவோர்',
    'base price': 'அடிப்படை விலை',
    'total invoice': 'மொத்த இன்வாய்ஸ்',
    'monthly emi': 'மாதாந்திர தவணை (EMI)',
    'principal amount': 'அசல் தொகை',
    'total interest payable': 'செலுத்த வேண்டிய மொத்த வட்டி',
    'total amount (principal + int)': 'மொத்த தொகை (அசல் + வட்டி)',
    'valuation range': 'மதிப்பீட்டு வரம்பு',
    'calculated arr': 'கணக்கிடப்பட்ட ARR',
    'applied arr multiple': 'பயன்படுத்தப்பட்ட ARR மடங்கு',
    'original project cost': 'அசல் திட்டச் செலவு',
    'expected subsidy': 'எதிர்பார்க்கப்படும் மானியம்',
    'net cost to business': 'தொழிலுக்கான நிகரச் செலவு',
    'cancel': 'இரத்து செய்',
    'use value': 'மதிப்பைப் பயன்படுத்து',
    'keep session only': 'அமர்வை மட்டும் வை',
    'save confirmed': 'சேமிப்பு உறுதி செய்யப்பட்டது',
    'view all': 'அனைத்தையும் காண்க',
    'review and save confirmed details':
        'உறுதிப்படுத்திய விவரங்களை ஆய்வு செய்து சேமிக்கவும்',
    'female': 'பெண்',
    'male': 'ஆண்',
    'transgender': 'திருநங்கை',
    'veteran status': 'முன்னாள் ராணுவத்தினர் நிலை',
    'disability': 'மாற்றுத்திறனாளி நிலை',
    'school': 'பள்ளி கல்வி',
    'diploma': 'டிப்ளோமா',
    'undergraduate': 'இளங்கலை (UG)',
    'postgraduate': 'முதுகலை (PG)',
    'ph.d.': 'முனைவர் பட்டம் (Ph.D.)',
    'existing business / entrepreneur': 'நிலவும் தொழில் / தொழில்முனைவோர்',
    'idea': 'யோசனை நிலை',
    'prototype': 'மாதிரி வடிவம்',
    'registered': 'பதிவு செய்யப்பட்டது',
    'operational': 'செயல்பாட்டில் உள்ளது',
    'expansion': 'தொழில் விரிவாக்கம்',
    'healthcare': 'சுகாதாரம்',
    'retail / services': 'சில்லறை வர்த்தகம் / சேவைகள்',
    'below ₹1.5 lakh': '₹1.5 இலட்சத்திற்குக் கீழ்',
    'above ₹8 lakh': '₹8 இலட்சத்திற்கு மேல்',
    'general inquiry': 'பொதுவான கேள்வி',
    'eligibility matcher bug': 'தகுதி கணக்கீட்டு பிழை',
    'wrong scheme details': 'தவறான திட்ட விவரங்கள்',
    'feature request': 'புதிய வசதி கோரிக்கை',
    'please describe the issue.': 'தயவுசெய்து சிக்கலை விவரிக்கவும்.',
    'selected notifications deleted':
        'தேர்ந்தெடுக்கப்பட்ட அறிவிப்புகள் நீக்கப்பட்டன',
    'filter options opened': 'வடிகட்டி விருப்பங்கள் திறக்கப்பட்டன',
    'all notifications marked as read':
        'அனைத்து அறிவிப்புகளும் படிக்கப்பட்டதாக குறிக்கப்பட்டன',
    'all notifications deleted': 'அனைத்து அறிவிப்புகளும் நீக்கப்பட்டன',
    'failed to fetch location': 'இருப்பிடத்தைப் பெற முடியவில்லை',
    'natural': 'இயற்கையான ஒலி',
    'clear': 'தெளிவான ஒலி',
    'latest': 'புதியது',
    'svg map here': 'வரைபடம்',
    'registered as pvt ltd / llp / partnership':
        'Pvt Ltd / LLP / பங்குதாரர் நிறுவனமாக பதிவு செய்யப்பட்டது',
    'must be registered in india':
        'இந்தியாவில் பதிவு செய்யப்பட்டிருக்க வேண்டும்',
    'incorporation age is under 10 years':
        'நிறுவன பதிவு காலம் 10 ஆண்டுகளுக்கு உட்பட்டது',
    'from incorporation date': 'நிறுவன பதிவு தேதியில் இருந்து',
    'annual turnover has never exceeded ₹100 cr':
        'ஆண்டு விற்றுமுதல் ஒருபோதும் ₹100 கோடியைத் தாண்டவில்லை',
    'for any financial year': 'எந்த ஒரு நிதி ஆண்டிலும்',
    'working towards innovation/scaling':
        'புதுமை/தொழில் விரிவாக்கத்தை நோக்கிய செயல்பாடு',
    'developing new products/processes':
        'புதிய தயாரிப்புகள்/செயல்முறைகளை உருவாக்குதல்',
    'micro manufacturing enterprises': 'குறு உற்பத்தி நிறுவனங்கள்',
    'micro enterprises': 'குறு நிறுவனங்கள்',
    'small enterprises': 'சிறு நிறுவனங்கள்',
    'medium enterprises': 'நடுத்தர நிறுவனங்கள்',
    'manufacturing msmes': 'உற்பத்தி MSMEகள்',
    'manufacturing msme': 'உற்பத்தி MSME',
    'new micro manufacturing enterprises': 'புதிய குறு உற்பத்தி நிறுவனங்கள்',
    'plant and machinery': 'ஆலை மற்றும் இயந்திரங்கள்',
    'plant & machinery': 'ஆலை & இயந்திரங்கள்',
    'subject to a maximum of': 'அதிகபட்சமாக',
    'lessor & lessee / issuing authority as applicable':
        'குத்தகைதாரர் மற்றும் குத்தகைக்கு விடுபவர் / சான்றிதழ் வழங்கும் அதிகாரம்',
    'lessor & lessee': 'குத்தகைதாரர் மற்றும் குத்தகைக்கு விடுபவர்',
    'as applicable': 'பொருந்தும் வகையில்',
    'if applicable': 'பொருந்தினால்',
    'post-sanction': 'அனுமதிக்கு பின்',
    'equitysupport': 'பங்கு நிதி உதவி',
    'customs duty (customs_duty)': 'சுங்க வரி',
    'startup india': 'ஸ்டார்ட்அப் இந்தியா',
    'block development officer': 'வட்டார வளர்ச்சி அதிகாரி (BDO)',
    'historical opening requirement': 'முந்தைய தொடக்கத் தேவை',
    'state-level edis': 'மாநில நிலை EDIகள்',
    'state-level edi': 'மாநில நிலை EDI',
    'official scheme information': 'அதிகாரப்பூர்வ திட்ட தகவல்',
    'scheme at a glance': 'திட்டத்தின் சுருக்கம்',
    'benefits details': 'நன்மைகள் பற்றிய விவரங்கள்',
    'eligibility criteria': 'தகுதி அளவுகோல்கள்',
    'required documents': 'தேவையான ஆவணங்கள்',
    'required services': 'தேவையான சேவைகள்',
    'application process': 'விண்ணப்பிக்கும் முறை',
    'no verified official link is available.':
        'சரிபார்க்கப்பட்ட அதிகாரப்பூர்வ இணைப்பு எதுவும் இல்லை.',
    'could not open the official website.':
        'அதிகாரப்பூர்வ இணையதளத்தைத் திறக்க முடியவில்லை.',
    'no document list is published for this scheme. check the official source before applying.':
        'இந்த திட்டத்திற்கு ஆவணப் பட்டியல் எதுவும் வெளியிடப்படவில்லை. விண்ணப்பிக்கும் முன் அதிகாரப்பூர்வ தளத்தை சரிபார்க்கவும்.',
    'no separate service requirement is listed for this scheme.':
        'இந்த திட்டத்திற்கு தனியான சேவைத் தேவைகள் எதுவும் பட்டியலிடப்படவில்லை.',
    'get document online': 'ஆவணத்தை ஆன்லைனில் பெறுக',
    'complete this phase to progress further.':
        'அடுத்த நிலைக்கு செல்ல இந்த படியை பூர்த்தி செய்யவும்.',
    'highly relevant': 'மிகவும் பொருத்தமானது',
    'verification note': 'சரிபார்ப்பு குறிப்பு',
    'aspiring and existing entrepreneurs':
        'புதிய மற்றும் நிலவும் தொழில்முனைவோர்கள்',
    'eligible msmes & enterprises': 'தகுதியுள்ள MSMEகள் மற்றும் நிறுவனங்கள்',
    'single-window application submission':
        'ஒற்றைச் சாளர விண்ணப்ப சமர்ப்பிப்பு',
    'single-window application submission, document verification, and subsidy processing.':
        'ஒற்றைச் சாளர விண்ணப்ப சமர்ப்பிப்பு, ஆவணங்கள் சரிபார்ப்பு மற்றும் மானிய செயலாக்கம்.',
    'document verification': 'ஆவணங்கள் சரிபார்ப்பு',
    'implementing agency service': 'செயல்படுத்தும் முகமை சேவை',
    'government service': 'அரசு சேவை',
    'application & verification service': 'விண்ணப்பம் மற்றும் சரிபார்ப்பு சேவை',
    'programme-specific': 'திட்டம் சார்ந்த',
    'training / entrepreneurship': 'பயிற்சி / தொழில்முனைவு',
    'batch-specific supporting documents': 'பிரிவு சார்ந்த ஆதரவு ஆவணங்கள்',
    'registration with msme-dfo': 'MSME-DFO அமைப்பில் பதிவு',
    'identity verification certificate': 'அடையாள சான்றிதழ்',
    'aadhaar card proof': 'ஆதார் அட்டை சான்று',
    'pan card proof': 'பான் அட்டை சான்று',
    'bank statement': 'வங்கி கணக்கு அறிக்கை',
    'project report': 'தொழில் திட்ட அறிக்கை',
    'udyam registration certificate': 'உத்யம் பதிவு சான்றிதழ்',
    'gst registration certificate': 'ஜிஎஸ்டி பதிவு சான்றிதழ்',
    'incorporation certificate': 'நிறுவன பதிவு சான்றிதழ்',
    'land / lease agreement': 'நில / குத்தகை ஒப்பந்தம்',
    'pollution control board clearance':
        'மாசு கட்டுப்பாட்டு வாரிய இசைவு சான்றிதழ்',
    'not specified': 'குறிப்பிடப்படவில்லை',
    'nil': 'கட்டணம் இல்லை',
    'technology centre': 'தொழில்நுட்ப மையம்',
    'technology centres': 'தொழில்நுட்ப மையங்கள்',
    'implementing agency': 'செயல்படுத்தும் முகமை',
    'implementing agencies': 'செயல்படுத்தும் முகமைகள்',
    'implementing authority': 'செயல்படுத்தும் அதிகாரம்',
    'field offices': 'கள அலுவலகங்கள்',
    'field office': 'கள அலுவலகம்',
    'district msme officer': 'மாவட்ட MSME அதிகாரி',
    'competent authority': 'தகுதியான அதிகாரம்',
    'competent officer': 'தகுதியான அதிகாரி',
    'direct benefit transfer': 'நேரடி பயன்பாட்டு பரிமாற்றம் (DBT)',
    'subsidy credit': 'மானிய கடன் தொகை',
    'no separate government fee stated': 'தனியான அரசு கட்டணம் இல்லை',
    'as decided by': 'முடிவு செய்தபடி',
    'micro, small & medium enterprises': 'குறு, சிறு & நடுத்தர தொழில்கள்',
    'micro, small and medium enterprises': 'குறு, சிறு & நடுத்தர தொழில்கள்',
    'ministry of micro, small & medium enterprises':
        'குறு, சிறு & நடுத்தர தொழில்கள் அமைச்சகம்',
    'entrepreneurship awareness': 'தொழில்முனைவு விழிப்புணர்வு',
    'entrepreneurship-cum-skill development':
        'தொழில்முனைவு மற்றும் திறன் மேம்பாடு',
    'management development': 'மேலாண்மை மேம்பாடு',
    'advanced programmes': 'மேம்பட்ட திட்டங்கள்',
    'cash subsidy': 'ரொக்க மானியம்',
    'universal cash subsidy': 'பொதுவான ரொக்க மானியம்',
    'eligible participants': 'தகுதியான பங்கேற்பாளர்கள்',
    'msme owners': 'MSME உரிமையாளர்கள்',
    'eligibility applies': 'தகுதி பொருந்தும்',
    'programme eligibility': 'திட்ட தகுதி',
    'eligibility information': 'தகுதி விவரங்கள்',
    'age / programme eligibility information': 'வயது / திட்ட தகுதி விவரங்கள்',
    'information required to establish programme eligibility':
        'திட்ட தகுதியை உறுதிப்படுத்த தேவையான விவரங்கள்',
    'participants aged 18 years and above':
        '18 வயது மற்றும் அதற்கு மேற்பட்ட பங்கேற்பாளர்கள்',
    'specific training notice': 'குறிப்பிட்ட பயிற்சி அறிவிப்பு',
    'organisation conducting the esdp programme':
        'ESDP திட்டத்தை நடத்தும் நிறுவனம்',
    'register and fill': 'பதிவு செய்து பூர்த்தி செய்யவும்',
    'uploaded online': 'ஆன்லைனில் பதிவேற்றப்பட்டது',
    'field inspection': 'கள ஆய்வு',
    'verification & field inspection': 'சரிபார்ப்பு & கள ஆய்வு',
    'capital subsidy': 'மூலதன மானியம்',
    'interest subvention': 'வட்டி மானியம்',
    'margin money': 'முன்பண உதவி',
    'loan guarantee': 'கடன் உத்தரவாதம்',
    'maximum funding': 'அதிகபட்ச நிதி உதவி',
    'minimum funding': 'குறைந்தபட்ச நிதி உதவி',
    'processing duration': 'செயலாக்க காலம்',
    'application fee': 'விண்ணப்பக் கட்டணம்',
    'intake timeline': 'சேர்க்கை காலக்கெடு',
    'yes': 'ஆம்',
    'no': 'இல்லை',
    'skip to results': 'முடிவுகளுக்குச் செல்',
    'back': 'பின்செல்',
    'next': 'அடுத்து',
    'previous': 'முந்தைய',
    'finish': 'முடிக்க',
    'done': 'முடிந்தது',
    'question': 'கேள்வி',
    'no questions available': 'கேள்விகள் எதுவும் இல்லை',
    'loading questions': 'கேள்விகள் ஏற்றப்படுகின்றன...',
    'recommended schemes': 'பரிந்துரைக்கப்பட்ட திட்டங்கள்',
    'view results': 'முடிவுகளைக் காண்க',
    'start again': 'மீண்டும் தொடங்கவும்',
    'continue': 'தொடரவும்',
    'close': 'மூடு',
  };

  static final Map<String, String> _termMap = {
    'candidate': 'விண்ணப்பதாரர்',
    'applicant': 'விண்ணப்பதாரர்',
    'implementing': 'செயல்படுத்தும்',
    'organisation': 'நிறுவனம்',
    'organization': 'நிறுவனம்',
    'conducting': 'நடத்தும்',
    'programme': 'திட்டம்',
    'programmes': 'திட்டங்கள்',
    'program': 'திட்டம்',
    'programs': 'திட்டங்கள்',
    'varies': 'மாறுபடும்',
    'stated': 'குறிப்பிடப்பட்டுள்ளது',
    'evidence': 'ஆதாரம்',
    'notice': 'அறிவிப்பு',
    'awareness': 'விழிப்புணர்வு',
    'management': 'மேலாண்மை',
    'advanced': 'மேம்பட்ட',
    'universal': 'பொதுவான',
    'cash': 'ரொக்கம்',
    'owners': 'உரிமையாளர்கள்',
    'owner': 'உரிமையாளர்',
    'participants': 'பங்கேற்பாளர்கள்',
    'participant': 'பங்கேற்பாளர்',
    'offices': 'அலுவலகங்கள்',
    'office': 'அலுவலகம்',
    'inspection': 'ஆய்வு',
    'officer': 'அதிகாரி',
    'competent': 'தகுதியான',
    'direct': 'நேரடி',
    'transfer': 'பரிமாற்றம்',
    'portal': 'தளம்',
    'centre': 'மையம்',
    'centers': 'மையங்கள்',
    'centres': 'மையங்கள்',
    'agency': 'முகமை',
    'agencies': 'முகமைகள்',
    'category': 'பிரிவு',
    'education': 'கல்வி',
    'training': 'பயிற்சி',
    'based': 'சார்ந்த',
    'rather': 'விட',
    'than': 'விட',
    'through': 'மூலம்',
    'via': 'மூலம்',
    'specifies': 'குறிப்பிடுகிறது',
    'established': 'உறுதிப்படுத்தப்பட்ட',
    'establish': 'உறுதிப்படுத்த',
    'includes': 'அடங்கும்',
    'applied': 'பொருந்தும்',
    'applies': 'பொருந்தும்',
    'information': 'விவரங்கள்',
    'required': 'தேவையான',
    'details': 'விவரங்கள்',
    'fee': 'கட்டணம்',
    'fees': 'கட்டணங்கள்',
    'separate': 'தனியான',
    'government': 'அரசு',
    'govt': 'அரசு',
    'enterprises': 'நிறுவனங்கள்',
    'enterprise': 'நிறுவனம்',
    'checklist': 'சரிபார்ப்புப் பட்டியல்',
    'guideline': 'வழிகாட்டுதல்',
    'guidelines': 'வழிகாட்டுதல்கள்',
    'proposal': 'திட்ட முன்மொழிவு',
    'ecosystem': 'தொழில் சூழல்',
    'records': 'பதிவுகள்',
    'authoritative': 'அதிகாரப்பூர்வ',
    'institutions': 'நிறுவனங்கள்',
    'entered': 'உள்ளிடப்பட்டது',
    'asserted': 'உறுதிப்படுத்தப்பட்டது',
    'component': 'கூறு',
    'tenure': 'காலஅளவு',
    'lakh': 'இலட்சம்',
    'crore': 'கோடி',
    'receipts': 'ரசீதுகள்',
    'bills': 'பில்கள்',
    'quotations': 'மேற்கோள்கள்',
    'invoices': 'இன்வாய்ஸ்கள்',
    'expenditure': 'செலவினம்',

    'online': 'ஆன்லைன்',
    'offline': 'ஆஃப்லைன்',
    'submit': 'சமர்ப்பிக்கவும்',
    'copy': 'நகல்',
    'copies': 'நகல்கள்',
    'sub-registrar': 'சார்புப் பதிவாளர்',
    'registrar': 'பதிவாளர்',
    'conditional': 'நிபந்தனைக்குட்பட்டது',
    'pending': 'நிலுவையில் உள்ள',
    'historical': 'முந்தைய',
    'opening': 'தொடக்க',
    'reservation': 'ஒதுக்கீடு',
    'implementation': 'செயல்படுத்தல்',
    'statutory': 'சட்டப்பூர்வ',
    'form': 'படிவம்',
    'incentive': 'ஊக்கத்தொகை',
    'funding': 'நிதித் தேவை',
    'product': 'தயாரிப்பு',
    'products': 'தயாரிப்புகள்',
    'level': 'நிலை',
    'new': 'புதிய',
    'existing': 'நிலவும்',
    'anywhere': 'எங்கும்',
    'record': 'பதிவு',
    'amount': 'தொகை',
    'rate': 'வீதம்',
    'duration': 'காலஅளவு',
    'cost': 'செலவு',
    'costs': 'செலவுகள்',
    'charges': 'கட்டணங்கள்',
    'charge': 'கட்டணம்',
    'institution': 'நிறுவனம்',

    'entrepreneurs': 'தொழில்முனைவோர்கள்',
    'entrepreneur': 'தொழில்முனைவோர்',
    'beneficiaries': 'பயனாளிகள்',
    'beneficiary': 'பயனாளி',
    'application': 'விண்ணப்பம்',
    'submission': 'சமர்ப்பிப்பு',
    'verification': 'சரிபார்ப்பு',
    'registration': 'பதிவு',
    'certificate': 'சான்றிதழ்',
    'proof': 'சான்று',
    'identity': 'அடையாளம்',
    'address': 'முகவரி',
    'income': 'வருமானம்',
    'caste': 'சாதி',
    'community': 'சமூகம்',
    'financial': 'நிதி',
    'assistance': 'உதவி',
    'project': 'திட்டம்',
    'report': 'அறிக்கை',
    'bank': 'வங்கி',
    'account': 'கணக்கு',
    'statement': 'அறிக்கை',
    'business': 'தொழில்',
    'plan': 'திட்டம்',
    'approval': 'ஒப்புதல்',
    'sanction': 'அனுமதி',
    'disbursement': 'நிதி வழங்குதல்',
    'authority': 'அதிகாரம்',
    'department': 'துறை',
    'ministry': 'அமைச்சகம்',
  };
}
