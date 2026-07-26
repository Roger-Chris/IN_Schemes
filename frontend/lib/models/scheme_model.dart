/// Scheme model - maps directly to public.schemes in Supabase.
/// The static seedData has been removed. All data comes from the database
/// via SchemeRepository.
class Scheme {
  final String id;           // UUID from Supabase
  final String schemeCode;   // e.g. "TN_NEEDS_001"
  final String name;
  final String governmentLevel; // Central / State
  final String sponsoringBody;  // issuing_department
  final String issuingBody;     // issuing_body (implementing agency)
  final String state;
  final String sector;
  final String targetBeneficiary;
  final String schemeType;      // assistance_type
  final String category;
  final String overview;        // maps to "overview" column
  final String objectives;
  final String benefits;        // benefits_description
  final double? subsidyPercentage;
  final double? maxFunding;
  final double? minFunding;
  final double? interestSubventionRate;
  final String applicationMode;
  final String officialWebsite;
  final String applicationUrl;
  final String searchKeywords;
  final String status;
  final bool isActive;

  // Joined / enriched fields (populated on detail load)
  final List<String> eligibilityCriteria;
  final List<String> requiredDocuments;
  final List<String> applicationProcess;
  final List<Map<String, String>> faqs;

  const Scheme({
    required this.id,
    this.schemeCode = '',
    required this.name,
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
    this.searchKeywords = '',
    this.status = 'ACTIVE',
    this.isActive = true,
    this.eligibilityCriteria = const [],
    this.requiredDocuments = const [],
    this.applicationProcess = const [],
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
      interestSubventionRate: (row['interest_subvention_rate'] as num?)?.toDouble(),
      applicationMode: row['application_mode'] as String? ?? '',
      officialWebsite: row['official_website'] as String? ?? '',
      applicationUrl: row['application_url'] as String? ?? '',
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
    List<Map<String, String>>? faqs,
  }) {
    return Scheme(
      id: id,
      schemeCode: schemeCode,
      name: name,
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
      searchKeywords: searchKeywords,
      status: status,
      isActive: isActive,
      eligibilityCriteria: eligibilityCriteria ?? this.eligibilityCriteria,
      requiredDocuments: requiredDocuments ?? this.requiredDocuments,
      applicationProcess: applicationProcess ?? this.applicationProcess,
      faqs: faqs ?? this.faqs,
    );
  }
}
