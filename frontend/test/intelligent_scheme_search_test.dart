import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/services/intelligent_scheme_search.dart';
import 'package:frontend/services/scheme_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const farmerScheme = Scheme(
    id: 'IN-FARM',
    name: 'Farmer Crop Capital Subsidy',
    sector: 'Agriculture and irrigation',
    targetBeneficiary: 'Small and marginal farmers',
    benefits: 'Capital subsidy for crop equipment',
  );
  const studentScheme = Scheme(
    id: 'IN-STUDENT',
    name: 'Higher Education Scholarship',
    sector: 'Education',
    targetBeneficiary: 'College students',
    benefits: 'Scholarship assistance for degree studies',
  );
  const businessScheme = Scheme(
    id: 'IN-BIZ',
    name: 'Women Entrepreneur Business Loan',
    sector: 'MSME enterprise development',
    targetBeneficiary: 'Women entrepreneurs',
    benefits: 'Bank credit and business funding',
  );
  const schemes = [farmerScheme, studentScheme, businessScheme];

  test('ranks a natural English business request by meaning', () {
    final matches = IntelligentSchemeSearch.rank(
      'I need a loan to start my own business',
      schemes,
    );

    expect(matches, isNotEmpty);
    expect(matches.first.scheme.id, 'IN-BIZ');
    expect(matches.first.reasons, isNotEmpty);
  });

  test('understands Tamil-script agriculture and subsidy intent', () {
    final intent = IntelligentSchemeSearch.interpret(
      'எனக்கு விவசாய மானியம் வேணும்',
    );
    final matches = IntelligentSchemeSearch.rank(
      'எனக்கு விவசாய மானியம் வேணும்',
      schemes,
    );

    expect(intent.isTamil, isTrue);
    expect(intent.concepts, containsAll(['agriculture', 'subsidy']));
    expect(matches.first.scheme.id, 'IN-FARM');
  });

  test('understands colloquial Tanglish education requests', () {
    final intent = IntelligentSchemeSearch.interpret(
      'enakku college padippuku scholarship venum',
    );
    final matches = IntelligentSchemeSearch.rank(
      'enakku college padippuku scholarship venum',
      schemes,
    );

    expect(intent.isTamil, isTrue);
    expect(intent.concepts, contains('education'));
    expect(matches.first.scheme.id, 'IN-STUDENT');
  });

  test('understands mixed English and colloquial Tamil requests', () {
    final intent = IntelligentSchemeSearch.interpret(
      'my mother ku own business start panna loan venum',
    );
    final matches = IntelligentSchemeSearch.rank(
      'my mother ku own business start panna loan venum',
      schemes,
    );

    expect(intent.isTamil, isTrue);
    expect(intent.concepts, containsAll(['women', 'business', 'loan']));
    expect(matches.first.scheme.id, 'IN-BIZ');
  });

  test('returns no confident match for an unrelated request', () {
    final matches = IntelligentSchemeSearch.rank('play a movie song', schemes);

    expect(matches, isEmpty);
  });

  test('tolerates a one-character spelling mistake', () {
    final matches = IntelligentSchemeSearch.rank(
      'college scholrship support',
      schemes,
    );

    expect(matches, isNotEmpty);
    expect(matches.first.scheme.id, 'IN-STUDENT');
  });

  test('Tamil voice query finds relevant real catalog records', () async {
    final schemes = await SchemeRepository.instance.getAllSchemes();
    final matches = IntelligentSchemeSearch.rank(
      'விவசாயிகளுக்கு மானியம் வேண்டும்',
      schemes,
    );

    expect(matches, isNotEmpty);
    expect(
      matches.any(
        (match) =>
            '${match.scheme.name} ${match.scheme.sector} ${match.scheme.targetBeneficiary} ${match.scheme.overview} ${match.scheme.searchKeywords}'
                .toLowerCase()
                .contains(RegExp(r'farm|agri|crop|horticulture|farmer|vivasayi|வேளாண்|விவசாயி')),
      ),
      isTrue,
    );
  });
}
