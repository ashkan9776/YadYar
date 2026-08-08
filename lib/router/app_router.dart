import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/books/book_detail_page.dart';
import '../features/books/book_edit_page.dart';
import '../features/categories/categories_page.dart';
import '../features/categories/category_detail_page.dart';
import '../features/categories/category_edit_page.dart';
import '../features/data_management/data_management_page.dart';
import '../features/decks/deck_detail_page.dart';
import '../features/decks/deck_edit_page.dart';
import '../features/home/home_page.dart';
import '../features/quiz/quiz_page.dart';
import '../features/review/review_page.dart';
import '../features/search/search_page.dart';
import '../features/settings/settings_page.dart';
import '../features/shell/home_shell.dart';
import '../features/stats/stats_page.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// مسیریاب اصلی اپ با نوار ناوبری پایین (خانه / دسته‌بندی‌ها / آمار).
final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => HomeShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/', builder: (_, _) => const HomePage())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
                path: '/decks', builder: (_, _) => const CategoriesPage()),
          ],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/stats', builder: (_, _) => const StatsPage())],
        ),
      ],
    ),

    // ── مرور و آزمون ─────────────────────────────────────────────
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

    // ── تنظیمات / داده / جستجو ───────────────────────────────────
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const SettingsPage(),
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

    // ── دسته‌بندی‌ها ───────────────────────────────────────────────
    GoRoute(
      path: '/category-new',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const CategoryEditPage(),
    ),
    GoRoute(
      path: '/category/:id',
      parentNavigatorKey: _rootKey,
      builder: (_, state) => CategoryDetailPage(
          categoryId: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/category/:id/edit',
      parentNavigatorKey: _rootKey,
      builder: (_, state) => CategoryEditPage(
          categoryId: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/category/:id/book-new',
      parentNavigatorKey: _rootKey,
      builder: (_, state) => BookEditPage(
          categoryId: int.parse(state.pathParameters['id']!)),
    ),

    // ── کتاب‌ها ────────────────────────────────────────────────────
    GoRoute(
      path: '/book/:id',
      parentNavigatorKey: _rootKey,
      builder: (_, state) =>
          BookDetailPage(bookId: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/book/:id/edit',
      parentNavigatorKey: _rootKey,
      builder: (_, state) =>
          BookEditPage(bookId: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/book/:id/deck-new',
      parentNavigatorKey: _rootKey,
      builder: (_, state) =>
          DeckEditPage(bookId: int.parse(state.pathParameters['id']!)),
    ),

    // ── دک‌ها (جزئیات / ویرایش) ────────────────────────────────────
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
  ],
);
