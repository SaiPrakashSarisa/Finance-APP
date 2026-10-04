import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/app_colors.dart';
import 'core/router/app_router.dart';
import 'data/sync/sync_manager.dart';

/// Purpose: Main Entry Point of Flutter Mobile Application (Offline-First)
/// Author: Antigravity AI
/// Design System: Stitch Finance Hub Enterprise (Luminous Ledger)

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize background sync & connectivity monitoring
  SyncManager.initialize();
  runApp(const ProviderScope(child: FinanceApp()));
}

class FinanceApp extends StatefulWidget {
  const FinanceApp({super.key});

  @override
  State<FinanceApp> createState() => _FinanceAppState();
}

class _FinanceAppState extends State<FinanceApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User brought app back to foreground: auto-flush pending queue & sync if stale
      SyncManager.syncIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Finance Hub Mobile',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primaryViolet,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryViolet,
          surface: AppColors.surfaceContainer,
          background: AppColors.background,
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      routerConfig: appRouter,
    );
  }
}
