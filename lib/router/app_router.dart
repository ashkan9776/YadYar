import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/data_management/data_management_page.dart';
import '../features/decks/deck_detail_page.dart';
import '../features/decks/deck_edit_page.dart';
import '../features/decks/decks_page.dart';
import '../features/home/home_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/quiz/quiz_page.dart';
import '../features/review/review_page.dart';
import '../features/search/search_page.dart';
import '../features/settings/settings_page.dart';
import '../features/shell/home_shell.dart';
import '../features/stats/stats_page.dart';
import '../providers/providers.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// مسیریاب اصلی اپ — به‌صورت provider تا بتواند تنظیمات کاربر را watch کند.
/// ریدایرکت آنبوردینگ: اگر کاربر هنوز آنبوردینگ را ندیده باشد، به /onboarding هدایت می‌شود.
final appRouterProvider = Provider<GoRouter>((ref) {
  final onboardingDone = ref.watch(settingsProvider).onboardingDone;

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (!onboardingDone && loc != '/onboarding') return '/onboarding';
      if (onboardingDone && loc == '/onboarding') return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const OnboardingPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (_, _) => const HomePage())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/decks', builder: (_, _) => const DecksPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/stats', builder: (_, _) => const StatsPage()),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/review/:deckId',
        parentNavigatorKey: _rootKey,
        builder: (_, state) {
          final raw = state.pathParameters['deckId']!;
          final deckId = int.tryParse(raw) ?? -1;
          return ReviewPage(deckId: deckId);
        },
      ),
      GoRoute(
        path: '/quiz/:deckId',
        parentNavigatorKey: _rootKey,
        builder: (_, state) {
          final raw = state.pathParameters['deckId']!;
          final deckId = int.tryParse(raw) ?? -1;
          return QuizPage(deckId: deckId);
        },
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const SettingsPage(),
      ),
      GoRoute(
        path: '/deck-new',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const DeckEditPage(),
      ),
      GoRoute(
        path: '/deck/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            DeckDetailPage(deckId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/deck/:id/edit',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            DeckEditPage(deckId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/data',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const DataManagementPage(),
      ),
      GoRoute(
        path: '/search',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const SearchPage(),
      ),
    ],
  );
});
