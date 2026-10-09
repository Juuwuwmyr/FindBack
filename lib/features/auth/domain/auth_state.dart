import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus { initial, authenticated, unauthenticated, emailUnverified }

class AppAuthState {
  const AppAuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isEmailVerified => user?.emailConfirmedAt != null;

  AppAuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) => AppAuthState(
    status: status ?? this.status,
    user: user ?? this.user,
    errorMessage: errorMessage,
  );
}
