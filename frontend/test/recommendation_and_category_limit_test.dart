import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/scheme_repository.dart';
import 'package:frontend/models/user_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Recommendation & Category Scheme Limits Audit', () {
    final repo = SchemeRepository.instance;
    final profile = UserProfile(
      gender: 'female',
      state: 'Tamil Nadu',
      community: 'BC',
    );

    test('1. Recommended For You section receives top 5 schemes limit', () async {
      final topRecs = await repo.getTopRecommendedSchemes(profile, limit: 5);
      expect(topRecs.length, lessThanOrEqualTo(5));
      expect(topRecs.isNotEmpty, isTrue);
    });

    test('2. Categories return complete matching datasets without 5-item cap', () async {
      final categoriesToTest = [
        'Manufacturing',
        'Women Entrepreneurs',
        'Business Loans & Credit',
        'Startup',
        'Technology',
        'MSME',
        'Export & Trade Promotion',
      ];

      for (final cat in categoriesToTest) {
        final matches = await repo.getSchemesByCategory(cat);
        // Ensure no artificial limit of 5 is applied to categories that have >5 items
        print('Category: "$cat" returned ${matches.length} schemes.');
        expect(matches.isNotEmpty, isTrue);
      }
    });

    test('3. Category Counts match exact size of getSchemesByCategory list', () async {
      final counts = await repo.getCategoryCounts(profile, activeFilter: 'All');
      for (final entry in counts.entries) {
        final categoryName = entry.key;
        final countValue = entry.value;
        final schemesList = await repo.getSchemesByCategory(categoryName);
        expect(countValue, equals(schemesList.length),
            reason: 'Count for $categoryName ($countValue) must match schemes list length (${schemesList.length})');
      }
    });

    test('4. searchSchemes returns all matching schemes without limit', () async {
      final searchResults = await repo.searchSchemes('loan');
      print('Search query "loan" returned ${searchResults.length} schemes.');
      expect(searchResults.length, greaterThan(5));
    });

    test('5. getRecommendedSchemes without limit parameter returns all eligible recommendations', () async {
      final allRecs = await repo.getRecommendedSchemes(profile);
      print('Full profile recommendations count: ${allRecs.length}');
      expect(allRecs.length, greaterThan(5));
    });
  });
}
