import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final client = Supabase.instance.client;

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '1033361761527-1cf1pr18qqsemtstpnidlfvntlgd7o6d.apps.googleusercontent.com',
  );

  static User? get currentUser => client.auth.currentUser;

  static Session? get currentSession => client.auth.currentSession;

  static Future<AuthResponse> signInWithGoogle() async {
    try {
      debugPrint('[AuthService] Google Sign-In starting...');
      
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('[AuthService] Google Sign-In was cancelled by the user.');
        throw 'Google Sign-In was cancelled by the user.';
      }
      
      debugPrint('[AuthService] Google Sign-In success for: ${googleUser.email}');
      
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      
      if (idToken == null) {
        debugPrint('[AuthService] Google Sign-In failed: ID Token not found.');
        throw 'Google Sign-In failed: ID Token not found.';
      }
      
      debugPrint('[AuthService] Supabase session creation starting via idToken...');
      final response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      
      debugPrint('[AuthService] Supabase session successfully created. User: ${response.user?.id}');
      return response;
    } catch (e) {
      debugPrint('[AuthService] Error during signInWithGoogle: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    debugPrint('[AuthService] Starting signOut process...');
    
    try {
      debugPrint('[AuthService] Signing out of Google Sign-In...');
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('[AuthService] Google signOut error: $e');
    }

    try {
      debugPrint('[AuthService] Revoking/Disconnecting Google Sign-In session...');
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint('[AuthService] Google disconnect error: $e');
    }

    try {
      debugPrint('[AuthService] Signing out of Supabase...');
      await client.auth.signOut();
    } catch (e) {
      debugPrint('[AuthService] Supabase signOut error: $e');
    }

    debugPrint('[AuthService] signOut process completed.');
  }
}

