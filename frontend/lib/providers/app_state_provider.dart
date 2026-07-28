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
import '../services/session_cache_service.dart';
import '../screens/splash_screen.dart';

class AppProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoggingOut = false;
  String _mobileNumber = '';
  String _selectedLanguage = 'en'; // 'en', 'hi'
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

  // Mock Announcements
  final List<Map<String, String>> announcements = [
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

  // Mock Notifications
  final List<Map<String, dynamic>> notifications = [
    {
      'id': '1',
      'title': 'PM Vidyalaxmi Education Loan Scheme',
      'body': 'A new scheme for students to provide collateral-free education loans for higher studies.',
      'time': '2h ago',
      'read': false,
      'category': 'new_schemes',
      'tag': 'Education',
      'isNew': true,
    },
    {
      'id': '2',
      'title': 'PM Vishwakarma Yojana',
      'body': 'Financial support for traditional artisans and craftspeople to upgrade their skills and tools.',
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
      'body': 'Changes in empanelment process for hospitals. Check full details.',
      'time': '1d ago',
      'read': false,
      'category': 'updates',
      'iconType': 'emblem',
    },
    {
      'id': '6',
      'title': 'Income Limit Revised for Several Schemes',
      'body': 'Revised income criteria effective from 1st April 2024 for multiple schemes.',
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

  AppProvider() {
    _loadState();
    _setupAuthListener();
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
            name: user.userMetadata?['full_name'] ??
                user.userMetadata?['name'] ??
                'Google User',
            email: user.email ?? '',
            mobile: user.phone ?? '',
            profilePhoto: user.userMetadata?['avatar_url'] ?? '',
            language: _selectedLanguage,
            navigationMode: _navigationMode,
          );
        }

        await _saveProfile();
        notifyListeners();
      } else if (event == AuthChangeEvent.signedOut) {
        _isLoggedIn = false;
        _mobileNumber = '';
        _profile = UserProfile();
        _bookmarkedIds.clear();
        _recentlyViewedIds.clear();
        _currentTabIndex = 0;
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

  // Recommended schemes (ranked by RecommendationEngine against cached list)
  List<MapEntry<Scheme, RecommendationResult>> get recommendedSchemes =>
      _recommendedSchemes;

  // Bookmarked schemes list
  List<Scheme> get bookmarkedSchemes {
    return _allSchemes
        .where((s) =>
            _bookmarkedIds.contains(s.id) ||
            _bookmarkedIds.contains(s.schemeCode))
        .toList();
  }

  // Recently viewed schemes list
  List<Scheme> get recentlyViewedSchemes {
    return _allSchemes
        .where((s) =>
            _recentlyViewedIds.contains(s.id) ||
            _recentlyViewedIds.contains(s.schemeCode))
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
      _recommendedSchemes =
          RecommendationEngine.getRecommendations(_profile, _allSchemes);
    } catch (e) {
      _schemesError = e.toString();
      debugPrint('[AppProvider] loadSchemes error: $e');
    } finally {
      _schemesLoading = false;
      notifyListeners();
    }
  }

  // Load state from SharedPreferences (for session continue support)
  Future<void> _loadState() async {
    try {
      _selectedLanguage = await SessionCacheService.instance.getLanguage() ?? 'en';
      _currentTabIndex = await SessionCacheService.instance.getCurrentTabIndex();

      final cachedProfile = await SessionCacheService.instance.loadProfile();
      if (cachedProfile != null) {
        _profile = cachedProfile;
        _navigationMode = _profile.navigationMode;
      }

      _bookmarkedIds = await SessionCacheService.instance.getBookmarks() ?? ['POST_MATRIC', 'PM_MATRU_VANDANA', 'PM_AWAS'];
      _recentlyViewedIds = await SessionCacheService.instance.getRecentlyViewed() ?? ['NSP_PORTAL', 'PM_EDRIVE', 'AYUSHMAN_BHARAT', 'MUDRA'];

      final downloadedDocsStr = await SessionCacheService.instance.getDownloadedDocs();
      if (downloadedDocsStr != null) {
        _downloadedDocs = List<Map<String, dynamic>>.from(jsonDecode(downloadedDocsStr));
      } else {
        _downloadedDocs = [
          {
            'id': 'POST_MATRIC_GUIDE',
            'title': 'Post Matric Scholarship Scheme – Information Guide',
            'size': '1.2 MB',
            'date': 'Downloaded on 20 May 2024',
            'fileType': 'PDF',
          },
          {
            'id': 'PMAY_ELIGIBILITY',
            'title': 'PMAY (Urban) – Eligibility & Benefits',
            'size': '0.8 MB',
            'date': 'Downloaded on 12 Jun 2024',
            'fileType': 'PDF',
          },
        ];
      }

      // Initialize filters based on loaded profile
      _filters['state'] = _profile.state;
      _filters['community'] = _profile.community;
      _filters['gender'] = _profile.gender;

      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        debugPrint('[AppProvider] Active Supabase session found during _loadState: user=${session.user.id}');
        _isLoggedIn = true;
        _mobileNumber = session.user.phone ?? '';
      } else {
        debugPrint('[AppProvider] No active Supabase session found during _loadState.');
      }

      notifyListeners();

      // Kick off scheme load after state is set
      loadSchemes();
    } catch (e) {
      debugPrint('Error loading state: $e');
    }
  }

  // Save state helpers
  Future<void> _saveProfile() async {
    await SessionCacheService.instance.saveProfile(_profile);
  }

  // Setters & Actions
  void changeLanguage(String lang) async {
    _selectedLanguage = lang;
    notifyListeners();
    await SessionCacheService.instance.saveLanguage(lang);
  }

  void changeNavigationMode(String mode) async {
    _navigationMode = mode;
    _profile = _profile.copyWith(navigationMode: mode);
    notifyListeners();
    await SessionCacheService.instance.saveNavigationMode(mode);
    await SessionCacheService.instance.saveProfile(_profile);

    if (_isLoggedIn) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          await SchemeRepository.instance.createProfile(_profile);
          debugPrint('[AppProvider] Successfully synced navigation mode ($mode) to Supabase.');
        } catch (e) {
          debugPrint('[AppProvider] Error syncing navigation mode to database: $e');
        }
      }
    }
  }


  void login(String mobile) async {
    _isLoggedIn = true;
    _mobileNumber = mobile;
    _currentTabIndex = 0;
    // Default initial profile
    _profile = UserProfile(mobile: mobile);
    notifyListeners();
    await _saveProfile();
    await SessionCacheService.instance.saveCurrentTabIndex(0);
  }

  Future<bool> loginWithGoogle() async {
    try {
      debugPrint('[AppProvider] Starting loginWithGoogle flow...');
      final response = await AuthService.signInWithGoogle();
      if (response.user != null) {
        final user = response.user!;
        _isLoggedIn = true;
        _mobileNumber = user.phone ?? '';

        final dbProfile = await SchemeRepository.instance.getProfile(user.id);
        if (dbProfile != null) {
          _profile = dbProfile;
          _selectedLanguage = dbProfile.language;
          _navigationMode = dbProfile.navigationMode;

          await SchemeRepository.instance.updateLastLogin(user.id);

          await SessionCacheService.instance.saveProfile(_profile);
          await SessionCacheService.instance.saveLanguage(_selectedLanguage);
          await SessionCacheService.instance.saveNavigationMode(_navigationMode);

          _currentTabIndex = 0;
          await SessionCacheService.instance.saveCurrentTabIndex(0);

          notifyListeners();
          debugPrint('[AppProvider] loginWithGoogle returning user: ${user.id}');
          return true; // Profile exists and complete
        } else {
          _profile = UserProfile(
            googleUserId: user.id,
            name: user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? '',
            email: user.email ?? '',
            mobile: user.phone ?? '',
            profilePhoto: user.userMetadata?['avatar_url'] ?? '',
            language: _selectedLanguage,
            navigationMode: _navigationMode,
            profileCompleted: false,
          );

          await _saveProfile();
          notifyListeners();
          debugPrint('[AppProvider] loginWithGoogle new user: ${user.id}');
          return false; // Profile does not exist yet
        }
      }
    } catch (e) {
      debugPrint('[AppProvider] Error signing in with Google: $e');
      rethrow;
    }
    return false;
  }

  Future<bool> checkSessionAndFetchProfile() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      _isLoggedIn = false;
      notifyListeners();
      return false;
    }

    final user = session.user;
    _isLoggedIn = true;
    _mobileNumber = user.phone ?? '';

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
        name: user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? '',
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

    // 1. Navigate instantly to SplashScreen to perform the fresh welcome animation sequence
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );

    // 2. Perform cleanup in the background
    _isLoggedIn = false;
    _mobileNumber = '';
    _selectedLanguage = 'en';
    _profile = UserProfile();
    _bookmarkedIds.clear();
    _recentlyViewedIds.clear();
    _currentTabIndex = 0;
    _tabHistory.clear();

    await SessionCacheService.instance.clearSession();

    try {
      await AuthService.signOut();
    } catch (e) {
      debugPrint('[AppProvider] Error during AuthService.signOut(): $e');
    }

    _isLoggingOut = false;
    notifyListeners();
  }

  Future<void> deleteAccount(BuildContext context) async {
    debugPrint('[AppProvider] deleteAccount initiated...');
    _isLoggingOut = true;
    notifyListeners();

    if (_isLoggedIn) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          debugPrint('[AppProvider] Deleting profile data from Supabase for user: ${user.id}');
          await Supabase.instance.client.from('profiles').delete().eq('id', user.id);
          debugPrint('[AppProvider] Supabase profile data deleted.');
        } catch (e) {
          debugPrint('[AppProvider] Error deleting profile from database: $e');
        }
      }
    }

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );

    _isLoggedIn = false;
    _mobileNumber = '';
    _selectedLanguage = 'en';
    _profile = UserProfile();
    _bookmarkedIds.clear();
    _recentlyViewedIds.clear();
    _currentTabIndex = 0;
    _tabHistory.clear();

    await SessionCacheService.instance.clearSession();

    try {
      await AuthService.signOut();
    } catch (e) {
      debugPrint('[AppProvider] Error during AuthService.signOut(): $e');
    }

    _isLoggingOut = false;
    notifyListeners();
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
        debugPrint('[AppProvider] Silent profile sync skipped (interval threshold not met).');
        return;
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      debugPrint('[AppProvider] Starting silent background sync...');
      final dbProfile = await SchemeRepository.instance.getProfile(user.id);
      
      if (dbProfile != null) {
        final remoteUpdated = dbProfile.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final localUpdated = _profile.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        if (remoteUpdated.isAfter(localUpdated)) {
          _profile = dbProfile;
          _selectedLanguage = dbProfile.language;
          _navigationMode = dbProfile.navigationMode;
          await SessionCacheService.instance.saveProfile(_profile);
          notifyListeners();
          debugPrint('[AppProvider] Silent background sync updated local profile.');
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
    );
    notifyListeners();
    _saveProfile();
  }

  // Notification action
  void markNotificationRead(String id) {
    final idx = notifications.indexWhere((n) => n['id'] == id);
    if (idx != -1) {
      notifications[idx]['read'] = true;
      notifyListeners();
    }
  }

  void markAllNotificationsRead() {
    for (var n in notifications) {
      n['read'] = true;
    }
    notifyListeners();
  }

  void deleteAllNotifications() {
    notifications.clear();
    notifyListeners();
  }

  void deleteNotifications(List<String> ids) {
    notifications.removeWhere((n) => ids.contains(n['id']));
    notifyListeners();
  }

  void markNotificationsRead(List<String> ids) {
    for (var n in notifications) {
      if (ids.contains(n['id'])) {
        n['read'] = true;
      }
    }
    notifyListeners();
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
      if (_profile.businessStage.trim().isEmpty || _profile.businessIndustry.trim().isEmpty) {
        missing.add('Business Details');
      }
    }
    return missing;
  }

  // Sync profile details
  Future<void> updateProfile(UserProfile updated) async {
    _profile = updated;
    _filters['state'] = _profile.state;
    _filters['community'] = _profile.community;
    _filters['gender'] = _profile.gender;
    notifyListeners();
    await _saveProfile();

    if (_isLoggedIn) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          // Sync profiles table (single source of truth)
          await SchemeRepository.instance.createProfile(_profile);

          // Sync startup_profiles table if they have business details
          final existingStartups = await Supabase.instance.client
              .from('startup_profiles')
              .select('id')
              .eq('user_id', user.id)
              .limit(1);

          final Map<String, dynamic> startupData = {
            'user_id': user.id,
            'profile_name': '${_profile.name} Business',
            'industry': _profile.businessIndustry.isNotEmpty ? _profile.businessIndustry : 'Technology',
            'applicant_type': _profile.employmentStatus.isNotEmpty ? _profile.employmentStatus : 'Student',
            'business_stage': _profile.businessStage.isNotEmpty ? _profile.businessStage : 'Idea',
            'business_registered': _profile.existingBusiness,
            'funding_required_amount': _profile.fundingRequired,
            'registration_numbers': _profile.registrationNumbers,
            'is_active': true,
          };

          if (existingStartups.isNotEmpty) {
            startupData['id'] = existingStartups.first['id'];
          }

          await Supabase.instance.client.from('startup_profiles').upsert(startupData);
        } catch (e) {
          debugPrint('Error syncing profile updates: $e');
        }
      }
    }
  }

  Future<void> updateProfilePhoto(String path) async {
    _profile = _profile.copyWith(profilePhoto: path);
    notifyListeners();
    await _saveProfile();
  }

  // Location/GPS Helper
  Future<Map<String, dynamic>?> fetchLocationAndPopulate() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

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
          'village': placemark.subLocality != null && placemark.name != null && placemark.subLocality != placemark.name ? placemark.name : '',
          'state': placemark.administrativeArea ?? '',
          'district': (placemark.subAdministrativeArea != null && placemark.subAdministrativeArea!.isNotEmpty)
              ? placemark.subAdministrativeArea!
              : (placemark.locality ?? ''),
          'city': placemark.locality ?? placemark.subLocality ?? '',
          'pinCode': placemark.postalCode ?? '',
          'latitude': position.latitude,
          'longitude': position.longitude,
        };

        _profile = _profile.copyWith(
          house: locData['house'] as String,
          street: locData['street'] as String,
          area: locData['area'] as String,
          village: locData['village'] as String,
          state: locData['state'] as String,
          district: locData['district'] as String,
          city: locData['city'] as String,
          pinCode: locData['pinCode'] as String,
        );

        notifyListeners();
        await _saveProfile();
        return locData;
      }
    } catch (e) {
      debugPrint('Error fetching location: $e');
    }
    return null;
  }

  List<Map<String, dynamic>> get downloadedDocs => _downloadedDocs;

  Future<void> _saveDownloadedDocs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('downloadedDocs', jsonEncode(_downloadedDocs));
  }

  void downloadDoc(String id, String title, String size) {
    if (!_downloadedDocs.any((doc) => doc['id'] == id)) {
      final now = DateTime.now();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final dateStr = 'Downloaded on ${now.day} ${months[now.month - 1]} ${now.year}';
      
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
}
