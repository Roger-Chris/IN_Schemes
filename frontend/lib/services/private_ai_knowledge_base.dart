import 'package:flutter/foundation.dart';

enum PrivateAiLanguage { english, tamil, tanglish }

@immutable
class GroundedAssistantReply {
  const GroundedAssistantReply({
    required this.topic,
    required this.displayText,
    required this.spokenText,
    required this.languageTag,
    required this.sourceLabel,
    required this.sourceUrl,
    this.relatedSchemeCodes = const [],
  });

  final String topic;
  final String displayText;
  final String spokenText;
  final String languageTag;
  final String sourceLabel;
  final String sourceUrl;
  final List<String> relatedSchemeCodes;
}

@immutable
class PrivateAiKnowledgeMatch {
  const PrivateAiKnowledgeMatch(this.entry, this.language);

  final PrivateAiKnowledgeEntry entry;
  final PrivateAiLanguage language;

  List<String> get relatedSchemeCodes => entry.relatedSchemeCodes;

  GroundedAssistantReply reply() {
    final text = switch (language) {
      PrivateAiLanguage.english => entry.english,
      PrivateAiLanguage.tamil => entry.tamil,
      PrivateAiLanguage.tanglish => entry.tanglish,
    };
    return GroundedAssistantReply(
      topic: entry.id,
      displayText: text,
      spokenText: text,
      languageTag: language == PrivateAiLanguage.tamil ? 'ta-IN' : 'en-IN',
      sourceLabel: entry.sourceLabel,
      sourceUrl: entry.sourceUrl,
      relatedSchemeCodes: entry.relatedSchemeCodes,
    );
  }
}

@immutable
class PrivateAiKnowledgeEntry {
  const PrivateAiKnowledgeEntry({
    required this.id,
    required this.english,
    required this.tamil,
    required this.tanglish,
    required this.sourceLabel,
    required this.sourceUrl,
    this.relatedSchemeCodes = const [],
  });

  final String id;
  final String english;
  final String tamil;
  final String tanglish;
  final String sourceLabel;
  final String sourceUrl;
  final List<String> relatedSchemeCodes;
}

/// Curated, offline MSME and startup answers grounded in official sources.
///
/// This layer deliberately answers only narrow, reviewed topics. Unknown or
/// time-sensitive questions fall through to the scheme matcher instead of
/// being guessed by the optional small language model.
class PrivateAiKnowledgeBase {
  const PrivateAiKnowledgeBase._();

  static PrivateAiKnowledgeMatch? lookup(String statement) {
    final value = normalizeForUnderstanding(statement);
    if (value.isEmpty) return null;
    final language = _languageOf(statement, value);

    PrivateAiKnowledgeEntry? entry;
    if (_hasAny(value, ['catering', 'caterer', 'food service'])) {
      entry = _catering;
    } else if (_hasAny(value, ['beauty parlour', 'beauty salon', 'salon'])) {
      entry = _beautyParlour;
    } else if (_hasAll(value, ['msme']) &&
        _hasAny(value, [
          'complaint',
          'grievance',
          'kurai',
          'koraigal',
          'cell',
          'office address',
        ])) {
      entry = _msmeGrievance;
    } else if (_hasAll(value, ['msme']) &&
        !_hasAny(value, ['stock exchange', 'sme exchange', 'sme ipo']) &&
        _hasAny(value, [
          'definition',
          'meaning',
          'na enna',
          'register',
          'authority',
          'what is',
        ])) {
      entry = _msmeDefinition;
    } else if (_hasAll(value, ['startup', 'msme']) &&
        _hasAny(value, ['difference', 'different', 'vithiyasam'])) {
      entry = _startupVsMsme;
    } else if (_hasAny(value, [
      'sme exchange',
      'msme stock exchange',
      'sme ipo',
      'stock exchange listing',
    ])) {
      entry = _smeExchange;
    } else if (_hasAll(value, ['gst']) &&
        _hasAny(value, ['msme', 'small business'])) {
      entry = _gst;
    } else if (_hasAll(value, ['msme']) &&
        _hasAny(value, [
          'tax benefit',
          'tax benefits',
          'income tax',
          'tax exemption',
        ])) {
      entry = _taxBenefits;
    } else if (_hasAny(value, [
      'cluster form',
      'form cluster',
      'cluster epdi',
      'mse cluster',
    ])) {
      entry = _cluster;
    } else if (_hasAny(value, [
          'collateral free',
          'without collateral',
          'security free',
        ]) ||
        (_hasAll(value, ['collateral']) && _hasAll(value, ['loan']))) {
      entry = _collateralFree;
    } else if (_hasAll(value, ['startup']) &&
        _hasAny(value, [
          'incubat',
          'incubate',
          'incubated',
          'incubation centre',
        ])) {
      entry = _incubation;
    } else if (_hasAny(value, [
      'free fund',
      'full free fund',
      'free funding',
      'equity free grant',
    ])) {
      entry = _freeFunding;
    } else if (_hasAll(value, ['idea']) &&
        _hasAny(value, ['fund', 'money', 'capital'])) {
      entry = _ideaFunding;
    } else if (_hasAll(value, ['chennai']) &&
        _hasAny(value, ['vc', 'venture capital', 'investor list'])) {
      entry = _chennaiVc;
    } else if (_hasAny(value, ['tamil nadu', 'tn']) &&
        _hasAny(value, [
          'major vc',
          'venture capitalist',
          'vc fund',
          'investor list',
        ])) {
      entry = _tamilNaduVc;
    } else if (_hasAny(value, ['angel funding', 'angel investor'])) {
      entry = _angelFunding;
    } else if (_hasAny(value, [
      'venture capital na enna',
      'what is venture capital',
      'vc na enna',
      'venture capital meaning',
    ])) {
      entry = _ventureCapital;
    } else if ((_hasAll(value, ['needs']) && _hasAll(value, ['scheme'])) ||
        _hasAny(value, [
          'needs scheme',
          'new entrepreneur cum enterprise development',
        ])) {
      entry = _needs;
    } else if (_hasAny(value, ['college student', 'college students']) &&
        _hasAny(value, [
          'scheme',
          'schemes',
          'scholarship',
          'help',
          'udhavi',
        ])) {
      entry = _collegeStudents;
    } else if (_hasAny(value, ['tamil nadu', 'tn government']) &&
        _hasAny(value, [
          'special scheme',
          'state scheme',
          'central government scheme',
          'scheme thaniya',
        ])) {
      entry = _tamilNaduSchemes;
    } else if (_hasAny(value, [
          'mun urimai',
          'priority business',
          'thrust sector',
        ]) &&
        _hasAny(value, ['tamil nadu', 'tn', 'msme'])) {
      entry = _prioritySectors;
    }

    return entry == null ? null : PrivateAiKnowledgeMatch(entry, language);
  }

