import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:macoloc/src/providers/auth_provider.dart';
import 'auth_provider_test.mocks.dart';

@GenerateMocks([FirebaseAuth, User, UserCredential])
void main() {
  late MockFirebaseAuth mockAuth;
  late ProviderContainer container;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(mockAuth),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('authStateProvider', () {
    test('emits null when user is not signed in', () async {
      when(mockAuth.authStateChanges())
          .thenAnswer((_) => Stream.value(null));

      final authState = container.read(authStateProvider);
      // StreamProvider starts as loading
      expect(authState.isLoading, isTrue);
    });

    test('emits user when signed in', () async {
      final mockUser = MockUser();
      when(mockUser.uid).thenReturn('uid1');
      when(mockAuth.authStateChanges())
          .thenAnswer((_) => Stream.value(mockUser));

      // Wait for the stream to emit
      await container.read(authStateProvider.future);
      final authState = container.read(authStateProvider);
      expect(authState.valueOrNull?.uid, 'uid1');
    });
  });

  group('signInWithEmail', () {
    test('calls Firebase signInWithEmailAndPassword', () async {
      final mockCredential = MockUserCredential();
      when(mockAuth.signInWithEmailAndPassword(
        email: 'test@test.com',
        password: 'password123',
      )).thenAnswer((_) async => mockCredential);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signInWithEmail('test@test.com', 'password123');

      verify(mockAuth.signInWithEmailAndPassword(
        email: 'test@test.com',
        password: 'password123',
      )).called(1);
    });
  });

  group('signUp', () {
    test('calls Firebase createUserWithEmailAndPassword', () async {
      final mockCredential = MockUserCredential();
      when(mockAuth.createUserWithEmailAndPassword(
        email: 'new@test.com',
        password: 'password123',
      )).thenAnswer((_) async => mockCredential);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signUp('new@test.com', 'password123');

      verify(mockAuth.createUserWithEmailAndPassword(
        email: 'new@test.com',
        password: 'password123',
      )).called(1);
    });
  });

  group('signOut', () {
    test('calls Firebase signOut', () async {
      when(mockAuth.signOut()).thenAnswer((_) async {});

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signOut();

      verify(mockAuth.signOut()).called(1);
    });
  });
}
