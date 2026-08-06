class SchemeDocument {
  final String name;
  final String mandatory;
  final String issuingAuthority;
  final String description;
  final String estimatedCost;
  final String remarks;
  final String sourceUrl;
  final String validityMonths;
  final String downloadTemplateUrl;
  final String sampleCopyUrl;
  final String verificationPortalUrl;

  const SchemeDocument({
    required this.name,
    this.mandatory = '',
    this.issuingAuthority = '',
    this.description = '',
    this.estimatedCost = '',
    this.remarks = '',
    this.sourceUrl = '',
    this.validityMonths = '',
    this.downloadTemplateUrl = '',
    this.sampleCopyUrl = '',
    this.verificationPortalUrl = '',
  });

  bool get isMandatory =>
      mandatory.toLowerCase() == 'yes' || mandatory.toLowerCase() == 'required';
}

class SchemeService {
  final String name;
  final String category;
  final bool mandatory;
  final String description;
  final String purpose;
  final String department;
  final String website;
  final String contact;
  final String status;
  final String notes;

  const SchemeService({
    required this.name,
    this.category = '',
    this.mandatory = false,
    this.description = '',
    this.purpose = '',
    this.department = '',
    this.website = '',
    this.contact = '',
    this.status = 'ACTIVE',
    this.notes = '',
  });
}

/// Unified scheme model populated by the bundled catalog, with Supabase kept
/// as a backwards-compatible fallback in [SchemeRepository].
class Scheme {
  final String id; // Stable catalog code or Supabase UUID
  final String schemeCode; // e.g. "IN001"
  final String name;
  final String shortName;
  final String fullSchemeName;
  final String ministry;
  final String department;
  final String implementingAgency;
  final double matchScore;
  final String logoUrl;
  final String officialSource;
  final String governmentLevel; // Central / State
  final String sponsoringBody; // issuing_department
  final String issuingBody; // issuing_body (implementing agency)
  final String state;
  final String sector;
  final String targetBeneficiary;
  final String schemeType; // assistance_type
  final String category;
  final String overview; // maps to "overview" column
  final String objectives;
  final String benefits; // benefits_description
  final double? subsidyPercentage;
  final double? maxFunding;
  final double? minFunding;
  final double? interestSubventionRate;
  final String applicationMode;
  final String officialWebsite;
  final String applicationUrl;
  final String guidelinesUrl;
  final String sourceUrl;
  final String districtApplicable;
  final String subsidyAmount;
  final String verificationStatus;
  final String verificationNotes;
  final String lastUpdated;
  final String searchKeywords;
  final String status;
  final bool isActive;

  // Phase 5 At-a-Glance Chips
  final List<String> glanceChips;

  // Phase 5 Benefits & Funding Breakdown
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

  // Phase 5 Linked Graph Extensions (Finance, Tax, Knowledge, Helplines)
  final List<String> financeProductsSummary;
  final List<String> taxExemptionsSummary;
  final List<String> applicableTaxesList;
  final List<String> knowledgeGuidanceList;
  final Map<String, String> helplineContactsMap;

  // Joined / enriched fields (populated on detail load)
  final List<String> eligibilityCriteria;
  final List<String> requiredDocuments;
  final List<String> applicationProcess;
  final List<SchemeDocument> documents;
  final List<SchemeService> requiredServices;
  final List<Map<String, String>> faqs;

