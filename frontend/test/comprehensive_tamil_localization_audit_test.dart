// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/localized_scheme.dart';
import 'package:frontend/services/mss_catalog_bundle.dart';
import 'package:frontend/services/mss_scheme_adapter.dart';
import 'package:frontend/services/centralized_translator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Comprehensive Tamil Localization Audit across ALL 217 Schemes', () {
    late MssCatalogBundle bundle;

    setUpAll(() async {
      bundle = await MssCatalogBundle.load(overrideChecksumForTest: true);
    });

    test('Audit all 217 schemes for remaining untranslated English strings', () {
      final schemes = bundle.schemes;
      final translator = CentralizedTranslator.instance;

      final Set<String> allowedAcronyms = {
        'MSME',
        'MSMES',
        'PMEGP',
        'SIDBI',
        'NSIC',
        'NABARD',
        'GST',
        'PAN',
        'AADHAAR',
        'CGTMSE',
        'MUDRA',
        'PMMY',
        'NEEDS',
        'UYEGP',
        'TIIC',
        'TNSDC',
        'TNSIM',
        'EDI',
        'EDII',
        'IIT',
        'IIM',
        'GSTIN',
        'INR',
        'FCRA',
        'TAN',
        'IEC',
        'FSSAI',
        'BIS',
        'ISO',
        'DGFT',
        'DIC',
        'KVIC',
        'KVIB',
        'Coir Board',
        'R&D',
        'IT',
        'ITES',
        'SC',
        'ST',
        'OBC',
      };

      final RegExp englishWordReg = RegExp(r'\b[A-Za-z]{2,}\b');

      final Map<String, List<String>> untranslatedByField = {};
      final Set<String> allUntranslatedEnglishWords = {};

      void checkText(String fieldName, String schemeId, String text) {
        if (text.trim().isEmpty) return;
        if (translator.isProtectedText(text)) return;

        final matches = englishWordReg.allMatches(text);
        for (final match in matches) {
          final word = match.group(0)!;
          final upperWord = word.toUpperCase();
          if (!allowedAcronyms.contains(upperWord)) {
            untranslatedByField
                .putIfAbsent(fieldName, () => [])
                .add('$word (Scheme: $schemeId)');
            allUntranslatedEnglishWords.add(word);
          }
        }
      }

      for (final entity in schemes) {
        final rawScheme = MssSchemeAdapter.toScheme(entity, bundle);
        final loc = rawScheme.toLocalized('ta');

        checkText('name', loc.id, loc.name);
        checkText('shortName', loc.id, loc.shortName);
        checkText('fullSchemeName', loc.id, loc.fullSchemeName);
        checkText('ministry', loc.id, loc.ministry);
        checkText('department', loc.id, loc.department);
        checkText('implementingAgency', loc.id, loc.implementingAgency);
        checkText('governmentLevel', loc.id, loc.governmentLevel);
        checkText('sponsoringBody', loc.id, loc.sponsoringBody);
        checkText('issuingBody', loc.id, loc.issuingBody);
        checkText('state', loc.id, loc.state);
        checkText('sector', loc.id, loc.sector);
        checkText('targetBeneficiary', loc.id, loc.targetBeneficiary);
        checkText('schemeType', loc.id, loc.schemeType);
        checkText('category', loc.id, loc.category);
        checkText('overview', loc.id, loc.overview);
        checkText('objectives', loc.id, loc.objectives);
        checkText('benefits', loc.id, loc.benefits);
        checkText('subsidyAmount', loc.id, loc.subsidyAmount);
        checkText('verificationStatus', loc.id, loc.verificationStatus);
        checkText('verificationNotes', loc.id, loc.verificationNotes);
        checkText('capitalSubsidyDetails', loc.id, loc.capitalSubsidyDetails);
        checkText(
          'interestSubventionDetails',
          loc.id,
          loc.interestSubventionDetails,
        );
        checkText('marginMoneyDetails', loc.id, loc.marginMoneyDetails);
        checkText('loanGuaranteeDetails', loc.id, loc.loanGuaranteeDetails);
        checkText('rawBenefitsDisplayText', loc.id, loc.rawBenefitsDisplayText);
        checkText('eligibilityAgeRange', loc.id, loc.eligibilityAgeRange);
        checkText('turnoverLimits', loc.id, loc.turnoverLimits);
        checkText('investmentLimits', loc.id, loc.investmentLimits);
        checkText('educationRequirements', loc.id, loc.educationRequirements);
        checkText('applicationFee', loc.id, loc.applicationFee);
        checkText('processingDurationDays', loc.id, loc.processingDurationDays);
        checkText('intakeTimelineText', loc.id, loc.intakeTimelineText);

        for (final chip in loc.glanceChips) {
          checkText('glanceChips', loc.id, chip);
        }
        for (final bType in loc.benefitTypesList) {
          checkText('benefitTypesList', loc.id, bType);
        }
        for (final sType in loc.supportTypes) {
          checkText('supportTypes', loc.id, sType);
        }
        for (final bType in loc.allowedBusinessTypes) {
          checkText('allowedBusinessTypes', loc.id, bType);
        }
        for (final cond in loc.mandatoryConditions) {
          checkText('mandatoryConditions', loc.id, cond);
        }
        for (final cond in loc.optionalConditions) {
          checkText('optionalConditions', loc.id, cond);
        }
        for (final sc in loc.specialCategories) {
          checkText('specialCategories', loc.id, sc);
        }
        for (final fin in loc.financeProductsSummary) {
          checkText('financeProductsSummary', loc.id, fin);
        }
        for (final tax in loc.taxExemptionsSummary) {
          checkText('taxExemptionsSummary', loc.id, tax);
        }
        for (final tax in loc.applicableTaxesList) {
          checkText('applicableTaxesList', loc.id, tax);
        }
        for (final kw in loc.knowledgeGuidanceList) {
          checkText('knowledgeGuidanceList', loc.id, kw);
        }
        for (final rule in loc.eligibilityCriteria) {
          checkText('eligibilityCriteria', loc.id, rule);
        }
        for (final docName in loc.requiredDocuments) {
          checkText('requiredDocuments', loc.id, docName);
        }
        for (final step in loc.applicationProcess) {
          checkText('applicationProcess', loc.id, step);
        }
        for (final doc in loc.documents) {
          checkText('documents.name', loc.id, doc.name);
          checkText('documents.mandatory', loc.id, doc.mandatory);
          checkText('documents.issuingAuthority', loc.id, doc.issuingAuthority);
          checkText('documents.description', loc.id, doc.description);
          checkText('documents.estimatedCost', loc.id, doc.estimatedCost);
          checkText('documents.remarks', loc.id, doc.remarks);
        }
        for (final srv in loc.requiredServices) {
          checkText('requiredServices.name', loc.id, srv.name);
          checkText('requiredServices.category', loc.id, srv.category);
          checkText('requiredServices.description', loc.id, srv.description);
          checkText('requiredServices.purpose', loc.id, srv.purpose);
          checkText('requiredServices.department', loc.id, srv.department);
          checkText('requiredServices.notes', loc.id, srv.notes);
        }
        for (final faq in loc.faqs) {
          checkText('faqs.question', loc.id, faq['question'] ?? '');
          checkText('faqs.answer', loc.id, faq['answer'] ?? '');
        }
      }

      print('======================================================');
      print(' UNTRANSLATED ENGLISH STRINGS AUDIT FINDINGS');
      print('======================================================');
      print(
        'Total Unique Untranslated Words Found: ${allUntranslatedEnglishWords.length}',
      );
      print(
        'Fields with Untranslated Strings: ${untranslatedByField.keys.join(', ')}',
      );
      print(
        'Sample Untranslated Words: ${allUntranslatedEnglishWords.take(50).join(', ')}',
      );
      print('======================================================');
    });
  });
}
