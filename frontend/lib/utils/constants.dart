import 'package:flutter/material.dart';

class AppConstants {
  // App Color Palette (New Light-Themed Premium Palette)
  static const Color primaryColor = Color(0xFF2563EB); // Royal Blue
  static const Color secondaryColor = Color(0xFF1565C0); // Azure Blue
  static const Color accentColor = Color(0xFFFF9933); // Saffron Orange
  static const Color successColor = Color(0xFF2E7D32); // Emerald Green
  static const Color warningColor = Color(0xFFFB8C00); // Amber Orange
  static const Color errorColor = Color(0xFFD32F2F); // Crimson Red

  static const Color backgroundColor = Color(0xFFF8FAFC); // Ice White
  static const Color surfaceColor = Color(0xFFFFFFFF); // Pure White
  static const Color cardBorderColor = Color(0xFFE5E7EB); // Mist Gray

  static const Color primaryText = Color(0xFF111827); // Charcoal Black
  static const Color secondaryText = Color(0xFF6B7280); // Slate Gray

  // Adjusted soft light blue gradient for scaffold background
  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFE0F2FE), Color(0xFFEFF6FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Colors.white70, Colors.white60],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Missing Document Assistance External Links (Official Portals)
  static const Map<String, String> documentLinks = {
    'PAN Card':
        'https://www.onlineservices.nsdl.com/paam/endUserRegisterContact.html',
    'Aadhaar Card': 'https://myaadhaar.uidai.gov.in/',
    'Udyam Registration Certificate': 'https://udyamregistration.gov.in/',
    'Nativity Certificate (TN)': 'https://www.tnesevai.tn.gov.in/',
    'Community Certificate': 'https://www.tnesevai.tn.gov.in/',
    'Artisan Identity Card (DC Handicrafts)': 'https://pehchan.deh.gov.in/',
    'DPIIT Certificate of Recognition': 'https://www.startupindia.gov.in/',
    'Certificate of Incorporation (Pvt Ltd / LLP / Registered Partnership)':
        'https://www.mca.gov.in/',
    'Project Report / Business Plan':
        'https://www.msmedi-chennai.gov.in/msme/project-profiles',
    'Project Report / DPR':
        'https://www.msmedi-chennai.gov.in/msme/project-profiles',
    'Project Report': 'https://www.msmedi-chennai.gov.in/msme/project-profiles',
    'Quotations for machinery/equipment': 'https://www.nsic.co.in/',
    'Price Quotation of machinery/equipment or items to be purchased':
        'https://www.nsic.co.in/',
  };

  // UI Translation Map for English & Tamil
  static const Map<String, Map<String, String>> translations = {
    'en': {
      'app_name': 'MSS',
      'tagline': 'Discover every Government Scheme in India',
      'launch_info': 'National Entrepreneurs\' Day Special Release',
      'continue': 'Continue',
      'login_title': 'Continue securely',
      'login_subtitle': 'Use your Google account to continue',
      'login_btn': 'Continue with Google',
      'guest_btn': 'Continue as Guest',
      'welcome_back': 'Welcome Back,',
      'recent_searches': 'Recent Searches',
      'popular_searches': 'Popular Searches',
      'recommended': 'Recommended for You',
      'categories': 'Scheme Categories',
      'search_placeholder': 'Search schemes, ministries, or keywords...',
      'check_eligibility': 'Check Eligibility',
      'saved_schemes': 'Saved Schemes',
      'notifications': 'Notifications',
      'profile': 'My Profile',
      'settings': 'Settings',
      'help_support': 'Help & Support',
    },
  };

  static String get(String key, String lang) {
    return translations[lang]?[key] ?? translations['en']?[key] ?? key;
  }
}