  const Scheme({
    required this.id,
    this.schemeCode = '',
    required this.name,
    this.shortName = '',
    this.fullSchemeName = '',
    this.ministry = '',
    this.department = '',
    this.implementingAgency = '',
    this.matchScore = 1.0,
    this.logoUrl = '',
    this.officialSource = '',
    this.governmentLevel = 'Central',
    this.sponsoringBody = '',
    this.issuingBody = '',
    this.state = 'All India',
    this.sector = '',
    this.targetBeneficiary = '',
    this.schemeType = '',
    this.category = '',
    this.overview = '',
    this.objectives = '',
    this.benefits = '',
    this.subsidyPercentage,
    this.maxFunding,
    this.minFunding,
    this.interestSubventionRate,
    this.applicationMode = '',
    this.officialWebsite = '',
    this.applicationUrl = '',
    this.guidelinesUrl = '',
    this.sourceUrl = '',
    this.districtApplicable = '',
    this.subsidyAmount = '',
    this.verificationStatus = '',
    this.verificationNotes = '',
    this.lastUpdated = '',
    this.searchKeywords = '',
    this.status = 'ACTIVE',
    this.isActive = true,
    this.glanceChips = const [],
    this.benefitTypesList = const [],
    this.capitalSubsidyDetails = '',
    this.interestSubventionDetails = '',
    this.marginMoneyDetails = '',
    this.loanGuaranteeDetails = '',
    this.supportTypes = const [],
    this.rawBenefitsDisplayText = '',
    this.eligibilityAgeRange = '',
    this.turnoverLimits = '',
    this.investmentLimits = '',
    this.allowedBusinessTypes = const [],
    this.educationRequirements = '',
    this.mandatoryConditions = const [],
    this.optionalConditions = const [],
    this.specialCategories = const [],
    this.applicationFee = '',
    this.processingDurationDays = '',
    this.intakeTimelineText = '',
    this.financeProductsSummary = const [],
    this.taxExemptionsSummary = const [],
    this.applicableTaxesList = const [],
    this.knowledgeGuidanceList = const [],
    this.helplineContactsMap = const {},
    this.eligibilityCriteria = const [],
    this.requiredDocuments = const [],
    this.applicationProcess = const [],
    this.documents = const [],
    this.requiredServices = const [],
    this.faqs = const [],
  });

  /// Build a Scheme from a Supabase row (public.schemes table).
  factory Scheme.fromSupabase(Map<String, dynamic> row) {
    return Scheme(
      id: row['id'] as String? ?? '',
      schemeCode: row['scheme_code'] as String? ?? '',
      name: row['scheme_name'] as String? ?? '',
      governmentLevel: row['government_level'] as String? ?? 'Central',
      sponsoringBody: row['issuing_department'] as String? ?? '',
      issuingBody: row['issuing_body'] as String? ?? '',
      state: row['state'] as String? ?? 'All India',
      sector: row['target_sector'] as String? ?? '',
      targetBeneficiary: row['target_beneficiary'] as String? ?? '',
      schemeType: row['scheme_type'] as String? ?? '',
      category: row['scheme_category'] as String? ?? '',
      overview: row['overview'] as String? ?? '',
      objectives: row['objectives'] as String? ?? '',
      benefits: row['benefits_description'] as String? ?? '',
      subsidyPercentage: (row['subsidy_percentage'] as num?)?.toDouble(),
      maxFunding: (row['max_funding_amount'] as num?)?.toDouble(),
      minFunding: (row['minimum_funding_amount'] as num?)?.toDouble(),
      interestSubventionRate: (row['interest_subvention_rate'] as num?)
          ?.toDouble(),
      applicationMode: row['application_mode'] as String? ?? '',
      officialWebsite: row['official_website'] as String? ?? '',
      applicationUrl: row['application_url'] as String? ?? '',
      guidelinesUrl: row['guidelines_url'] as String? ?? '',
      sourceUrl: row['source_url'] as String? ?? '',
      districtApplicable: row['district_applicable'] as String? ?? '',
      subsidyAmount:
          row['subsidy_amount_display']?.toString() ??
          row['subsidy_amount']?.toString() ??
          '',
      verificationStatus: row['verification_status']?.toString() ?? '',
      verificationNotes: row['verification_notes']?.toString() ?? '',
      lastUpdated:
          row['source_last_updated']?.toString() ??
          row['last_updated']?.toString() ??
          '',
      searchKeywords: row['search_keywords'] as String? ?? '',
      status: row['status'] as String? ?? 'ACTIVE',
      isActive: row['is_active'] as bool? ?? true,
    );
  }

