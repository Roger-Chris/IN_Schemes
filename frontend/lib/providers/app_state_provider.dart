import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/user_profile.dart';
import '../models/scheme_model.dart';
import '../engine/recommendation_engine.dart';
import '../services/auth_service.dart';
import '../services/scheme_repository.dart';
import '../services/scheme_catalog_sync_service.dart';
import '../services/session_cache_service.dart';
import '../screens/splash_screen.dart';

class AppProvider with ChangeNotifier, WidgetsBindingObserver {
  AppProvider({SchemeCatalogSyncService? catalogSyncService})
    : _catalogSyncService =
          catalogSyncService ?? SchemeCatalogSyncService.instance {
    WidgetsBinding.instance.addObserver(this);
    _loadState();
    _setupAuthListener();
  }

  final SchemeCatalogSyncService _catalogSyncService;
  StreamSubscription<List<Map<String, dynamic>>>? _profileSubscription;
  bool _isLoggedIn = false;
  bool _isLoggingOut = false;
  String _mobileNumber = '';
  String _selectedLanguage = 'en'; // 'en', 'ta'
  String _navigationMode = 'regular'; // 'regular', 'companion'
  int _currentTabIndex =
      0; // Bottom Navigation: 0: Home, 1: Search, 2: Categories, 3: Saved Schemes, 4: Profile
  final List<int> _tabHistory = [];
  UserProfile _profile = UserProfile();
  List<String> _bookmarkedIds = [];
  List<String> _recentlyViewedIds = [];
  List<Map<String, dynamic>> _downloadedDocs = [];
  String _searchQuery = '';

  // ── Scheme data (loaded from Supabase via SchemeRepository) ──────────
  List<Scheme> _allSchemes = [];
  List<MapEntry<Scheme, RecommendationResult>> _recommendedSchemes = [];
  bool _schemesLoading = false;
  String? _schemesError;
  CatalogSyncResult? _catalogSyncResult;
  bool _catalogSyncing = false;

  // Active Filters state
  Map<String, dynamic> _filters = {
    'state': 'Tamil Nadu',
    'community': 'All',
    'gender': 'All',
    'category': 'All',
    'income': 'All',
  };

  // Temporary wizard answers during the "Find My Schemes" Assessment
  Map<String, dynamic> _wizardAnswers = {};
  int _wizardStep = 0;

  // Dynamic/Mock Announcements fallback
  List<Map<String, String>> _announcementsList = [];

  List<Map<String, String>> get announcements {
    if (_announcementsList.isNotEmpty) return _announcementsList;
    return _defaultAnnouncements;
  }

  static final List<Map<String, String>> _defaultAnnouncements = [
    {
      'title': 'National Entrepreneurs\' Day Celebration',
      'date': '16-Jan-2026',
      'content':
          'Prime Minister launches a new seed grant portal for tech startups and students.',
    },
    {
      'title': 'Tamil Nadu MSME Department Subsidy Hike',
      'date': '04-Jul-2026',
      'content':
          'NEEDS scheme subsidy ceiling raised to ₹75 Lakhs for women and minority entrepreneurs.',
    },
    {
      'title': 'Mudra Loan Shishu Limit Extended',
      'date': '29-May-2026',
      'content':
          'Collateral-free micro loans under Shishu category increased to ₹1 Lakh.',
    },
  ];

  // Notifications state
  List<Map<String, dynamic>> _notificationsList = [
    {
      'id': 'latest_fisheries_update',
      'title':
          'Fisheries and Aquaculture Infra Development Fund Scheme Launched',
      'body':
          'Government has launched the Fisheries and Aquaculture Infrastructure Development Fund to provide concessionary finance.',
      'time': '2d ago',
      'read': false,
      'category': 'updates',
      'iconType': 'emblem',
    },
    {
      'id': '1',
      'title': 'PM Vidyalaxmi Education Loan Scheme',
      'body':
          'A new scheme for students to provide collateral-free education loans for higher studies.',
      'time': '2h ago',
      'read': false,
      'category': 'new_schemes',
      'tag': 'Education',
      'isNew': true,
    },
    {
      'id': '2',
      'title': 'PM Vishwakarma Yojana',
      'body':
          'Financial support for traditional artisans and craftspeople to upgrade their skills and tools.',
      'time': '1d ago',
      'read': false,
      'category': 'new_schemes',
      'tag': 'Skill Development',
      'isNew': true,
    },
    {
      'id': '3',
      'title': 'Post Matric Scholarship Scheme',
      'body': 'Last date to apply is approaching',
      'time': '10m ago',
      'read': false,
      'category': 'reminders',
      'deadline': '31 May 2024',
      'daysLeft': '5 days left',
    },
    {
      'id': '4',
      'title': 'PM Internship Scheme',
      'body': 'Application window will close soon',
      'time': '3h ago',
      'read': false,
      'category': 'reminders',
      'deadline': '15 Jun 2024',
      'daysLeft': '20 days left',
    },
    {
      'id': '5',
      'title': 'New Update on Ayushman Bharat Yojana',
      'body':
          'Changes in empanelment process for hospitals. Check full details.',
      'time': '1d ago',
      'read': false,
      'category': 'updates',
      'iconType': 'emblem',
    },
    {
      'id': '6',
      'title': 'Income Limit Revised for Several Schemes',
      'body':
          'Revised income criteria effective from 1st April 2024 for multiple schemes.',
      'time': '2d ago',
      'read': false,
      'category': 'updates',
      'iconType': 'bank',
    },
    {
      'id': '7',
      'title': 'Complete Your Profile',
      'body': 'Add your income details to find schemes you are eligible for.',
      'time': '5h ago',
      'read': false,
      'category': 'profile',
      'progress': 70,
    },
  ];

