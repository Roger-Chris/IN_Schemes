import '../models/mss_entity.dart';
import '../models/scheme_model.dart';
import 'mss_catalog_bundle.dart';

/// MssSchemeAdapter
/// ─────────────────
/// Converts an [MssEntity] of type 'scheme' into the existing [Scheme] domain model object.
/// Resolves linked entities (authority, institution, finance, tax, etc.) strictly in-memory
/// from [MssCatalogBundle] using `relationships.references` and `byId`.
class MssSchemeAdapter {
  MssSchemeAdapter._();

  static List<dynamic>? _asList(dynamic val) {
    if (val is List) return val;
    if (val is String && val.trim().isNotEmpty) return [val.trim()];
    return null;
  }

  static List<String> _extractLegacyCodes(Map<String, dynamic> identity) {
    final codes = <String>[];
    final rawLegacy = identity['legacyCodes'] ?? identity['legacy_codes'];
    if (rawLegacy is List) {
      for (final item in rawLegacy) {
        if (item is Map) {
          final c = item['code'] as String?;
          if (c != null && c.isNotEmpty) codes.add(c);
        } else if (item is String && item.isNotEmpty) {
          codes.add(item);
        }
      }
    } else if (rawLegacy is String && rawLegacy.isNotEmpty) {
      codes.add(rawLegacy);
    }
    return codes;
  }

