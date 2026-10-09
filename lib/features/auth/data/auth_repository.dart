import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/supabase_service.dart';

class AuthRepository {
  AuthRepository(this._client);
  final SupabaseClient _client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  User? get currentUser => _client.auth.currentUser;

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );
    } on AuthException catch (e) {
      throw AuthAppException(e.message);
    } catch (e) {
      throw ServerException('Sign up failed: $e');
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw AuthAppException(e.message);
    } catch (e) {
      throw ServerException('Sign in failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw AuthAppException(e.message);
    } catch (e) {
      throw ServerException('Sign out failed: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw AuthAppException(e.message);
    } catch (e) {
      throw ServerException('Password reset failed: $e');
    }
  }

  Future<void> resendVerificationEmail(String email) async {
    try {
      await _client.auth.resend(type: OtpType.signup, email: email);
    } on AuthException catch (e) {
      throw AuthAppException(e.message);
    } catch (e) {
      throw ServerException('Resend verification failed: $e');
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);
