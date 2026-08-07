import '../models/mss_entity.dart';
import '../models/scheme_model.dart';
import 'mss_catalog_bundle.dart';

/// MssSchemeAdapter
/// ─────────────────
/// Canonical translation layer converting an [MssEntity] of type 'scheme'
/// into the rich [Scheme] domain model object.
/// Resolves linked entities (authority, institution, finance, tax, CSR, export,
/// TReDS, knowledge, services, documents) strictly in-memory from [MssCatalogBundle]
/// using `relationships.references` and `byId` graph resolution.
class MssSchemeAdapter {
  MssSchemeAdapter._();

  static List<dynamic>? _asList(dynamic val) {
    if (val is List) return val;
    if (val is String && val.trim().isNotEmpty) return [val.trim()];
    return null;
  }

  static (String en, String ta) _extractMultilingualStr(
    dynamic rawObj, [
    String defaultStr = '',
  ]) {
    if (rawObj is Map<String, dynamic>) {
      final en = (rawObj['en'] as String? ?? '').trim();
      final ta = (rawObj['ta'] as String? ?? '').trim();
      final name =
          (rawObj['name'] as String? ??
                  rawObj['title'] as String? ??
                  rawObj['description'] as String? ??
                  '')
              .trim();
      final nameTa =
          (rawObj['name_ta'] as String? ??
                  rawObj['title_ta'] as String? ??
                  rawObj['description_ta'] as String? ??
                  '')
              .trim();
      return (
        en.isNotEmpty ? en : (name.isNotEmpty ? name : defaultStr),
        ta.isNotEmpty ? ta : nameTa,
      );
    }
    if (rawObj is String && rawObj.trim().isNotEmpty) {
      return (rawObj.trim(), '');
    }
    return (defaultStr, '');
  }

  /// Extracts localized text from a map, list, or string with strict fallback:
  /// `preferred locale (langCode) → alternate locale (en/ta) → default text`
  static String _getLocalizedText(dynamic val, [String preferredLang = 'en']) {
    if (val == null) return '';
    if (val is Map) {
      final preferred = val[preferredLang]?.toString();
      if (preferred != null && preferred.trim().isNotEmpty) {
        return preferred.trim();
      }
      final altLang = preferredLang == 'ta' ? 'en' : 'ta';
      final alt = val[altLang]?.toString();
      if (alt != null && alt.trim().isNotEmpty) {
        return alt.trim();
      }
      final desc =
          val['description'] ?? val['summary'] ?? val['text'] ?? val['name'];
      if (desc != null) return _getLocalizedText(desc, preferredLang);
    } else if (val is List) {
      final items = val
          .map((e) => _getLocalizedText(e, preferredLang))
          .where((s) => s.isNotEmpty);
      return items.join('\n• ');
    } else if (val is String) {
      return val.trim();
    }
    return '';
  }

