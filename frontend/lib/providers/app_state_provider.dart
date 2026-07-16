import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';
import '../models/scheme_model.dart';
import '../engine/recommendation_engine.dart';

class AppProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isGuest = false;
  String _mobileNumber = '';
  String _selectedLanguage = 'en'; // 'en', 'hi'
  int _currentTabIndex = 0; // Bottom Navigation: 0: Home, 1: Categories, 2: Search, 3: FindMySchemes, 4: Profile
  UserProfile _profile = UserProfile();
  List<String> _bookmarkedIds = [];
  List<String> _recentlyViewedIds = [];
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
      'content': 'Prime Minister launches a new seed grant portal for tech startups and students.'
    },
    {
      'title': 'Tamil Nadu MSME Department Subsidy Hike',
      'date': '04-Jul-2026',
      'content': 'NEEDS scheme subsidy ceiling raised to ₹75 Lakhs for women and minority entrepreneurs.'
    },
    {
      'title': 'Mudra Loan Shishu Limit Extended',
      'date': '29-May-2026',
      'content': 'Collateral-free micro loans under Shishu category increased to ₹1 Lakh.'
    }
  ];

  // Mock Notifications
  final List<Map<String, dynamic>> notifications = [
    {
      'id': '1',
      'title': 'New Scheme Added',
      'body': 'StartupTN Seed Grant details updated. Check eligibility now.',
      'time': '10 minutes ago',
      'read': false
    },
    {
      'id': '2',
      'title': 'Application Deadline',
      'body': 'NEEDS Tamil Nadu application cycle ends on August 31st. Complete your profile.',
      'time': '2 hours ago',
      'read': false
    },
    {
      'id': '3',
      'title': 'Profile Reminder',
      'body': 'Complete your profile setup to receive 100% accurate scheme matches.',
      'time': '1 day ago',
      'read': true
    }
  ];

  AppProvider() {
    _loadState();
  }

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  bool get isGuest => _isGuest;
  String get mobileNumber => _mobileNumber;
  String get selectedLanguage => _selectedLanguage;
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
    return Scheme.seedData.where((s) => _recentlyViewedIds.contains(s.id)).toList();
  }

  // Load state from SharedPreferences (for session continue support)
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedLanguage = prefs.getString('language') ?? 'en';
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _isGuest = prefs.getBool('isGuest') ?? false;
      _mobileNumber = prefs.getString('mobileNumber') ?? '';
      _currentTabIndex = prefs.getInt('currentTabIndex') ?? 0;
      
      final profileStr = prefs.getString('userProfile');
      if (profileStr != null) {
        _profile = UserProfile.fromJson(jsonDecode(profileStr));
      }
      
      _bookmarkedIds = prefs.getStringList('bookmarks') ?? [];
      _recentlyViewedIds = prefs.getStringList('recentlyViewed') ?? [];
      
      // Initialize filters based on loaded profile
      _filters['state'] = _profile.state;
      _filters['community'] = _profile.community;
      _filters['gender'] = _profile.gender;
      
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
    await prefs.setBool('isLoggedIn', _isLoggedIn);
    await prefs.setBool('isGuest', _isGuest);
    await prefs.setString('mobileNumber', _mobileNumber);
  }

  // Setters & Actions
  void changeLanguage(String lang) async {
    _selectedLanguage = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
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
      await GoogleSignIn.instance.initialize(
        clientId: '1033361761527-n9759fh7qsur1c6g142f2tceo62g9o3t.apps.googleusercontent.com',
      );
      final account = await GoogleSignIn.instance.authenticate();
      _isLoggedIn = true;
      _isGuest = false;
      _mobileNumber = ''; // Google sign in does not provide mobile number by default
      _currentTabIndex = 0;
      _profile = UserProfile(
        name: account.displayName ?? 'Google User',
        email: account.email,
      );
      notifyListeners();
      await _saveLoginState();
      await _saveProfile();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('currentTabIndex', 0);
      return true;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
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
    _isLoggedIn = false;
    _isGuest = false;
    _mobileNumber = '';
    _profile = UserProfile();
    _bookmarkedIds.clear();
    _recentlyViewedIds.clear();
    _currentTabIndex = 0;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  void updateProfile(UserProfile updated) {
    _profile = updated;
    // Keep filters in sync
    _filters['state'] = _profile.state;
    _filters['community'] = _profile.community;
    _filters['gender'] = _profile.gender;
    notifyListeners();
    _saveProfile();
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
}
