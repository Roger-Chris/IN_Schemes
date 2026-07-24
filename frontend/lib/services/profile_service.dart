import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class ProfileService {
  static final _client = Supabase.instance.client;

  static Future<UserProfile?> fetchProfile(String userId) async {
    try {
      final userRes = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (userRes == null) {
        return null;
      }

      final startupRes = await _client
          .from('startup_profiles')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      // Combine database results to construct the UserProfile model
      final Map<String, dynamic> merged = {};
      merged.addAll(userRes);
      if (startupRes != null) {
        merged.addAll(startupRes);
      }

      return UserProfile.fromJson(merged);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> createProfile(String userId, UserProfile profile) async {
    try {
      final userData = {
        'id': userId,
        'full_name': profile.name.isNotEmpty ? profile.name : 'Google User',
        'phone': profile.mobile,
        'is_active': true,
        'dob': profile.dob?.toIso8601String(),
        'gender': profile.gender,
        'disability': profile.disability,
        'veteran': profile.veteran,
        'house': profile.house,
        'street': profile.street,
        'area': profile.area,
        'village': profile.village,
        'pin': profile.pinCode,
        'state': profile.state,
        'district': profile.district,
        'city': profile.city,
        'qualification': profile.qualification,
        'employment': profile.employmentStatus,
        'annual_income': profile.annualIncome,
        'community': profile.community,
        'language': profile.language,
        'notifications': profile.notificationsEnabled,
        'theme': profile.theme,
        'profile_completed': profile.profileCompleted,
        'google_user_id': profile.googleUserId,
        'email_verified': profile.emailVerified,
        'provider': profile.provider,
        'last_login_time': DateTime.now().toIso8601String(),
      };

      await _client.from('users').insert(userData);

      final startupData = {
        'user_id': userId,
        'profile_name': '${profile.name.isNotEmpty ? profile.name : 'User'}\'s Business',
        'industry': profile.businessIndustry.isNotEmpty ? profile.businessIndustry : 'Technology',
        'applicant_type': profile.employmentStatus.isNotEmpty ? profile.employmentStatus : 'Student',
        'business_stage': profile.businessStage.isNotEmpty ? profile.businessStage : 'Idea',
        'business_registered': profile.existingBusiness,
        'funding_required_amount': profile.fundingRequired,
        'registration_numbers': profile.registrationNumbers,
        'is_active': true,
      };

      await _client.from('startup_profiles').insert(startupData);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> updateProfile(String userId, UserProfile profile) async {
    try {
      final userData = {
        'full_name': profile.name,
        'phone': profile.mobile,
        'dob': profile.dob?.toIso8601String(),
        'gender': profile.gender,
        'disability': profile.disability,
        'veteran': profile.veteran,
        'house': profile.house,
        'street': profile.street,
        'area': profile.area,
        'village': profile.village,
        'pin': profile.pinCode,
        'state': profile.state,
        'district': profile.district,
        'city': profile.city,
        'qualification': profile.qualification,
        'employment': profile.employmentStatus,
        'annual_income': profile.annualIncome,
        'community': profile.community,
        'language': profile.language,
        'notifications': profile.notificationsEnabled,
        'theme': profile.theme,
        'profile_completed': profile.profileCompleted,
        'google_user_id': profile.googleUserId,
        'email_verified': profile.emailVerified,
        'provider': profile.provider,
        'last_login_time': DateTime.now().toIso8601String(),
      };

      await _client.from('users').update(userData).eq('id', userId);

      // Check if a startup profile exists.
      final startupRes = await _client
          .from('startup_profiles')
          .select('id')
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();

      final startupData = {
        'user_id': userId,
        'profile_name': '${profile.name}\'s Business',
        'industry': profile.businessIndustry,
        'applicant_type': profile.employmentStatus,
        'business_stage': profile.businessStage,
        'business_registered': profile.existingBusiness,
        'funding_required_amount': profile.fundingRequired,
        'registration_numbers': profile.registrationNumbers,
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (startupRes != null) {
        await _client
            .from('startup_profiles')
            .update(startupData)
            .eq('id', startupRes['id']);
      } else {
        await _client.from('startup_profiles').insert(startupData);
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> deleteProfile(String userId) async {
    try {
      await _client.from('users').delete().eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }
}