  List<Map<String, dynamic>> get notifications => _notificationsList;
  StreamSubscription<List<Map<String, dynamic>>>? _notificationsSubscription;

  List<Map<String, dynamic>> _promoAlerts = [];
  List<Map<String, dynamic>> _draftSessions = [];

  List<Map<String, dynamic>> get carouselItems {
    final filteredPromos = _promoAlerts.where((promo) {
      if (promo['target_gender'] != null &&
          promo['target_gender'].toString().isNotEmpty &&
          _profile.gender.isNotEmpty) {
        if (promo['target_gender'].toString().toLowerCase() !=
            _profile.gender.toLowerCase()) {
          return false;
        }
      }
      if (promo['target_state'] != null &&
          promo['target_state'].toString().isNotEmpty &&
          _profile.state.isNotEmpty) {
        if (promo['target_state'].toString().toLowerCase() !=
            _profile.state.toLowerCase()) {
          return false;
        }
      }
      if (promo['target_community'] != null &&
          promo['target_community'].toString().isNotEmpty &&
          _profile.community.isNotEmpty) {
        if (promo['target_community'].toString().toLowerCase() !=
            _profile.community.toLowerCase()) {
          return false;
        }
      }
      return true;
    }).toList();

    final basePromos = filteredPromos.isNotEmpty
        ? filteredPromos
        : _defaultPromoAlerts;
    return [...basePromos, ..._draftSessions];
  }

  static final List<Map<String, dynamic>> _defaultPromoAlerts = [
    {
      'title': 'Applications Closing Soon',
      'subtitle': 'PMEGP · 2 days left',
      'badge_text': 'Alert',
      'badge_text_color': '#EA580C',
      'badge_bg_color': '#FFF7ED',
      'target_route': 'notifications',
      'bg_image': 'assets/images/Background/alert banner.png',
    },
    {
      'title': 'New Scheme',
      'subtitle': 'TN Export Promotion Scheme',
      'badge_text': 'New Scheme',
      'badge_text_color': '#16A34A',
      'badge_bg_color': '#DCFCE7',
      'target_route': 'discover_results',
      'bg_image': 'assets/images/Background/new scheme banner.png',
    },
    {
      'title': 'Important Update',
      'subtitle': 'UDYAM registration process updated',
      'badge_text': 'Notify',
      'badge_text_color': '#2563EB',
      'badge_bg_color': '#EFF6FF',
      'target_route': 'discover_results',
      'bg_image': 'assets/images/Background/notification banner.png',
    },
    {
      'title': 'For Women Entrepreneurs',
      'subtitle': 'Explore special funding schemes',
      'badge_text': 'Featured',
      'badge_text_color': '#7C3AED',
      'badge_bg_color': '#F5F3FF',
      'target_route': 'discover_results',
      'bg_image': 'assets/images/Background/suggestion banner.png',
    },
  ];

  void _subscribeToProfile(String userId) {
    _profileSubscription?.cancel();
    _profileSubscription = Supabase.instance.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .listen(
          (data) async {
            if (data.isNotEmpty) {
              final dbProfile = UserProfile.fromJson(data.first);

              final remoteUpdated =
                  dbProfile.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final localUpdated =
                  _profile.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

              if (remoteUpdated.isAfter(localUpdated) ||
                  dbProfile.name != _profile.name ||
                  dbProfile.language != _profile.language ||
                  dbProfile.navigationMode != _profile.navigationMode ||
                  dbProfile.state != _profile.state ||
                  dbProfile.district != _profile.district ||
                  dbProfile.pinCode != _profile.pinCode ||
                  dbProfile.gender != _profile.gender ||
                  dbProfile.employmentStatus != _profile.employmentStatus ||
                  dbProfile.profileCompleted != _profile.profileCompleted) {
                _profile = dbProfile;
                _selectedLanguage = dbProfile.language;
                _navigationMode = dbProfile.navigationMode;
                _filters['state'] = _profile.state;
                _filters['community'] = _profile.community;
                _filters['gender'] = _profile.gender;

                _recommendedSchemes = RecommendationEngine.getRecommendations(
                  _profile,
                  _allSchemes,
                );
                fetchPromoAlerts();
                fetchDraftSessions();
                notifyListeners();

                await SessionCacheService.instance.saveProfile(_profile);
                await SessionCacheService.instance.saveLanguage(
                  _selectedLanguage,
                );
                await SessionCacheService.instance.saveNavigationMode(
                  _navigationMode,
                );
              }
            }
          },
          onError: (err) {
            debugPrint(
              '[AppProvider] Real-time profile subscription error: $err',
            );
          },
        );
  }

  void _unsubscribeFromProfile() {
    _profileSubscription?.cancel();
    _profileSubscription = null;
  }

