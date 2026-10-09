import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:findback/features/auth/data/auth_repository.dart';
import 'package:findback/core/errors/app_exception.dart';

class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late AuthRepository repo;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockClient.auth).thenReturn(mockAuth);
    repo = AuthRepository(mockClient);
  });

  group('AuthRepository', () {
    test('currentUser returns null when not signed in', () {
      when(() => mockAuth.currentUser).thenReturn(null);
      expect(repo.currentUser, isNull);
    });

    test('signIn throws AuthAppException on AuthException', () async {
      when(() => mockAuth.signInWithPassword(email: any(named:'email'), password: any(named:'password')))
          .thenThrow(AuthException('Invalid credentials'));
      expect(() => repo.signIn(email: 'a@b.com', password: 'wrong'), throwsA(isA<AuthAppException>()));
    });

    test('signUp throws AuthAppException on AuthException', () async {
      when(() => mockAuth.signUp(email: any(named:'email'), password: any(named:'password'), data: any(named:'data')))
          .thenThrow(AuthException('Email already registered'));
      expect(() => repo.signUp(email: 'a@b.com', password: 'pass1234', displayName: 'Test'), throwsA(isA<AuthAppException>()));
    });
  });
}