  /// Convert a scheme entity to a Scheme model object using in-memory catalog graph references.
  static Scheme toScheme(
    MssEntity entity,
    MssCatalogBundle bundle, {
    String langCode = 'en',
  }) {
    assert(
      entity.entityType == 'scheme',
      'MssSchemeAdapter requires an entity of type scheme',
    );

    final content = entity.content;
    final classification =
        (content['classification'] as Map<String, dynamic>?) ?? {};
    final gov = (classification['government'] as Map<String, dynamic>?) ?? {};
    final resources = (content['resources'] as Map<String, dynamic>?) ?? {};
    final appProc =
        (content['applicationProcess'] as Map<String, dynamic>?) ?? {};
    final appTimeline =
        (content['applicationTimeline'] as Map<String, dynamic>?) ?? {};

    final metadata = entity.metadata;
    final overviewObj = (content['overview'] as Map<String, dynamic>?) ?? {};
    final targetBeneficiariesObj =
        (content['targetBeneficiaries'] as Map<String, dynamic>?) ?? {};
    final eligibilityObj =
        (content['eligibility'] as Map<String, dynamic>?) ?? {};
    final eligibilityTextObj =
        (content['eligibilityText'] as Map<String, dynamic>?) ?? {};
    final benefitsObj = (content['benefits'] as Map<String, dynamic>?) ?? {};
    final contactsObj = (content['contacts'] as Map<String, dynamic>?) ?? {};

    // ── 1. Status & Header Information ──────────────────────────────────
    final rawStatus = entity.status.toLowerCase().trim();
    final statusStr = rawStatus.isEmpty ? 'ACTIVE' : rawStatus.toUpperCase();
    final isActive = statusStr != 'CLOSED';

    final nameEn = entity.getLocalizedName('en');
    final nameTa = entity.getLocalizedName('ta');
    final name = nameEn.isNotEmpty
        ? nameEn
        : (nameTa.isNotEmpty ? nameTa : entity.code);
    final shortName = _getLocalizedText(
      entity.identity['shortName'] ?? classification['shortName'],
      langCode,
    );
    final fullSchemeName = _getLocalizedText(
      entity.identity['fullName'],
      langCode,
    );
    final finalFullName = fullSchemeName.isNotEmpty ? fullSchemeName : name;

    // ── 2. Graph Relationship Resolution (Authorities & Institutions) ───
    final resolvedAuthorities = bundle.getAuthoritiesForScheme(entity);
    final resolvedInstitutions = bundle.getInstitutionsForScheme(entity);

    String ministry = _getLocalizedText(gov['ministryText'], langCode);
    String department = _getLocalizedText(gov['departmentText'], langCode);
    String implementingAgency = _getLocalizedText(
      gov['implementingAgencyText'],
      langCode,
    );

    if (ministry.isEmpty && resolvedAuthorities.isNotEmpty) {
      ministry = resolvedAuthorities.first.getLocalizedName(langCode);
    }
    if (department.isEmpty) {
      if (resolvedAuthorities.length > 1) {
        department = resolvedAuthorities[1].getLocalizedName(langCode);
      } else if (ministry.isNotEmpty) {
        department = ministry;
      }
    }
    if (implementingAgency.isEmpty && resolvedInstitutions.isNotEmpty) {
      implementingAgency = resolvedInstitutions.first.getLocalizedName(
        langCode,
      );
    }

    final sponsoringBody = ministry.isNotEmpty
        ? ministry
        : (department.isNotEmpty ? department : 'Government of India');
    final issuingBody = implementingAgency.isNotEmpty
        ? implementingAgency
        : sponsoringBody;

    final govLevelRaw =
        (gov['levelText'] as String?) ?? (gov['level'] as String?) ?? 'Central';
    final governmentLevel = govLevelRaw.isNotEmpty ? govLevelRaw : 'Central';

    final stateRaw = (gov['statesText'] as String?);
    final state = (stateRaw != null && stateRaw.isNotEmpty)
        ? stateRaw
        : (governmentLevel.toLowerCase().contains('central')
              ? 'All India'
              : 'Tamil Nadu');

    final sector =
        (classification['sectorsText'] as String?) ??
        _asList(classification['sectors'])?.join(', ') ??
        (classification['sector'] as String?) ??
        (content['sector'] as String?) ??
        '';

    final schemeType =
        (classification['schemeTypeText'] as String?) ??
        _asList(classification['schemeType'])?.join(', ') ??
        (classification['schemeType'] as String?) ??
        '';

    final category = schemeType.isNotEmpty
        ? schemeType
        : (sector.isNotEmpty ? sector : 'General');

    // ── 3. Overview & Objectives ───────────────────────────────────────
    String overviewEn = '';
    String overviewTa = entity.getLocalizedAttribute('summary', 'ta');
    if (overviewTa.isEmpty) {
      overviewTa = entity.getLocalizedAttribute('overview', 'ta');
    }
    if (overviewTa.isEmpty) {
      overviewTa = entity.getLocalizedAttribute('description', 'ta');
    }

    final summaryRaw =
        overviewObj['summary'] ??
        overviewObj['description'] ??
        content['summary'] ??
        content['description'] ??
        content['overview'];
    if (summaryRaw is Map<String, dynamic>) {
      final en = summaryRaw['en'] as String? ?? '';
      final ta = summaryRaw['ta'] as String? ?? '';
      overviewEn = en.isNotEmpty ? en : ta;
      if (overviewTa.isEmpty && ta.isNotEmpty) overviewTa = ta;
    } else if (summaryRaw is String) {
      overviewEn = summaryRaw;
    }

    final objectivesEn = _getLocalizedText(
      content['objectives'] ?? overviewObj['objective'],
      langCode,
    );

    // ── 4. Target Beneficiaries & At-a-Glance Chips ────────────────────
    final beneficiaryDesc = _getLocalizedText(
      targetBeneficiariesObj['description'] ??
          classification['targetBeneficiariesText'] ??
          classification['targetBeneficiaries'],
      langCode,
    );
    final targetBeneficiary = beneficiaryDesc.isNotEmpty
        ? beneficiaryDesc
        : 'Eligible MSMEs & Enterprises';

    if (overviewEn.isEmpty) {
      final elTextEn =
          (eligibilityTextObj['summary'] as String?) ??
          (content['eligibilityText'] as String?) ??
          entity.getLocalizedAttribute('eligibilityText', 'en');
      final elTextTa = entity.getLocalizedAttribute('eligibilityText', 'ta');
      if (elTextEn.isNotEmpty) {
        overviewEn = elTextEn;
        if (overviewTa.isEmpty && elTextTa.isNotEmpty) overviewTa = elTextTa;
      } else {
        overviewEn =
            'Government scheme providing financial and institutional support for $targetBeneficiary.';
      }
    }

    final glanceChips = <String>{};
    if (governmentLevel.isNotEmpty) glanceChips.add(governmentLevel);
    if (state.isNotEmpty) glanceChips.add(state);
    if (sector.isNotEmpty) {
      glanceChips.addAll(
        sector.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty),
      );
    }
    if (schemeType.isNotEmpty) glanceChips.add(schemeType);

