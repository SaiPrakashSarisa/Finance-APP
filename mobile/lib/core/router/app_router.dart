import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/register_screen.dart';
import '../../presentation/screens/main_shell_screen.dart';
import '../../presentation/screens/add_transaction_screen.dart';
import '../../presentation/screens/accounts_screen.dart';
import '../../presentation/screens/categories_screen.dart';

/// Purpose: Application Navigation Router using GoRouter
/// Author: Antigravity AI
/// Design System: Stitch Finance Hub Enterprise

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: <RouteBase>[
    GoRoute(
      path: '/splash',
      builder: (BuildContext context, GoRouterState state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (BuildContext context, GoRouterState state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (BuildContext context, GoRouterState state) => const MainShellScreen(initialTab: 0),
    ),
    GoRoute(
      path: '/transactions',
      builder: (BuildContext context, GoRouterState state) => const MainShellScreen(initialTab: 1),
    ),
    GoRoute(
      path: '/budgets',
      builder: (BuildContext context, GoRouterState state) => const MainShellScreen(initialTab: 2),
    ),
    GoRoute(
      path: '/analytics',
      builder: (BuildContext context, GoRouterState state) => const MainShellScreen(initialTab: 3),
    ),
    GoRoute(
      path: '/profile',
      builder: (BuildContext context, GoRouterState state) => const MainShellScreen(initialTab: 4),
    ),
    GoRoute(
      path: '/accounts',
      builder: (BuildContext context, GoRouterState state) => const AccountsScreen(),
    ),
    GoRoute(
      path: '/categories',
      builder: (BuildContext context, GoRouterState state) => const CategoriesScreen(),
    ),
    GoRoute(
      path: '/add-transaction',
      builder: (BuildContext context, GoRouterState state) {
        final type = state.uri.queryParameters['type'] ?? 'expense';
        return AddTransactionScreen(initialType: type);
      },
    ),
  ],
);
