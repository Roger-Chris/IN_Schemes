import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/services/assistant_session_controller.dart';
import 'package:frontend/services/scheme_understanding_engine.dart';

void main() {
  const engine = LocalSchemeUnderstandingEngine();

  const womenBusiness = Scheme(
    id: 'IN-WOMEN-BIZ',
    schemeCode: 'IN-WOMEN-BIZ',
    name: 'Women Manufacturing Enterprise Loan',
    state: 'Tamil Nadu',
    sector: 'Manufacturing MSME',
    targetBeneficiary: 'Women entrepreneurs',
    benefits: 'Business loan and capital subsidy',
    status: 'Current',
    verificationStatus: 'Verified current official source',
    sourceUrl: 'https://example.gov.in/women-business',
    eligibilityCriteria: [
      'Women entrepreneurs aged 21-45 residing in Tamil Nadu who are starting a manufacturing enterprise.',
    ],
  );
  const farmerScheme = Scheme(
    id: 'IN-FARM',
    schemeCode: 'IN-FARM',
    name: 'Small Farmer Equipment Subsidy',
    state: 'Tamil Nadu',
    sector: 'Agriculture irrigation crop equipment',
    targetBeneficiary: 'Small and marginal farmers',
    benefits: 'Subsidy for agricultural equipment',
    status: 'Current',
    verificationStatus: 'Verified official source',
    sourceUrl: 'https://example.gov.in/farmer',
    eligibilityCriteria: [
      'Farmers aged 18-60 residing in Tamil Nadu can apply.',
    ],
  );
  const scholarship = Scheme(
    id: 'IN-STUDENT',
    schemeCode: 'IN-STUDENT',
    name: 'College Student Scholarship',
    sector: 'Education',
    targetBeneficiary: 'College students',
    benefits: 'Scholarship for degree education',
    status: 'Current',
    verificationStatus: 'Verified official source',
    sourceUrl: 'https://example.gov.in/student',
    eligibilityCriteria: [
      'Current students with annual family income up to 2.5 lakh can apply.',
    ],
  );
  const historical = Scheme(
    id: 'IN-OLD',
    schemeCode: 'IN-OLD',
    name: 'Historical Women Business Grant',
    sector: 'Business entrepreneurship',
    targetBeneficiary: 'Women entrepreneurs',
    benefits: 'Business grant',
    status: 'Historical closed programme',
    verificationStatus: 'Historical/closed',
    sourceUrl: 'https://example.gov.in/old',
  );
  const schemes = [womenBusiness, farmerScheme, scholarship, historical];

  test(
    'extracts an English situation and ranks a suitable verified scheme',
    () async {
      final result = await engine.understand(
        const SchemeUnderstandingRequest(
          statement:
              'I am a 32 years old woman in Tamil Nadu starting a manufacturing business and need a loan',
          schemes: schemes,
          knownFacts: {},
          questionsAsked: 0,
        ),
      );

      expect(result.facts[EligibilityFactKey.age]?.value, '32');
      expect(result.facts[EligibilityFactKey.gender]?.value, 'Female');
      expect(result.facts[EligibilityFactKey.state]?.value, 'Tamil Nadu');
      expect(
        result.facts[EligibilityFactKey.businessSector]?.value,
        'Manufacturing',
      );
      expect(result.recommendations.first.scheme.id, 'IN-WOMEN-BIZ');
      expect(result.recommendations.first.disqualifiers, isEmpty);
    },
  );

  test('understands colloquial Tamil, Tanglish, and landholding', () async {
    final result = await engine.understand(
      const SchemeUnderstandingRequest(
        statement:
            'naan 42 vayasu Tamil Nadu vivasayi, 3 acre nilam irukku equipment maaniyam venum',
        schemes: schemes,
        knownFacts: {},
        questionsAsked: 0,
      ),
    );

    expect(result.isTamil, isTrue);
    expect(result.facts[EligibilityFactKey.age]?.value, '42');
    expect(result.facts[EligibilityFactKey.occupation]?.value, 'Farmer');
    expect(result.facts[EligibilityFactKey.landholding]?.value, '3 acres');
    expect(result.recommendations.first.scheme.id, 'IN-FARM');
  });

  test('keeps Tamil ration requests in the required food category', () async {
    const foodScheme = Scheme(
      id: 'IN-FOOD',
      schemeCode: 'IN-FOOD',
      name: 'Family Food Security Assistance',
      sector: 'Food security ration nutrition',
      targetBeneficiary: 'Families requiring ration support',
      benefits: 'Subsidized food and nutrition assistance',
      status: 'Current',
      verificationStatus: 'Verified official source',
      sourceUrl: 'https://example.gov.in/food',
    );
    final result = await engine.understand(
      const SchemeUnderstandingRequest(
        statement: 'ரேஷன் உணவு உதவி வேண்டும்',
        schemes: [foodScheme, womenBusiness],
        knownFacts: {},
        questionsAsked: 0,
      ),
    );

    expect(result.concepts, contains('food'));
    expect(result.recommendations.first.scheme.id, 'IN-FOOD');
  });

  test('negation does not turn a non-student into a student', () async {
    final result = await engine.understand(
      const SchemeUnderstandingRequest(
        statement: 'I am not a student, I need job training',
        schemes: schemes,
        knownFacts: {},
        questionsAsked: 0,
      ),
    );

    expect(result.facts[EligibilityFactKey.studentStatus]?.value, 'No');
    expect(
      result.facts[EligibilityFactKey.occupation]?.value,
      isNot('Student'),
    );
  });

  test('asks the highest-value missing eligibility question', () async {
    final result = await engine.understand(
      const SchemeUnderstandingRequest(
        statement: 'I am a college student and need a scholarship',
        schemes: schemes,
        knownFacts: {},
        questionsAsked: 0,
      ),
    );

    expect(result.recommendations.first.scheme.id, 'IN-STUDENT');
    expect(result.followUpQuestion?.factKey, EligibilityFactKey.annualIncome);
  });

  test('does not ask more than five follow-up questions', () async {
    final result = await engine.understand(
      const SchemeUnderstandingRequest(
        statement: 'I need a college scholarship',
        schemes: schemes,
        knownFacts: {},
        questionsAsked: 5,
      ),
    );

    expect(result.followUpQuestion, isNull);
    expect(result.recommendations, isNotEmpty);
  });

  test('excludes uncertain schemes unless explicitly requested', () async {
    final filtered = await engine.understand(
      const SchemeUnderstandingRequest(
        statement: 'historical women business grant',
        schemes: schemes,
        knownFacts: {},
        questionsAsked: 0,
      ),
    );
    final included = await engine.understand(
      const SchemeUnderstandingRequest(
        statement: 'historical women business grant',
        schemes: schemes,
        knownFacts: {},
        questionsAsked: 0,
        includeUncertain: true,
      ),
    );

    expect(filtered.excludedUncertainCount, 1);
    expect(
      filtered.recommendations.any((item) => item.scheme.id == 'IN-OLD'),
      isFalse,
    );
    expect(
      included.recommendations.any((item) => item.scheme.id == 'IN-OLD'),
      isTrue,
    );
  });

  test('returns no confident match for out-of-domain statements', () async {
    final result = await engine.understand(
      const SchemeUnderstandingRequest(
        statement: 'play a movie song and tell me the cricket score',
        schemes: schemes,
        knownFacts: {},
        questionsAsked: 0,
      ),
    );

    expect(result.noConfidentMatch, isTrue);
    expect(result.recommendations, isEmpty);
  });

  test('marks spoken facts that conflict with the saved profile', () async {
    final controller = AssistantSessionController(
      engine: engine,
      schemes: schemes,
      profile: UserProfile(
        profileCompleted: true,
        state: 'Tamil Nadu',
        gender: 'Female',
        employmentStatus: 'Student',
      ),
    );

    await controller.start('I live in Karnataka and need a business loan');

    final state = controller.state.facts[EligibilityFactKey.state];
    expect(state?.value, 'Karnataka');
    expect(state?.conflictingValue, 'Tamil Nadu');
    expect(state?.confirmed, isFalse);
    controller.dispose();
  });
}