    final benTypes = _asList(targetBeneficiariesObj['beneficiaryTypes']);
    if (benTypes != null) glanceChips.addAll(benTypes.map((e) => e.toString()));

    final entTypes = _asList(targetBeneficiariesObj['enterpriseTypes']);
    if (entTypes != null) glanceChips.addAll(entTypes.map((e) => e.toString()));

    final busStages = _asList(targetBeneficiariesObj['businessStages']);
    if (busStages != null) {
      glanceChips.addAll(busStages.map((e) => e.toString()));
    }

    final specCats = _asList(targetBeneficiariesObj['specialCategories']);
    if (specCats != null) glanceChips.addAll(specCats.map((e) => e.toString()));

    final tags = _asList(classification['tags']);
    if (tags != null) glanceChips.addAll(tags.map((e) => e.toString()));

    // ── 5. Benefits & Funding Breakdown ────────────────────────────────
    double? maxFunding;
    double? minFunding;
    double? subsidyPercentage;
    double? interestSubventionRate;
    String subsidyAmountText = '';
    String benefitsText = '';
    String benefitsTa = '';
    final benefitsRaw =
        benefitsObj['summary'] ??
        benefitsObj['description'] ??
        content['benefits'] ??
        content['benefitsText'];
    if (benefitsRaw is Map<String, dynamic>) {
      final benefitsEn = (benefitsRaw['en'] as String? ?? '').trim();
      benefitsTa = (benefitsRaw['ta'] as String? ?? '').trim();
      benefitsText = benefitsEn.isNotEmpty ? benefitsEn : benefitsTa;
    } else if (benefitsRaw is String) {
      benefitsText = benefitsRaw;
    }
    if (benefitsTa.isEmpty) {
      benefitsTa = entity.getLocalizedAttribute('benefitsText', 'ta');
    }
    if (benefitsTa.isEmpty) {
      benefitsTa = entity.getLocalizedAttribute('benefits', 'ta');
    }

    if (benefitsText.isEmpty) {
      final bTextEn = entity.getLocalizedAttribute('benefitsText', 'en');
      if (bTextEn.isNotEmpty) {
        benefitsText = bTextEn;
      } else {
        benefitsText =
            'Provides financial assistance, subsidies, or institutional support for eligible applicants.';
      }
    }

    final capSubsidy = benefitsObj['capitalSubsidy'] as Map<String, dynamic>?;
    final intSubvention =
        benefitsObj['interestSubvention'] as Map<String, dynamic>?;
    final marginMoney = benefitsObj['marginMoney'] as Map<String, dynamic>?;
    final loanGuarantee = benefitsObj['guarantee'] as Map<String, dynamic>?;

