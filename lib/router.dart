import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/house_provider.dart';
import 'src/features/onboarding/sign_in_screen.dart';
import 'src/features/onboarding/house_choice_screen.dart';
import 'src/features/onboarding/create_house_screen.dart';
import 'src/features/onboarding/join_house_screen.dart';
import 'src/features/onboarding/house_created_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final houseIdAsync = ref.watch(currentHouseIdProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isOnAuthPage = state.matchedLocation == '/sign-in';
      final isOnOnboarding = state.matchedLocation.startsWith('/onboarding');
      final isLoading = authState.isLoading || houseIdAsync.isLoading;

      // While auth or house query is loading, stay put (show splash/loading)
      if (isLoading) return null;

      // Not logged in -> sign-in
      if (!isLoggedIn && !isOnAuthPage) return '/sign-in';
      // Logged in but on sign-in page -> onboarding or home
      if (isLoggedIn && isOnAuthPage) {
        return houseIdAsync.valueOrNull != null ? '/home' : '/onboarding';
      }
      // Logged in, no house, not on onboarding -> onboarding
      if (isLoggedIn && houseIdAsync.valueOrNull == null && !isOnOnboarding) {
        return '/onboarding';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const HouseChoiceScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const CreateHouseScreen(),
          ),
          GoRoute(
            path: 'join',
            builder: (context, state) => const JoinHouseScreen(),
          ),
          GoRoute(
            path: 'created',
            builder: (context, state) => const HouseCreatedScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Home — Sprint 2')),
        ),
      ),
      GoRoute(
        path: '/',
        redirect: (context, state) => '/sign-in',
      ),
    ],
  );
});
