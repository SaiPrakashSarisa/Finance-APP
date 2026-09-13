import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

/// Purpose: Registration / Sign Up Screen
/// Author: Antigravity AI
/// Design System: Stitch Finance Hub Enterprise (Luminous Ledger)

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController(text: 'Android Demo User');
  final _emailController = TextEditingController(text: 'android_demo@example.com');
  final _passwordController = TextEditingController(text: '123456');
  bool _obscurePassword = true;

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) return;

    final success = await ref.read(authProvider.notifier).register(name, email, password);

    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: AppColors.onSurface,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Start managing your finances like an enterprise',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 28),

                // Glass Form Panel
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Full Name',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        style: GoogleFonts.outfit(color: AppColors.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Enter your full name',
                          hintStyle: GoogleFonts.outfit(color: AppColors.outline),
                          filled: true,
                          fillColor: AppColors.surfaceContainerHigh,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Email Address',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        style: GoogleFonts.outfit(color: AppColors.onSurface),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Enter your email',
                          hintStyle: GoogleFonts.outfit(color: AppColors.outline),
                          filled: true,
                          fillColor: AppColors.surfaceContainerHigh,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary, size: 20),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Password',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: GoogleFonts.outfit(color: AppColors.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Create a password',
                          hintStyle: GoogleFonts.outfit(color: AppColors.outline),
                          filled: true,
                          fillColor: AppColors.surfaceContainerHigh,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.onSurfaceVariant,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      if (authState.error != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.expenseRose.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.expenseRose.withOpacity(0.3)),
                          ),
                          child: Text(
                            authState.error!,
                            style: GoogleFonts.outfit(color: AppColors.expenseRose, fontSize: 12, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: authState.isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryViolet,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                          shadowColor: AppColors.primaryViolet.withOpacity(0.4),
                        ),
                        child: authState.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                'Create Account',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
