import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/scheme_model.dart';
import '../models/user_profile.dart';
import 'intelligent_scheme_search.dart';
import 'mss_catalog_bundle.dart';
import 'mss_scheme_adapter.dart';
import '../engine/recommendation_engine.dart';

/// SchemeRepository
/// ─────────────────
/// Single source of truth for all scheme-related data.
/// Powered by the offline MssCatalogBundle as the primary data source.
class SchemeRepository {
  SchemeRepository._();
  static final SchemeRepository instance = SchemeRepository._();

  SupabaseClient get _db => Supabase.instance.client;

  // ── In-memory cache ──────────────────────────────────────────────────
  List<Scheme>? _cachedSchemes;
  Map<String, Scheme>? _schemeByIdMap;
  String? _cachedLanguage;
  Future<MssCatalogBundle>? _bundleFuture;
  Map<String, int>? _cachedCategoryCounts;

  void clearCache() {
    _cachedSchemes = null;
    _schemeByIdMap = null;
    _cachedLanguage = null;
    _bundleFuture = null;
    _cachedCategoryCounts = null;
  }

  /// Returns total number of schemes dynamically loaded from catalog.
  Future<int> getTotalSchemeCount() async {
    final schemes = await getAllSchemes();
    return schemes.length;
  }

  /// Returns top [limit] recommended schemes for user profile sorted by relevance score.
  Future<List<Scheme>> getTopRecommendedSchemes(
    UserProfile profile, {
    int limit = 5,
  }) async {
    final all = await getAllSchemes();
    final recommendations = RecommendationEngine.getRecommendations(profile, all);
    return recommendations
        .where((e) => e.value.score > 0)
        .map((e) => e.key)
        .take(limit)
        .toList();
  }

  /// Computes dynamic category scheme counts once and caches results.
  Future<Map<String, int>> getCategoryCounts(
    UserProfile profile, {
    String activeFilter = 'All',
  }) async {
    if (_cachedCategoryCounts != null && activeFilter == 'All') {
      return _cachedCategoryCounts!;
    }

    final Map<String, int> counts = {};
    final categoriesToQuery = [
      "MSME",
      "Startup",
      "Women Entrepreneurs",
      "Business Loans & Credit",
      "SHG & Artisan",
      "Technology",
      "Manufacturing",
      "Export & Trade Promotion",
    ];

    for (final cat in categoriesToQuery) {
      final matches = await getSchemesByCategory(cat);
      counts[cat] = matches.length;
    }

    if (activeFilter == 'All') {
      _cachedCategoryCounts = Map.unmodifiable(counts);
    }
    return counts;
  }

  /// Returns dynamic search hint prompt from loaded catalog entries.
  Future<String> getDynamicSearchHint([String langCode = 'en']) async {
    final all = await getAllSchemes();
    if (all.isEmpty) return 'PMEGP, Startup India, MSME loans...';
    final sample = (List<Scheme>.from(all)..shuffle()).first;
    final name = sample.getName(langCode);
    return name.isNotEmpty ? name : (sample.shortName.isNotEmpty ? sample.shortName : sample.name);
  }

  Future<MssCatalogBundle> _loadBundle() =>
      _bundleFuture ??= MssCatalogBundle.load();

  // ── 1. getAllSchemes() ────────────────────────────────────────────────
  /// Returns the complete curated catalog of schemes (217 records) for [langCode].
  Future<List<Scheme>> getAllSchemes({String langCode = 'en'}) async {
    if (_cachedSchemes != null && _cachedLanguage == langCode) {
      return _cachedSchemes!;
    }

    try {
      final bundle = await _loadBundle();
      final schemeEntities = bundle.schemes;

      final schemes = <Scheme>[];
      final byIdMap = <String, Scheme>{};

      for (final entity in schemeEntities) {
        final scheme = MssSchemeAdapter.toScheme(entity, bundle, langCode: langCode);
        schemes.add(scheme);
        byIdMap[scheme.id.toLowerCase()] = scheme;
        if (scheme.schemeCode.isNotEmpty) {
          byIdMap[scheme.schemeCode.toLowerCase()] = scheme;
        }
      }

      _cachedLanguage = langCode;
      _cachedSchemes = List.unmodifiable(schemes);
      _schemeByIdMap = Map.unmodifiable(byIdMap);
      return _cachedSchemes!;
    } catch (e) {
      debugPrint('[SchemeRepository] catalog bundle load error: $e');
      return _cachedSchemes ?? const [];
    }
  }

  // ── 2. searchSchemes(query) ────────────────────────────────────────────
  /// Intelligently ranks natural-language English, Tamil, and Tanglish queries.
  Future<List<Scheme>> searchSchemes(String query, {String langCode = 'en'}) async {
    if (query.trim().isEmpty) return getAllSchemes(langCode: langCode);
    final matches = await searchSchemeMatches(query, langCode: langCode);
    return matches.map((match) => match.scheme).toList(growable: false);
  }