    if (capSubsidy != null) {
      if (capSubsidy['maxAmountInr'] != null) {
        maxFunding = (capSubsidy['maxAmountInr'] as num).toDouble();
      }
      if (capSubsidy['minAmountInr'] != null) {
        minFunding = (capSubsidy['minAmountInr'] as num).toDouble();
      }
      if (capSubsidy['percentage'] != null) {
        subsidyPercentage = (capSubsidy['percentage'] as num).toDouble();
      }
      if (capSubsidy['maxText'] != null) {
        subsidyAmountText = capSubsidy['maxText'] as String;
      }
    }
    if (intSubvention != null) {
      if (intSubvention['percentage'] != null) {
        interestSubventionRate = (intSubvention['percentage'] as num)
            .toDouble();
      }
      if (intSubvention['rate'] != null) {
        interestSubventionRate ??= (intSubvention['rate'] as num).toDouble();
      }
    }

    final benefitTypesList =
        _asList(
          benefitsObj['benefitTypes'],
        )?.map((e) => e.toString()).toList() ??
        [];
    final capitalSubsidyDetails = capSubsidy != null
        ? _getLocalizedText(
            capSubsidy['description'] ?? capSubsidy['maxText'],
            langCode,
          )
        : '';
    final interestSubventionDetails = intSubvention != null
        ? _getLocalizedText(
            intSubvention['description'] ?? intSubvention['text'],
            langCode,
          )
        : '';
    final marginMoneyDetails = marginMoney != null
        ? _getLocalizedText(
            marginMoney['description'] ?? marginMoney['text'],
            langCode,
          )
        : '';
    final loanGuaranteeDetails = loanGuarantee != null
        ? _getLocalizedText(
            loanGuarantee['description'] ?? loanGuarantee['text'],
            langCode,
          )
        : '';

    final rawBenefitsDisplayText = benefitsText.isNotEmpty
        ? benefitsText
        : overviewEn;

    // ── 6. Eligibility Details (Comprehensive Mapping) ─────────────────
    final elCriteriaList = <String>[];
    final structuredEl = eligibilityObj['structured'] as Map<String, dynamic>?;
    final narrativeEl = eligibilityObj['narrative'] as Map<String, dynamic>?;

    // A. Narrative Summary & Bullets
    if (narrativeEl != null) {
      final nSum = _getLocalizedText(narrativeEl['summary'], langCode);
      if (nSum.isNotEmpty) elCriteriaList.add(nSum);

      final nBullets = _asList(narrativeEl['bulletPoints']);
      if (nBullets != null) {
        for (final b in nBullets) {
          final s = _getLocalizedText(b, langCode);
          if (s.isNotEmpty && !elCriteriaList.contains(s)) {
            elCriteriaList.add(s);
          }
        }
      }
    }

    // B. Direct Eligibility Text / Rules
    final elSum = _getLocalizedText(eligibilityTextObj['summary'], langCode);
    if (elSum.isNotEmpty && !elCriteriaList.contains(elSum)) {
      elCriteriaList.add(elSum);
    }

    final elRules = _asList(content['eligibilityRules']);
    if (elRules != null) {
      for (final rule in elRules) {
        final rText = _getLocalizedText(rule, langCode);
        if (rText.isNotEmpty && !elCriteriaList.contains(rText)) {
          elCriteriaList.add(rText);
        }
      }
    }

    // C. Structured Conditions Parsing
    String ageRange = '';
    String turnoverLimits = '';
    String investmentLimits = '';
    String educationRequirements = '';
    final allowedBusinessTypes = <String>[];
    final mandatoryConditions = <String>[];
    final optionalConditions = <String>[];
    final specialCategories = <String>[];