  static String normalizeForUnderstanding(String input) {
    var value = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\u0B80-\u0BFF]+', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    const corrections = <String, String>{
      'm s m e': 'msme',
      'micro small medium enterprise': 'msme',
      'beauty parlor': 'beauty parlour',
      'beauty parlour nan': 'beauty parlour naan',
      'danger funding': 'angel funding',
      'anjal funding': 'angel funding',
      'angel founding': 'angel funding',
      'threads scheme': 'needs scheme',
      'threads uh': 'needs',
      'needs uh scheme': 'needs scheme',
      'need scheme': 'needs scheme',
      'venture capitalist list': 'vc investor list',
      'stock market la company': 'stock exchange listing company',
      'incubation center': 'incubation centre',
    };
    for (final correction in corrections.entries) {
      value = value.replaceAll(correction.key, correction.value);
    }
    return value;
  }

  static PrivateAiLanguage _languageOf(String original, String normalized) {
    if (RegExp(r'[\u0B80-\u0BFF]').hasMatch(original)) {
      return PrivateAiLanguage.tamil;
    }
    const markers = <String>{
      'enaku',
      'enakku',
      'enna',
      'entha',
      'enga',
      'epdi',
      'irukka',
      'irukku',
      'kedaikkum',
      'kedaikutha',
      'kandipa',
      'nan',
      'naan',
      'pananum',
      'pannanum',
      'sollunga',
      'thara',
      'mudiyuma',
      'ku',
      'la',
    };
    final tokens = normalized.split(' ').toSet();
    return tokens.any(markers.contains)
        ? PrivateAiLanguage.tanglish
        : PrivateAiLanguage.english;
  }

  static bool _hasAll(String value, List<String> phrases) =>
      phrases.every((phrase) => _containsPhrase(value, phrase));

  static bool _hasAny(String value, List<String> phrases) =>
      phrases.any((phrase) => _containsPhrase(value, phrase));

  static bool _containsPhrase(String value, String phrase) =>
      ' $value '.contains(' $phrase ');

  static const _catering = PrivateAiKnowledgeEntry(
    id: 'catering_business',
    english:
        'A normal catering unit is usually a service MSME, not automatically a DPIIT startup. Prepare a project report, choose the legal entity, obtain FSSAI and local trade permissions, then use the official Udyam portal. Start with your District Industries Centre; UYEGP, PMEGP, MUDRA or NEEDS may fit depending on project cost and your profile.',
    tamil:
        'சாதாரண கேட்டரிங் நிறுவனம் பொதுவாக சேவை MSME; அது தானாக DPIIT ஸ்டார்ட்அப் ஆகாது. திட்ட அறிக்கை தயாரித்து, நிறுவன வடிவத்தைத் தேர்வு செய்து, FSSAI மற்றும் உள்ளூர் வணிக அனுமதிகளைப் பெற்று, அதிகாரப்பூர்வ Udyam தளத்தில் பதிவு செய்யுங்கள். முதலில் மாவட்ட தொழில் மையத்தை அணுகுங்கள்; திட்டச் செலவு மற்றும் உங்கள் விவரத்தின்படி UYEGP, PMEGP, MUDRA அல்லது NEEDS பொருந்தலாம்.',
    tanglish:
        'Normal catering unit usually service MSME; automatic-ah DPIIT startup illa. Project report ready panni, entity type choose panni, FSSAI/local trade permission vangittu official Udyam portal-la register pannunga. First District Industries Centre-a approach pannunga; project cost/profile poruthu UYEGP, PMEGP, MUDRA illa NEEDS suit aagalam.',
    sourceLabel: 'Tamil Nadu MSME portal',
    sourceUrl: 'https://msmeonline.tn.gov.in/',
    relatedSchemeCodes: ['IN200', 'IN130', 'IN128', 'IN115'],
  );

  static const _beautyParlour = PrivateAiKnowledgeEntry(
    id: 'beauty_parlour',
    english:
        'A beauty parlour is normally a service micro-enterprise, not automatically a startup. Prepare costs, training proof where applicable, premises and local-body permissions, then register through Udyam. Approach the District Industries Centre and a bank; UYEGP, PMEGP and MUDRA are the main catalog options, subject to current eligibility.',
    tamil:
        'அழகு நிலையம் பொதுவாக சேவை குறு நிறுவனம்; அது தானாக ஸ்டார்ட்அப் ஆகாது. செலவுத் திட்டம், தேவையான பயிற்சி சான்று, இடம் மற்றும் உள்ளாட்சி அனுமதிகளைத் தயாரித்து Udyam பதிவு செய்யுங்கள். மாவட்ட தொழில் மையத்தையும் வங்கியையும் அணுகுங்கள்; தற்போதைய தகுதியைப் பொறுத்து UYEGP, PMEGP மற்றும் MUDRA முக்கிய வாய்ப்புகள்.',
    tanglish:
        'Beauty parlour usually service micro enterprise; automatic-ah startup illa. Cost plan, applicable training proof, premises/local-body permission ready panni Udyam register pannunga. DIC-um bank-um approach pannunga; current eligibility poruthu UYEGP, PMEGP, MUDRA main options.',
    sourceLabel: 'Tamil Nadu MSME portal',
    sourceUrl: 'https://msmeonline.tn.gov.in/',
    relatedSchemeCodes: ['IN200', 'IN130', 'IN128'],
  );

  static const _msmeDefinition = PrivateAiKnowledgeEntry(
    id: 'msme_definition',
    english:
        'From 1 April 2025, micro means investment up to ₹2.5 crore and turnover up to ₹10 crore; small is up to ₹25 crore and ₹100 crore; medium is up to ₹125 crore and ₹500 crore. Registration is free on the Government of India Udyam portal. DIC and CHAMPIONS control rooms can assist; private agents are not the registration authority.',
    tamil:
        '1 ஏப்ரல் 2025 முதல், குறு நிறுவனம்: முதலீடு ₹2.5 கோடி வரை மற்றும் வருவாய் ₹10 கோடி வரை; சிறு நிறுவனம்: ₹25 கோடி மற்றும் ₹100 கோடி வரை; நடுத்தர நிறுவனம்: ₹125 கோடி மற்றும் ₹500 கோடி வரை. பதிவு இந்திய அரசின் Udyam தளத்தில் இலவசம். DIC அல்லது CHAMPIONS உதவலாம்; தனியார் முகவர்கள் பதிவு அதிகாரம் அல்ல.',
    tanglish:
        '1 April 2025-lendhu micro-na investment ₹2.5 crore varai, turnover ₹10 crore varai; small ₹25/₹100 crore; medium ₹125/₹500 crore. Government Udyam portal-la registration free. DIC illa CHAMPIONS help pannuvanga; private agent official registration authority illa.',
    sourceLabel: 'Official Udyam Registration',
    sourceUrl: 'https://udyamregistration.gov.in/Important.aspx',
  );

  static const _msmeGrievance = PrivateAiKnowledgeEntry(
    id: 'msme_grievance',
    english:
        'Use the MSME CHAMPIONS portal for grievance redressal and guidance. For Udyam or local facilitation in Chennai, MSME-DFO is at 65/1 GST Road, Guindy, Chennai 600032; you can also approach your District Industries Centre. For delayed payments, use MSME Samadhaan/MSEFC instead.',
    tamil:
        'MSME குறைகள் மற்றும் வழிகாட்டுதலுக்கு CHAMPIONS தளத்தைப் பயன்படுத்துங்கள். Udyam அல்லது சென்னை உதவிக்காக MSME-DFO, 65/1 GST Road, Guindy, Chennai 600032-ஐ அல்லது உங்கள் மாவட்ட தொழில் மையத்தை அணுகலாம். தாமதமான பணப்பரிவர்த்தனைக்கு MSME Samadhaan/MSEFC பயன்படுத்த வேண்டும்.',
    tanglish:
        'MSME grievance/guidance-ku CHAMPIONS portal use pannunga. Udyam illa Chennai local help-ku MSME-DFO, 65/1 GST Road, Guindy, Chennai 600032, illa unga DIC-a approach pannalam. Delayed payment issue-na MSME Samadhaan/MSEFC use pannanum.',
    sourceLabel: 'MSME CHAMPIONS',
    sourceUrl:
        'https://ramp.msme.gov.in/ramp/RAMP-initiative/champions-grievance/champions-grievance',
  );

  static const _taxBenefits = PrivateAiKnowledgeEntry(
    id: 'msme_tax_benefits',
    english:
        'Udyam registration does not create a blanket income-tax exemption. Tax treatment depends on entity type, turnover, activity and the current tax law; DPIIT startup exemptions have separate recognition and approval conditions. Use Udyam for MSME benefits, but verify any tax claim with the Income Tax portal or a qualified tax professional.',
    tamil:
        'Udyam பதிவு செய்ததனால் அனைத்து MSME-களுக்கும் பொதுவான வருமானவரி விலக்கு கிடையாது. வரி சலுகை நிறுவன வடிவம், வருவாய், செயல்பாடு மற்றும் தற்போதைய சட்டத்தைப் பொறுத்தது; DPIIT ஸ்டார்ட்அப் வரிச்சலுகைக்கு தனி நிபந்தனைகள் உள்ளன. எந்த வரிக் கூற்றையும் வருமானவரி தளம் அல்லது தகுதியான வரி நிபுணரிடம் சரிபார்க்கவும்.',
    tanglish:
        'Udyam register pannina udane ella MSME-kum blanket income-tax exemption kedaiyathu. Entity type, turnover, activity, current law poruthu tax treatment maarum; DPIIT startup exemption-ku separate conditions irukku. Tax claim-a Income Tax portal illa qualified tax professional kitta verify pannunga.',
    sourceLabel: 'Startup India recognition and benefits',
    sourceUrl:
        'https://www.startupindia.gov.in/content/sih/en/startup-scheme.html',
  );

  static const _incubation = PrivateAiKnowledgeEntry(
    id: 'startup_incubation',
    english:
        'No. DPIIT startup recognition does not require a company to be incubated. Some funding programmes route selection or money through approved incubators; for example, the Startup India Seed Fund has no mandatory physical incubation, but selected incubators evaluate and disburse support.',
    tamil:
        'இல்லை. DPIIT ஸ்டார்ட்அப் அங்கீகாரத்திற்கு கட்டாயமாக incubation centre-ல் இருக்க வேண்டியதில்லை. சில நிதித் திட்டங்கள் அங்கீகரிக்கப்பட்ட incubator வழியாக தேர்வு மற்றும் நிதி வழங்கும்; Startup India Seed Fund-ல் physical incubation கட்டாயமில்லை, ஆனால் incubator தான் மதிப்பீடு செய்து நிதி வழங்கும்.',
    tanglish:
        'Illa. DPIIT startup recognition-ku incubation centre-la incubate aagirukkanum-nu compulsory illa. Aana sila funding programme approved incubator moolama select/disburse pannum; Startup India Seed Fund-la physical incubation mandatory illa, but incubator evaluate panni fund release pannum.',
    sourceLabel: 'Startup India Seed Fund',
    sourceUrl: 'https://seedfund.startupindia.gov.in/',
    relatedSchemeCodes: ['IN170'],
  );

  static const _smeExchange = PrivateAiKnowledgeEntry(
    id: 'sme_exchange',
    english:
        'An MSME does not simply register itself on a stock exchange. The issuer must be an Indian company and undertake an SME IPO through a SEBI-registered merchant banker, with due diligence, offer documents, underwriting, market-making and exchange eligibility checks. Start with the current NSE Emerge or BSE SME criteria and appoint a qualified merchant banker.',
    tamil:
        'MSME நிறுவனம் நேரடியாக பங்குச் சந்தையில் சாதாரண பதிவு செய்ய முடியாது. இந்தியாவில் பதிவு செய்யப்பட்ட company, SEBI பதிவு பெற்ற merchant banker வழியாக SME IPO, due diligence, offer document, underwriting, market-making மற்றும் exchange தகுதி செயல்முறைகளை நிறைவேற்ற வேண்டும். தற்போதைய NSE Emerge அல்லது BSE SME நிபந்தனைகளைப் பார்த்து merchant banker-ஐ அணுகுங்கள்.',
    tanglish:
        'MSME direct-ah stock exchange-la simple register panna mudiyathu. Indian company-ah irundhu SEBI-registered merchant banker moolama SME IPO, due diligence, offer document, underwriting, market-making, exchange eligibility complete pannanum. Current NSE Emerge/BSE SME criteria check panni merchant banker-a approach pannunga.',
    sourceLabel: 'NSE Emerge eligibility',
    sourceUrl:
        'https://www.nseindia.com/static/companies-listing/raising-capital-public-issues-emerge-eligibility-criteria',
  );

  static const _ideaFunding = PrivateAiKnowledgeEntry(
    id: 'idea_funding',
    english:
        'An idea alone rarely receives automatic funding. First document the problem, customer, solution, validation plan, team and budget; then approach StartupTN incubators for mentoring and current calls. Grants are competitive, loans must be repaid, and angel/VC money normally takes equity. Seed-fund availability must be checked because calls can close.',
    tamil:
        'ஒரு யோசனை மட்டும் இருந்தால் தானாக நிதி கிடைப்பது அரிது. பிரச்சினை, வாடிக்கையாளர், தீர்வு, சரிபார்ப்பு திட்டம், குழு மற்றும் செலவுத் திட்டத்தைத் தயாரித்து StartupTN incubator-ஐ அணுகுங்கள். மானியம் போட்டித் தேர்வு; கடன் திருப்பிச் செலுத்த வேண்டும்; angel/VC நிதிக்கு பொதுவாக equity கொடுக்க வேண்டும். விண்ணப்ப காலம் மாறுவதால் தற்போதைய அறிவிப்பைச் சரிபார்க்கவும்.',
    tanglish:
        'Idea mattum irundha automatic funding usually kedaikathu. Problem, customer, solution, validation plan, team, budget ready panni StartupTN incubator-a approach pannunga. Grant competitive; loan repay pannanum; angel/VC money-ku usually equity kudukkanum. Calls close aagalam, so current availability check pannunga.',
    sourceLabel: 'StartupTN incubator ecosystem',
    sourceUrl: 'https://catalyst.startuptn.in/',
    relatedSchemeCodes: ['IN170'],
  );

  static const _startupVsMsme = PrivateAiKnowledgeEntry(
    id: 'startup_vs_msme',
    english:
        'MSME classification is based mainly on investment and turnover and is registered through Udyam. Startup recognition is based on entity age, legal form, innovation/scalability and turnover rules under DPIIT. A business can qualify as both, one, or neither; a normal local service business is usually an MSME but not automatically a startup.',
    tamil:
        'MSME வகைப்பாடு முக்கியமாக முதலீடு மற்றும் வருவாயை அடிப்படையாகக் கொண்டு Udyam வழியாக பதிவு செய்யப்படுகிறது. ஸ்டார்ட்அப் அங்கீகாரம் நிறுவன வயது, சட்ட வடிவம், புதுமை/வளர்ச்சித் திறன் மற்றும் DPIIT விதிகளை அடிப்படையாகக் கொண்டது. ஒரு நிறுவனம் இரண்டாகவும், ஒன்றாகவும் அல்லது எதுவுமில்லாமலும் இருக்கலாம்.',
    tanglish:
        'MSME classification mainly investment/turnover base; Udyam-la register pannuvanga. Startup recognition entity age, legal form, innovation/scalability, DPIIT turnover rules base. Oru business rendu category-layum irukkalam, onnu mattum irukkalam; normal local service business usually MSME, automatic startup illa.',
    sourceLabel: 'Startup India eligibility',
    sourceUrl:
        'https://www.startupindia.gov.in/content/sih/en/startup-scheme.html',
  );

  static const _tamilNaduSchemes = PrivateAiKnowledgeEntry(
    id: 'tamil_nadu_schemes',
    english:
        'Yes. Tamil Nadu has state-specific options including NEEDS, UYEGP, Annal Ambedkar Business Champions Scheme and manufacturing capital subsidies, besides central schemes. The correct choice depends on project type, cost, age, community, education and whether the unit is manufacturing, trading or service.',
    tamil:
        'ஆம். மத்திய திட்டங்களுக்கு கூடுதலாக தமிழ்நாட்டில் NEEDS, UYEGP, அண்ணல் அம்பேத்கர் தொழில் முன்னோடிகள் திட்டம் மற்றும் உற்பத்தி மூலதன மானியங்கள் உள்ளன. சரியான தேர்வு திட்ட வகை, செலவு, வயது, சமூகப் பிரிவு, கல்வி மற்றும் நிறுவனம் உற்பத்தி/வணிகம்/சேவை என்பதைக் கொண்டே தீர்மானிக்கப்படும்.',
    tanglish:
        'Aama. Central schemes thavira Tamil Nadu-ku NEEDS, UYEGP, Annal Ambedkar Business Champions Scheme, manufacturing capital subsidy madhiri state options irukku. Correct choice project type, cost, age, community, education, manufacturing/trading/service-nu poruthu decide aagum.',
    sourceLabel: 'Tamil Nadu MSME schemes',
    sourceUrl: 'https://msmeonline.tn.gov.in/',
    relatedSchemeCodes: ['IN115', 'IN200', 'IN008', 'IN001'],
  );

  static const _collegeStudents = PrivateAiKnowledgeEntry(
    id: 'college_student_schemes',
    english:
        'Yes. The catalog includes Pudhumai Penn, Tamil Puthalvan and Naan Mudhalvan, along with other education support. Eligibility differs by gender, prior school type, course and current government rules, so open each result and confirm the official criteria before applying.',
    tamil:
        'ஆம். பட்டியலில் புதுமைப் பெண், தமிழ் புதல்வன் மற்றும் நான் முதல்வன் உள்ளிட்ட கல்வி ஆதரவு திட்டங்கள் உள்ளன. பாலினம், முன்பு படித்த பள்ளி வகை, பாடநெறி மற்றும் தற்போதைய அரசு விதிகளின்படி தகுதி மாறும்; விண்ணப்பிக்கும் முன் ஒவ்வொரு திட்டத்தின் அதிகாரப்பூர்வ தகுதியையும் சரிபார்க்கவும்.',
    tanglish:
        'Aama. Catalog-la Pudhumai Penn, Tamil Puthalvan, Naan Mudhalvan plus vera education support irukku. Gender, previous school type, course, current government rule poruthu eligibility maarum; apply panna munadi official criteria check pannunga.',
    sourceLabel: 'Tamil Nadu official scheme catalog',
    sourceUrl: 'https://www.tn.gov.in/scheme',
    relatedSchemeCodes: ['IN098', 'IN185', 'IN107'],
  );

  static const _collateralFree = PrivateAiKnowledgeEntry(
    id: 'collateral_free_credit',
    english:
        'Collateral-free credit is possible but not automatic. Ask the eligible bank or lender whether the proposal can be covered under CGTMSE; there is no general rule requiring “1% collateral.” The lender decides sanction and interest under its policy/RBI rules, while guarantee or service fees are separate—request the written rate, APR, fees and repayment schedule.',
    tamil:
        'அடமானமில்லா கடன் கிடைக்கலாம்; ஆனால் அது தானாக உறுதி செய்யப்படாது. உங்கள் திட்டத்தை CGTMSE உத்தரவாதத்தின் கீழ் வங்கி பரிசீலிக்குமா என்று கேளுங்கள்; “1% collateral” என்ற பொதுவான விதி இல்லை. வட்டி மற்றும் அனுமதியை வங்கி தனது கொள்கை/RBI விதிப்படி தீர்மானிக்கும்; எழுத்துப்பூர்வ வட்டி, APR, கட்டணம் மற்றும் திருப்பிச் செலுத்தும் அட்டவணையைப் பெறுங்கள்.',
    tanglish:
        'Collateral-free loan possible, aana automatic guarantee illa. Proposal-a CGTMSE cover-la consider pannuveengala-nu eligible bank kitta kelunga; general-ah “1% collateral” rule illa. Sanction/interest lender policy and RBI rules poruthu; written rate, APR, fees, repayment schedule vangunga.',
    sourceLabel: 'CGTMSE official portal',
    sourceUrl: 'https://www.cgtmse.in/',
    relatedSchemeCodes: ['IN038', 'IN128'],
  );

  static const _gst = PrivateAiKnowledgeEntry(
    id: 'msme_gst',
    english:
        'There is no blanket GST exemption merely because a business is an MSME. Registration threshold, compulsory-registration cases, composition eligibility, rates and input-tax-credit rules depend on turnover and activity. Catering and beauty services can have different GST treatment, so check the current GST portal/CBIC guidance or a qualified GST professional before choosing a scheme.',
    tamil:
        'MSME என்பதற்காக மட்டும் பொதுவான GST விலக்கு கிடையாது. பதிவு வரம்பு, கட்டாய பதிவு, composition தகுதி, விகிதம் மற்றும் input tax credit விதிகள் வருவாய் மற்றும் செயல்பாட்டைப் பொறுத்தது. கேட்டரிங் மற்றும் அழகு சேவைகளுக்கு விதிகள் வேறுபடலாம்; தற்போதைய GST/CBIC வழிகாட்டுதலை அல்லது தகுதியான GST நிபுணரை அணுகுங்கள்.',
    tanglish:
        'MSME-nu mattum blanket GST exemption illa. Registration threshold, compulsory cases, composition eligibility, rate, ITC ellam turnover/activity poruthu. Catering and beauty service treatment different-a irukkalam; current GST/CBIC guidance illa qualified GST professional kitta check pannunga.',
    sourceLabel: 'CBIC GST FAQs',
    sourceUrl: 'https://cbic-gst.gov.in/faq.html',
  );

  static const _cluster = PrivateAiKnowledgeEntry(
    id: 'mse_cluster',
    english:
        'Begin with a group of nearby or value-chain-linked micro/small enterprises sharing products, facilities or problems. Contact the DIC, State agency or MSME-DFO for a diagnostic study and DPR. For a Common Facility Centre, the participating units generally form a dedicated SPV—typically a Section 8 company—and apply through the MSE-CDP process.',
    tamil:
        'ஒரே பகுதி அல்லது value chain-ல் இருந்து ஒரே மாதிரி தயாரிப்பு, வசதி அல்லது பிரச்சினை கொண்ட குறு/சிறு நிறுவனக் குழுவை முதலில் உருவாக்குங்கள். Diagnostic study மற்றும் DPR-க்காக DIC, மாநில நிறுவனம் அல்லது MSME-DFO-வை அணுகுங்கள். Common Facility Centre-க்கு பொதுவாக உறுப்பினர்கள் தனி SPV, வழக்கமாக Section 8 company, அமைத்து MSE-CDP வழியாக விண்ணப்பிக்க வேண்டும்.',
    tanglish:
        'Same area/value chain-la similar product, facility illa problem share panra micro/small units group-a first form pannunga. Diagnostic study/DPR-ku DIC, State agency illa MSME-DFO approach pannunga. Common Facility Centre-ku members usually separate SPV—generally Section 8 company—form panni MSE-CDP process-la apply pannuvanga.',
    sourceLabel: 'MSE Cluster Development Programme',
    sourceUrl: 'https://my.msme.gov.in/mymsme/reg/COM_ClusterForm.aspx',
    relatedSchemeCodes: ['IN092'],
  );

  static const _needs = PrivateAiKnowledgeEntry(
    id: 'needs_scheme',
    english:
        'NEEDS is Tamil Nadu’s New Entrepreneur-cum-Enterprise Development Scheme for first-generation entrepreneurs starting new manufacturing or service ventures. The official portal currently describes project cost above ₹10 lakh and up to ₹5 crore, with training, business-plan support and bank linkage. Apply through the Tamil Nadu MSME portal and work with your District Industries Centre; final eligibility must be checked on the current portal.',
    tamil:
        'NEEDS என்பது புதிய உற்பத்தி அல்லது சேவை நிறுவனத்தைத் தொடங்கும் முதல் தலைமுறை தொழில்முனைவோருக்கான தமிழ்நாடு திட்டம். அதிகாரப்பூர்வ தளம் தற்போது ₹10 லட்சத்திற்கு மேல் ₹5 கோடி வரை திட்டச் செலவு, பயிற்சி, business plan உதவி மற்றும் வங்கி இணைப்பை குறிப்பிடுகிறது. தமிழ்நாடு MSME தளத்தில் விண்ணப்பித்து மாவட்ட தொழில் மையத்தை அணுகுங்கள்; இறுதி தகுதியை தற்போதைய தளத்தில் சரிபார்க்கவும்.',
    tanglish:
        'NEEDS-na first-generation entrepreneur new manufacturing/service venture start panna Tamil Nadu scheme. Official portal current-ah project cost ₹10 lakh-ku mela ₹5 crore varai, training, business-plan support, bank linkage-nu solluthu. TN MSME portal-la apply panni DIC-oda work pannunga; final eligibility current portal-la verify pannanum.',
    sourceLabel: 'Tamil Nadu NEEDS',
    sourceUrl: 'https://msmeonline.tn.gov.in/',
    relatedSchemeCodes: ['IN115'],
  );

  static const _ventureCapital = PrivateAiKnowledgeEntry(
    id: 'venture_capital',
    english:
        'Venture capital is equity investment in a company expected to grow rapidly. It is not a grant or normal bank loan: the investor receives ownership, conducts due diligence, may seek governance rights and expects an eventual exit. It usually fits scalable startups better than ordinary small local businesses.',
    tamil:
        'Venture capital என்பது வேகமாக வளரக்கூடிய நிறுவனத்தில் செய்யப்படும் equity முதலீடு. இது மானியம் அல்லது சாதாரண வங்கிக் கடன் அல்ல; முதலீட்டாளர் உரிமைப் பங்கைப் பெறுவார், due diligence செய்வார், நிர்வாக உரிமைகள் கேட்கலாம், பின்னர் exit எதிர்பார்ப்பார். சாதாரண உள்ளூர் சிறு தொழிலை விட வளர்ச்சித் திறன் கொண்ட startup-க்கு இது பொருத்தமானது.',
    tanglish:
        'Venture capital-na fast growth expect panra company-la equity investment. Idhu grant illa normal bank loan illa; investor ownership share eduppanga, due diligence pannuvanga, governance rights/exit expect pannuvanga. Ordinary local small business vida scalable startup-ku usually better fit.',
    sourceLabel: 'Startup India Investor Connect',
    sourceUrl: 'https://www.startupindia.gov.in/',
  );

  static const _freeFunding = PrivateAiKnowledgeEntry(
    id: 'free_startup_funding',
    english:
        'There is no universal, fully free startup fund. A grant may be equity-free but is competitive, milestone-based and restricted to approved uses; a loan must be repaid, and angel/VC funding exchanges money for ownership. Use StartupTN and Startup India to check open calls, and never pay an intermediary who promises guaranteed government funding.',
    tamil:
        'அனைத்து startup-களுக்கும் முழுமையாக இலவச நிதி என்ற ஒன்று இல்லை. மானியம் equity-free ஆக இருக்கலாம்; ஆனால் அது போட்டித் தேர்வு, milestone மற்றும் அனுமதிக்கப்பட்ட செலவுகளுக்கு உட்பட்டது. கடன் திருப்பிச் செலுத்த வேண்டும்; angel/VC நிதிக்கு உரிமைப் பங்கு கொடுக்க வேண்டும். StartupTN மற்றும் Startup India-வில் திறந்த அறிவிப்பைச் சரிபார்க்கவும்; உறுதி செய்யப்பட்ட அரசு நிதி என்று கூறும் இடைத்தரகருக்கு பணம் கொடுக்க வேண்டாம்.',
    tanglish:
        'Ella startup-kum universal full-free fund kedaiyathu. Grant equity-free-a irukkalam, aana competitive, milestone-based, approved use-ku mattum. Loan repay pannanum; angel/VC funding-ku ownership share pogum. StartupTN/Startup India open calls check pannunga; guaranteed government fund-nu sollra intermediary-ku money kudukkadheenga.',
    sourceLabel: 'Startup India Seed Fund FAQs',
    sourceUrl: 'https://seedfund.startupindia.gov.in/faq',
    relatedSchemeCodes: ['IN170'],
  );

  static const _chennaiVc = PrivateAiKnowledgeEntry(
    id: 'chennai_vc_discovery',
    english:
        'A static VC list becomes outdated quickly, so this offline assistant should not claim an exhaustive “current” list. Use StartupTN/Startup India investor-connect channels and verify each fund’s sector, stage, cheque size, SEBI registration where applicable and official domain. StartupTN’s Chennai office and incubator network can direct you to active ecosystem contacts.',
    tamil:
        'VC பட்டியல் விரைவாக மாறுவதால் இந்த offline assistant தற்போதைய முழுப் பட்டியல் என்று கூறாது. StartupTN/Startup India investor-connect வழிகளைப் பயன்படுத்தி ஒவ்வொரு fund-ன் sector, stage, cheque size, தேவையான SEBI பதிவு மற்றும் அதிகாரப்பூர்வ இணையதளத்தைச் சரிபார்க்கவும். StartupTN சென்னை அலுவலகம் மற்றும் incubator network செயலில் உள்ள தொடர்புகளுக்கு வழிகாட்டும்.',
    tanglish:
        'VC list romba fast-ah change aagum; offline assistant exhaustive current list-nu claim panna koodathu. StartupTN/Startup India investor-connect use panni each fund sector, stage, cheque size, applicable SEBI registration, official domain verify pannunga. StartupTN Chennai office/incubator network active contacts-ku direct pannum.',
    sourceLabel: 'StartupTN Catalyst',
    sourceUrl: 'https://catalyst.startuptn.in/',
  );

  static const _tamilNaduVc = PrivateAiKnowledgeEntry(
    id: 'tamil_nadu_vc_discovery',
    english:
        'Investor activity changes frequently, so “major players” must be looked up live rather than frozen into the app. Start with StartupTN’s official ecosystem and Startup India Investor Connect, then filter by sector and stage. Verify the fund’s official website, team, portfolio, investment terms and regulatory status before sharing documents.',
    tamil:
        'முக்கிய VC நிறுவனங்கள் காலத்துக்கு ஏற்ப மாறுவதால், பட்டியலை app-ல் நிலையாக வைப்பது பாதுகாப்பானது அல்ல. StartupTN அதிகாரப்பூர்வ ecosystem மற்றும் Startup India Investor Connect-ல் தொடங்கி sector மற்றும் stage அடிப்படையில் தேர்வு செய்யுங்கள். ஆவணங்களை பகிரும் முன் fund-ன் அதிகாரப்பூர்வ தளம், குழு, portfolio, முதலீட்டு நிபந்தனை மற்றும் regulatory status-ஐ சரிபார்க்கவும்.',
    tanglish:
        'Major VC players frequent-ah change aagum, so frozen list safe illa. StartupTN official ecosystem/Startup India Investor Connect-la start panni sector-stage filter pannunga. Documents share panna munadi official website, team, portfolio, terms, regulatory status verify pannunga.',
    sourceLabel: 'StartupTN',
    sourceUrl: 'https://startuptn.in/',
  );

  static const _angelFunding = PrivateAiKnowledgeEntry(
    id: 'angel_funding',
    english:
        'Angel funding is early-stage money invested by an individual or angel network, usually in exchange for equity or a convertible instrument. It is not “danger funding,” a grant, or guaranteed money. Expect pitching, due diligence, valuation and ownership dilution; verify the investor before sharing sensitive information.',
    tamil:
        'Angel funding என்பது ஆரம்பகட்டத்தில் தனிநபர் அல்லது angel network, equity அல்லது convertible instrumentக்கு மாற்றாக வழங்கும் முதலீடு. இது மானியம் அல்லது உறுதி செய்யப்பட்ட பணம் அல்ல. Pitch, due diligence, valuation மற்றும் ownership dilution இருக்கும்; ரகசிய தகவலைப் பகிரும் முன் முதலீட்டாளரைச் சரிபார்க்கவும்.',
    tanglish:
        'Angel funding-na early-stage-la individual/angel network equity illa convertible instrument-ku money invest pannradhu. Idhu “danger funding” illa, grant illa, guaranteed money-um illa. Pitch, due diligence, valuation, ownership dilution irukkum; sensitive info share panna munadi investor-a verify pannunga.',
    sourceLabel: 'Startup India Investor Connect',
    sourceUrl: 'https://www.startupindia.gov.in/',
  );

  static const _prioritySectors = PrivateAiKnowledgeEntry(
    id: 'tamil_nadu_priority_sectors',
    english:
        'Tamil Nadu’s capital-subsidy priority is not for every MSME activity. The official portal covers new micro manufacturing units statewide and specified small/medium manufacturing thrust sectors, with additional support for categories such as women, SC/ST, differently-abled and transgender entrepreneurs. Service units such as catering or beauty parlours are excluded from that manufacturing capital subsidy, but may fit UYEGP, PMEGP or NEEDS.',
    tamil:
        'தமிழ்நாட்டின் மூலதன மானிய முன்னுரிமை அனைத்து MSME செயல்களுக்கும் இல்லை. புதிய குறு உற்பத்தி நிறுவனங்கள் மற்றும் குறிப்பிட்ட சிறு/நடுத்தர உற்பத்தி thrust sectors தகுதி பெறலாம்; மகளிர், SC/ST, மாற்றுத் திறனாளி மற்றும் திருநங்கை தொழில்முனைவோருக்கு கூடுதல் ஆதரவு உள்ளது. கேட்டரிங் அல்லது அழகு நிலையம் போன்ற சேவை நிறுவனங்கள் அந்த உற்பத்தி மானியத்தில் இல்லை; ஆனால் UYEGP, PMEGP அல்லது NEEDS பொருந்தலாம்.',
    tanglish:
        'Tamil Nadu capital-subsidy priority ella MSME activity-kum illa. New micro manufacturing statewide-um specified small/medium manufacturing thrust sectors-um eligible aagalam; women, SC/ST, differently-abled, transgender entrepreneurs-ku additional support irukku. Catering/beauty parlour service units manufacturing subsidy-la illa, aana UYEGP, PMEGP illa NEEDS fit aagalam.',
    sourceLabel: 'Tamil Nadu capital subsidy',
    sourceUrl: 'https://www.msmeonline.tn.gov.in/incentives/html_cye_CS.php',
    relatedSchemeCodes: ['IN001', 'IN200', 'IN130', 'IN115'],
  );
}
