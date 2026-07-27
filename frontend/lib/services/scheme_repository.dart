import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/scheme_model.dart';
import '../models/user_profile.dart';
import 'scheme_catalog.dart';

/// SchemeRepository
/// ─────────────────
/// Single source of truth for all scheme-related data. The curated bundled
/// catalog is loaded first so search and details work offline; Supabase remains
/// a fallback for deployments that provide additional database-only records.
class SchemeRepository {
  SchemeRepository._();
  static final SchemeRepository instance = SchemeRepository._();

  final SupabaseClient _db = Supabase.instance.client;

  // ── In-memory cache ──────────────────────────────────────────────────
  List<Scheme>? _cachedSchemes;
  Future<SchemeCatalog>? _catalogFuture;
  DateTime? _cacheTime;
  static const Duration _cacheTTL = Duration(minutes: 10);

  bool get _isCacheValid =>
      _cachedSchemes != null &&
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!) < _cacheTTL;

  void clearCache() {
    _cachedSchemes = null;
    _cacheTime = null;
    _catalogFuture = null;
  }

  Future<SchemeCatalog> _loadCatalog() =>
      _catalogFuture ??= SchemeCatalog.load();

  // ── 1. getAllSchemes() ────────────────────────────────────────────────
  /// Returns the complete curated catalog. Uses cache when valid.
  Future<List<Scheme>> getAllSchemes() async {
    if (_isCacheValid) return _cachedSchemes!;

    try {
      final catalog = await _loadCatalog();
      if (catalog.schemes.isNotEmpty) {
        _cachedSchemes = catalog.schemes;
        _cacheTime = DateTime.now();
        return _cachedSchemes!;
      }
    } catch (e) {
      debugPrint('[SchemeRepository] bundled catalog error: $e');
    }

    try {
      final rows = await _db
          .from('schemes')
          .select()
          .eq('is_active', true)
          .order('scheme_name');

      _cachedSchemes = (rows as List)
          .map((r) => Scheme.fromSupabase(r as Map<String, dynamic>))
          .toList();
      _cacheTime = DateTime.now();
      return _cachedSchemes!;
    } catch (e) {
      debugPrint('[SchemeRepository] getAllSchemes error: $e');
      return _cachedSchemes ?? [];
    }
  }

  // ── 2. searchSchemes(query) ────────────────────────────────────────────
  /// Full-text search across name, overview, keywords, category.
  Future<List<Scheme>> searchSchemes(String query) async {
    if (query.trim().isEmpty) return getAllSchemes();

    final q = query.toLowerCase().trim();
    final all = await getAllSchemes();

    return all.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.overview.toLowerCase().contains(q) ||
          s.searchKeywords.toLowerCase().contains(q) ||
          s.category.toLowerCase().contains(q) ||
          s.schemeCode.toLowerCase().contains(q) ||
          s.sponsoringBody.toLowerCase().contains(q) ||
          s.targetBeneficiary.toLowerCase().contains(q) ||
          s.sector.toLowerCase().contains(q);
    }).toList();
  }

  // ── 3. getSchemesByCategory(category) ─────────────────────────────────
  /// Returns schemes matching a broad category keyword.
  Future<List<Scheme>> getSchemesByCategory(String category) async {
    if (category.trim().isEmpty) return getAllSchemes();

    final q = category.toLowerCase().trim();
    final all = await getAllSchemes();

    return all.where((s) {
      return s.category.toLowerCase().contains(q) ||
          s.sector.toLowerCase().contains(q) ||
          s.targetBeneficiary.toLowerCase().contains(q) ||
          s.searchKeywords.toLowerCase().contains(q);
    }).toList();
  }

  // ── 4. getSchemeById(id) ───────────────────────────────────────────────
  /// Loads a fully enriched Scheme with eligibility, documents, and services.
  Future<Scheme?> getSchemeById(String id) async {
    try {
      final catalogScheme = (await _loadCatalog()).findById(id);
      if (catalogScheme != null) return catalogScheme;
    } catch (e) {
      debugPrint('[SchemeRepository] bundled scheme detail error: $e');
    }

    try {
      // Base scheme row
      final rows = await _db.from('schemes').select().eq('id', id).limit(1);

      if ((rows as List).isEmpty) return null;
      Scheme scheme = Scheme.fromSupabase(rows[0]);

      // Eligibility rules
      final eligibilityRows = await _db
          .from('eligibility_rules')
          .select('description, parameter_name, value')
          .eq('scheme_id', id);

      final eligibility = (eligibilityRows as List)
          .map((r) => r['description'] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toList();

      // Required documents via join
      final docRows = await _db
          .from('scheme_documents')
          .select('document_types(document_name)')
          .eq('scheme_id', id)
          .eq('is_mandatory', true);

      final documents = (docRows as List)
          .map((r) {
            final dt = r['document_types'] as Map<String, dynamic>?;
            return dt?['document_name'] as String? ?? '';
          })
          .where((s) => s.isNotEmpty)
          .toList();

      // Application process: stored as objectives text split by bullet points,
      // or derive from the seed keywords as fallback steps
      final steps = _deriveApplicationSteps(scheme);

      return scheme.copyWithDetails(
        eligibilityCriteria: eligibility.isNotEmpty
            ? eligibility
            : ['Please check official website for eligibility criteria.'],
        requiredDocuments: documents.isNotEmpty
            ? documents
            : ['Aadhaar Card', 'PAN Card', 'Project Report'],
        applicationProcess: steps,
        faqs: [],
      );
    } catch (e) {
      debugPrint('[SchemeRepository] getSchemeById error: $e');
      return null;
    }
  }

  // ── 5. getRecommendedSchemes(profile) ─────────────────────────────────
  /// Returns schemes ranked by relevance to the user's profile.
  /// Scoring is done client-side over cached data for speed.
  Future<List<Scheme>> getRecommendedSchemes(UserProfile profile) async {
    final all = await getAllSchemes();

    // Score each scheme against profile
    final scored = all.map((s) {
      double score = 0.5; // baseline

      final keywords = '${s.searchKeywords} ${s.targetBeneficiary} ${s.sector}'
          .toLowerCase();

      // State match
      if (s.state.toLowerCase() == 'all india') score += 0.1;
      if (profile.state.isNotEmpty &&
          s.state.toLowerCase().contains(profile.state.toLowerCase())) {
        score += 0.2;
      }

      // Gender match
      if (profile.gender.toLowerCase() == 'female' &&
          keywords.contains('women')) {
        score += 0.15;
      }

      // Community match
      if ((profile.community.toLowerCase() == 'sc' ||
              profile.community.toLowerCase() == 'st') &&
          (keywords.contains('sc/st') || keywords.contains('scheduled'))) {
        score += 0.15;
      }

      // Business / employment match
      if (profile.businessStage.isNotEmpty &&
          keywords.contains(profile.businessStage.toLowerCase())) {
        score += 0.15;
      }

      // Industry match
      if (profile.businessIndustry.isNotEmpty &&
          keywords.contains(profile.businessIndustry.toLowerCase())) {
        score += 0.1;
      }

      // Subsidy preference
      if ((profile.fundingRequired) > 0 &&
          s.maxFunding != null &&
          s.maxFunding! >= profile.fundingRequired) {
        score += 0.1;
      }

      return MapEntry(s, score.clamp(0.0, 1.0));
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }

  // ── 6. getSavedSchemes(bookmarkedIds) ─────────────────────────────────
  /// Returns schemes for a list of bookmarked scheme IDs (UUID strings).
  Future<List<Scheme>> getSavedSchemes(List<String> bookmarkedIds) async {
    if (bookmarkedIds.isEmpty) return [];

    final all = await getAllSchemes();
    // Match either by UUID (id) or by scheme_code for backwards compatibility
    return all
        .where(
          (s) =>
              bookmarkedIds.contains(s.id) ||
              bookmarkedIds.contains(s.schemeCode),
        )
        .toList();
  }

  // ── Helper: derive simple application steps from description ──────────
  List<String> _deriveApplicationSteps(Scheme scheme) {
    if (scheme.applicationMode.toLowerCase().contains('online')) {
      return [
        'Visit the official portal: ${scheme.officialWebsite.isNotEmpty ? scheme.officialWebsite : 'india.gov.in'}',
        'Register or log in with your Aadhaar / mobile number.',
        'Fill in the online application form with all required details.',
        'Upload scanned copies of all mandatory documents.',
        'Submit the application and note your application reference number.',
        'Track your application status via the portal or helpdesk.',
      ];
    } else if (scheme.applicationMode.toLowerCase().contains('bank')) {
      return [
        'Visit your nearest branch of a member bank or NBFC.',
        'Collect the application form for this scheme.',
        'Fill in all required fields and attach self-attested documents.',
        'Submit the form at the bank branch for preliminary scrutiny.',
        'The bank processes and forwards the proposal to the nodal agency.',
        'Receive sanction letter and complete any further formalities.',
      ];
    } else {
      return [
        'Collect application form from the District Industries Centre (DIC) or designated office.',
        'Fill in the application with complete details and attach required documents.',
        'Submit the application at the designated office.',
        'Application is scrutinized by the selection committee.',
        'Attend an interview/presentation if required.',
        'Receive approval and complete post-approval formalities.',
      ];
    }
  }
}