  /// Convert a scheme entity to a Scheme model object using in-memory catalog references.
  static Scheme toScheme(MssEntity entity, MssCatalogBundle bundle) {
    assert(
      entity.entityType == 'scheme',
      'MssSchemeAdapter requires an entity of type scheme',
    );

    final content = entity.content;
    final classification = (content['classification'] as Map<String, dynamic>?) ?? {};
    final gov = (classification['government'] as Map<String, dynamic>?) ?? {};
    final resources = (content['resources'] as Map<String, dynamic>?) ?? {};
    final appProc = (content['applicationProcess'] as Map<String, dynamic>?) ?? {};
    final search = entity.search;
    final metadata = entity.metadata;

    // ── Status Resolution ──────────────────────────────────────────────
    final rawStatus = entity.status.toLowerCase().trim();
    final statusStr = rawStatus.isEmpty ? 'unknown' : rawStatus;
    final isActive = statusStr != 'closed';

    // ── Localized Names & Text ─────────────────────────────────────────
    final nameEn = entity.getLocalizedName('en');
    final nameTa = entity.getLocalizedName('ta');
    final name = nameEn.isNotEmpty ? nameEn : (nameTa.isNotEmpty ? nameTa : entity.code);

    String overviewEn = '';
    final summaryRaw = content['summary'] ?? content['description'];
    if (summaryRaw is Map<String, dynamic>) {
      final en = summaryRaw['en'] as String? ?? '';
      final ta = summaryRaw['ta'] as String? ?? '';
      overviewEn = '$en $ta'.trim();
    } else if (summaryRaw is String) {
      overviewEn = summaryRaw;
    }

    String objectivesEn = '';
    final objectivesRaw = content['objectives'];
    if (objectivesRaw is Map<String, dynamic>) {
      final en = objectivesRaw['en'] as String? ?? '';
      final ta = objectivesRaw['ta'] as String? ?? '';
      objectivesEn = '$en $ta'.trim();
    } else if (objectivesRaw is List) {
      objectivesEn = objectivesRaw.whereType<String>().join(' ');
    } else if (objectivesRaw is String) {
      objectivesEn = objectivesRaw;
    }

    // ── Government Classification ──────────────────────────────────────
    final govLevelRaw = (gov['levelText'] as String?) ?? (gov['level'] as String?);
    final governmentLevel = govLevelRaw ?? '';

    // In-memory Authority / Ministry resolution via content pointers and relationships.references
    String sponsoringBody = (gov['ministryText'] as String?) ?? (gov['departmentText'] as String?) ?? '';
    if (sponsoringBody.isEmpty) {
      final minId = (gov['ministryId'] as String?) ?? (gov['departmentId'] as String?);
      if (minId != null) {
        final authEntity = bundle.getEntity(minId);
        if (authEntity != null) {
          sponsoringBody = authEntity.getLocalizedName('en');
        }
      }
    }

    // In-memory Institution / Implementing Agency resolution via content pointers and relationships.references
    String issuingBody = (gov['implementingAgencyText'] as String?) ?? '';
    if (issuingBody.isEmpty) {
      final agencyIds = _asList(gov['implementingAgencyIds']);
      if (agencyIds != null && agencyIds.isNotEmpty) {
        final agencyId = agencyIds.first?.toString();
        if (agencyId != null) {
          final instEntity = bundle.getEntity(agencyId);
          if (instEntity != null) {
            issuingBody = instEntity.getLocalizedName('en');
          }
        }
      }
    }

    // Graph resolution fallback via entity.references (relationships.references)
    for (final ref in entity.references) {
      final targetId = ref['targetId'] as String? ?? ref['target_id'] as String?;
      if (targetId == null || targetId.isEmpty) continue;
      final targetEntity = bundle.getEntity(targetId);
      if (targetEntity == null) continue;

      final relType = (ref['relationType'] as String? ?? ref['type'] as String? ?? '').toLowerCase();
      final targetType = targetEntity.entityType.toLowerCase();

      if (sponsoringBody.isEmpty && (targetType == 'authority' || relType.contains('authority') || relType.contains('ministry'))) {
        sponsoringBody = targetEntity.getLocalizedName('en');
      }
      if (issuingBody.isEmpty && (targetType == 'institution' || relType.contains('agency') || relType.contains('institution'))) {
        issuingBody = targetEntity.getLocalizedName('en');
      }
    }

    final stateRaw = (gov['statesText'] as String?);
    final state = (stateRaw != null && stateRaw.isNotEmpty)
        ? stateRaw
        : (governmentLevel.toLowerCase() == 'central' ? 'All India' : '');

    final sector = (classification['targetSectorsText'] as String?) ??
        _asList(classification['targetSectors'])?.join(', ') ??
        (classification['sector'] as String?) ??
        (content['sector'] as String?) ??
        (content['category'] as String?) ??
        '';

    final eligibilityText = (content['eligibilityText'] as Map<String, dynamic>?) ?? {};
    final elSummary = (eligibilityText['summary'] as String?) ?? '';

    final targetBeneficiary = (classification['targetBeneficiariesText'] as String?) ??
        _asList(classification['targetBeneficiaries'])?.join(', ') ??
        (classification['targetBeneficiary'] as String?) ??
        (content['targetBeneficiary'] as String?) ??
        elSummary;

    final schemeType = (classification['schemeTypeText'] as String?) ??
        _asList(classification['schemeType'])?.join(', ') ??
        (classification['schemeType'] as String?) ??
        (content['schemeType'] as String?) ??
        '';

    // ── In-Memory Linked Finance / Subsidies / Tax / CSR / Export ──────
    double? maxFunding;
    double? minFunding;
    double? subsidyPercentage;
    double? interestSubventionRate;
    String subsidyAmountText = '';
    String benefitsText = '';

    // 1. Check direct content funding sub-objects
    final fundingObj = (content['capitalSubsidy'] as Map<String, dynamic>?) ??
        (content['interestSubvention'] as Map<String, dynamic>?) ??
        (content['funding'] as Map<String, dynamic>?);

    if (fundingObj != null) {
      if (fundingObj['maxAmountInr'] != null) maxFunding = (fundingObj['maxAmountInr'] as num).toDouble();
      if (fundingObj['minAmountInr'] != null) minFunding = (fundingObj['minAmountInr'] as num).toDouble();
      if (fundingObj['amountInr'] != null) {
        maxFunding ??= (fundingObj['amountInr'] as num).toDouble();
        minFunding ??= (fundingObj['amountInr'] as num).toDouble();
      }
      if (fundingObj['maxText'] != null) subsidyAmountText = fundingObj['maxText'] as String;
      if (fundingObj['percentage'] != null) subsidyPercentage = (fundingObj['percentage'] as num).toDouble();
    }

    // 2. Resolve linked finance entities from in-memory byCatalog['finance']
    final financeProducts = bundle.getCatalog('finance');
    for (final fin in financeProducts) {
      final finSchemeId = fin.content['schemeId'] as String?;
      if (finSchemeId == entity.id) {
        final amountObj = fin.content['amount'] as Map<String, dynamic>?;
        if (amountObj != null) {
          if (amountObj['maxInr'] != null) maxFunding ??= (amountObj['maxInr'] as num).toDouble();
          if (amountObj['minInr'] != null) minFunding ??= (amountObj['minInr'] as num).toDouble();
          if (subsidyAmountText.isEmpty && amountObj['maxText'] != null) {
            subsidyAmountText = amountObj['maxText'] as String;
          }
        }
        final intRateObj = fin.content['interestRate'] as Map<String, dynamic>?;
        if (intRateObj != null && intRateObj['percent'] != null) {
          interestSubventionRate = (intRateObj['percent'] as num).toDouble();
        }
        final prodType = fin.content['productType'] as String?;
        if (prodType != null && benefitsText.isEmpty) {
          benefitsText = fin.getLocalizedName('en');
        }
      }
    }

    // 3. Resolve linked tax entities from in-memory byCatalog['tax']
    final taxIncentives = bundle.getCatalog('tax');
    for (final tax in taxIncentives) {
      final schemesList = _asList(tax.content['evidencedInSchemes']);
      if (schemesList != null && schemesList.contains(entity.id)) {
        final exObj = tax.content['exemption'] as Map<String, dynamic>?;
        if (exObj != null && exObj['percentage'] != null) {
          subsidyPercentage ??= (exObj['percentage'] as num).toDouble();
        }
      }
    }

    // ── Application & Resource URLs ─────────────────────────────────────
    final applicationMode = (appProc['modeText'] as String?) ?? (appProc['mode'] as String?) ?? '';
    final officialWebsiteRaw = (resources['officialWebsiteUrl'] as String?) ??
        (resources['applicationPortalUrl'] as String?) ??
        (resources['schemePortalUrl'] as String?) ??
        (resources['portalUrl'] as String?);
    final officialWebsite = (officialWebsiteRaw != null && officialWebsiteRaw.trim().isNotEmpty)
        ? officialWebsiteRaw.trim()
        : 'https://tn.gov.in';
    final applicationUrl = (resources['applicationPortalUrl'] as String?) ?? officialWebsite;
    final guidelinesUrl = (resources['guidelinesPdfUrl'] as String?) ?? '';
    final districtApplicable = (gov['districtsText'] as String?) ?? '';
    final lastUpdated = (metadata['updatedAt'] as String?) ?? '';

    // ── Eligibility Criteria ───────────────────────────────────────────
    final elCriteriaList = <String>[];
    if (elSummary.isNotEmpty) elCriteriaList.add(elSummary);

    final elRules = _asList(content['eligibilityRules']);
    if (elRules != null) {
      for (final rule in elRules) {
        if (rule is Map<String, dynamic>) {
          final desc = rule['description'] as String?;
          if (desc != null && desc.isNotEmpty && !elCriteriaList.contains(desc)) {
            elCriteriaList.add(desc);
          }
        }
      }
    }

    // Search keywords & legacy code mapping
    final kwEn = _asList(search['keywords']?['en'])?.join(' ') ?? '';
    final kwTa = _asList(search['keywords']?['ta'])?.join(' ') ?? '';
    final extractedLegacyCodes = _extractLegacyCodes(entity.identity).join(' ');
    final searchKeywords = '$kwEn $kwTa $extractedLegacyCodes $nameTa $nameEn $sponsoringBody $issuingBody ${elCriteriaList.join(" ")} $benefitsText'.trim();

    // ── Documents Required ──────────────────────────────────────────────
    final docList = <SchemeDocument>[];
    final reqDocNames = <String>[];

    final docRefs = _asList(content['documents']);
    if (docRefs != null) {
      for (final docItem in docRefs) {
        if (docItem is Map<String, dynamic>) {
          final docName = (docItem['name'] as String?) ?? '';
          if (docName.isNotEmpty) {
            reqDocNames.add(docName);
            docList.add(SchemeDocument(
              name: docName,
              mandatory: (docItem['mandatory'] == true) ? 'Yes' : 'No',
              issuingAuthority: (docItem['issuingAuthority'] as String?) ?? '',
              description: (docItem['description'] as String?) ?? '',
              sourceUrl: (docItem['sourceUrl'] as String?) ?? '',
            ));
          }
        }
      }
    }

    // ── Application Steps ───────────────────────────────────────────────
    final stepsList = <String>[];
    final appSteps = _asList(appProc['steps']);
    if (appSteps != null) {
      for (final step in appSteps) {
        if (step is Map<String, dynamic>) {
          final title = step['title'] as String?;
          final desc = step['description'] as String?;
          if (title != null && title.isNotEmpty) {
            stepsList.add('$title: ${desc ?? ''}');
          } else if (desc != null && desc.isNotEmpty) {
            stepsList.add(desc);
          }
        } else if (step is String && step.isNotEmpty) {
          stepsList.add(step);
        }
      }
    }

    return Scheme(
      id: entity.id,
      schemeCode: entity.code,
      name: name,
      governmentLevel: governmentLevel,
      sponsoringBody: sponsoringBody,
      issuingBody: issuingBody,
      state: state,
      sector: sector,
      targetBeneficiary: targetBeneficiary,
      schemeType: schemeType,
      category: schemeType.isNotEmpty ? schemeType : sector,
      overview: overviewEn,
      objectives: objectivesEn,
      benefits: benefitsText.isNotEmpty ? benefitsText : overviewEn,
      subsidyPercentage: subsidyPercentage,
      maxFunding: maxFunding,
      minFunding: minFunding,
      interestSubventionRate: interestSubventionRate,
      applicationMode: applicationMode,
      officialWebsite: officialWebsite,
      applicationUrl: applicationUrl,
      guidelinesUrl: guidelinesUrl,
      sourceUrl: officialWebsite,
      districtApplicable: districtApplicable,
      subsidyAmount: subsidyAmountText,
      verificationStatus: (metadata['verificationStatus'] as String?) ?? 'VERIFIED',
      verificationNotes: (metadata['sourceNotes'] as String?) ?? '',
      lastUpdated: lastUpdated,
      searchKeywords: searchKeywords,
      status: statusStr,
      isActive: isActive,
      eligibilityCriteria: elCriteriaList,
      requiredDocuments: reqDocNames,
      applicationProcess: stepsList,
      documents: docList,
      requiredServices: const [],
      faqs: const [],
    );
  }
}
