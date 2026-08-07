import '../services/centralized_translator.dart';
import 'scheme_model.dart';

/// LocalizedScheme
/// ─────────────────
/// Centralized wrapper for [Scheme] that exposes pre-localized fields
/// for the active language. UI widgets consume this object directly,
/// eliminating all inline widget translation logic.
class LocalizedScheme {
  final Scheme rawScheme;
  final String languageCode;

  final String name;
  final String shortName;
  final String fullSchemeName;
  final String ministry;
  final String department;
  final String implementingAgency;
  final String governmentLevel;
  final String sponsoringBody;
  final String issuingBody;
  final String state;
  final String sector;
  final String targetBeneficiary;
  final String schemeType;
  final String category;
  final String overview;
  final String objectives;
  final String benefits;
  final String subsidyAmount;
  final String verificationStatus;
  final String verificationNotes;
  final String lastUpdated;

  // Phase 5 Benefits & Funding Breakdown
  final List<String> glanceChips;
  final List<String> benefitTypesList;
  final String capitalSubsidyDetails;
  final String interestSubventionDetails;
  final String marginMoneyDetails;
  final String loanGuaranteeDetails;
  final List<String> supportTypes;
  final String rawBenefitsDisplayText;

  // Phase 5 Detailed Eligibility Breakdown
  final String eligibilityAgeRange;
  final String turnoverLimits;
  final String investmentLimits;
  final List<String> allowedBusinessTypes;
  final String educationRequirements;
  final List<String> mandatoryConditions;
  final List<String> optionalConditions;
  final List<String> specialCategories;

  // Phase 5 Application Timeline & Services
  final String applicationFee;
  final String processingDurationDays;
  final String intakeTimelineText;

  // Phase 5 Linked Graph Extensions
  final List<String> financeProductsSummary;
  final List<String> taxExemptionsSummary;
  final List<String> applicableTaxesList;
  final List<String> knowledgeGuidanceList;
  final Map<String, String> helplineContactsMap;

  // Joined / enriched fields
  final List<String> eligibilityCriteria;
  final List<String> requiredDocuments;
  final List<String> applicationProcess;
  final List<SchemeDocument> documents;
  final List<SchemeService> requiredServices;
  final List<Map<String, String>> faqs;

  // Pass-through getters for non-text / protected attributes
  String get id => rawScheme.id;
  String get schemeCode => rawScheme.schemeCode;
  double get matchScore => rawScheme.matchScore;
  String get logoUrl => rawScheme.logoUrl;
  String get officialSource => rawScheme.officialSource;
  double? get subsidyPercentage => rawScheme.subsidyPercentage;
  double? get maxFunding => rawScheme.maxFunding;
  double? get minFunding => rawScheme.minFunding;
  double? get interestSubventionRate => rawScheme.interestSubventionRate;
  String get applicationMode => rawScheme.applicationMode;
  String get officialWebsite => rawScheme.officialWebsite;
  String get applicationUrl => rawScheme.applicationUrl;
  String get guidelinesUrl => rawScheme.guidelinesUrl;
  String get sourceUrl => rawScheme.sourceUrl;
  String get districtApplicable => rawScheme.districtApplicable;
  String get searchKeywords => rawScheme.searchKeywords;
  String get status => rawScheme.status;
  bool get isActive => rawScheme.isActive;

  const LocalizedScheme._({
    required this.rawScheme,
    required this.languageCode,
    required this.name,
    required this.shortName,
    required this.fullSchemeName,
    required this.ministry,
    required this.department,
    required this.implementingAgency,
    required this.governmentLevel,
    required this.sponsoringBody,
    required this.issuingBody,
    required this.state,
    required this.sector,
    required this.targetBeneficiary,
    required this.schemeType,
    required this.category,
    required this.overview,
    required this.objectives,
    required this.benefits,
    required this.subsidyAmount,
    required this.verificationStatus,
    required this.verificationNotes,
    required this.lastUpdated,
    required this.glanceChips,
    required this.benefitTypesList,
    required this.capitalSubsidyDetails,
    required this.interestSubventionDetails,
    required this.marginMoneyDetails,
    required this.loanGuaranteeDetails,
    required this.supportTypes,
    required this.rawBenefitsDisplayText,
    required this.eligibilityAgeRange,
    required this.turnoverLimits,
    required this.investmentLimits,
    required this.allowedBusinessTypes,
    required this.educationRequirements,
    required this.mandatoryConditions,
    required this.optionalConditions,
    required this.specialCategories,
    required this.applicationFee,
    required this.processingDurationDays,
    required this.intakeTimelineText,
    required this.financeProductsSummary,
    required this.taxExemptionsSummary,
    required this.applicableTaxesList,
    required this.knowledgeGuidanceList,
    required this.helplineContactsMap,
    required this.eligibilityCriteria,
    required this.requiredDocuments,
    required this.applicationProcess,
    required this.documents,
    required this.requiredServices,
    required this.faqs,
  });

