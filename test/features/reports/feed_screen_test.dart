import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:findback/features/auth/domain/auth_provider.dart';
import 'package:findback/features/auth/domain/auth_state.dart';
import 'package:findback/features/reports/domain/reports_provider.dart';
import 'package:findback/features/reports/domain/item_report_model.dart';
import 'package:findback/features/reports/presentation/feed_screen.dart';
import 'package:findback/core/theme/app_theme.dart';

// Stub auth — unauthenticated, no Supabase dependency
class _StubAuthNotifier extends AuthNotifier {
  @override
  Future<AppAuthState> build() async =>
      const AppAuthState(status: AuthStatus.unauthenticated);
}

// Feed stub that returns an empty list immediately
class _EmptyFeedNotifier extends ReportsFeedNotifier {
  @override
  Future<List<ItemReportModel>> build() async => [];
}

// Feed stub whose build() never resolves — controlled by a Completer passed in
// from the test so the test can complete it on teardown.
class _HoldingFeedNotifier extends ReportsFeedNotifier {
  _HoldingFeedNotifier(this._completer);
  final Completer<List<ItemReportModel>> _completer;

  @override
  Future<List<ItemReportModel>> build() => _completer.future;
}

GoRouter _makeRouter() {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => const FeedScreen()),
    ],
  );
}

void main() {
  testWidgets('shows empty state when no reports', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_StubAuthNotifier.new),
          reportsFeedProvider.overrideWith(_EmptyFeedNotifier.new),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: _makeRouter(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No reports yet'), findsOneWidget);
  });

  testWidgets('shows loading state initially', (tester) async {
    // Use a Completer so build() never resolves during the test, keeping the
    // provider in AsyncLoading.  Complete it in addTearDown to avoid leaks.
    final completer = Completer<List<ItemReportModel>>();
    addTearDown(() {
      if (!completer.isCompleted) completer.complete([]);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_StubAuthNotifier.new),
          reportsFeedProvider
              .overrideWith(() => _HoldingFeedNotifier(completer)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: _makeRouter(),
        ),
      ),
    );
    // One pump — the future has not resolved, loading/shimmer state is shown.
    await tester.pump();

    // The shimmer loading skeleton renders Card widgets
    expect(find.byType(Card), findsWidgets);
  });
}
