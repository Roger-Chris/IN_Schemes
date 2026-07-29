import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/scheme_model.dart';

/// Parses the curated offline catalog bundled with the application.
class SchemeCatalog {
  SchemeCatalog._(this.schemes)
    : _byId = {
        for (final scheme in schemes) scheme.id.toLowerCase(): scheme,
        for (final scheme in schemes) scheme.schemeCode.toLowerCase(): scheme,
      };

  static const assetPath = 'assets/data/government_schemes.json';

  final List<Scheme> schemes;
  final Map<String, Scheme> _byId;

  static Future<SchemeCatalog> load() async {
    final contents = await rootBundle.loadString(assetPath);
    return SchemeCatalog.fromJson(contents);
  }

  factory SchemeCatalog.fromJson(String contents) {
    final root = jsonDecode(contents) as Map<String, dynamic>;
    final eligibilityRows = _rows(root['All Schemes']);
    final infoRows = _rows(root['Scheme Info']);
    final documentRows = _rows(root['Documents Required']);
    final serviceRows = _rows(root['Services Required']);

    final eligibilityByCode = <String, Map<String, dynamic>>{
      for (final row in eligibilityRows) _text(row, 'Scheme ID'): row,
    };
    final eligibilityCodeByName = <String, String>{
      for (final row in eligibilityRows)
        _text(row, 'Scheme Name'): _text(row, 'Scheme ID'),
    };
    final documentsByCode = <String, List<SchemeDocument>>{};
    for (final row in documentRows) {
      final code = _text(row, 'Scheme Code');
      if (code.isEmpty) continue;
      documentsByCode
          .putIfAbsent(code, () => [])
          .add(
            SchemeDocument(
              name: _text(row, 'Document'),
              mandatory: _text(row, 'Mandatory'),
              issuingAuthority: _text(row, 'Issuing Authority'),
              description: _text(row, 'Description'),
              estimatedCost: _text(row, 'Estimated Cost'),
              remarks: _text(row, 'Remarks'),
              sourceUrl: _validUrl(_text(row, 'Source URL')),
            ),
          );
    }

    final servicesByCode = <String, List<SchemeService>>{};
    final codePattern = RegExp(r'^(IN\d{3})\s*[—-]\s*');
    for (final row in serviceRows) {
      final serviceName = _text(row, 'Service Name');
      final match = codePattern.firstMatch(serviceName);
      if (match == null) continue;
      final code = match.group(1)!;
      servicesByCode
          .putIfAbsent(code, () => [])
          .add(
            SchemeService(
              name: serviceName.replaceFirst(codePattern, '').trim(),
              category: _text(row, 'Category'),
              mandatory: _bool(row['Mandatory (TRUE/FALSE)']),
              description: _text(row, 'Description'),
            ),
          );
    }

    final schemes =
        infoRows
            .map((info) {
              final name = _text(info, 'Scheme Name');
              final suppliedCode = _text(info, 'Scheme Code');
              final code = RegExp(r'^IN\d{3}$').hasMatch(suppliedCode)
                  ? suppliedCode
                  : eligibilityCodeByName[name] ?? '';
              final eligibility =
                  eligibilityByCode[code] ?? const <String, dynamic>{};
              final originalEligibility = _text(
                eligibility,
                'Eligibility Criteria',
              );
              final verifiedEligibility = _text(
                eligibility,
                'Verified Eligibility',
              );
              final eligibilityCriteria = <String>[
                if (verifiedEligibility.isNotEmpty) verifiedEligibility,
                if (originalEligibility.isNotEmpty &&
                    originalEligibility != verifiedEligibility)
                  originalEligibility,
              ];
              final documents =
                  documentsByCode[code] ?? const <SchemeDocument>[];
              final officialWebsite = _firstUrl([
                _text(info, 'Official Website'),
                _text(info, 'Source URL'),
                _text(eligibility, 'Official Source'),
              ]);
              final guidelinesUrl = _firstUrl([
                _text(info, 'Guidelines URL'),
                _text(eligibility, 'Official Source'),
                _text(info, 'Source URL'),
              ]);
              final sourceUrl = _firstUrl([
                _text(eligibility, 'Official Source'),
                _text(info, 'Source URL'),
                guidelinesUrl,
                officialWebsite,
              ]);
              final applicationUrl = _firstUrl([
                _text(info, 'Application URL'),
                officialWebsite,
                guidelinesUrl,
                sourceUrl,
              ]);
              final applicationMode = _text(info, 'Application Mode');
              final sector = _text(info, 'Target Sector');
              final beneficiary = _text(info, 'Target Beneficiary');
              final schemeType = _text(info, 'Scheme Type');
              final overview = _text(info, 'Overview');
              final objectives = _text(info, 'Objectives');
              final benefits = _text(info, 'Benefits Description');
              final sourceName = _text(eligibility, 'Source');

              return Scheme(
                id: code,
                schemeCode: code,
                name: name,
                governmentLevel: _fallback(
                  _text(info, 'Government Level'),
                  'Central',
                ),
                sponsoringBody: _firstText([
                  _text(info, 'Department'),
                  _text(info, 'Ministry'),
                ]),
                issuingBody: _text(info, 'Implementing Agency'),
                state: _fallback(_text(info, 'State'), 'All India'),
                sector: sector,
                targetBeneficiary: beneficiary,
                schemeType: schemeType,
                category: _firstText([sector, schemeType]),
                overview: overview,
                objectives: objectives,
                benefits: benefits,
                subsidyPercentage: _parsePercentage(
                  _text(info, 'Subsidy Percentage'),
                ),
                maxFunding: _parseMoney(_text(info, 'Maximum Funding Amount')),
                minFunding: _parseMoney(_text(info, 'Minimum Funding Amount')),
                applicationMode: applicationMode,
                officialWebsite: officialWebsite,
                applicationUrl: applicationUrl,
                guidelinesUrl: guidelinesUrl,
                sourceUrl: sourceUrl,
                districtApplicable: _text(info, 'District Applicable'),
                subsidyAmount: _text(info, 'Subsidy Amount'),
                verificationStatus: _firstText([
                  _text(eligibility, 'Verification Status'),
                  _text(info, 'Verified (Yes/No)'),
                ]),
                verificationNotes: _text(eligibility, 'Verification Notes'),
                lastUpdated: _text(info, 'Last Updated'),
                searchKeywords: [
                  name,
                  code,
                  sourceName,
                  _text(info, 'Ministry'),
                  _text(info, 'Department'),
                  _text(info, 'Implementing Agency'),
                  sector,
                  beneficiary,
                  schemeType,
                  overview,
                  objectives,
                  benefits,
                  originalEligibility,
                  verifiedEligibility,
                ].where((value) => value.isNotEmpty).join(' '),
                status: _fallback(
                  _text(info, 'Status'),
                  'Status not specified',
                ),
                isActive: true,
                eligibilityCriteria: eligibilityCriteria.isEmpty
                    ? const [
                        'Refer to the official scheme source for eligibility.',
                      ]
                    : eligibilityCriteria,
                requiredDocuments: documents
                    .map((document) => document.name)
                    .toList(),
                documents: documents,
                requiredServices:
                    servicesByCode[code] ?? const <SchemeService>[],
                applicationProcess: _applicationSteps(
                  applicationMode,
                  applicationUrl,
                ),
              );
            })
            .where((scheme) => scheme.schemeCode.isNotEmpty)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    return SchemeCatalog._(List.unmodifiable(schemes));
  }

