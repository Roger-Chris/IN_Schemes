import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/smart_assessment_bottom_sheet.dart';
import 'package:frontend/services/centralized_translator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adaptive Questionnaire Multilingual Localization Tests', () {
    final translator = CentralizedTranslator.instance;

    test('1. QuestionNode.toLocalized produces 100% Tamil node for Tamil language', () {
      const rawNode = QuestionNode(
        id: 'test_q1',
        questionText: 'What is your current level of education?',
        questionTextTa: 'உங்கள் தற்போதைய கல்வித் தகுதி என்ன?',
        options: ['Schooling (Up to 12th)', 'Undergraduate', 'Postgraduate', 'Ph.D. & Research'],
        optionsTa: ['பள்ளி கல்வி (12 ஆம் வகுப்பு வரை)', 'இளங்கலை (UG)', 'முதுகலை (PG)', 'முனைவர் பட்டம் & ஆராய்ச்சி'],
        nextId: null,
      );

      final locTa = rawNode.toLocalized('ta');
      expect(locTa.questionText, equals('உங்கள் தற்போதைய கல்வித் தகுதி என்ன?'));
      expect(locTa.options[0], equals('பள்ளி கல்வி (12 ஆம் வகுப்பு வரை)'));
      expect(locTa.options[1], equals('இளங்கலை (UG)'));
      expect(locTa.options[2], equals('முதுகலை (PG)'));
      expect(locTa.options[3], equals('முனைவர் பட்டம் & ஆராய்ச்சி'));

      final locEn = rawNode.toLocalized('en');
      expect(locEn.questionText, equals('What is your current level of education?'));
      expect(locEn.options[0], equals('Schooling (Up to 12th)'));
    });

    test('2. QuestionNode fallback to CentralizedTranslator when Tamil fields are null', () {
      const rawNode = QuestionNode(
        id: 'test_q2',
        questionText: 'Is your business legally registered?',
        options: ['Yes', 'No'],
        nextId: null,
      );

      final locTa = rawNode.toLocalized('ta');
      expect(locTa.questionText.isNotEmpty, isTrue);
      expect(locTa.options[0], equals('ஆம்'));
      expect(locTa.options[1], equals('இல்லை'));
    });

    test('3. Questionnaire UI Control buttons & labels translate properly to Tamil', () {
      expect(translator.translate('Skip to Results'), equals('முடிவுகளுக்குச் செல்'));
      expect(translator.translate('Back'), equals('பின்செல்'));
      expect(translator.translate('Next'), equals('அடுத்து'));
      expect(translator.translate('Previous'), equals('முந்தைய'));
      expect(translator.translate('Finish'), equals('முடிக்க'));
      expect(translator.translate('Done'), equals('முடிந்தது'));
    });

    test('4. Category and Ministry titles translate properly', () {
      expect(translator.translateTag('Business & MSME'), contains('தொழில்'));
      expect(translator.translateTag('Women Entrepreneurship'), contains('பெண்'));
      expect(translator.translateTag('Ministry of Finance'), contains('அமைச்சகம்'));
      expect(translator.translateTag('Agriculture'), contains('வேளாண்மை'));
      expect(translator.translateTag('Skill Development'), contains('திறன்'));
    });
  });
}