    if (structuredEl != null) {
      final aMin = structuredEl['ageMin'];
      final aMax = structuredEl['ageMax'];
      if (aMin != null || aMax != null) {
        ageRange = '${aMin ?? 18} - ${aMax ?? "No upper limit"} years';
        elCriteriaList.add('Applicant Age: $ageRange');
      }

      final tMin = structuredEl['turnoverMinInr'];
      final tMax = structuredEl['turnoverMaxInr'];
      if (tMin != null || tMax != null) {
        turnoverLimits = '₹${tMin ?? 0} to ₹${tMax ?? "No limit"}';
        elCriteriaList.add('Enterprise Turnover: $turnoverLimits');
      }

      final iMin = structuredEl['investmentMinInr'];
      final iMax = structuredEl['investmentMaxInr'];
      if (iMin != null || iMax != null) {
        investmentLimits = '₹${iMin ?? 0} to ₹${iMax ?? "No limit"}';
        elCriteriaList.add('Plant & Machinery Investment: $investmentLimits');
      }

      final bTypes = _asList(structuredEl['businessTypes']);
      if (bTypes != null && bTypes.isNotEmpty) {
        allowedBusinessTypes.addAll(bTypes.map((e) => e.toString()));
        elCriteriaList.add(
          'Eligible Business Types: ${allowedBusinessTypes.join(', ')}',
        );
      }

      educationRequirements = _getLocalizedText(
        structuredEl['education'],
        langCode,
      );
      if (educationRequirements.isNotEmpty) {
        elCriteriaList.add('Educational Qualification: $educationRequirements');
      }

      final mConds = _asList(structuredEl['mandatoryConditions']);
      if (mConds != null) {
        for (final mc in mConds) {
          final s = _getLocalizedText(mc, langCode);
          if (s.isNotEmpty) {
            mandatoryConditions.add(s);
            if (!elCriteriaList.contains(s)) elCriteriaList.add(s);
          }
        }
      }

      final oConds = _asList(structuredEl['optionalConditions']);
      if (oConds != null) {
        for (final oc in oConds) {
          final s = _getLocalizedText(oc, langCode);
          if (s.isNotEmpty) {
            optionalConditions.add(s);
            if (!elCriteriaList.contains(s)) elCriteriaList.add(s);
          }
        }
      }

      final sCats = _asList(structuredEl['specialCategories']);
      if (sCats != null) {
        for (final sc in sCats) {
          final s = _getLocalizedText(sc, langCode);
          if (s.isNotEmpty) specialCategories.add(s);
        }
      }

      final locReq = _getLocalizedText(
        structuredEl['locationRequirement'],
        langCode,
      );
      if (locReq.isNotEmpty && !elCriteriaList.contains('Location: $locReq')) {
        elCriteriaList.add('Location: $locReq');
      }
    }

    if (elCriteriaList.isEmpty && targetBeneficiary.isNotEmpty) {
      elCriteriaList.add('Target Beneficiaries: $targetBeneficiary');
    }

    // ── 7. Required Documents ──────────────────────────────────────────
    final docList = <SchemeDocument>[];
    final reqDocNames = <String>[];

    final rawDocs = _asList(
      content['requiredDocuments'] ?? content['documents'],
    );
    if (rawDocs != null) {
      for (final docItem in rawDocs) {
        if (docItem is Map<String, dynamic>) {
          final (dNameEn, dNameTa) = _extractMultilingualStr(
            docItem['name'] ?? docItem['title'] ?? docItem,
          );
          final (dDescEn, dDescTa) = _extractMultilingualStr(
            docItem['description'] ?? docItem['summary'],
          );
          final (dAuthEn, dAuthTa) = _extractMultilingualStr(
            docItem['issuingAuthorityText'] ?? docItem['issuingAuthority'],
          );
          final (dCostEn, dCostTa) = _extractMultilingualStr(
            docItem['estimatedCostText'] ?? docItem['estimatedCostInr'],
          );
          final (dRemEn, dRemTa) = _extractMultilingualStr(docItem['remarks']);

          final finalDocName = dNameEn.isNotEmpty
              ? dNameEn
              : (dNameTa.isNotEmpty ? dNameTa : 'Required Document');

          reqDocNames.add(finalDocName);
          docList.add(
            SchemeDocument(
              name: finalDocName,
              nameTa: dNameTa,
              mandatory:
                  (docItem['mandatoryText'] as String?) ??
                  (docItem['mandatory'] == 'required' ||
                          docItem['mandatory'] == true
                      ? 'Yes'
                      : 'No'),
              issuingAuthority: dAuthEn,
              issuingAuthorityTa: dAuthTa,
              description: dDescEn,
              descriptionTa: dDescTa,
              estimatedCost: dCostEn,
              estimatedCostTa: dCostTa,
              remarks: dRemEn,
              remarksTa: dRemTa,
              sourceUrl: (docItem['sourceUrl'] as String?) ?? '',
              validityMonths: docItem['validityMonths']?.toString() ?? '',
              downloadTemplateUrl:
                  (docItem['downloadTemplateUrl'] as String?) ?? '',
              sampleCopyUrl: (docItem['sampleCopyUrl'] as String?) ?? '',
              verificationPortalUrl:
                  (docItem['verificationPortalUrl'] as String?) ?? '',
            ),
          );
        }
      }
    }