  factory LocalizedScheme.fromScheme(Scheme scheme, String languageCode) {
    if (languageCode != 'ta') {
      return LocalizedScheme._(
        rawScheme: scheme,
        languageCode: languageCode,
        name: scheme.name,
        shortName: scheme.shortName,
        fullSchemeName: scheme.fullSchemeName,
        ministry: scheme.ministry,
        department: scheme.department,
        implementingAgency: scheme.implementingAgency,
        governmentLevel: scheme.governmentLevel,
        sponsoringBody: scheme.sponsoringBody,
        issuingBody: scheme.issuingBody,
        state: scheme.state,
        sector: scheme.sector,
        targetBeneficiary: scheme.targetBeneficiary,
        schemeType: scheme.schemeType,
        category: scheme.category,
        overview: scheme.overview,
        objectives: scheme.objectives,
        benefits: scheme.benefits,
        subsidyAmount: scheme.subsidyAmount,
        verificationStatus: scheme.verificationStatus,
        verificationNotes: scheme.verificationNotes,
        lastUpdated: scheme.lastUpdated,
        glanceChips: scheme.glanceChips,
        benefitTypesList: scheme.benefitTypesList,
        capitalSubsidyDetails: scheme.capitalSubsidyDetails,
        interestSubventionDetails: scheme.interestSubventionDetails,
        marginMoneyDetails: scheme.marginMoneyDetails,
        loanGuaranteeDetails: scheme.loanGuaranteeDetails,
        supportTypes: scheme.supportTypes,
        rawBenefitsDisplayText: scheme.rawBenefitsDisplayText,
        eligibilityAgeRange: scheme.eligibilityAgeRange,
        turnoverLimits: scheme.turnoverLimits,
        investmentLimits: scheme.investmentLimits,
        allowedBusinessTypes: scheme.allowedBusinessTypes,
        educationRequirements: scheme.educationRequirements,
        mandatoryConditions: scheme.mandatoryConditions,
        optionalConditions: scheme.optionalConditions,
        specialCategories: scheme.specialCategories,
        applicationFee: scheme.applicationFee,
        processingDurationDays: scheme.processingDurationDays,
        intakeTimelineText: scheme.intakeTimelineText,
        financeProductsSummary: scheme.financeProductsSummary,
        taxExemptionsSummary: scheme.taxExemptionsSummary,
        applicableTaxesList: scheme.applicableTaxesList,
        knowledgeGuidanceList: scheme.knowledgeGuidanceList,
        helplineContactsMap: scheme.helplineContactsMap,
        eligibilityCriteria: scheme.eligibilityCriteria,
        requiredDocuments: scheme.requiredDocuments,
        applicationProcess: scheme.applicationProcess,
        documents: scheme.documents,
        requiredServices: scheme.requiredServices,
        faqs: scheme.faqs,
      );
    }

    final translator = CentralizedTranslator.instance;

    // Priority 1: Use catalog JSON Tamil values if non-empty;
    // Priority 2: Use CentralizedTranslator on English fields;
    // Priority 3: Fallback / Protected fields preserved.
    final nameTa = scheme.nameTa.trim();
    final name = nameTa.isNotEmpty ? nameTa : translator.translate(scheme.name);

    final overviewTa = scheme.overviewTa.trim();
    final overview = overviewTa.isNotEmpty
        ? overviewTa
        : translator.translate(scheme.overview);

    final benefitsTa = scheme.benefitsTa.trim();
    final benefits = benefitsTa.isNotEmpty
        ? benefitsTa
        : translator.translate(scheme.benefits);

    return LocalizedScheme._(
      rawScheme: scheme,
      languageCode: 'ta',
      name: name,
      shortName: translator.translateTag(scheme.shortName),
      fullSchemeName: nameTa.isNotEmpty
          ? nameTa
          : translator.translate(scheme.fullSchemeName),
      ministry: translator.translate(scheme.ministry),
      department: translator.translate(scheme.department),
      implementingAgency: translator.translate(scheme.implementingAgency),
      governmentLevel: translator.translateTag(scheme.governmentLevel),
      sponsoringBody: translator.translate(scheme.sponsoringBody),
      issuingBody: translator.translate(scheme.issuingBody),
      state: translator.translateTag(scheme.state),
      sector: translator.translateTag(scheme.sector),
      targetBeneficiary: translator.translate(scheme.targetBeneficiary),
      schemeType: translator.translateTag(scheme.schemeType),
      category: translator.translateTag(scheme.category),
      overview: overview,
      objectives: translator.translate(scheme.objectives),
      benefits: benefits,
      subsidyAmount: translator.translate(scheme.subsidyAmount),
      verificationStatus: translator.translate(scheme.verificationStatus),
      verificationNotes: translator.translate(scheme.verificationNotes),
      lastUpdated: scheme.lastUpdated,
      glanceChips: scheme.glanceChips.map(translator.translateTag).toList(),
      benefitTypesList: scheme.benefitTypesList
          .map(translator.translateTag)
          .toList(),
      capitalSubsidyDetails: translator.translate(scheme.capitalSubsidyDetails),
      interestSubventionDetails: translator.translate(
        scheme.interestSubventionDetails,
      ),
      marginMoneyDetails: translator.translate(scheme.marginMoneyDetails),
      loanGuaranteeDetails: translator.translate(scheme.loanGuaranteeDetails),
      supportTypes: scheme.supportTypes.map(translator.translateTag).toList(),
      rawBenefitsDisplayText: translator.translate(
        scheme.rawBenefitsDisplayText,
      ),
      eligibilityAgeRange: translator.translate(scheme.eligibilityAgeRange),
      turnoverLimits: translator.translate(scheme.turnoverLimits),
      investmentLimits: translator.translate(scheme.investmentLimits),
      allowedBusinessTypes: scheme.allowedBusinessTypes
          .map(translator.translateTag)
          .toList(),
      educationRequirements: translator.translate(scheme.educationRequirements),
      mandatoryConditions: scheme.mandatoryConditions
          .map(translator.translate)
          .toList(),
      optionalConditions: scheme.optionalConditions
          .map(translator.translate)
          .toList(),
      specialCategories: scheme.specialCategories
          .map(translator.translateTag)
          .toList(),
      applicationFee: translator.translate(scheme.applicationFee),
      processingDurationDays: translator.translate(
        scheme.processingDurationDays,
      ),
      intakeTimelineText: translator.translate(scheme.intakeTimelineText),
      financeProductsSummary: scheme.financeProductsSummary
          .map(translator.translate)
          .toList(),
      taxExemptionsSummary: scheme.taxExemptionsSummary
          .map(translator.translate)
          .toList(),
      applicableTaxesList: scheme.applicableTaxesList
          .map(translator.translateTag)
          .toList(),
      knowledgeGuidanceList: scheme.knowledgeGuidanceList
          .map(translator.translate)
          .toList(),
      helplineContactsMap: scheme.helplineContactsMap,
      eligibilityCriteria: scheme.eligibilityCriteria
          .map(translator.translate)
          .toList(),
      requiredDocuments: scheme.requiredDocuments
          .map(translator.translate)
          .toList(),
      applicationProcess: scheme.applicationProcess
          .map(translator.translate)
          .toList(),
      documents: scheme.documents
          .map(
            (d) => d.copyWith(
              name: d.nameTa.isNotEmpty
                  ? d.nameTa
                  : translator.translate(d.name),
              description: d.descriptionTa.isNotEmpty
                  ? d.descriptionTa
                  : translator.translate(d.description),
              issuingAuthority: d.issuingAuthorityTa.isNotEmpty
                  ? d.issuingAuthorityTa
                  : translator.translate(d.issuingAuthority),
              estimatedCost: d.estimatedCostTa.isNotEmpty
                  ? d.estimatedCostTa
                  : translator.translate(d.estimatedCost),
              mandatory: d.mandatoryTa.isNotEmpty
                  ? d.mandatoryTa
                  : translator.translateTag(d.mandatory),
              remarks: d.remarksTa.isNotEmpty
                  ? d.remarksTa
                  : translator.translate(d.remarks),
            ),
          )
          .toList(),
      requiredServices: scheme.requiredServices
          .map(
            (s) => SchemeService(
              name: s.nameTa.isNotEmpty
                  ? s.nameTa
                  : translator.translate(s.name),
              nameTa: s.nameTa,
              category: s.categoryTa.isNotEmpty
                  ? s.categoryTa
                  : translator.translateTag(s.category),
              categoryTa: s.categoryTa,
              mandatory: s.mandatory,
              description: s.descriptionTa.isNotEmpty
                  ? s.descriptionTa
                  : translator.translate(s.description),
              descriptionTa: s.descriptionTa,
              purpose: s.purposeTa.isNotEmpty
                  ? s.purposeTa
                  : translator.translate(s.purpose),
              purposeTa: s.purposeTa,
              department: s.departmentTa.isNotEmpty
                  ? s.departmentTa
                  : translator.translate(s.department),
              departmentTa: s.departmentTa,
              website: s.website,
              contact: s.contact,
              status: s.status,
              notes: s.notesTa.isNotEmpty
                  ? s.notesTa
                  : translator.translate(s.notes),
              notesTa: s.notesTa,
            ),
          )
          .toList(),
      faqs: scheme.faqs
          .map(
            (faq) => {
              'question': translator.translate(faq['question'] ?? ''),
              'answer': translator.translate(faq['answer'] ?? ''),
            },
          )
          .toList(),
    );
  }
}

extension SchemeLocalizationExtension on Scheme {
  LocalizedScheme toLocalized(String languageCode) {
    return LocalizedScheme.fromScheme(this, languageCode);
  }
}
