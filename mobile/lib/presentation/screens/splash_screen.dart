import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

/// Purpose: Splash & Initial Session Check Screen
/// Author: Antigravity AI
/// Design System: Stitch Finance Hub Enterprise

import '../../core/security/mpin_service.dart';
import '../../core/security/biometric_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // 1. Await both minimum splash animation duration and local session check
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 800)),
      ref.read(authProvider.notifier).checkSession(),
    ]);
    if (!mounted) return;

    final authState = ref.read(authProvider);
    debugPrint('[SPLASH] Session check: isAuthenticated=${authState.isAuthenticated}, user=${authState.user?.name}');

    if (!authState.isAuthenticated) {
      context.go('/login');
      return;
    }

    // 2. User is authenticated locally. Check biometric unlock
    final isBioAvailable = await BiometricService.isBiometricsAvailable();
    final isBioEnabled = await BiometricService.isBiometricEnabled();
    debugPrint('[SPLASH] Biometrics check: available=$isBioAvailable, enabled=$isBioEnabled');

    if (isBioAvailable && isBioEnabled && mounted) {
      final authenticated = await BiometricService.authenticate(
        reason: 'Touch fingerprint sensor to unlock Finance Hub',
      );
      debugPrint('[SPLASH] Biometric authenticate result: $authenticated');
      if (authenticated && mounted) {
        context.go('/dashboard');
        return;
      }

      // If biometric was cancelled or failed by user:
      final hasMpin = await MpinService.hasMpin();
      if (hasMpin && mounted) {
        context.go('/mpin');
      } else if (mounted) {
        context.go('/login');
      }
      return;
    }

    // 3. If biometrics not enabled or not available on device:
    final hasMpin = await MpinService.hasMpin();
    if (hasMpin && mounted) {
      context.go('/mpin');
    } else if (mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Container with Neon Glow
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primaryContainer, AppColors.primaryViolet],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryViolet.withOpacity(0.4),
                    blurRadius: 28,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Finance Hub',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enterprise Financial Intelligence',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
