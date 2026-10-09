import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:findback/features/auth/domain/auth_provider.dart';
import 'package:findback/features/auth/domain/auth_state.dart';
import 'package:findback/features/auth/presentation/login_screen.dart';
import 'package:findback/core/theme/app_theme.dart';

// Stub notifier — returns unauthenticated, never touches Supabase
class _StubAuthNotifier extends AuthNotifier {
  @override
  Future<AppAuthState> build() async =>
      const AppAuthState(status: AuthStatus.unauthenticated);

  @override
  Future<void> signIn({required String email, required String password}) async {}
}

Widget _buildApp() {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(_StubAuthNotifier.new),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    ),
  );
}

void main() {
  testWidgets('shows validation errors when submitted with empty fields',
      (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump(); // settle the async build()

    // Tap the Sign In button without filling any fields
    final signInBtn = find.text('Sign In');
    expect(signInBtn, findsOneWidget);
    await tester.tap(signInBtn);
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('shows email validation error for invalid email', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();

    // Enter an invalid email, leave password empty
    await tester.enterText(find.byType(TextFormField).first, 'notanemail');
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Enter a valid email'), findsOneWidget);
  });
}
