import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/domain/auth_provider.dart';
import '../features/profile/domain/profile_provider.dart';

bool isAuthenticated(WidgetRef ref) {
  return ref.read(authNotifierProvider).valueOrNull?.isAuthenticated ?? false;
}

bool isEmailVerified(WidgetRef ref) {
  return ref.read(authNotifierProvider).valueOrNull?.isEmailVerified ?? false;
}

bool isModerator(WidgetRef ref) {
  return ref.read(ownProfileProvider).valueOrNull?.isModerator ?? false;
}
