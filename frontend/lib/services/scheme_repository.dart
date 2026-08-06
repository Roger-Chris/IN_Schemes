import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/scheme_model.dart';
import '../models/user_profile.dart';
import 'intelligent_scheme_search.dart';
import 'mss_catalog_bundle.dart';
import 'mss_scheme_adapter.dart';

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
  Future<MssCatalogBundle>? _bundleFuture;

  void clearCache() {
    _cachedSchemes = null;
    _schemeByIdMap = null;
    _bundleFuture = null;
  }

  Future<MssCatalogBundle> _loadBundle() =>
      _bundleFuture ??= MssCatalogBundle.load();

  // ── 1. getAllSchemes() ────────────────────────────────────────────────
  /// Returns the complete curated catalog of schemes (217 records).
  Future<List<Scheme>> getAllSchemes() async {
    if (_cachedSchemes != null) return _cachedSchemes!;

    try {
      final bundle = await _loadBundle();
      final schemeEntities = bundle.schemes;

      final schemes = <Scheme>[];
      final byIdMap = <String, Scheme>{};

      for (final entity in schemeEntities) {
        final scheme = MssSchemeAdapter.toScheme(entity, bundle);
        schemes.add(scheme);
        byIdMap[scheme.id.toLowerCase()] = scheme;
        if (scheme.schemeCode.isNotEmpty) {
          byIdMap[scheme.schemeCode.toLowerCase()] = scheme;
        }
      }

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
  Future<List<Scheme>> searchSchemes(String query) async {
    if (query.trim().isEmpty) return getAllSchemes();
    final matches = await searchSchemeMatches(query);
    return matches.map((match) => match.scheme).toList(growable: false);
  }

  /// Returns scored matches for conversational search and voice result UIs.
  Future<List<SchemeSearchMatch>> searchSchemeMatches(
    String query, {
    int? limit,
  }) async {
    final all = await getAllSchemes();
    return IntelligentSchemeSearch.rank(query, all, limit: limit);
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
  /// Loads a Scheme by ID or Code in O(1) time.
  Future<Scheme?> getSchemeById(String id) async {
    if (id.trim().isEmpty) return null;
    await getAllSchemes();
    final key = id.trim().toLowerCase();
    final cached = _schemeByIdMap?[key];
    if (cached != null) return cached;

    // Fallback: Check bundle directly
    try {
      final bundle = await _loadBundle();
      final entity = bundle.getEntity(id);
      if (entity != null && entity.entityType == 'scheme') {
        return MssSchemeAdapter.toScheme(entity, bundle);
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