    // ── 8. Application Process & Required Services ────────────────────
    final stepsList = <String>[];
    final rawSteps = _asList(
      appProc['steps'] ?? content['process']?['steps'] ?? content['workflow'],
    );
    if (rawSteps != null && rawSteps.isNotEmpty) {
      for (int i = 0; i < rawSteps.length; i++) {
        final step = rawSteps[i];
        if (step is Map<String, dynamic>) {
          final (titleEn, titleTa) = _extractMultilingualStr(step['title']);
          final (descEn, descTa) = _extractMultilingualStr(step['description']);
          final stepNum = step['stepNumber'] ?? (i + 1);

          final stepEn = titleEn.isNotEmpty
              ? 'Step $stepNum: $titleEn${descEn.isNotEmpty ? " - $descEn" : ""}'
              : (descEn.isNotEmpty ? 'Step $stepNum: $descEn' : '');
          final stepTa = titleTa.isNotEmpty
              ? 'படி $stepNum: $titleTa${descTa.isNotEmpty ? " - $descTa" : ""}'
              : (descTa.isNotEmpty ? 'படி $stepNum: $descTa' : '');

          if (stepTa.isNotEmpty) {
            stepsList.add(stepTa);
          } else if (stepEn.isNotEmpty) {
            stepsList.add(stepEn);
          }
        } else if (step is String && step.isNotEmpty) {
          stepsList.add('Step ${i + 1}: $step');
        }
      }
    }

    if (stepsList.isEmpty) {
      final mode =
          (appProc['modeText'] as String?) ??
          (appProc['mode'] as String?) ??
          'Online';
      stepsList.add(
        'Step 1: Register and fill $mode application via $sponsoringBody portal',
      );
      if (appProc['onlineUrl'] != null &&
          (appProc['onlineUrl'] as String).isNotEmpty) {
        stepsList.add(
          'Step 2: Upload required documents online at ${appProc['onlineUrl']}',
        );
      } else {
        stepsList.add(
          'Step 2: Submit application copy and checklist documents to $issuingBody',
        );
      }
      stepsList.add(
        'Step 3: Verification & field inspection by District MSME Officer / Competent Authority',
      );
      stepsList.add(
        'Step 4: Approval and direct benefit transfer / subsidy credit to bank account',
      );
    }

    final serviceList = <SchemeService>[];
    final rawServices = _asList(
      appProc['services'] ?? content['services'] ?? content['requiredServices'],
    );
    if (rawServices != null && rawServices.isNotEmpty) {
      for (final sItem in rawServices) {
        if (sItem is Map<String, dynamic>) {
          final (sNameEn, sNameTa) = _extractMultilingualStr(
            sItem['name'] ?? sItem['title'],
          );
          final (sCatEn, sCatTa) = _extractMultilingualStr(
            sItem['category'],
            'Government Service',
          );
          final (sDescEn, sDescTa) = _extractMultilingualStr(
            sItem['description'],
          );
          final (sPurpEn, sPurpTa) = _extractMultilingualStr(sItem['purpose']);
          final (sDeptEn, sDeptTa) = _extractMultilingualStr(
            sItem['department'],
            issuingBody,
          );
          final (sNotesEn, sNotesTa) = _extractMultilingualStr(sItem['notes']);

          final finalServiceName = sNameEn.isNotEmpty
              ? sNameEn
              : (sNameTa.isNotEmpty ? sNameTa : 'Government Service');

          serviceList.add(
            SchemeService(
              name: finalServiceName,
              nameTa: sNameTa,
              category: sCatEn,
              categoryTa: sCatTa,
              mandatory:
                  sItem['mandatory'] == true ||
                  sItem['mandatory'] == 'required',
              description: sDescEn,
              descriptionTa: sDescTa,
              purpose: sPurpEn,
              purposeTa: sPurpTa,
              department: sDeptEn,
              departmentTa: sDeptTa,
              website: (sItem['website'] as String?) ?? '',
              contact: (sItem['contact'] as String?) ?? '',
              status: (sItem['status'] as String?) ?? 'ACTIVE',
              notes: sNotesEn,
              notesTa: sNotesTa,
            ),
          );
        }
      }
    }

