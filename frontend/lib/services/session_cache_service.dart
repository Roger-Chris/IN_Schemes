import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class SessionCacheService {
  SessionCacheService._privateConstructor();
  static final SessionCacheService instance = SessionCacheService._privateConstructor();

  // Cache keys
  static const String _keyProfile = 'userProfile';
  static const String _keyLanguage = 'language';
  static const String _keyNavigationMode = 'navigationMode';
  static const String _keyOnboardingCompleted = 'onboardingCompleted';
  static const String _keyLastProfileSync = 'last_profile_sync';
  static const String _keyTheme = 'theme';
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyFeatureFlags = 'feature_flags';
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyIsGuest = 'isGuest';

  /// Loads the cached user profile.
  Future<UserProfile?> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileStr = prefs.getString(_keyProfile);
      if (profileStr != null) {
        return UserProfile.fromJson(jsonDecode(profileStr));
      }
    } catch (e) {
      debugPrint('[SessionCacheService] Error loading profile: $e');
    }
    return null;
  }

  /// Saves the user profile.
  Future<void> saveProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyProfile, jsonEncode(profile.toJson()));
      // Keep other sync fields updated
      await prefs.setString(_keyNavigationMode, profile.navigationMode);
      await prefs.setBool(_keyOnboardingCompleted, profile.profileCompleted);
      await prefs.setBool(_keyIsLoggedIn, profile.profileCompleted);
    } catch (e) {
      debugPrint('[SessionCacheService] Error saving profile: $e');
    }
  }

  /// Saves the language preference.
  Future<void> saveLanguage(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLanguage, language);
    } catch (e) {
      debugPrint('[SessionCacheService] Error saving language: $e');
    }
  }

  /// Saves the navigation mode preference.
  Future<void> saveNavigationMode(String mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyNavigationMode, mode);
    } catch (e) {
      debugPrint('[SessionCacheService] Error saving navigation mode: $e');
    }
  }

  /// Clears session-specific authentication cache (removes user profile, user ID, nav mode, etc.)
  /// while preserving global app preferences like language, theme, and first launch.
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Preserve settings
      final lang = prefs.getString(_keyLanguage);
      final theme = prefs.getString(_keyTheme);
      final firstLaunch = prefs.getBool(_keyFirstLaunch);
      final featureFlags = prefs.getString(_keyFeatureFlags);

      // Clear all
      await prefs.clear();

      // Restore settings
      if (lang != null) await prefs.setString(_keyLanguage, lang);
      if (theme != null) await prefs.setString(_keyTheme, theme);
      if (firstLaunch != null) await prefs.setBool(_keyFirstLaunch, firstLaunch);
      if (featureFlags != null) await prefs.setString(_keyFeatureFlags, featureFlags);
      
      debugPrint('[SessionCacheService] Auth session cache cleared. App preferences preserved.');
    } catch (e) {
      debugPrint('[SessionCacheService] Error clearing session: $e');
    }
  }

  /// Retrieves the last profile sync timestamp.
  Future<DateTime?> getLastProfileSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncStr = prefs.getString(_keyLastProfileSync);
      if (syncStr != null) {
        return DateTime.tryParse(syncStr);
      }
    } catch (e) {
      debugPrint('[SessionCacheService] Error getting last sync time: $e');
    }
    return null;
  }

  /// Updates the last profile sync timestamp to the current time.
  Future<void> updateLastProfileSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastProfileSync, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('[SessionCacheService] Error updating last sync time: $e');
    }
  }

  Future<String?> getLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyLanguage);
    } catch (e) {
      debugPrint('[SessionCacheService] Error getting language: $e');
      return null;
    }
  }

  Future<String?> getNavigationMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyNavigationMode);
    } catch (e) {
      debugPrint('[SessionCacheService] Error getting navigation mode: $e');
      return null;
    }
  }

  Future<bool> getIsGuest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsGuest) ?? false;
    } catch (e) {
      debugPrint('[SessionCacheService] Error getting isGuest: $e');
      return false;
    }
  }

  Future<void> saveIsGuest(bool isGuest) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsGuest, isGuest);
    } catch (e) {
      debugPrint('[SessionCacheService] Error saving isGuest: $e');
    }
  }

  Future<int> getCurrentTabIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('currentTabIndex') ?? 0;
    } catch (e) {
      debugPrint('[SessionCacheService] Error getting current tab index: $e');
      return 0;
    }
  }

  Future<void> saveCurrentTabIndex(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('currentTabIndex', index);
    } catch (e) {
      debugPrint('[SessionCacheService] Error saving current tab index: $e');
    }
  }

  Future<List<String>?> getBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('bookmarks');
    } catch (e) {
      debugPrint('[SessionCacheService] Error getting bookmarks: $e');
      return null;
    }
  }

  Future<void> saveBookmarks(List<String> bookmarks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('bookmarks', bookmarks);
    } catch (e) {
      debugPrint('[SessionCacheService] Error saving bookmarks: $e');
    }
  }

  Future<List<String>?> getRecentlyViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('recentlyViewed');
    } catch (e) {
      debugPrint('[SessionCacheService] Error getting recently viewed: $e');
      return null;
    }
  }

  Future<void> saveRecentlyViewed(List<String> recentlyViewed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recentlyViewed', recentlyViewed);
    } catch (e) {
      debugPrint('[SessionCacheService] Error saving recently viewed: $e');
    }
  }

  Future<String?> getDownloadedDocs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('downloadedDocs');
    } catch (e) {
      debugPrint('[SessionCacheService] Error getting downloaded docs: $e');
      return null;
    }
  }

  Future<void> saveDownloadedDocs(String downloadedDocs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('downloadedDocs', downloadedDocs);
    } catch (e) {
      debugPrint('[SessionCacheService] Error saving downloaded docs: $e');
    }
  }
}