  /// Returns scored matches for conversational search and voice result UIs.
  Future<List<SchemeSearchMatch>> searchSchemeMatches(
    String query, {
    int? limit,
    String langCode = 'en',
  }) async {
    final all = await getAllSchemes(langCode: langCode);
    return IntelligentSchemeSearch.rank(query, all, limit: limit);
  }

  // ── 3. getSchemesByCategory(category) ─────────────────────────────────
  /// Returns schemes matching a specific category key with exact & keyword metadata filtering.
  Future<List<Scheme>> getSchemesByCategory(String category, {String langCode = 'en'}) async {
    if (category.trim().isEmpty) return getAllSchemes(langCode: langCode);

    final q = category.toLowerCase().trim();
    final all = await getAllSchemes(langCode: langCode);

    final matches = all.where((s) {
      final cat = s.category.toLowerCase();
      final type = s.schemeType.toLowerCase();
      final target = s.targetBeneficiary.toLowerCase();
      final kw = s.searchKeywords.toLowerCase();
      final sector = s.sector.toLowerCase();
      final fullText = '${s.name} ${s.shortName} ${s.schemeType} ${s.category} ${s.sector} ${s.searchKeywords} ${s.overview} ${s.benefits}'.toLowerCase();

      // 1. Export Support / Trade
      if (q.contains('export') || q.contains('trade') || q.contains('foreign')) {
        return cat.contains('export') || sector.contains('export') || kw.contains('export') || fullText.contains('export') || fullText.contains('trade') || fullText.contains('dgft') || fullText.contains('customs') || fullText.contains('ship');
      }

      // 2. Grow Business / Expansion / Subsidy
      if (q.contains('grow') || q.contains('growth') || q.contains('expand') || q.contains('scaling')) {
        return cat.contains('msme') || cat.contains('business') || type.contains('subsidy') || kw.contains('growth') || fullText.contains('growth') || fullText.contains('expansion') || fullText.contains('moderniz') || fullText.contains('subsidy') || fullText.contains('technology') || fullText.contains('incentive') || fullText.contains('scale');
      }

      // 3. Find Funding / Finding Fund / Finance / Loan / Credit / Capital
      if (q.contains('fund') || q.contains('financ') || q.contains('loan') || q.contains('credit') || q.contains('capital') || q.contains('money')) {
        return type.contains('loan') ||
            cat.contains('loan') ||
            cat.contains('credit') ||
            cat.contains('finance') ||
            fullText.contains('loan') ||
            fullText.contains('credit') ||
            fullText.contains('fund') ||
            fullText.contains('mudra') ||
            fullText.contains('cgtmse') ||
            fullText.contains('capital') ||
            fullText.contains('grant') ||
            fullText.contains('subsidy') ||
            fullText.contains('working capital');
      }

      // 4. Start a Business / Startup / Launch / Incubator
      if (q.contains('start') || q.contains('launch') || q.contains('startup') || q.contains('incubat')) {
        return cat.contains('startup') || kw.contains('startup') || kw.contains('dpiit') || fullText.contains('incubator') || fullText.contains('seed fund') || fullText.contains('pmegp') || fullText.contains('mudra') || fullText.contains('entrepreneur') || fullText.contains('start') || fullText.contains('new business');
      }

      // 5. Udyam / Registration / Compliance
      if (q.contains('udyam') || q.contains('register')) {
        return cat.contains('msme') || fullText.contains('udyam') || fullText.contains('register') || fullText.contains('compliance') || fullText.contains('msme');
      }

      // 6. MSME
      if (q == 'msme' || q.contains('msme')) {
        return cat.contains('msme') || sector.contains('msme') || target.contains('msme') || fullText.contains('micro') || fullText.contains('udyam') || fullText.contains('small');
      }

      // 7. Women
      if (q.contains('women') || q.contains('female') || q.contains('mahila')) {
        return target.contains('women') || kw.contains('women') || target.contains('female') || fullText.contains('mahila') || fullText.contains('stree');
      }

      // 8. SHG / Artisan
      if (q.contains('shg') || q.contains('artisan') || q.contains('craft')) {
        return target.contains('artisan') || target.contains('shg') || kw.contains('vishwakarma') || kw.contains('weaver') || fullText.contains('craftsman');
      }

      // 9. Technology
      if (q.contains('tech') || q.contains('digital')) {
        return cat.contains('tech') || sector.contains('tech') || kw.contains('technology') || fullText.contains('digital') || fullText.contains('r&d');
      }

      // 10. Manufacturing
      if (q.contains('manufactur') || q.contains('factory') || q.contains('product')) {
        return sector.contains('manufactur') || cat.contains('manufactur') || kw.contains('manufacturing') || fullText.contains('production') || fullText.contains('factory');
      }

      // Word-level search fallback
      final words = q.split(' ').where((w) => w.length > 2);
      for (final w in words) {
        if (cat.contains(w) || sector.contains(w) || target.contains(w) || fullText.contains(w)) {
          return true;
        }
      }

      return cat.contains(q) || sector.contains(q) || target.contains(q) || fullText.contains(q);
    }).toList();

    if (matches.isEmpty) {
      return all.where((s) => s.category.toLowerCase().contains('business') || s.category.toLowerCase().contains('msme') || s.sector.toLowerCase().contains('msme')).toList();
    }

    return matches;
  }

