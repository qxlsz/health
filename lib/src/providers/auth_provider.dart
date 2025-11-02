import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:health_app/src/services/supabase_client.dart';

/// Provider for current authentication state
final authStateProvider = StreamProvider<User?>((ref) {
  return SupabaseService.client.auth.onAuthStateChange.map(
    (event) => event.session?.user,
  );
});

/// Provider for authentication service
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Service class for authentication operations
class AuthService {
  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      return await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await SupabaseService.client.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// Get current user
  User? get currentUser => SupabaseService.client.auth.currentUser;

  /// Get current session
  Session? get currentSession => SupabaseService.client.auth.currentSession;
}

