import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/scheme_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SchemeCatalog catalog;

  setUpAll(() async {
    catalog = await SchemeCatalog.load();
  });

  test('bundled catalog loads all 217 unique schemes', () {
    expect(catalog.schemes, hasLength(217));
    expect(
      catalog.schemes.map((scheme) => scheme.schemeCode).toSet(),
      hasLength(217),
    );
    expect(catalog.findById('IN001'), isNotNull);
    expect(catalog.findById('IN217'), isNotNull);
  });

  test('catalog joins scheme information, documents, services, and URLs', () {
    final scheme = catalog.findById('IN001')!;

    expect(
      scheme.name,
      'Additional Capital Subsidy for Micro Manufacturing Enterprises',
    );
    expect(scheme.subsidyPercentage, 10);
    expect(scheme.benefits, contains('₹5 lakh'));
    expect(scheme.eligibilityCriteria, isNotEmpty);
    expect(scheme.documents, isNotEmpty);
    expect(scheme.requiredServices, isNotEmpty);
    expect(Uri.parse(scheme.applicationUrl).hasScheme, isTrue);
  });

  test('missing scheme codes are recovered from matching scheme names', () {
    for (var number = 121; number <= 130; number++) {
      final code = 'IN${number.toString().padLeft(3, '0')}';
      expect(catalog.findById(code), isNotNull, reason: '$code was not joined');
    }
  });
}
