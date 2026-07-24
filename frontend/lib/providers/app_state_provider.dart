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
import '../services/profile_service.dart';

class AppProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool _isLoggedIn = false;
  bool _isGuest = false;
  String _mobileNumber = '';
  String _selectedLanguage = 'en'; // 'en', 'hi'
  String _navigationMode = 'regular'; // 'regular', 'companion'
  int _currentTabIndex =
      0; // Bottom Navigation: 0: Home, 1: Categories, 2: Search, 3: FindMySchemes, 4: Profile
  UserProfile _profile = UserProfile();
  List<String> _bookmarkedIds = [];
  List<String> _recentlyViewedIds = [];
  List<Map<String, dynamic>> _downloadedDocs = [];
  String _searchQuery = '';


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
        _isGuest = false;
        final user = session.user;
        _mobileNumber = user.phone ?? '';

        await loadProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        _isLoggedIn = false;
        _isGuest = false;
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
  bool get isGuest => _isGuest;
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

  // Recommendations calculated on-the-fly based on current profile details
  List<MapEntry<Scheme, RecommendationResult>> get recommendedSchemes {
    return RecommendationEngine.getRecommendations(_profile, Scheme.seedData);
  }

  // Bookmarked schemes list
  List<Scheme> get bookmarkedSchemes {
    return Scheme.seedData.where((s) => _bookmarkedIds.contains(s.id)).toList();
  }

  // Recently viewed schemes list
  List<Scheme> get recentlyViewedSchemes {
    return Scheme.seedData
        .where((s) => _recentlyViewedIds.contains(s.id))
        .toList();
  }

  // Load state from SharedPreferences (for session continue support)
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedLanguage = prefs.getString('language') ?? 'en';
      _navigationMode = prefs.getString('navigationMode') ?? 'regular';
      _isGuest = prefs.getBool('isGuest') ?? false;
      _currentTabIndex = prefs.getInt('currentTabIndex') ?? 0;


      final profileStr = prefs.getString('userProfile');
      if (profileStr != null) {
        _profile = UserProfile.fromJson(jsonDecode(profileStr));
      }

      _bookmarkedIds = prefs.getStringList('bookmarks') ?? ['POST_MATRIC', 'PM_MATRU_VANDANA', 'PM_AWAS'];
      _recentlyViewedIds = prefs.getStringList('recentlyViewed') ?? ['NSP_PORTAL', 'PM_EDRIVE', 'AYUSHMAN_BHARAT', 'MUDRA'];

      final downloadedDocsStr = prefs.getString('downloadedDocs');
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
        _isLoggedIn = true;
        _isGuest = false;
        _mobileNumber = session.user.phone ?? '';
        loadProfile();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading state: $e');
    }
  }

  // Save state helpers
  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userProfile', jsonEncode(_profile.toJson()));
  }

  Future<void> _saveLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuest', _isGuest);
  }

  // Setters & Actions
  void changeLanguage(String lang) async {
    _selectedLanguage = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
  }

  void changeNavigationMode(String mode) async {
    _navigationMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('navigationMode', mode);
  }


  void login(String mobile) async {
    _isLoggedIn = true;
    _isGuest = false;
    _mobileNumber = mobile;
    _currentTabIndex = 0;
    // Default initial profile
    _profile = UserProfile(mobile: mobile);
    notifyListeners();
    await _saveLoginState();
    await _saveProfile();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentTabIndex', 0);
  }

  Future<bool> loginWithGoogle() async {
    try {
      final response = await AuthService.signInWithGoogle();
      if (response.user != null) {
        _currentTabIndex = 0;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('currentTabIndex', 0);
        return true;
      }
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
    return false;
  }

  void continueAsGuest() async {
    _isLoggedIn = false;
    _isGuest = true;
    _mobileNumber = '';
    _currentTabIndex = 0;
    _profile = UserProfile(name: 'Guest User');
    notifyListeners();
    await _saveLoginState();
    await _saveProfile();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentTabIndex', 0);
  }

  void logout() async {
    await Supabase.instance.client.auth.signOut();

    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language');
    final onboarding = prefs.getBool('onboardingCompleted');

    await prefs.clear();

    if (lang != null) {
      await prefs.setString('language', lang);
    }
    if (onboarding != null) {
      await prefs.setBool('onboardingCompleted', onboarding);
    }

    _isLoggedIn = false;
    _isGuest = false;
    _mobileNumber = '';
    _profile = UserProfile();
    _bookmarkedIds.clear();
    _recentlyViewedIds.clear();
    _currentTabIndex = 0;
    notifyListeners();
  }



  void updateTabIndex(int index) async {
    _currentTabIndex = index;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentTabIndex', index);
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
    updateProfile(_profile);
  }

  // Notification action
  void markNotificationRead(String id) {
    final idx = notifications.indexWhere((n) => n['id'] == id);
    if (idx != -1) {
      notifications[idx]['read'] = true;
      notifyListeners();
    }
  }

  // Completion calculation
  int get profileCompletionPercentage {
    int totalFields = 6;
    int filledFields = 0;

    if (_profile.mobile.isNotEmpty) filledFields++;
    if (_profile.dob != null) filledFields++;
    if (_profile.address.isNotEmpty) filledFields++;
    if (_profile.existingBusiness) filledFields++;
    if (_profile.qualification.isNotEmpty) filledFields++;
    if (_profile.profileCompleted) filledFields++;

    return ((filledFields / totalFields) * 100).round();
  }

  List<String> get missingProfileSections {
    final missing = <String>[];
    if (_profile.mobile.isEmpty) missing.add('Phone');
    if (_profile.address.isEmpty) missing.add('Address');
    if (!_profile.existingBusiness) missing.add('Business');
    return missing;
  }

  // Sync profile details
  Future<void> updateProfile(UserProfile updated) async {
    await saveProfile(updated);
  }

  Future<void> loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fetched = await ProfileService.fetchProfile(user.id);
      if (fetched != null) {
        _profile = fetched;
        _mobileNumber = _profile.mobile;
        _filters['state'] = _profile.state;
        _filters['community'] = _profile.community;
        _filters['gender'] = _profile.gender;
        await _saveProfile();
      } else {
        // Create default profile
        final defaultProfile = UserProfile(
          name: user.userMetadata?['full_name'] ??
              user.userMetadata?['name'] ??
              'Google User',
          email: user.email ?? '',
          mobile: user.phone ?? '',
          googleUserId: user.id,
          provider: 'google',
        );
        await ProfileService.createProfile(user.id, defaultProfile);
        _profile = defaultProfile;
        _mobileNumber = _profile.mobile;
        await _saveProfile();
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveProfile(UserProfile updatedProfile) async {
    final user = Supabase.instance.client.auth.currentUser;
    _isLoading = true;
    _error = null;
    _profile = updatedProfile;
    _filters['state'] = _profile.state;
    _filters['community'] = _profile.community;
    _filters['gender'] = _profile.gender;
    notifyListeners();

    try {
      if (user != null) {
        await ProfileService.updateProfile(user.id, updatedProfile);
      }
      await _saveProfile();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error saving profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    await loadProfile();
  }

  // Location/GPS Helper
  Future<Map<String, dynamic>?> fetchLocationAndPopulate() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied';
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
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
          'district': placemark.subAdministrativeArea ?? '',
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
      rethrow;
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