  /// Returns schemes sponsored or issued by a given ministry/department.
  Future<List<Scheme>> getSchemesByMinistry(String ministry) async {
    if (ministry.trim().isEmpty) return getAllSchemes();

    final q = ministry.toLowerCase().trim();
    final all = await getAllSchemes();

    return all.where((s) {
      final sponsor = s.sponsoringBody.toLowerCase();
      final issuer = s.issuingBody.toLowerCase();
      final fullText = '${s.name} ${s.shortName} ${s.searchKeywords}'.toLowerCase();

      return sponsor.contains(q) || issuer.contains(q) || fullText.contains(q);
    }).toList();
  }

  /// Returns schemes applicable to a specific state or All India.
  Future<List<Scheme>> getSchemesByState(String state) async {
    if (state.trim().isEmpty) return getAllSchemes();

    final q = state.toLowerCase().trim();
    final all = await getAllSchemes();

    return all.where((s) {
      final st = s.state.toLowerCase();
      final code = s.schemeCode.toLowerCase();
      final name = s.name.toLowerCase();

      if (q.contains('tamil nadu') || q == 'tn') {
        return st.contains('tamil') || st.contains('tn') || code.contains('tn_') || name.contains('tamil');
      }

      return st.contains(q) || code.contains(q) || name.contains(q);
    }).toList();
  }

  // ── 4. getSchemeById(id) ───────────────────────────────────────────────
  /// Loads a Scheme by ID or Code in O(1) time.
  Future<Scheme?> getSchemeById(String id, {String langCode = 'en'}) async {
    if (id.trim().isEmpty) return null;
    await getAllSchemes(langCode: langCode);
    final key = id.trim().toLowerCase();
    final cached = _schemeByIdMap?[key];
    if (cached != null) return cached;

    // Fallback: Check bundle directly
    try {
      final bundle = await _loadBundle();
      final entity = bundle.getEntity(id);
      if (entity != null && entity.entityType == 'scheme') {
        return MssSchemeAdapter.toScheme(entity, bundle, langCode: langCode);
      }
    } catch (e) {
      debugPrint('[SchemeRepository] getSchemeById error: $e');
    }

    return null;
  }

  // ── 5. getRecommendedSchemes(profile) ─────────────────────────────────
  /// Returns schemes ranked by relevance to the user's profile.
  /// Scoring is done client-side over cached data for speed.
  Future<List<Scheme>> getRecommendedSchemes(UserProfile profile) async {
    final all = await getAllSchemes();

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
  /// Returns schemes for a list of bookmarked scheme IDs.
  Future<List<Scheme>> getSavedSchemes(List<String> bookmarkedIds) async {
    if (bookmarkedIds.isEmpty) return [];

    final all = await getAllSchemes();
    return all
        .where(
          (s) =>
              bookmarkedIds.contains(s.id) ||
              bookmarkedIds.contains(s.schemeCode),
        )
        .toList();
  }

  // ── 7. Profile Database Management Methods ────────────────────────────

  /// Retrieves a user profile by their UUID from public.profiles table.
  Future<UserProfile?> getProfile(String uid) async {
    try {
      final rows = await _db.from('profiles').select().eq('id', uid).limit(1);
      if ((rows as List).isEmpty) {
        debugPrint('[SchemeRepository] No profile found for user UUID: $uid');
        return null;
      }
      return UserProfile.fromJson(rows[0]);
    } catch (e) {
      debugPrint('[SchemeRepository] Error fetching profile: $e');
      return null;
    }
  }

  /// Creates a new profile record in the database.
  Future<void> createProfile(UserProfile profile) async {
    try {
      debugPrint(
        '[SchemeRepository] Creating profile for user UUID: ${profile.googleUserId}',
      );
      await _db.from('profiles').upsert(profile.toSupabase());
      debugPrint('[SchemeRepository] Profile successfully created.');
    } catch (e) {
      debugPrint('[SchemeRepository] Error creating profile: $e');
      rethrow;
    }
  }

  /// Updates an existing profile record in the database.
  Future<void> updateProfile(UserProfile profile) async {
    try {
      debugPrint(
        '[SchemeRepository] Updating profile for user UUID: ${profile.googleUserId}',
      );
      await _db
          .from('profiles')
          .update(profile.toSupabase())
          .eq('id', profile.googleUserId);
      debugPrint('[SchemeRepository] Profile successfully updated.');
    } catch (e) {
      debugPrint('[SchemeRepository] Error updating profile: $e');
      rethrow;
    }
  }

  /// Updates the last login timestamp for the user.
  Future<void> updateLastLogin(String uid) async {
    try {
      debugPrint(
        '[SchemeRepository] Updating last login timestamp for user UUID: $uid',
      );
      await _db
          .from('profiles')
          .update({'last_login_at': DateTime.now().toIso8601String()})
          .eq('id', uid);
      debugPrint(
        '[SchemeRepository] Last login timestamp successfully updated.',
      );
    } catch (e) {
      debugPrint('[SchemeRepository] Error updating last login: $e');
    }
  }
}
