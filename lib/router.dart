import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/house_provider.dart';
import 'src/features/onboarding/sign_in_screen.dart';
import 'src/features/onboarding/house_choice_screen.dart';
import 'src/features/onboarding/create_house_screen.dart';
import 'src/features/onboarding/join_house_screen.dart';
import 'src/features/onboarding/house_created_screen.dart';
import 'src/features/shell/mobile_shell.dart';
import 'src/features/home/home_screen.dart';
import 'src/features/issues/issues_list_screen.dart';
import 'src/features/issues/create_issue_screen.dart';
import 'src/features/issues/issue_detail_screen.dart';
import 'src/features/leaderboard/leaderboard_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final houseIdAsync = ref.watch(currentHouseIdProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      // Dev bypass: skip auth when Firebase is placeholder (no real backend)
      if (kDebugMode && DefaultFirebaseOptions.isPlaceholder) {
        // Allow free navigation — go to /home if on root or sign-in
        if (state.matchedLocation == '/' ||
            state.matchedLocation == '/sign-in') {
          return '/home';
        }
        return null;
      }

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

      // Main shell with bottom tab bar
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MobileShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/issues',
                builder: (context, state) => const IssuesListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/leaderboard',
                builder: (context, state) => const LeaderboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Profile — Coming Soon')),
                ),
              ),
            ],
          ),
        ],
      ),

      // Sub-screens outside the shell (use root navigator)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/create',
        builder: (context, state) => const CreateIssueScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/issues/:id',
        builder: (context, state) => IssueDetailScreen(
          issueId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/settings',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Settings — Coming Soon')),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/clean',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Deep Clean — Coming Soon')),
        ),
      ),

      GoRoute(
        path: '/',
        redirect: (context, state) => '/sign-in',
      ),
    ],
  );
});