    if (serviceList.isEmpty) {
      serviceList.add(
        SchemeService(
          name: '$issuingBody Application & Verification Service',
          category: 'Implementing Agency Service',
          mandatory: true,
          description:
              'Single-window application submission, document verification, and subsidy processing.',
          department: issuingBody,
          website:
              (appProc['onlineUrl'] as String?) ??
              (resources['officialWebsiteUrl'] as String?) ??
              '',
          status: 'ACTIVE',
        ),
      );
    }

    final applicationFee =
        (appProc['applicationFeeText'] as String?) ??
        (appProc['applicationFeeInr'] != null
            ? '₹${appProc['applicationFeeInr']}'
            : 'Nil');
    final processingDurationDays =
        appTimeline['processingDurationDays']?.toString() ?? '30';
    final intakeTimelineText =
        (appTimeline['text'] as String?) ??
        'Rolling intake throughout financial year';

    // ── 9. Graph Linking: Finance, Tax, Knowledge, Contacts ───────────
    final financeProducts = bundle.getFinanceProductsForScheme(entity);
    final financeProductsSummary = financeProducts
        .map(
          (f) =>
              '${f.getLocalizedName(langCode)} - ${f.content['summary'] ?? f.code}',
        )
        .toList();

    for (final fin in financeProducts) {
      final amountObj = fin.content['amount'] as Map<String, dynamic>?;
      if (amountObj != null) {
        if (amountObj['maxInr'] != null) {
          maxFunding ??= (amountObj['maxInr'] as num).toDouble();
        }
        if (amountObj['minInr'] != null) {
          minFunding ??= (amountObj['minInr'] as num).toDouble();
        }
        if (subsidyAmountText.isEmpty && amountObj['maxText'] != null) {
          subsidyAmountText = amountObj['maxText'] as String;
        }
      }
      final intRateObj = fin.content['interestRate'] as Map<String, dynamic>?;
      if (intRateObj != null && intRateObj['percent'] != null) {
        interestSubventionRate ??= (intRateObj['percent'] as num).toDouble();
      }
    }

    final taxProvisions = bundle.getTaxProvisionsForScheme(entity);
    final taxExemptionsSummary = taxProvisions
        .map((t) => '${t.getLocalizedName(langCode)} (${t.code})')
        .toList();
    final applicableTaxesList = taxProvisions
        .map((t) => (t.content['taxType'] as String?) ?? 'Income Tax')
        .toSet()
        .toList();

    final knowledgeItems = bundle.getKnowledgeItemsForScheme(entity);
    final knowledgeGuidanceList = knowledgeItems
        .map(
          (k) =>
              '${k.getLocalizedName(langCode)}: ${k.content['summary'] ?? ""}',
        )
        .toList();

    final faqList = <Map<String, String>>[];
    final rawFaqs = _asList(content['faqs']);
    if (rawFaqs != null) {
      for (final f in rawFaqs) {
        if (f is Map<String, dynamic>) {
          final q = _getLocalizedText(f['question'], langCode);
          final a = _getLocalizedText(f['answer'], langCode);
          if (q.isNotEmpty && a.isNotEmpty) {
            faqList.add({
              'question': q,
              'answer': a,
              'category': (f['category'] as String?) ?? '',
            });
          }
        }
      }
    }

    // ── 10. Official Links & Helplines ───────────────────────────────
    final sourcesList = _asList(content['sources']);
    String? officialWebsiteRaw =
        (resources['officialWebsiteUrl'] as String?) ??
        (resources['applicationPortalUrl'] as String?) ??
        (resources['schemePortalUrl'] as String?) ??
        (resources['portalUrl'] as String?) ??
        (appProc['onlineUrl'] as String?);

    String? guidelinesUrlRaw = (resources['guidelinesPdfUrl'] as String?);

    if (sourcesList != null) {
      for (final s in sourcesList) {
        if (s is Map<String, dynamic>) {
          final type = (s['sourceType'] as String? ?? '').toLowerCase();
          final url = s['url'] as String?;
          if (url != null && url.isNotEmpty) {
            if (officialWebsiteRaw == null || officialWebsiteRaw.isEmpty) {
              if (type.contains('website') ||
                  type.contains('portal') ||
                  s['isPrimary'] == true) {
                officialWebsiteRaw = url;
              }
            }
            if (guidelinesUrlRaw == null || guidelinesUrlRaw.isEmpty) {
              if (type.contains('guideline') ||
                  type.contains('pdf') ||
                  url.endsWith('.pdf')) {
                guidelinesUrlRaw = url;
              }
            }
          }
        }
      }
    }

