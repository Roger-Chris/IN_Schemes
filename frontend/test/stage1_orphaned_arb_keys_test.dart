/// Stage 1 verification — orphaned ARB keys are now consumed by the UI.
///
/// Guards two things:
///   1. Every ARB key rewired in Stage 1 resolves to real Tamil in `ta`
///      and to the unchanged English in `en`.
///   2. The English literals that were replaced no longer appear as
///      hardcoded strings at the rewired call sites (regression guard —
///      stops the literals creeping back in).
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';

/// Pumps a bare MaterialApp in [locale] and hands back its AppLocalizations.
Future<AppLocalizations> _l10nFor(WidgetTester tester, Locale locale) async {
  late AppLocalizations captured;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          captured = AppLocalizations.of(context)!;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return captured;
}

/// Keys rewired in Stage 1 -> (expected English, must-be-Tamil?).
const Map<String, String> _stage1EnglishValues = {
  'navHome': 'Home',
  'navSearch': 'Search',
  'navDiscover': 'Discover',
  'navSaved': 'Saved',
  'navProfile': 'Profile',
  'viewAll': 'View All',
  'doneManaging': 'Done',
  'manageSaved': 'Manage',
  'browseByCategories': 'Browse by Categories',
  'browseByMinistry': 'Browse by Ministry',
  'browseByState': 'Browse by State',
};

String _read(AppLocalizations l, String key) => switch (key) {
      'navHome' => l.navHome,
      'navSearch' => l.navSearch,
      'navDiscover' => l.navDiscover,
      'navSaved' => l.navSaved,
      'navProfile' => l.navProfile,
      'viewAll' => l.viewAll,
      'doneManaging' => l.doneManaging,
      'manageSaved' => l.manageSaved,
      'browseByCategories' => l.browseByCategories,
      'browseByMinistry' => l.browseByMinistry,
      'browseByState' => l.browseByState,
      _ => throw ArgumentError('unmapped key $key'),
    };

/// Tamil script block: U+0B80..U+0BFF.
final RegExp _tamilScript = RegExp(r'[஀-௿]');

void main() {
  testWidgets('en locale returns the unchanged English for every Stage 1 key',
      (tester) async {
    final l10n = await _l10nFor(tester, const Locale('en'));
    for (final entry in _stage1EnglishValues.entries) {
      expect(
        _read(l10n, entry.key),
        entry.value,
        reason: 'English for ${entry.key} must not change',
      );
    }
  });

  testWidgets('ta locale returns real Tamil script for every Stage 1 key',
      (tester) async {
    final l10n = await _l10nFor(tester, const Locale('ta'));
    for (final key in _stage1EnglishValues.keys) {
      final value = _read(l10n, key);
      expect(
        _tamilScript.hasMatch(value),
        isTrue,
        reason: '$key resolved to "$value" in ta — no Tamil script found',
      );
      expect(
        value,
        isNot(_stage1EnglishValues[key]),
        reason: '$key fell back to English in ta locale',
      );
    }
  });

  test('rewired call sites no longer hold the hardcoded English literal', () {
    // file -> literals that must no longer appear anywhere in it.
    const expectations = <String, List<String>>{
      'lib/main.dart': [
        "'Home',",
        "'Search',",
        "'Discover',",
        "'Saved',",
        "'Profile',",
      ],
      'lib/screens/regular_mode/categories_screen.dart': [
        "title: 'By Category'",
        "title: 'By Ministry'",
        "title: 'By State'",
      ],
      'lib/screens/notifications_screen.dart': ["'View All',"],
      'lib/screens/regular_mode/eligibility_results_screen.dart': [
        "'View All',",
      ],
      'lib/screens/regular_mode/saved_schemes_screen.dart': ['"Manage List"'],
    };

    expectations.forEach((path, literals) {
      final source = File(path).readAsStringSync();
      for (final literal in literals) {
        expect(
          source.contains(literal),
          isFalse,
          reason: '$path still contains the hardcoded literal $literal',
        );
      }
    });
  });
}