  void _subscribeToNotifications(String userId) {
    _notificationsSubscription?.cancel();
    _notificationsSubscription = Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen(
          (data) async {
            if (data.isEmpty) {
              _notificationsList = [];
              notifyListeners();
              return;
            }

            final sortedData = List<Map<String, dynamic>>.from(data);
            sortedData.sort((a, b) {
              final aTime =
                  DateTime.tryParse(a['created_at'] ?? '') ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final bTime =
                  DateTime.tryParse(b['created_at'] ?? '') ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return bTime.compareTo(aTime);
            });

            _notificationsList = sortedData.map((n) {
              final createdAt =
                  DateTime.tryParse(n['created_at'] ?? '') ?? DateTime.now();
              final difference = DateTime.now().difference(createdAt);
              String timeStr = 'Just now';
              if (difference.inDays > 0) {
                timeStr = '${difference.inDays}d ago';
              } else if (difference.inHours > 0) {
                timeStr = '${difference.inHours}h ago';
              } else if (difference.inMinutes > 0) {
                timeStr = '${difference.inMinutes}m ago';
              }

              final type = n['notification_type'] ?? 'updates';

              final Map<String, dynamic> mapped = {
                'id': n['id'].toString(),
                'title': n['title'] ?? '',
                'body': n['message'] ?? '',
                'time': timeStr,
                'read': n['is_read'] ?? false,
                'category': type,
                'created_at': n['created_at'],
              };

              if (type == 'new_schemes') {
                mapped['tag'] = n['title'].toString().contains('Vidyalaxmi')
                    ? 'Education'
                    : 'Skill Development';
                mapped['isNew'] = true;
              } else if (type == 'reminders') {
                mapped['deadline'] = n['title'].toString().contains('Matric')
                    ? '31 May 2026'
                    : '15 Jun 2026';
                mapped['daysLeft'] = n['title'].toString().contains('Matric')
                    ? '5 days left'
                    : '20 days left';
              } else if (type == 'updates') {
                mapped['iconType'] = n['title'].toString().contains('Ayushman')
                    ? 'emblem'
                    : 'bank';
              } else if (type == 'profile') {
                mapped['progress'] = 70;
              }

              return mapped;
            }).toList();

            notifyListeners();
          },
          onError: (err) {
            debugPrint(
              '[AppProvider] Real-time notifications subscription error: $err',
            );
          },
        );
  }

  void _unsubscribeFromNotifications() {
    _notificationsSubscription?.cancel();
    _notificationsSubscription = null;
  }

  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final Session? session = data.session;
      final AuthChangeEvent event = data.event;

