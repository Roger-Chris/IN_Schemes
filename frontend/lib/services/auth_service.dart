import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final client = Supabase.instance.client;

  static const googleRedirectUrl = 'com.inschemes.app://login-callback/';

  static User? get currentUser => client.auth.currentUser;

  static Session? get currentSession => client.auth.currentSession;

  static Future<bool> signInWithGoogle() async {
    try {
      return await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: googleRedirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
        scopes: 'openid email profile',
      );
    } catch (e) {
      debugPrint('[AuthService] Unable to start Google OAuth: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }
}