  Scheme? findById(String id) => _byId[id.toLowerCase()];

  static List<Map<String, dynamic>> _rows(Object? value) {
    if (value is! List) return const [];
    return value.whereType<Map<String, dynamic>>().toList();
  }

  static String _text(Map<String, dynamic> row, String key) {
    final value = row[key];
    return value == null ? '' : value.toString().trim();
  }

  static String _fallback(String value, String fallback) =>
      value.isEmpty || value.toLowerCase() == 'not specified'
      ? fallback
      : value;

  static String _firstText(Iterable<String> values) => values.firstWhere(
    (value) => value.isNotEmpty && value.toLowerCase() != 'not specified',
    orElse: () => '',
  );

  static String _validUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https')
        ? uri.toString()
        : '';
  }

  static String _firstUrl(Iterable<String> values) => values
      .map(_validUrl)
      .firstWhere((value) => value.isNotEmpty, orElse: () => '');

  static bool _bool(Object? value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }

  static double? _parsePercentage(String value) {
    final match = RegExp(
      r'\d+(?:\.\d+)?',
    ).firstMatch(value.replaceAll(',', ''));
    return match == null ? null : double.tryParse(match.group(0)!);
  }

  static double? _parseMoney(String value) {
    final normalized = value.toLowerCase().replaceAll(',', '');
    final match = RegExp(r'\d+(?:\.\d+)?').firstMatch(normalized);
    if (match == null) return null;
    final amount = double.tryParse(match.group(0)!);
    if (amount == null) return null;
    if (normalized.contains('crore')) return amount * 10000000;
    if (normalized.contains('lakh')) return amount * 100000;
    if (normalized.contains('thousand')) return amount * 1000;
    return amount;
  }

  static List<String> _applicationSteps(String mode, String url) {
    final normalizedMode = mode.toLowerCase();
    if (normalizedMode.contains('online')) {
      return [
        if (url.isNotEmpty) 'Open the official scheme portal.',
        'Register or sign in using the details requested by the portal.',
        'Complete the application form and upload the required documents.',
        'Submit the form and retain the application reference number.',
        'Track the application through the official portal or implementing agency.',
      ];
    }
    if (normalizedMode.contains('bank')) {
      return const [
        'Contact an eligible bank or financial institution for the scheme form.',
        'Complete the form and attach the required supporting documents.',
        'Submit the proposal for appraisal and retain the acknowledgement.',
      ];
    }
    return const [
      'Contact the listed implementing agency or designated office.',
      'Confirm the current application window and collect the application form.',
      'Submit the completed form with all required supporting documents.',
      'Retain the acknowledgement and follow up with the official agency.',
    ];
  }
}