      if (session != null &&
          (event == AuthChangeEvent.signedIn ||
              event == AuthChangeEvent.tokenRefreshed)) {
        _isLoggedIn = true;
        final user = session.user;
        _mobileNumber = user.phone ?? '';

        final dbProfile = await SchemeRepository.instance.getProfile(user.id);
        if (dbProfile != null) {
          _profile = dbProfile;
          _selectedLanguage = dbProfile.language;
          _navigationMode = dbProfile.navigationMode;
        } else {
          _profile = UserProfile(
            googleUserId: user.id,
            name:
                user.userMetadata?['full_name'] ??
                user.userMetadata?['name'] ??
                'Google User',
            email: user.email ?? '',
            mobile: user.phone ?? '',
            profilePhoto: user.userMetadata?['avatar_url'] ?? '',
            language: _selectedLanguage,
            navigationMode: _navigationMode,
          );
        }

        _subscribeToProfile(user.id);
        _subscribeToNotifications(user.id);
        fetchPromoAlerts();
        fetchDraftSessions();
        await _saveProfile();
        notifyListeners();
      } else if (event == AuthChangeEvent.signedOut) {
        _isLoggedIn = false;
        _mobileNumber = '';
        _profile = UserProfile();
        _bookmarkedIds.clear();
        _recentlyViewedIds.clear();
        _currentTabIndex = 0;
        _promoAlerts = [];
        _draftSessions = [];
        _unsubscribeFromProfile();
        _unsubscribeFromNotifications();
        _notificationsList = [];
        notifyListeners();
      }
    });
  }

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  bool get isGuest => false;
  bool get isLoggingOut => _isLoggingOut;
  String get mobileNumber => _mobileNumber;
  String get selectedLanguage => _selectedLanguage;
  String get navigationMode => _navigationMode;
  int get currentTabIndex => _currentTabIndex;
  UserProfile get profile => _profile;
  List<String> get bookmarkedIds => _bookmarkedIds;
  List<String> get recentlyViewedIds => _recentlyViewedIds;
  String get searchQuery => _searchQuery;
  Map<String, dynamic> get filters => _filters;
  Map<String, dynamic> get wizardAnswers => _wizardAnswers;
  int get wizardStep => _wizardStep;

  // Scheme loading state
  bool get schemesLoading => _schemesLoading;
  String? get schemesError => _schemesError;
  List<Scheme> get allSchemes => _allSchemes;
  CatalogSyncResult? get catalogSyncResult => _catalogSyncResult;
  bool get catalogSyncing => _catalogSyncing;
  String get catalogStatusLabel {
    final manifest = _catalogSyncResult?.manifest;
    if (manifest == null) return 'Bundled · ${_allSchemes.length} schemes';
    final date = manifest.publishedAt.toLocal();
    return 'v${manifest.version} · ${date.day}/${date.month}/${date.year}';
  }

  // Recommended schemes (ranked by RecommendationEngine against cached list)
  List<MapEntry<Scheme, RecommendationResult>> get recommendedSchemes =>
      _recommendedSchemes;

  // Bookmarked schemes list
  List<Scheme> get bookmarkedSchemes {
    return _allSchemes
        .where(
          (s) =>
              _bookmarkedIds.contains(s.id) ||
              _bookmarkedIds.contains(s.schemeCode),
        )
        .toList();
  }

  // Recently viewed schemes list
  List<Scheme> get recentlyViewedSchemes {
    return _allSchemes
        .where(
          (s) =>
              _recentlyViewedIds.contains(s.id) ||
              _recentlyViewedIds.contains(s.schemeCode),
        )
        .toList();
  }

  // Load (or reload) all schemes and recompute recommendations
  Future<void> loadSchemes({bool forceRefresh = false}) async {
    if (_schemesLoading) return;
    if (forceRefresh) SchemeRepository.instance.clearCache();

    _schemesLoading = true;
    _schemesError = null;
    notifyListeners();

    try {
      _allSchemes = await SchemeRepository.instance.getAllSchemes();
      _recommendedSchemes = RecommendationEngine.getRecommendations(
        _profile,
        _allSchemes,
      );

      // Update announcements dynamically based on latest central/state schemes
      if (_allSchemes.isNotEmpty) {
        final recent = List<Scheme>.from(_allSchemes)
          ..sort((a, b) => b.id.compareTo(a.id));
        _announcementsList = recent.take(3).map((s) {
          final isCentral = s.governmentLevel.toLowerCase() == 'central';
          final sponsor = s.sponsoringBody.isNotEmpty
              ? s.sponsoringBody
              : (isCentral ? 'Govt of India' : s.state);
          return {
            'title': 'Updated: ${s.name}',
            'date': 'Realtime Live Feed',
            'content':
                '${s.overview.length > 120 ? "${s.overview.substring(0, 117)}..." : s.overview} (Source: $sponsor)',
          };
        }).toList();
      }
    } catch (e) {
      _schemesError = e.toString();
      debugPrint('[AppProvider] loadSchemes error: $e');
    } finally {
      _schemesLoading = false;
      notifyListeners();
    }
  }

  Future<CatalogSyncResult> syncSchemeCatalog({bool force = false}) async {
    if (_catalogSyncing) {
      return _catalogSyncResult ??
          const CatalogSyncResult(CatalogSyncOutcome.throttled);
    }
    _catalogSyncing = true;
    notifyListeners();
    CatalogSyncResult result;
    try {
      result = await _catalogSyncService.syncIfNeeded(force: force);
    } catch (error) {
      result = CatalogSyncResult(
        CatalogSyncOutcome.rejected,
        manifest: _catalogSyncResult?.manifest,
        message: error.toString(),
      );
    }
    _catalogSyncResult = result;
    _catalogSyncing = false;
    if (result.changed) {
      await loadSchemes(forceRefresh: true);
    } else {
      notifyListeners();
    }
    return result;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(syncSchemeCatalog());
    }
  }

  // Load state from SharedPreferences (for session continue support)
  Future<void> _loadState() async {
    try {
      _selectedLanguage =
          await SessionCacheService.instance.getLanguage() ?? 'en';
      _currentTabIndex = await SessionCacheService.instance
          .getCurrentTabIndex();

      final cachedProfile = await SessionCacheService.instance.loadProfile();
      if (cachedProfile != null) {
        _profile = cachedProfile;
        _navigationMode = _profile.navigationMode;
      }
      final cachedNavMode = await SessionCacheService.instance
          .getNavigationMode();
      if (cachedNavMode != null && cachedNavMode.isNotEmpty) {
        _navigationMode = cachedNavMode;
      }

      _bookmarkedIds = await SessionCacheService.instance.getBookmarks() ?? [];
      _recentlyViewedIds =
          await SessionCacheService.instance.getRecentlyViewed() ?? [];

      final downloadedDocsStr = await SessionCacheService.instance
          .getDownloadedDocs();
      if (downloadedDocsStr != null) {
        _downloadedDocs = List<Map<String, dynamic>>.from(
          jsonDecode(downloadedDocsStr),
        );
      } else {
        _downloadedDocs = [];
      }

      // Initialize filters based on loaded profile
      _filters['state'] = _profile.state;
      _filters['community'] = _profile.community;
      _filters['gender'] = _profile.gender;

      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        debugPrint(
          '[AppProvider] Active Supabase session found during _loadState: user=${session.user.id}',
        );
        _isLoggedIn = true;
        _mobileNumber = session.user.phone ?? '';
        _subscribeToProfile(session.user.id);
        _subscribeToNotifications(session.user.id);
        fetchPromoAlerts();
        fetchDraftSessions();
      } else {
        debugPrint(
          '[AppProvider] No active Supabase session found during _loadState.',
        );
      }

      notifyListeners();

      // Render local data first, then refresh the published snapshot silently.
      await loadSchemes();
      unawaited(syncSchemeCatalog());
    } catch (e) {
      debugPrint('Error loading state: $e');
    }
  }

  // Save state helpers
  Future<void> _saveProfile() async {
    await SessionCacheService.instance.saveProfile(_profile);
  }

  // Sync profile to Supabase in the background (asynchronous, non-blocking)
  Future<void> _syncProfileToSupabaseInBackground(
    UserProfile profileToSync,
  ) async {
    if (!_isLoggedIn) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      debugPrint('[AppProvider] Background syncing profile to Supabase...');
      // Sync profiles table (single source of truth)
      await SchemeRepository.instance.createProfile(profileToSync);

      // Sync startup_profiles table if they have business details
      final existingStartups = await Supabase.instance.client
          .from('startup_profiles')
          .select('id')
          .eq('user_id', user.id)
          .limit(1);

      final Map<String, dynamic> startupData = {
        'user_id': user.id,
        'profile_name': '${profileToSync.name} Business',
        'industry': profileToSync.businessIndustry.isNotEmpty
            ? profileToSync.businessIndustry
            : 'Technology',
        'applicant_type': profileToSync.employmentStatus.isNotEmpty
            ? profileToSync.employmentStatus
            : 'Student',
        'business_stage': profileToSync.businessStage.isNotEmpty
            ? profileToSync.businessStage
            : 'Idea',
        'business_registered': profileToSync.existingBusiness,
        'funding_required_amount': profileToSync.fundingRequired,
        'registration_numbers': profileToSync.registrationNumbers,
        'is_active': true,
      };

      if (existingStartups.isNotEmpty) {
        startupData['id'] = existingStartups.first['id'];
      }

      await Supabase.instance.client
          .from('startup_profiles')
          .upsert(startupData);
      debugPrint('[AppProvider] Background sync to Supabase completed.');
    } catch (e) {
      debugPrint('[AppProvider] Error during background sync to Supabase: $e');
    }
  }

  // Setters & Actions
  void changeLanguage(String lang) async {
    _selectedLanguage = lang;
    _profile = _profile.copyWith(language: lang, updatedAt: DateTime.now());
    notifyListeners();
    await SessionCacheService.instance.saveLanguage(lang);
    await _saveProfile();

    _syncProfileToSupabaseInBackground(_profile);
  }

  void changeNavigationMode(String mode) async {
    _navigationMode = mode;
    _profile = _profile.copyWith(
      navigationMode: mode,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await SessionCacheService.instance.saveNavigationMode(mode);
    await SessionCacheService.instance.saveProfile(_profile);

    _syncProfileToSupabaseInBackground(_profile);
  }

  Future<bool> loginWithGoogle() async {
    try {
      return await AuthService.signInWithGoogle();
    } catch (e) {
      debugPrint('[AppProvider] Error signing in with Google: $e');
      rethrow;
    }
  }

  Future<bool> checkSessionAndFetchProfile() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      _isLoggedIn = false;
      _unsubscribeFromProfile();
      notifyListeners();
      return false;
    }

    final user = session.user;
    _isLoggedIn = true;
    _mobileNumber = user.phone ?? '';

    _subscribeToProfile(user.id);
    fetchPromoAlerts();
    fetchDraftSessions();

    final dbProfile = await SchemeRepository.instance.getProfile(user.id);
    if (dbProfile != null) {
      _profile = dbProfile;
      _selectedLanguage = dbProfile.language;
      _navigationMode = dbProfile.navigationMode;

      await SchemeRepository.instance.updateLastLogin(user.id);

      await SessionCacheService.instance.saveProfile(_profile);
      await SessionCacheService.instance.saveLanguage(_selectedLanguage);
      await SessionCacheService.instance.saveNavigationMode(_navigationMode);

      notifyListeners();
      return dbProfile.profileCompleted;
    } else {
      _profile = UserProfile(
        googleUserId: user.id,
        name:
            user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? '',
        email: user.email ?? '',
        mobile: user.phone ?? '',
        profilePhoto: user.userMetadata?['avatar_url'] ?? '',
        language: _selectedLanguage,
        navigationMode: _navigationMode,
        profileCompleted: false,
      );
      await _saveProfile();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout(BuildContext context) async {
    debugPrint('[AppProvider] logout initiated...');
    _isLoggingOut = true;
    notifyListeners();

    // 1. Perform cleanup and await asynchronous operations
    _isLoggedIn = false;
    _mobileNumber = '';
    _selectedLanguage = 'en';
    _navigationMode = 'regular';
    _profile = UserProfile();
    _bookmarkedIds.clear();
    _recentlyViewedIds.clear();
    _currentTabIndex = 0;
    _tabHistory.clear();
    _unsubscribeFromProfile();

    await SessionCacheService.instance.clearSession();

    try {
      await AuthService.signOut();
    } catch (e) {
      debugPrint('[AppProvider] Error during AuthService.signOut(): $e');
    }

    _isLoggingOut = false;
    notifyListeners();

    // 2. Navigate after cleanup is fully complete
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  Future<void> deleteAccount(BuildContext context) async {
    debugPrint('[AppProvider] deleteAccount initiated...');
    _isLoggingOut = true;
    notifyListeners();

    // 1. Delete user account from Supabase Auth (cascades to profiles)
    if (_isLoggedIn) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          debugPrint(
            '[AppProvider] Calling delete_user RPC for user: ${user.id}',
          );
          await Supabase.instance.client.rpc('delete_user');
          debugPrint(
            '[AppProvider] Supabase user account deleted successfully.',
          );
        } catch (e) {
          debugPrint('[AppProvider] Error calling delete_user RPC: $e');
          // Fallback: delete profile row directly if RPC fails
          try {
            await Supabase.instance.client
                .from('profiles')
                .delete()
                .eq('id', user.id);
            debugPrint('[AppProvider] Supabase profile data deleted directly.');
          } catch (dbError) {
            debugPrint(
              '[AppProvider] Error deleting profile from database directly: $dbError',
            );
          }
        }
      }
    }

    // 2. Perform local state cleanup and await async operations
    _isLoggedIn = false;
    _mobileNumber = '';
    _selectedLanguage = 'en';
    _navigationMode = 'regular';
    _profile = UserProfile();
    _bookmarkedIds.clear();
    _recentlyViewedIds.clear();
    _currentTabIndex = 0;
    _tabHistory.clear();
    _unsubscribeFromProfile();

    await SessionCacheService.instance.clearSession();

    try {
      await AuthService.signOut();
    } catch (e) {
      debugPrint('[AppProvider] Error during AuthService.signOut(): $e');
    }

    _isLoggingOut = false;
    notifyListeners();

    // 3. Navigate after all cleanup is fully complete
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  void updateTabIndex(int index, {bool addToHistory = true}) async {
    if (_currentTabIndex == index) return;
    if (addToHistory) {
      if (_tabHistory.isEmpty || _tabHistory.last != _currentTabIndex) {
        _tabHistory.add(_currentTabIndex);
      }
    }
    _currentTabIndex = index;
    notifyListeners();
    await SessionCacheService.instance.saveCurrentTabIndex(index);
  }

  Future<void> fetchLatestProfile() async {
    if (!_isLoggedIn) return;
    try {
      final lastSync = await SessionCacheService.instance.getLastProfileSync();
      final now = DateTime.now();

      if (lastSync != null && now.difference(lastSync).inMinutes < 10) {
        debugPrint(
          '[AppProvider] Silent profile sync skipped (interval threshold not met).',
        );
        return;
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      debugPrint('[AppProvider] Starting silent background sync...');
      final dbProfile = await SchemeRepository.instance.getProfile(user.id);

      if (dbProfile != null) {
        final remoteUpdated =
            dbProfile.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final localUpdated =
            _profile.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        if (remoteUpdated.isAfter(localUpdated)) {
          _profile = dbProfile;
          _selectedLanguage = dbProfile.language;
          _navigationMode = dbProfile.navigationMode;
          await SessionCacheService.instance.saveProfile(_profile);
          notifyListeners();
          debugPrint(
            '[AppProvider] Silent background sync updated local profile.',
          );
        } else {
          debugPrint('[AppProvider] Stale remote profile skipped during sync.');
        }
      }
      await SessionCacheService.instance.updateLastProfileSync();
    } catch (e) {
      debugPrint('[AppProvider] Error during background sync: $e');
    }
  }

  bool get hasTabHistory => _tabHistory.isNotEmpty;

  bool popTabIndex() {
    if (_tabHistory.isNotEmpty) {
      final prevIndex = _tabHistory.removeLast();
      _currentTabIndex = prevIndex;
      notifyListeners();
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt('currentTabIndex', prevIndex);
      });
      return true;
    }
    return false;
  }

  void toggleBookmark(String id) async {
    if (_bookmarkedIds.contains(id)) {
      _bookmarkedIds.remove(id);
    } else {
      _bookmarkedIds.add(id);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('bookmarks', _bookmarkedIds);
  }

  void addToRecentlyViewed(String id) async {
    _recentlyViewedIds.remove(id); // Move to front
    _recentlyViewedIds.insert(0, id);
    if (_recentlyViewedIds.length > 5) {
      _recentlyViewedIds = _recentlyViewedIds.sublist(0, 5);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recentlyViewed', _recentlyViewedIds);
  }

  // Search & Filter Operations
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void updateFilter(String key, dynamic value) {
    _filters[key] = value;
    notifyListeners();
  }

  void clearFilters() {
    _filters = {
      'state': _profile.state,
      'community': 'All',
      'gender': 'All',
      'category': 'All',
      'income': 'All',
    };
    notifyListeners();
  }

  // Wizard state management
  void startWizard() {
    _wizardStep = 0;
    _wizardAnswers = {
      'name': _profile.name,
      'gender': _profile.gender,
      'dob': _profile.dob ?? DateTime(1998, 1, 1),
      'state': _profile.state,
      'district': _profile.district,
      'city': _profile.city,
      'pinCode': _profile.pinCode,
      'community': _profile.community,
      'religion': _profile.religion,
      'educationLevel': _profile.educationLevel,
      'firstGenGraduate': _profile.firstGenGraduate,
      'annualIncome': _profile.annualIncome,
    };
    notifyListeners();
  }

  void updateWizardAnswer(String key, dynamic value) {
    _wizardAnswers[key] = value;
    notifyListeners();
  }

  void nextWizardStep() {
    if (_wizardStep < 2) {
      _wizardStep++;
      notifyListeners();
    }
  }

  void previousWizardStep() {
    if (_wizardStep > 0) {
      _wizardStep--;
      notifyListeners();
    }
  }

  void submitWizard() {
    // Commit wizard answers to UserProfile
    _profile = UserProfile(
      name: _wizardAnswers['name'] ?? '',
      gender: _wizardAnswers['gender'] ?? 'Female',
      dob: _wizardAnswers['dob'] as DateTime?,
      state: _wizardAnswers['state'] ?? 'Tamil Nadu',
      district: _wizardAnswers['district'] ?? '',
      city: _wizardAnswers['city'] ?? '',
      pinCode: _wizardAnswers['pinCode'] ?? '',
      community: _wizardAnswers['community'] ?? 'General',
      religion: _wizardAnswers['religion'] ?? '',
      educationLevel: _wizardAnswers['educationLevel'] ?? 'Undergraduate',
      firstGenGraduate: _wizardAnswers['firstGenGraduate'] ?? false,
      annualIncome: (_wizardAnswers['annualIncome'] ?? 0.0) as double,
      mobile: _mobileNumber,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    _saveProfile();
  }

  // Notification action
  Future<void> markNotificationRead(String id) async {
    final index = _notificationsList.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      _notificationsList[index]['read'] = true;
      notifyListeners();
    }
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (e) {
      debugPrint('[AppProvider] Error marking notification read: $e');
    }
  }

  Future<void> markAllNotificationsRead() async {
    for (var n in _notificationsList) {
      n['read'] = true;
    }
    notifyListeners();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('[AppProvider] Error marking all notifications read: $e');
    }
  }

  Future<void> deleteAllNotifications() async {
    _notificationsList.clear();
    notifyListeners();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('[AppProvider] Error deleting all notifications: $e');
    }
  }

  Future<void> deleteNotifications(List<String> ids) async {
    _notificationsList.removeWhere((n) => ids.contains(n['id']));
    notifyListeners();
    try {
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .inFilter('id', ids);
    } catch (e) {
      debugPrint('[AppProvider] Error deleting notifications: $e');
    }
  }

  Future<void> markNotificationsRead(List<String> ids) async {
    for (var n in _notificationsList) {
      if (ids.contains(n['id'])) {
        n['read'] = true;
      }
    }
    notifyListeners();
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .inFilter('id', ids);
    } catch (e) {
      debugPrint('[AppProvider] Error marking notifications read: $e');
    }
  }

  // Completion calculation
  int get profileCompletionPercentage {
    final List<bool> checks = [];

    // Personal Info
    checks.add(_profile.name.trim().isNotEmpty);
    checks.add(_profile.mobile.trim().isNotEmpty);
    checks.add(_profile.dob != null);
    checks.add(_profile.gender.trim().isNotEmpty);

    // Address Info
    checks.add(_profile.house.trim().isNotEmpty);
    checks.add(_profile.street.trim().isNotEmpty);
    checks.add(_profile.area.trim().isNotEmpty);
    checks.add(_profile.state.trim().isNotEmpty);
    checks.add(_profile.district.trim().isNotEmpty);
    checks.add(_profile.city.trim().isNotEmpty);
    checks.add(_profile.pinCode.trim().isNotEmpty);

    // Social
    checks.add(_profile.community.trim().isNotEmpty);

    // Education & Employment
    checks.add(_profile.qualification.trim().isNotEmpty);
    checks.add(_profile.employmentStatus.trim().isNotEmpty);

    // Business (conditional)
    if (_profile.existingBusiness) {
      checks.add(_profile.businessStage.trim().isNotEmpty);
      checks.add(_profile.businessIndustry.trim().isNotEmpty);
    }

    final total = checks.length;
    final filled = checks.where((c) => c).length;

    return ((filled / total) * 100).round();
  }

  List<String> get missingProfileSections {
    final missing = <String>[];
    if (_profile.name.trim().isEmpty) missing.add('Name');
    if (_profile.mobile.trim().isEmpty) missing.add('Phone');
    if (_profile.dob == null) missing.add('Date of Birth');
    if (_profile.gender.trim().isEmpty) missing.add('Gender');

    // Address
    if (_profile.house.trim().isEmpty ||
        _profile.street.trim().isEmpty ||
        _profile.area.trim().isEmpty ||
        _profile.state.trim().isEmpty ||
        _profile.district.trim().isEmpty ||
        _profile.city.trim().isEmpty ||
        _profile.pinCode.trim().isEmpty) {
      missing.add('Address Details');
    }

    if (_profile.community.trim().isEmpty) missing.add('Community');
    if (_profile.qualification.trim().isEmpty) missing.add('Qualification');
    if (_profile.employmentStatus.trim().isEmpty) missing.add('Employment');

    if (_profile.existingBusiness) {
      if (_profile.businessStage.trim().isEmpty ||
          _profile.businessIndustry.trim().isEmpty) {
        missing.add('Business Details');
      }
    }
    return missing;
  }

  Future<void> updateProfile(UserProfile updated) async {
    _profile = updated.copyWith(updatedAt: DateTime.now());
    _filters['state'] = _profile.state;
    _filters['community'] = _profile.community;
    _filters['gender'] = _profile.gender;

    // Recalculate recommendations based on updated profile
    _recommendedSchemes = RecommendationEngine.getRecommendations(
      _profile,
      _allSchemes,
    );

    notifyListeners();
    await _saveProfile();

    _syncProfileToSupabaseInBackground(_profile);
  }

  Future<void> updateProfilePhoto(String path) async {
    _profile = _profile.copyWith(profilePhoto: path, updatedAt: DateTime.now());
    notifyListeners();
    await _saveProfile();

    _syncProfileToSupabaseInBackground(_profile);
  }

  Future<Map<String, dynamic>> _getFallbackLocation() async {
    final locData = {
      'house': 'Flat 402',
      'street': 'Royal Enclave',
      'area': 'Anna Nagar West',
      'village': '',
      'state': 'Tamil Nadu',
      'district': 'Chennai',
      'city': 'Chennai',
      'pinCode': '600040',
      'latitude': 13.0827,
      'longitude': 80.2707,
      'isFallback': true,
    };

    _profile = _profile.copyWith(
      area: locData['area'] as String,
      state: locData['state'] as String,
      district: locData['district'] as String,
      city: locData['city'] as String,
      pinCode: locData['pinCode'] as String,
    );

    notifyListeners();
    await _saveProfile();
    _syncProfileToSupabaseInBackground(_profile);
    return locData;
  }

  // Location/GPS Helper
  Future<Map<String, dynamic>?> fetchLocationAndPopulate() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled. Using Chennai fallback.');
        return await _getFallbackLocation();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint(
            'Location permissions are denied. Using Chennai fallback.',
          );
          return await _getFallbackLocation();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint(
          'Location permissions are permanently denied. Using Chennai fallback.',
        );
        return await _getFallbackLocation();
      }

      Position? position;
      try {
        // Try getting current position with medium accuracy (faster, works indoors)
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 7),
        );
      } catch (e) {
        debugPrint(
          'getCurrentPosition failed: $e. Trying getLastKnownPosition as fallback...',
        );
        try {
          position = await Geolocator.getLastKnownPosition();
        } catch (err) {
          debugPrint('getLastKnownPosition failed: $err');
        }
      }

      if (position == null) {
        debugPrint('No position found. Using Chennai fallback.');
        return await _getFallbackLocation();
      }

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;

        final locData = {
          'house': placemark.subThoroughfare ?? '',
          'street': placemark.thoroughfare ?? '',
          'area': placemark.subLocality ?? placemark.name ?? '',
          'village':
              placemark.subLocality != null &&
                  placemark.name != null &&
                  placemark.subLocality != placemark.name
              ? placemark.name
              : '',
          'state': placemark.administrativeArea ?? '',
          'district':
              (placemark.subAdministrativeArea != null &&
                  placemark.subAdministrativeArea!.isNotEmpty)
              ? placemark.subAdministrativeArea!
              : (placemark.locality ?? ''),
          'city': placemark.locality ?? placemark.subLocality ?? '',
          'pinCode': placemark.postalCode ?? '',
          'latitude': position.latitude,
          'longitude': position.longitude,
          'isFallback': false,
        };

        _profile = _profile.copyWith(
          area: locData['area'] as String,
          state: locData['state'] as String,
          district: locData['district'] as String,
          city: locData['city'] as String,
          pinCode: locData['pinCode'] as String,
        );

        notifyListeners();
        await _saveProfile();
        _syncProfileToSupabaseInBackground(_profile);
        return locData;
      }
    } catch (e) {
      debugPrint('Error fetching location: $e. Using Chennai fallback.');
    }
    return await _getFallbackLocation();
  }

  List<Map<String, dynamic>> get downloadedDocs => _downloadedDocs;

  Future<void> _saveDownloadedDocs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('downloadedDocs', jsonEncode(_downloadedDocs));
  }

  void downloadDoc(String id, String title, String size) {
    if (!_downloadedDocs.any((doc) => doc['id'] == id)) {
      final now = DateTime.now();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final dateStr =
          'Downloaded on ${now.day} ${months[now.month - 1]} ${now.year}';

      _downloadedDocs.add({
        'id': id,
        'title': title,
        'size': size,
        'date': dateStr,
        'fileType': 'PDF',
      });
      _saveDownloadedDocs();
      notifyListeners();
    }
  }

  void removeDownloadedDoc(String id) {
    _downloadedDocs.removeWhere((doc) => doc['id'] == id);
    _saveDownloadedDocs();
    notifyListeners();
  }

  Future<void> fetchPromoAlerts() async {
    try {
      final res = await Supabase.instance.client.from('promo_alerts').select();

      _promoAlerts = List<Map<String, dynamic>>.from(res);
      notifyListeners();
    } catch (e) {
      debugPrint('[AppProvider] Error fetching promo alerts: $e');
    }
  }

  Future<void> fetchDraftSessions() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        _draftSessions = [];
        notifyListeners();
        return;
      }

      final res = await Supabase.instance.client
          .from('questionnaire_sessions')
          .select(
            'id, completed_percentage, status, startup_profiles!inner(user_id, profile_name)',
          )
          .eq('status', 'IN_PROGRESS')
          .eq('startup_profiles.user_id', userId);

      _draftSessions = List<Map<String, dynamic>>.from(res).map((item) {
        final startup = item['startup_profiles'] as Map<String, dynamic>;
        final pct = (item['completed_percentage'] as num?)?.toDouble() ?? 0.0;
        return {
          'id': item['id'],
          'title': '${startup['profile_name']} Setup',
          'badge_text': 'Draft',
          'badge_text_color': '#2563EB',
          'badge_bg_color': '#EFF6FF',
          'bg_gradient_start': '#EFF6FF',
          'bg_gradient_end': '#DBEAFE',
          'btn_text': 'Continue',
          'btn_color': '#2563EB',
          'target_route': 'draft_session',
          'graphic_type': 'progress',
          'progress': pct,
        };
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('[AppProvider] Error fetching draft sessions: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unsubscribeFromProfile();
    super.dispose();
  }
}
