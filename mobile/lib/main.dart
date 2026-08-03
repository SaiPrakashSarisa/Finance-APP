import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'core/router/app_router.dart';

/// Purpose: Main Entry Point of Flutter Mobile Application
/// Author: Antigravity AI
/// Last Modified: 2026-08-03

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: FinanceApp()));
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Finance Tracker Mobile',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primaryViolet,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryViolet,
          surface: AppColors.surface,
        ),
      ),
      routerConfig: appRouter,
    );
  }
}
