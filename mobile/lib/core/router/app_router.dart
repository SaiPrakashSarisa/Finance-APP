import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/dashboard_screen.dart';
import '../../presentation/screens/accounts_screen.dart';
import '../../presentation/screens/transactions_screen.dart';
import '../../presentation/screens/add_transaction_screen.dart';

/// Purpose: Application Navigation Router using GoRouter
/// Author: Antigravity AI
/// Last Modified: 2026-08-03

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
      path: '/dashboard',
      builder: (BuildContext context, GoRouterState state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/accounts',
      builder: (BuildContext context, GoRouterState state) => const AccountsScreen(),
    ),
    GoRoute(
      path: '/transactions',
      builder: (BuildContext context, GoRouterState state) => const TransactionsScreen(),
    ),
    GoRoute(
      path: '/add-transaction',
      builder: (BuildContext context, GoRouterState state) => const AddTransactionScreen(),
    ),
  ],
);
