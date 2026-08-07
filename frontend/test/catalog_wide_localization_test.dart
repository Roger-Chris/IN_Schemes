// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/localized_scheme.dart';
import 'package:frontend/services/mss_catalog_bundle.dart';
import 'package:frontend/services/mss_scheme_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Catalog-Wide 217 Schemes Localization Verification', () {
    late MssCatalogBundle bundle;

    setUpAll(() async {
      bundle = await MssCatalogBundle.load(overrideChecksumForTest: true);
    });

    test(
      'All catalog scheme entities (217 total) load and localize without errors',
      () {
        final schemes = bundle.schemes;
        expect(
          schemes.length,
          greaterThanOrEqualTo(200),
          reason: 'Catalog must contain 200+ schemes',
        );

        int testedCount = 0;
        int tamilNameCount = 0;
        int tamilOverviewCount = 0;
        int tamilBenefitsCount = 0;

        for (final entity in schemes) {
          testedCount++;
          final scheme = MssSchemeAdapter.toScheme(entity, bundle);
          final localized = scheme.toLocalized('ta');

          // 1. Basic Non-Null / Non-Empty Checks
          expect(
            localized.name,
            isNotEmpty,
            reason: 'Scheme name must not be empty for ID: ${entity.id}',
          );
          expect(
            localized.overview,
            isNotEmpty,
            reason: 'Scheme overview must not be empty for ID: ${entity.id}',
          );
          expect(
            localized.benefits,
            isNotEmpty,
            reason: 'Scheme benefits must not be empty for ID: ${entity.id}',
          );
          expect(
            localized.category,
            isNotEmpty,
            reason: 'Scheme category must not be empty for ID: ${entity.id}',
          );
          expect(
            localized.governmentLevel,
            isNotEmpty,
            reason:
                'Scheme governmentLevel must not be empty for ID: ${entity.id}',
          );
          expect(
            localized.state,
            isNotEmpty,
            reason: 'Scheme state must not be empty for ID: ${entity.id}',
          );
          expect(
            localized.targetBeneficiary,
            isNotEmpty,
            reason:
                'Scheme targetBeneficiary must not be empty for ID: ${entity.id}',
          );

          // 2. Collection Audits
          expect(
            localized.eligibilityCriteria,
            isNotEmpty,
            reason:
                'Eligibility criteria list must not be empty for ID: ${entity.id}',
          );
          for (final item in localized.eligibilityCriteria) {
            expect(
              item,
              isNotEmpty,
              reason:
                  'Eligibility item must not be empty in scheme ${entity.id}',
            );
          }

          expect(
            localized.applicationProcess,
            isNotEmpty,
            reason:
                'Application process list must not be empty for ID: ${entity.id}',
          );
          for (final step in localized.applicationProcess) {
            expect(
              step,
              isNotEmpty,
              reason:
                  'Application step must not be empty in scheme ${entity.id}',
            );
          }

          for (final doc in localized.documents) {
            expect(
              doc.name,
              isNotEmpty,
              reason: 'Document name must not be empty in scheme ${entity.id}',
            );
            expect(
              doc.mandatory,
              isNotEmpty,
              reason:
                  'Document mandatory flag must not be empty in scheme ${entity.id}',
            );
          }

          for (final srv in localized.requiredServices) {
            expect(
              srv.name,
              isNotEmpty,
              reason: 'Service name must not be empty in scheme ${entity.id}',
            );
            expect(
              srv.category,
              isNotEmpty,
              reason:
                  'Service category must not be empty in scheme ${entity.id}',
            );
          }

          for (final chip in localized.glanceChips) {
            expect(
              chip,
              isNotEmpty,
              reason: 'Glance chip must not be empty in scheme ${entity.id}',
            );
          }

          for (final cond in localized.mandatoryConditions) {
            expect(
              cond,
              isNotEmpty,
              reason:
                  'Mandatory condition must not be empty in scheme ${entity.id}',
            );
          }

          for (final cond in localized.optionalConditions) {
            expect(
              cond,
              isNotEmpty,
              reason:
                  'Optional condition must not be empty in scheme ${entity.id}',
            );
          }

          for (final faq in localized.faqs) {
            expect(
              faq['question'],
              isNotNull,
              reason: 'FAQ question must not be null in scheme ${entity.id}',
            );
            expect(
              faq['answer'],
              isNotNull,
              reason: 'FAQ answer must not be null in scheme ${entity.id}',
            );
          }

          // Count Tamil script matches (Unicode range \u0B80-\u0BFF)
          final tamilReg = RegExp(r'[\u0B80-\u0BFF]');
          if (tamilReg.hasMatch(localized.name)) tamilNameCount++;
          if (tamilReg.hasMatch(localized.overview)) tamilOverviewCount++;
          if (tamilReg.hasMatch(localized.benefits)) tamilBenefitsCount++;
        }

        print('\n======================================================');
        print(' CATALOG LOCALIZATION AUDIT SUMMARY ($testedCount SCHEMES)');
        print('======================================================');
        print('Total Schemes Tested: $testedCount');
        print('Schemes with Tamil Title: $tamilNameCount / $testedCount');
        print(
          'Schemes with Tamil Overview: $tamilOverviewCount / $testedCount',
        );
        print(
          'Schemes with Tamil Benefits: $tamilBenefitsCount / $testedCount',
        );
        print('======================================================\n');
      },
    );
  });
}
