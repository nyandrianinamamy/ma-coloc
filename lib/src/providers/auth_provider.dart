import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../main.dart' show firebaseInitializedProvider;

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  final isReady = ref.watch(firebaseInitializedProvider);
  if (!isReady) return Stream.value(null);
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AsyncValue<void>>(AuthNotifier.new);

class AuthNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(firebaseAuthProvider)
          .signInWithEmailAndPassword(email: email, password: password);
    });
  }

  Future<void> signUp(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(firebaseAuthProvider)
          .createUserWithEmailAndPassword(email: email, password: password);
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();
      final account = await googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await ref.read(firebaseAuthProvider).signInWithCredential(credential);
    });
  }

  Future<void> signInAnonymously() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(firebaseAuthProvider).signInAnonymously();
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(firebaseAuthProvider).signOut();
    });
  }
}