    final officialWebsite =
        (officialWebsiteRaw != null && officialWebsiteRaw.trim().isNotEmpty)
        ? officialWebsiteRaw.trim()
        : 'https://tn.gov.in';
    final applicationUrl =
        (appProc['onlineUrl'] as String?) ??
        (resources['applicationPortalUrl'] as String?) ??
        officialWebsite;
    final guidelinesUrl = guidelinesUrlRaw ?? '';
    final logoUrl = (resources['logoUrl'] as String?) ?? '';

    final helplineContactsMap = <String, String>{};
    if (contactsObj['helplines'] is List) {
      for (final h in contactsObj['helplines']) {
        if (h is Map) {
          final title = h['title'] ?? h['name'] ?? 'Helpline';
          final phone = h['phone'] ?? h['number'] ?? '';
          if (phone.toString().isNotEmpty) {
            helplineContactsMap[title.toString()] = phone.toString();
          }
        }
      }
    }

    final searchKeywords =
        '$name $shortName $finalFullName $sponsoringBody $issuingBody $sector ${glanceChips.join(" ")}'
            .trim();

    return Scheme(
      id: entity.id,
      schemeCode: entity.code,
      name: name,
      nameTa: nameTa,
      shortName: shortName,
      fullSchemeName: finalFullName,
      ministry: ministry,
      department: department,
      implementingAgency: implementingAgency,
      matchScore: 1.0,
      logoUrl: logoUrl,
      officialSource: officialWebsite,
      governmentLevel: governmentLevel,
      sponsoringBody: sponsoringBody,
      issuingBody: issuingBody,
      state: state,
      sector: sector,
      targetBeneficiary: targetBeneficiary,
      schemeType: schemeType,
      category: category,
      overview: overviewEn,
      overviewTa: overviewTa,
      objectives: objectivesEn,
      benefits: rawBenefitsDisplayText,
      benefitsTa: benefitsTa,
      subsidyPercentage: subsidyPercentage,
      maxFunding: maxFunding,
      minFunding: minFunding,
      interestSubventionRate: interestSubventionRate,
      applicationMode:
          (appProc['modeText'] as String?) ??
          (appProc['mode'] as String?) ??
          'Online / Offline',
      officialWebsite: officialWebsite,
      applicationUrl: applicationUrl,
      guidelinesUrl: guidelinesUrl,
      sourceUrl: officialWebsite,
      districtApplicable: (gov['districtsText'] as String?) ?? '',
      subsidyAmount: subsidyAmountText,
      verificationStatus:
          (metadata['verificationStatus'] as String?) ?? 'VERIFIED',
      verificationNotes: (metadata['sourceNotes'] as String?) ?? '',
      lastUpdated: (metadata['updatedAt'] as String?) ?? '',
      searchKeywords: searchKeywords,
      status: statusStr,
      isActive: isActive,
      glanceChips: glanceChips.toList(),
      benefitTypesList: benefitTypesList,
      capitalSubsidyDetails: capitalSubsidyDetails,
      interestSubventionDetails: interestSubventionDetails,
      marginMoneyDetails: marginMoneyDetails,
      loanGuaranteeDetails: loanGuaranteeDetails,
      supportTypes: const [],
      rawBenefitsDisplayText: rawBenefitsDisplayText,
      eligibilityAgeRange: ageRange,
      turnoverLimits: turnoverLimits,
      investmentLimits: investmentLimits,
      allowedBusinessTypes: allowedBusinessTypes,
      educationRequirements: educationRequirements,
      mandatoryConditions: mandatoryConditions,
      optionalConditions: optionalConditions,
      specialCategories: specialCategories,
      applicationFee: applicationFee,
      processingDurationDays: processingDurationDays,
      intakeTimelineText: intakeTimelineText,
      financeProductsSummary: financeProductsSummary,
      taxExemptionsSummary: taxExemptionsSummary,
      applicableTaxesList: applicableTaxesList,
      knowledgeGuidanceList: knowledgeGuidanceList,
      helplineContactsMap: helplineContactsMap,
      eligibilityCriteria: elCriteriaList,
      requiredDocuments: reqDocNames,
      applicationProcess: stepsList,
      documents: docList,
      requiredServices: serviceList,
      faqs: faqList,
    );
  }
}
