import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/private_ai_knowledge_base.dart';
import 'package:frontend/services/scheme_catalog.dart';
import 'package:frontend/services/scheme_understanding_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const edgeCases = <String, String>{
    'i want to start one catering business, what are the eligibility criteria enaku adhu sollunga startup ah illa msme ah whom should i approach':
        'catering_business',
    'i want to start a beauty parlour nan enna pananum': 'beauty_parlour',
    'msme na definition enna entha government authority enga poi register pananum':
        'msme_definition',
    'msme koraigal ah solrathukku adha address panra cell edhu avanga office enga irukku nan anga enna pannalam':
        'msme_grievance',
    'msme ku ethavathu tax benefits irukka': 'msme_tax_benefits',
    'startup na kandipa incubation centre la incubate agirkanuma':
        'startup_incubation',
    'msme stock exchange la company epdi register panrathu': 'sme_exchange',
    'enaku oru idea mattum irukku enga irunthu enakku fund keadikkum':
        'idea_funding',
    'startup kum msme kum irukka difference enna': 'startup_vs_msme',
    'tamil nadu government scheme ethavathu special ah irukka central government scheme thavira':
        'tamil_nadu_schemes',
    'college students ku ethavathu schemes irukka thaniya':
        'college_student_schemes',
    'collateral free loan bank la kedaikutha illa nanga 1% collateral kudukanuma what is the rate of interest':
        'collateral_free_credit',
    'gst benefits msme ku enna irukku': 'msme_gst',
    'oru cluster epdi form panrathu': 'mse_cluster',
    'threads uh antha scheme pathi engalukku konjam sollunga': 'needs_scheme',
    'venture capital na enna': 'venture_capital',
    'full free fund startup ku epdi kedaikkum': 'free_startup_funding',
    'chennai la irukka vc fund list thara mudiyuma': 'chennai_vc_discovery',
    'tamil nadu la yaaru major players venture capitalist':
        'tamil_nadu_vc_discovery',
    'danger funding na enna': 'angel_funding',
    'entha maari business ku ellam tamil nadu government msme ku mun urimai kudukuthu':
        'tamil_nadu_priority_sectors',
  };

  test('recognizes all locked English and Tanglish edge cases', () {
    for (final edgeCase in edgeCases.entries) {
      final match = PrivateAiKnowledgeBase.lookup(edgeCase.key);
      expect(
        match?.entry.id,
        edgeCase.value,
        reason: 'Failed to understand: ${edgeCase.key}',
      );
      expect(match?.reply().displayText, isNotEmpty);
      expect(match?.reply().sourceUrl, startsWith('https://'));
    }
  });

  test('repairs common speech recognition substitutions', () {
    expect(
      PrivateAiKnowledgeBase.normalizeForUnderstanding('danger funding'),
      'angel funding',
    );
    expect(
      PrivateAiKnowledgeBase.normalizeForUnderstanding('threads scheme'),
      'needs scheme',
    );
    expect(
      PrivateAiKnowledgeBase.normalizeForUnderstanding('m s m e register'),
      'msme register',
    );
  });

  test(
    'answers questions and suggests only explicitly related schemes',
    () async {
      final catalog = await SchemeCatalog.load();
      const engine = LocalSchemeUnderstandingEngine();

      for (final edgeCase in edgeCases.entries) {
        final result = await engine.understand(
          SchemeUnderstandingRequest(
            statement: edgeCase.key,
            schemes: catalog.schemes,
            knownFacts: const {},
            questionsAsked: LocalSchemeUnderstandingEngine.maxFollowUpQuestions,
          ),
        );
        expect(result.reply?.topic, edgeCase.value);
        final allowed = PrivateAiKnowledgeBase.lookup(
          edgeCase.key,
        )!.relatedSchemeCodes.toSet();
        expect(
          result.recommendations.every(
            (item) => allowed.contains(item.scheme.schemeCode),
          ),
          isTrue,
          reason: 'Unexpected scheme for ${edgeCase.value}',
        );
      }
    },
  );
}
