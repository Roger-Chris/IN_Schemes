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
    'enterprise finance': 'நிறுவன நிதி',
    'research grant / career support': 'ஆராய்ச்சி மானியம் / தொழில் ஆதரவு',
    'general': 'பொதுவானவை',
    'manufacturing enterprises': 'உற்பத்தி நிறுவனங்கள்',
    'land-purchase subsidy': 'நிலக் கொள்முதல் மானியம்',
    'women welfare / household support': 'பெண்கள் நலன் / குடும்ப ஆதரவு',
    'enterprise/startup support': 'நிறுவனம் / ஸ்டார்ட்அப் ஆதரவு',
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
    'find government subsidies, grants, and registration schemes you are eligible for, customized to your profile details.':
        'உங்கள் சுயவிவர விவரங்களின் அடிப்படையில் நீங்கள் தகுதியான அரசு மானியங்கள், உதவித்தொகைகள் மற்றும் பதிவு திட்டங்களை கண்டறியுங்கள்.',
    'access loan options, credit guarantees, equipment loans, and sidbi schemes to finance and expand your enterprise.':
        'உங்கள் தொழிலுக்கு நிதியளிக்கவும் விரிவாக்கவும் கடன் விருப்பங்கள், கடன் உத்தரவாதங்கள், உபகரண கடன்கள் மற்றும் SIDBI திட்டங்களை அணுகுங்கள்.',
    'learn about corporate tax reductions, gst threshold relief, composition schemes, and legal interest claims for payment delays.':
        'கார்ப்பரேட் வரி குறைப்புகள், GST வரம்பு விலக்குகள், காம்போசிஷன் திட்டங்கள் மற்றும் தாமதமான செலுத்துகைகளுக்கான சட்டப்பூர்வ வட்டி உரிமைக்கோரல்கள் பற்றி அறியுங்கள்.',
    'discover export incentives, financial credits, credit insurance, and regulatory agencies to expand your business globally.':
        'உங்கள் தொழிலை உலகளவில் விரிவாக்க ஏற்றுமதி சலுகைகள், நிதி கடன்கள், கடன் காப்பீடு மற்றும் ஒழுங்குமுறை முகமைகளை கண்டறியுங்கள்.',
    'discount your trade invoices through online bidding with banks and financial institutions to get immediate cash flow without collateral.':
        'பிணையமின்றி உடனடி பணப்புழக்கத்தைப் பெற வங்கிகள் மற்றும் நிதி நிறுவனங்களின் ஆன்லைன் ஏலம் மூலம் உங்கள் வர்த்தக இன்வாய்ஸ்களை தள்ளுபடி செய்யுங்கள்.',
    'connect with corporate social responsibility (csr) programs, tech incubation grants, and specialized skill development clusters.':
        'கார்ப்பரேட் சமூகப் பொறுப்பு (CSR) திட்டங்கள், தொழில்நுட்ப இன்குபேஷன் மானியங்கள் மற்றும் சிறப்பு திறன் மேம்பாட்டு கிளஸ்டர்களுடன் இணையுங்கள்.',
    'understand government department responsibilities and reach the appropriate authority (central ministry, state directorate, or district dic) for business help.':
        'அரசுத் துறைகளின் பொறுப்புகளைப் புரிந்து கொண்டு தொழில் உதவிக்காக பொருத்தமான அதிகார அமைப்பை (மத்திய அமைச்சகம், மாநில இயக்ககம் அல்லது மாவட்ட DIC) தொடர்பு கொள்ளுங்கள்.',
    'identify the right institutions (sidbi, nsic, dic, kvic, etc.) and explore their service catalogs, contact avenues, and programs.':
        'சரியான நிறுவனங்களை (SIDBI, NSIC, DIC, KVIC போன்றவை) அடையாளம் கண்டு அவற்றின் சேவைப் பட்டியல்கள், தொடர்பு வழிகள் மற்றும் திட்டங்களை ஆராயுங்கள்.',
    'export readiness assessment': 'ஏற்றுமதி தயார்நிலை மதிப்பீடு',
    'complete this checklist to identify missing links for international trade registration.':
        'சர்வதேச வர்த்தகப் பதிவிற்கான விடுபட்டத் தேவைகளைக் கண்டறிய இந்த சரிபார்ப்புப் பட்டியலைப் பூர்த்தி செய்யுங்கள்.',
    'do you have an import export code (iec) from dgft?':
        'உங்களிடம் DGFT வழங்கும் இறக்குமதி ஏற்றுமதி குறியீடு (IEC) உள்ளதா?',
    'apply online on dgft.gov.in. it is issued instantly against pan.':
        'dgft.gov.in இல் ஆன்லைனில் விண்ணப்பிக்கவும். இது PAN அடிப்படையில் உடனடியாக வழங்கப்படுகிறது.',
    'do you have an active bank account and ad code registration?':
        'உங்களிடம் செயலில் உள்ள வங்கிக் கணக்கு மற்றும் AD Code பதிவு உள்ளதா?',
    'request an ad (authorized dealer) code from your bank and register it with customs.':
        'உங்கள் வங்கியிலிருந்து AD (அங்கீகரிக்கப்பட்ட விநியோகஸ்தர்) குறியீட்டைக் கேட்டு சுங்கத்துறையில் பதிவு செய்யவும்.',
    'have you identified the hs code (harmonized system code) for your product?':
        'உங்கள் தயாரிப்புக்கான HS குறியீட்டை (இணக்கமான அமைப்பு குறியீடு) கண்டறிந்துவிட்டீர்களா?',
    'hs codes classify products globally. search online or consult a customs broker.':
        'HS குறியீடுகள் தயாரிப்புகளை உலகளவில் வகைப்படுத்துகின்றன. ஆன்லைனில் தேடவும் அல்லது சுங்க தரகரை ஆலோசிக்கவும்.',
    'is your business registered under udyam (msme registration)?':
        'உங்கள் தொழில் உத்யம் (MSME பதிவு) கீழ் பதிவு செய்யப்பட்டுள்ளதா?',
    'free registration on udyamregistration.gov.in. required for export subsidies.':
        'udyamregistration.gov.in இல் இலவச பதிவு. ஏற்றுமதி மானியங்களுக்கு தேவை.',
    'do you have an rcmc from an export promotion council?':
        'ஏற்றுமதி மேம்பாட்டுக் குழுவில் இருந்து RCMC சான்றிதழ் உங்களிடம் உள்ளதா?',
    'registration cum membership certificate (rcmc) is needed to claim duty refunds/incentives.':
        'வரித் திரும்பப் பெறுதல்/சலுகைகளைக் கோர பதிவு மற்றும் உறுப்பினர் சான்றிதழ் (RCMC) தேவை.',
    'treds invoice discounting flow': 'TReDS இன்வாய்ஸ் தள்ளுபடி செயல்முறை',
    '1. invoice upload': '1. இன்வாய்ஸ் பதிவேற்றம்',
    'msme seller uploads the invoice for goods/services delivered to the corporate buyer on the treds platform (rxil/m1xchange/invoicemart).':
        'MSME விற்பனையாளர் கார்ப்பரேட் வாங்குபவருக்கு வழங்கப்பட்ட பொருட்கள்/சேவைகளுக்கான இன்வாய்ஸை TReDS தளத்தில் (RXIL/M1xchange/Invoicemart) பதிவேற்றுகிறார்.',
    'seller uploads invoice & supporting documents.':
        'விற்பனையாளர் இன்வாய்ஸ் மற்றும் ஆதரவு ஆவணங்களை பதிவேற்றுகிறார்.',
    '2. buyer acceptance': '2. வாங்குபவரின் ஏற்பு',
    'the corporate buyer logs into the treds portal, verifies the details, and digitally accepts the uploaded invoice.':
        'கார்ப்பரேட் வாங்குபவர் TReDS போர்ட்டலில் உள்நுழைந்து, விவரங்களைச் சரிபார்த்து, பதிவேற்றிய இன்வாய்ஸை டிஜிட்டல் முறையில் ஏற்கிறார்.',
    'buyer approves invoice; it becomes a legally binding payment obligation.':
        'வாங்குபவர் இன்வாய்ஸை அங்கீகரிக்கிறார்; இது சட்டப்பூர்வ கட்டணப் பொறுப்பாக மாறுகிறது.',
    '3. bank bidding': '3. வங்கி ஏலம்',
    'multiple financiers (banks and nbfcs) compete by placing bids with their discount rates (interest rates) to buy the invoice.':
        'பல நிதியாளர்கள் (வங்கிகள் மற்றும் NBFCகள்) இன்வாய்ஸை வாங்க தங்களது தள்ளுபடி விகிதங்களுடன் (வட்டி விகிதங்கள்) ஏலம் எடுக்க போட்டியிடுகின்றனர்.',
    'banks bid anonymously based on the buyer\'s credit rating.':
        'வாங்குபவரின் கடன் மதிப்பீட்டின் அடிப்படையில் வங்கிகள் அநாமதேயமாக ஏலம் எடுக்கின்றன.',
    '4. funds disbursal': '4. நிதி வழங்குதல்',
    'seller selects the best bid (lowest discount rate). funds are credited to the seller\'s bank account within 24-48 hours (t+1 or t+2) minus the discount.':
        'விற்பனையாளர் சிறந்த ஏலத்தைத் (குறைந்த தள்ளுபடி விகிதம்) தேர்ந்தெடுக்கிறார். தள்ளுபடி கழித்து 24-48 மணி நேரத்திற்குள் (T+1 அல்லது T+2) விற்பனையாளரின் வங்கிக் கணக்கில் நிதி வரவு வைக்கப்படுகிறது.',
    'seller gets instant working capital; buyer pays the bank on the due date.':
        'விற்பனையாளர் உடனடி நடப்பு மூலதனத்தைப் பெறுகிறார்; வாங்குபவர் குறித்த தேதியில் வங்கிக்குச் செலுத்துகிறார்.',
    'explore csr & technology clusters':
        'CSR மற்றும் தொழில்நுட்ப கிளஸ்டர்களை ஆராயுங்கள்',
    'search cluster / tech schemes':
        'கிளஸ்டர் / தொழில்நுட்ப திட்டங்களைத் தேடுக',
    'government authorities tree': 'அரசு அதிகார அமைப்புகள் படிநிலை',
    'central': 'மத்திய அரசு',
    'state': 'மாநில அரசு',
    'district': 'மாவட்ட நிலை',
    'ministry of micro, small and medium enterprises (m/o msme)':
        'குறு, சிறு மற்றும் நடுத்தர தொழில்கள் அமைச்சகம் (M/o MSME)',
    '• formulation and administration of rules, regulations, and laws.\n• designs apex developmental schemes (pmegp, cgtmse, sfurti).\n• coordinates with other central ministries for national policy.':
        '• விதிகள், விதிமுறைகள் மற்றும் சட்டங்களை உருவாக்குதல் மற்றும் நிர்வகித்தல்.\n• முதன்மை மேம்பாட்டுத் திட்டங்களை (PMEGP, CGTMSE, SFURTI) வடிவமைத்தல்.\n• தேசியக் கொள்கைக்காக பிற மத்திய அமைச்சகங்களுடன் ஒருங்கிணைத்தல்.',
    'located in udyog bhawan, new delhi. operates msme development institutes (msme-di) nationwide.':
        'புது தில்லியில் உள்ள உத்யோக் பவனில் அமைந்துள்ளது. நாடு முழுவதும் MSME மேம்பாட்டு நிறுவனங்களை (MSME-DI) இயக்குகிறது.',
    'state directorate of industries / commissionerate':
        'மாநில தொழில்கள் இயக்ககம் / ஆணையரகம்',
    '• implements central and state industrial policies.\n• handles state capital incentives, interest subsidies, and power tariff concessions.\n• coordinates development of industrial parks and estates.':
        '• மத்திய மற்றும் மாநில தொழில் கொள்கைகளை செயல்படுத்துகிறது.\n• மாநில மூலதனச் சலுகைகள், வட்டி மானியங்கள் மற்றும் மின் கட்டண சலுகைகளைக் கையாள்கிறது.\n• தொழில் பூங்காக்கள் மற்றும் எஸ்டேட்டுகளின் வளர்ச்சியை ஒருங்கிணைக்கிறது.',
    'in tamil nadu, this is the department of industries and commerce (msme department).':
        'தமிழ்நாட்டில், இது தொழில் மற்றும் வணிகத் துறை (MSME துறை) ஆகும்.',
    'district industries centre (dic)': 'மாவட்ட தொழில் மையம் (DIC)',
    '• nodal agency at the grass-roots level providing udyam registration assistance.\n• recommends loan approvals to banks under pmegp.\n• performs spot verification of industrial units for subsidy release.\n• resolves local vendor issues via micro & small enterprises facilitation council (msefc).':
        '• உத்யம் பதிவு உதவியை வழங்கும் அடிமட்ட அளவிலான முதன்மை நிறுவனம்.\n• PMEGP இன் கீழ் வங்கிகளுக்கு கடன் ஒப்புதல்களை பரிந்துரைக்கிறது.\n• மானிய வெளியீட்டிற்காக தொழில்முறை பிரிவுகளின் நேரடி கள ஆய்வை மேற்கொள்கிறது.\n• MSEFC மூலம் உள்ளூர் விற்பனையாளர் பிரச்சினைகளை தீர்க்கிறது.',
    'each district in india has a dic, headed by a general manager.':
        'இந்தியாவில் உள்ள ஒவ்வொரு மாவட்டத்திலும் ஒரு பொது மேலாளர் தலைமையிலான DIC உள்ளது.',
    'search support institutions': 'ஆதரவு நிறுவனங்களைத் தேடுக',
    'principal financial institution for msme promotion, financing, and development.':
        'MSME ஊக்குவிப்பு, நிதியளிப்பு மற்றும் வளர்ச்சிக்கான முதன்மை நிதி நிறுவனம்.',
    'direct lending, venture capital, refinance to banks, startup funding.':
        'நேரடி கடன், வென்ச்சர் கேபிட்டல், வங்கிகளுக்கு மறுநிதியளிப்பு, ஸ்டார்ட்அப் நிதி.',
    'government enterprise facilitating marketing, technology, and raw material support.':
        'சந்தைப்படுத்தல், தொழில்நுட்பம் மற்றும் மூலப்பொருட்களின் உதவியை வழங்கும் அரசு நிறுவனம்.',
    'raw material assistance scheme, single point registration scheme for govt tenders.':
        'மூலப்பொருள் உதவித் திட்டம், அரசு டெண்டர்களுக்கான ஒற்றைப் புள்ளி பதிவுத் திட்டம்.',
    'district-level nodal agency providing single-window assistance for setting up msmes.':
        'MSMEகளை அமைப்பதற்கான ஒற்றைச் சாளர உதவியை வழங்கும் மாவட்ட அளவிலான முதன்மை நிறுவனம்.',
    'udyam registration support, state subsidy verification, local clearances, pmegp implementation.':
        'உத்யம் பதிவு ஆதரவு, மாநில மானிய சரிபார்ப்பு, உள்ளூர் அனுமதிகள், PMEGP அமலாக்கம்.',
    'nodal agency implementing rural employment and cottage industry schemes.':
        'ஊரக வேலைவாய்ப்பு மற்றும் குடிசைத் தொழில் திட்டங்களை செயல்படுத்தும் முதன்மை நிறுவனம்.',
    'subsidies, training centers, khadi production support, sales outlets.':
        'மானியங்கள், பயிற்சி மையங்கள், கதர் உற்பத்தி ஆதரவு, விற்பனை நிலையங்கள்.',
    'state-level financial institution providing term loans to msmes in tamil nadu.':
        'தமிழ்நாட்டில் உள்ள MSMEகளுக்கு தவணை கடன்களை வழங்கும் மாநில அளவிலான நிதி நிறுவனம்.',
    'term loans for land, building, and machinery acquisition.':
        'நிலம், கட்டிடம் மற்றும் இயந்திரங்கள் வாங்குவதற்கான தவணைக் கடன்கள்.',
    'nodal agencies for fostering startup ecosystem and facilitating msmes in tamil nadu.':
        'தமிழ்நாட்டில் ஸ்டார்ட்அப் சுற்றுச்சூழல் அமைப்பை வளர்ப்பதற்கும் MSMEகளை எளிாக்குவதற்கும் முதன்மை முகமைகள்.',
    'tanseed seed fund, incubator support, marketing assistance, buyer-seller meets.':
        'TANSEED விதை நிதி, இன்குபேட்டர் ஆதரவு, சந்தைப்படுத்தல் உதவி, வாங்குபவர்-விற்பனையாளர் சந்திப்புகள்.',
    'industrial infrastructure development agency.':
        'தொழில்துறை உள்கட்டமைப்பு மேம்பாட்டு முகமை.',
    'allotment of plots/sheds in industrial parks, basic infrastructure provisions.':
        'தொழில் பூங்காக்களில் மனைகள்/கொட்டகைகள் ஒதுக்கீடு, அடிப்படை உள்கட்டமைப்பு விதிகள்.',
    'business utilities & tools': 'தொழில்முறை பயன்பாடுகள் & கருவிகள்',
    'udyam classifier': 'உத்யம் வகைப்படுத்தி',
    'check msme tier': 'MSME நிலையைச் சரிபார்க்கவும்',
    'subsidy estimator': 'மானியம் மதிப்பீட்டாளர்',
    'machinery subsidies': 'இயந்திர மானியங்கள்',
    'gst calculator': 'GST கால்குலேட்டர்',
    'compute gst invoice': 'GST இன்வாய்ஸைக் கணக்கிடுக',
    'emi calculator': 'EMI கால்குலேட்டர்',
    'calculate loan emis': 'கடன் EMIகளைக் கணக்கிடுக',
    'dpiit eligibility': 'DPIIT தகுதிநிலை',
    'check startup criteria': 'ஸ்டார்ட்அப் தகுதிகளைச் சரிபார்க்கவும்',
    'valuation estimator': 'மதிப்பீடு மதிப்பீட்டாளர்',
    'seed valuation ranges': 'விதை நிலை மதிப்பீட்டு வரம்புகள்',
    'doc checklist': 'ஆவணங்கள் சரிபார்ப்பு',
    'business setup docs': 'தொழில் தொடக்க ஆவணங்கள்',
    'udyam msme classifier': 'உத்யம் MSME வகைப்படுத்தி',
    'classify your business under official government guidelines.':
        'அதிகாரப்பூர்வ அரசு வழிகாட்டுதல்களின் கீழ் உங்கள் தொழிலை வகைப்படுத்துங்கள்.',
    'investment in plant & machinery': 'ஆலை & இயந்திரங்களில் முதலீடு',
    'enter original purchase value of machinery in crores':
        'இயந்திரங்களின் அசல் கொள்முதல் மதிப்பை கோடிகளில் உள்ளிடவும்',
    'annual turnover': 'ஆண்டு விற்றுமுதல்',
    'enter total revenue/sales of last financial year in crores':
        'கடந்த நிதியாண்டின் மொத்த வருவாய்/விற்பனையை கோடிகளில் உள்ளிடவும்',
    'classification result': 'வகைப்பாட்டின் முடிவு',
    'calculate classification': 'வகைப்பாட்டைக் கணக்கிடுக',
    'micro enterprise': 'குறு நிறுவனம்',
    'small enterprise': 'சிறு நிறுவனம்',
    'medium enterprise': 'நடுத்தர நிறுவனம்',
    'large enterprise (beyond msme limits)':
        'பெரிய நிறுவனம் (MSME வரம்புகளுக்கு மேல்)',
    'limits: micro (≤1cr / ≤5cr) | small (≤10cr / ≤50cr) | medium (≤50cr / ≤250cr)':
        'வரம்புகள்: குறு (≤1கோடி / ≤5கோடி) | சிறு (≤10கோடி / ≤50கோடி) | நடுத்தரம் (≤50கோடி / ≤250கோடி)',
    'gst / tax calculator': 'GST / வரி கால்குலேட்டர்',
    'calculate cgst, sgst, and total invoice amounts.':
        'CGST, SGST மற்றும் மொத்த இன்வாய்ஸ் தொகைகளைக் கணக்கிடுங்கள்.',
    'base amount': 'அடிப்படைத் தொகை',
    'enter net value of goods or services before gst':
        'GSTக்கு முந்தைய பொருட்கள் அல்லது சேவைகளின் நிகர மதிப்பை உள்ளிடவும்',
    'gst rate (%)': 'GST விகிதம் (%)',
    'calculate tax': 'வரியைக் கணக்கிடுக',
    'please enter a valid base amount':
        'செல்லுபடியாகும் அடிப்படைத் தொகையை உள்ளிடவும்',
    'invalid input': 'செல்லுபடியற்ற உள்ளீடு',
    'please enter valid values greater than 0':
        '0 ஐ விட அதிகமான செல்லுபடியாகும் மதிப்புகளை உள்ளிடவும்',
    'base price': 'அடிப்படை விலை',
    'total invoice': 'மொத்த இன்வாய்ஸ்',
    'selected notifications marked as read':
        'தேர்ந்தெடுக்கப்பட்ட அறிவிப்புகள் படித்ததாகக் குறிக்கப்பட்டன',
    'selected notifications deleted':
        'தேர்ந்தெடுக்கப்பட்ட அறிவிப்புகள் நீக்கப்பட்டன',
    'filter options opened': 'வடிகட்டி விருப்பங்கள் திறக்கப்பட்டன',
    'all notifications marked as read':
        'அனைத்து அறிவிப்புகளும் படித்ததாகக் குறிக்கப்பட்டன',
    'all notifications deleted': 'அனைத்து அறிவிப்புகளும் நீக்கப்பட்டன',
    'retry voice': 'மீண்டும் குரலை முயற்சிக்கவும்',
    'business loan emi calculator': 'தொழில் கடன் EMI கால்குலேட்டர்',
    'calculate monthly payments for your business loan.':
        'உங்கள் தொழில் கடனுக்கான மாதாந்திர தவணைகளைக் கணக்கிடுங்கள்.',
    'loan amount': 'கடன் தொகை',
    'enter total business loan sum required':
        'தேவையான மொத்த தொழில் கடன் தொகையை உள்ளிடவும்',
    'interest rate (% p.a.)': 'வட்டி விகிதம் (% ஆண்டுக்கு)',
    'enter annual rate': 'ஆண்டு வட்டி விகிதத்தை உள்ளிடவும்',
    'tenure (months)': 'கால அளவு (மாதங்களில்)',
    'enter term in months': 'மாதங்களில் கால அளவை உள்ளிடவும்',
    'calculate emi': 'EMI கணக்கிடுக',
    'please enter valid inputs': 'செல்லுபடியாகும் உள்ளீடுகளை உள்ளிடவும்',
    'dpiit recognition checklist': 'DPIIT அங்கீகார சரிபார்ப்புப் பட்டியல்',
    'evaluate if your business qualifies as a startup under dpiit rules.':
        'DPIIT விதிகளின் கீழ் உங்கள் தொழில் ஸ்டார்ட்அப்பாக தகுதி பெறுகிறதா என்பதை மதிப்பிடுங்கள்.',
    'registered as pvt ltd / llp / partnership':
        'Pvt Ltd / LLP / பங்குதாரராகப் பதிவு செய்யப்பட்டுள்ளது',
    'must be registered in india':
        'இந்தியாவில் பதிவு செய்யப்பட்டிருக்க வேண்டும்',
    'incorporation age is under 10 years':
        'நிறுவன தொடக்கக் காலம் 10 ஆண்டுகளுக்குள் உள்ளது',
    'from incorporation date': 'நிறுவனம் தொடங்கப்பட்ட தேதியிலிருந்து',
    'annual turnover has never exceeded ₹100 cr':
        'ஆண்டு விற்றுமுதல் ₹100 கோடியை தாண்டவில்லை',
    'for any financial year': 'எந்தவொரு நிதியாண்டிற்கும்',
    'working towards innovation/scaling':
        'புத்தாக்கம்/தொழில் விரிவாக்கத்தில் செயல்படுகிறது',
    'developing new products/processes':
        'புதிய தயாரிப்புகள்/செயல்முறைகளை உருவாக்குதல்',
    'eligible for dpiit recognition': 'DPIIT அங்கீகாரத்திற்கு தகுதியானது',
    'not eligible (must fulfill all 4 criteria)':
        'தகுதியற்றது (4 விதிகளையும் பூர்த்தி செய்ய வேண்டும்)',
    'seed valuation estimator': 'விதை நிலை மதிப்பீடு கணக்கிடுபவர்',
    'calculate estimated seed stage valuation ranges based on mrr and growth.':
        'MRR மற்றும் வளர்ச்சியின் அடிப்படையில் விதை நிலை மதிப்பீட்டு வரம்பைக் கணக்கிடுங்கள்.',
    'monthly recurring revenue (mrr)': 'மாதாந்திரத் திரும்பவரும் வருவாய் (MRR)',
    'annual growth rate (%)': 'ஆண்டு வளர்ச்சி விகிதம் (%)',
    'calculate valuation': 'மதிப்பீட்டைக் கணக்கிடுக',
    'business setup document checklist': 'தொழில் தொடக்க ஆவணப் பட்டியல்',
    'essential documents for registering and operating a business in india.':
        'இந்தியாவில் ஒரு தொழிலைப் பதிவு செய்து இயக்குவதற்கான அத்தியாவசிய ஆவணங்கள்.',
    'personalized schemes matched to business profile':
        'உங்கள் தொழில் சுயவிவரத்திற்கு பொருந்தும் தனிப்பயன் திட்டங்கள்',
    'personalized schemes matched to your profile':
        'உங்கள் சுயவிவரத்திற்கு பொருந்தும் தனிப்பயன் திட்டங்கள்',
    'complete your profile or explore schemes with the search engine to get smart matching results.':
        'உங்கள் சுயவிவரத்தை பூர்த்தி செய்து அல்லது தேடுபொறி மூலம் திட்டங்களை ஆராய்ந்து பொருத்தமான முடிவுகளைப் பெறுங்கள்.',
    'instantly search our database for credit support, collateral-free business loans, and sidbi programs.':
        'கடன் உதவி, பிணையமற்ற தொழில் கடன்கள் மற்றும் SIDBI திட்டங்களுக்காக எங்கள் தரவுத்தளத்தில் உடனடி தேடல் செய்யுங்கள்.',
    'under the msmed act section 15/16, buyers must pay 3x the rbi bank rate as compound interest with monthly rests for delays exceeding 45 days.':
        'MSMED சட்டம் பிரிவு 15/16-ன் கீழ், 45 நாட்களுக்கு மேல் தாமதமாகும் செலுத்துகைகளுக்கு வாங்குபவர்கள் RBI வங்கி வீதத்தை விட 3 மடங்கு கூட்டு வட்டியை செலுத்த வேண்டும்.',
    'discover every government scheme in india':
        'இந்தியாவின் ஒவ்வொரு அரசு திட்டத்தையும் கண்டறியுங்கள்',
    'search for schemes offering cluster development, technology upgrades, and incubator grants.':
        'கிளஸ்டர் மேம்பாடு, தொழில்நுட்ப மேம்பாடு மற்றும் இன்குபேட்டர் மானியங்களை வழங்கும் திட்டங்களை தேடுங்கள்.',
    'what the user gets': 'பயனர் பெறும் நன்மைகள்',
    'interactive tools & actions': 'ஊடாடும் கருவிகள் & நடவடிக்கைகள்',
    'main features inside': 'முதன்மை அம்சங்கள்',
    'delayed payment interest calculator':
        'தாமதமான செலுத்துகை வட்டி கால்குலேட்டர்',
    'invoice amount': 'இன்வாய்ஸ் தொகை',
    'days delayed': 'தாமதமான நாட்கள்',
    'interest rate': 'வட்டி விகிதம்',
    'total claimable': 'மொத்த உரிமைக்கோரக்கூடிய தொகை',
    'search msme loans & funding': 'MSME கடன்கள் & நிதியுதவி தேடுக',
    'search schemes': 'திட்டங்களை தேடுக',
    'complete profile': 'சுயவிவரத்தை பூர்த்தி செய்க',
    'find funding options': 'நிதியுதவி விருப்பங்களைக் கண்டறியவும்',
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
    'failed to fetch location': 'இருப்பிடத்தைப் பெற முடியவில்லை',
    'natural': 'இயற்கையான ஒலி',
    'clear': 'தெளிவான ஒலி',
    'latest': 'புதியது',
    'svg map here': 'வரைபடம்',
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
