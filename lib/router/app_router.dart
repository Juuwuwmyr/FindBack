import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/auth_provider.dart';
import '../features/auth/domain/auth_state.dart';
import '../features/profile/domain/profile_provider.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/verify_email_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/reports/presentation/feed_screen.dart';
import '../features/reports/presentation/report_detail_screen.dart';
import '../features/reports/presentation/create_report_screen.dart';
import '../features/reports/presentation/edit_report_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/claims/presentation/submit_claim_screen.dart';
import '../features/claims/presentation/claim_detail_screen.dart';
import '../features/claims/presentation/claims_list_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/moderation/presentation/moderation_queue_screen.dart';
import '../features/shell/main_shell.dart';

// Auth-required route paths
const _authRequired = [
  '/report/create',
  '/profile/edit',
  '/notifications',
];

bool _requiresAuth(String location) {
  if (_authRequired.contains(location)) return true;
  if (location.startsWith('/report/') && location.endsWith('/edit')) return true;
  if (location.startsWith('/claims/')) return true;
  return false;
}

bool _requiresModerator(String location) {
  return location == '/moderation';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/feed',
    refreshListenable: _AuthNotifierListenable(ref),
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider).valueOrNull;
      final authenticated = authState?.isAuthenticated ?? false;
      final emailVerified = authState?.isEmailVerified ?? false;
      final moderator = ref.read(ownProfileProvider).valueOrNull?.isModerator ?? false;
      final location = state.matchedLocation;

      // Moderator-only routes
      if (_requiresModerator(location)) {
        if (!authenticated) return '/auth/login';
        if (!moderator) return '/feed';
      }

      // Auth-required routes
      if (_requiresAuth(location)) {
        if (!authenticated) return '/auth/login';
        if (!emailVerified) return '/auth/verify-email';
      }

      // Already-authenticated users don't need auth screens
      if (location.startsWith('/auth/') && authenticated) return '/feed';

      return null;
    },
    routes: [
      // Auth routes (outside shell)
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),

      // Report routes outside shell
      GoRoute(
        path: '/report/create',
        builder: (context, state) => const CreateReportScreen(),
      ),
      GoRoute(
        path: '/report/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ReportDetailScreen(id: id);
        },
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return EditReportScreen(id: id);
            },
          ),
        ],
      ),

      // Profile edit outside shell
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),

      // Claims routes outside shell
      GoRoute(
        path: '/claims/submit/:reportId',
        builder: (context, state) {
          final reportId = state.pathParameters['reportId']!;
          return SubmitClaimScreen(reportId: reportId);
        },
      ),
      GoRoute(
        path: '/claims/list/:reportId',
        builder: (context, state) {
          final reportId = state.pathParameters['reportId']!;
          return ClaimsListScreen(reportId: reportId);
        },
      ),
      GoRoute(
        path: '/claims/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ClaimDetailScreen(id: id);
        },
      ),

      // Moderation outside shell
      GoRoute(
        path: '/moderation',
        builder: (context, state) => const ModerationQueueScreen(),
      ),

      // Shell routes (bottom nav)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                builder: (context, state) => const FeedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile/:userId',
                builder: (context, state) {
                  final userId = state.pathParameters['userId']!;
                  return ProfileScreen(userId: userId);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Makes GoRouter re-run its redirect when authNotifierProvider changes.
class _AuthNotifierListenable extends ChangeNotifier {
  _AuthNotifierListenable(Ref ref) {
    ref.listen<AsyncValue<AppAuthState>>(authNotifierProvider, (_, __) {
      notifyListeners();
    });
  }
}
