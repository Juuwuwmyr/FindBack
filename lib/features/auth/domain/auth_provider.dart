import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

final authStreamProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

class AuthNotifier extends AsyncNotifier<AppAuthState> {
  @override
  Future<AppAuthState> build() async {
    // Re-evaluate when the auth stream fires
    ref.listen(authStreamProvider, (_, next) {
      next.whenData((authState) {
        final user = authState.session?.user;
        if (user == null) {
          state = const AsyncData(AppAuthState(status: AuthStatus.unauthenticated));
        } else if (user.emailConfirmedAt == null) {
          state = AsyncData(AppAuthState(status: AuthStatus.emailUnverified, user: user));
        } else {
          state = AsyncData(AppAuthState(status: AuthStatus.authenticated, user: user));
        }
      });
    });

    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return const AppAuthState(status: AuthStatus.unauthenticated);
    if (user.emailConfirmedAt == null) return AppAuthState(status: AuthStatus.emailUnverified, user: user);
    return AppAuthState(status: AuthStatus.authenticated, user: user);
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signIn(email: email, password: password);
      final user = ref.read(authRepositoryProvider).currentUser!;
      if (user.emailConfirmedAt == null) {
        return AppAuthState(status: AuthStatus.emailUnverified, user: user);
      }
      return AppAuthState(status: AuthStatus.authenticated, user: user);
    });
  }

  Future<void> signUp({required String email, required String password, required String displayName}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signUp(email: email, password: password, displayName: displayName);
      final user = ref.read(authRepositoryProvider).currentUser;
      return AppAuthState(status: AuthStatus.emailUnverified, user: user);
    });
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(AppAuthState(status: AuthStatus.unauthenticated));
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AppAuthState>(AuthNotifier.new);

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authNotifierProvider).valueOrNull?.user?.id;
});