  /// Returns a copy with enriched detail fields (eligibility, documents, etc.)
  Scheme copyWithDetails({
    List<String>? eligibilityCriteria,
    List<String>? requiredDocuments,
    List<String>? applicationProcess,
    List<SchemeDocument>? documents,
    List<SchemeService>? requiredServices,
    List<Map<String, String>>? faqs,
    List<String>? glanceChips,
    List<String>? benefitTypesList,
    String? capitalSubsidyDetails,
    String? interestSubventionDetails,
    String? marginMoneyDetails,
    String? loanGuaranteeDetails,
    List<String>? supportTypes,
    String? rawBenefitsDisplayText,
    String? eligibilityAgeRange,
    String? turnoverLimits,
    String? investmentLimits,
    List<String>? allowedBusinessTypes,
    String? educationRequirements,
    List<String>? mandatoryConditions,
    List<String>? optionalConditions,
    List<String>? specialCategories,
    String? applicationFee,
    String? processingDurationDays,
    String? intakeTimelineText,
    List<String>? financeProductsSummary,
    List<String>? taxExemptionsSummary,
    List<String>? applicableTaxesList,
    List<String>? knowledgeGuidanceList,
    Map<String, String>? helplineContactsMap,
  }) {
    return Scheme(
      id: id,
      schemeCode: schemeCode,
      name: name,
      shortName: shortName,
      fullSchemeName: fullSchemeName,
      ministry: ministry,
      department: department,
      implementingAgency: implementingAgency,
      matchScore: matchScore,
      logoUrl: logoUrl,
      officialSource: officialSource,
      governmentLevel: governmentLevel,
      sponsoringBody: sponsoringBody,
      issuingBody: issuingBody,
      state: state,
      sector: sector,
      targetBeneficiary: targetBeneficiary,
      schemeType: schemeType,
      category: category,
      overview: overview,
      objectives: objectives,
      benefits: benefits,
      subsidyPercentage: subsidyPercentage,
      maxFunding: maxFunding,
      minFunding: minFunding,
      interestSubventionRate: interestSubventionRate,
      applicationMode: applicationMode,
      officialWebsite: officialWebsite,
      applicationUrl: applicationUrl,
      guidelinesUrl: guidelinesUrl,
      sourceUrl: sourceUrl,
      districtApplicable: districtApplicable,
      subsidyAmount: subsidyAmount,
      verificationStatus: verificationStatus,
      verificationNotes: verificationNotes,
      lastUpdated: lastUpdated,
      searchKeywords: searchKeywords,
      status: status,
      isActive: isActive,
      glanceChips: glanceChips ?? this.glanceChips,
      benefitTypesList: benefitTypesList ?? this.benefitTypesList,
      capitalSubsidyDetails: capitalSubsidyDetails ?? this.capitalSubsidyDetails,
      interestSubventionDetails: interestSubventionDetails ?? this.interestSubventionDetails,
      marginMoneyDetails: marginMoneyDetails ?? this.marginMoneyDetails,
      loanGuaranteeDetails: loanGuaranteeDetails ?? this.loanGuaranteeDetails,
      supportTypes: supportTypes ?? this.supportTypes,
      rawBenefitsDisplayText: rawBenefitsDisplayText ?? this.rawBenefitsDisplayText,
      eligibilityAgeRange: eligibilityAgeRange ?? this.eligibilityAgeRange,
      turnoverLimits: turnoverLimits ?? this.turnoverLimits,
      investmentLimits: investmentLimits ?? this.investmentLimits,
      allowedBusinessTypes: allowedBusinessTypes ?? this.allowedBusinessTypes,
      educationRequirements: educationRequirements ?? this.educationRequirements,
      mandatoryConditions: mandatoryConditions ?? this.mandatoryConditions,
      optionalConditions: optionalConditions ?? this.optionalConditions,
      specialCategories: specialCategories ?? this.specialCategories,
      applicationFee: applicationFee ?? this.applicationFee,
      processingDurationDays: processingDurationDays ?? this.processingDurationDays,
      intakeTimelineText: intakeTimelineText ?? this.intakeTimelineText,
      financeProductsSummary: financeProductsSummary ?? this.financeProductsSummary,
      taxExemptionsSummary: taxExemptionsSummary ?? this.taxExemptionsSummary,
      applicableTaxesList: applicableTaxesList ?? this.applicableTaxesList,
      knowledgeGuidanceList: knowledgeGuidanceList ?? this.knowledgeGuidanceList,
      helplineContactsMap: helplineContactsMap ?? this.helplineContactsMap,
      eligibilityCriteria: eligibilityCriteria ?? this.eligibilityCriteria,
      requiredDocuments: requiredDocuments ?? this.requiredDocuments,
      applicationProcess: applicationProcess ?? this.applicationProcess,
      documents: documents ?? this.documents,
      requiredServices: requiredServices ?? this.requiredServices,
      faqs: faqs ?? this.faqs,
    );
  }
}

