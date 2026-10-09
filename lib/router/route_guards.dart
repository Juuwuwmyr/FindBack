import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/domain/auth_provider.dart';

bool isAuthenticated(WidgetRef ref) {
  final authState = ref.read(authNotifierProvider).valueOrNull;
  return authState?.isAuthenticated ?? false;
}

bool isEmailVerified(WidgetRef ref) {
  final authState = ref.read(authNotifierProvider).valueOrNull;
  return authState?.isEmailVerified ?? false;
}

bool isModerator(WidgetRef ref) {
  // Wired fully in TASK-011. Returns false for now.
  return false;
}
