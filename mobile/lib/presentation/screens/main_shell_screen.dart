import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../providers/budget_provider.dart';
import '../providers/credit_provider.dart';
import 'dashboard_screen.dart';
import 'budgets_credits_screen.dart';
import 'analytics_screen.dart';
import 'profile_settings_screen.dart';

/// Purpose: Main Navigation Shell with Persistent Bottom Bar & FAB Quick Action Sheet
/// Author: Antigravity AI
/// Design System: Stitch Finance Hub Enterprise

class MainShellScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const MainShellScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    if (_currentIndex == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(budgetProvider.notifier).fetchSummary();
      });
    } else if (_currentIndex == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(creditProvider.notifier).fetchCredits();
      });
    }
  }

  @override
  void didUpdateWidget(MainShellScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      setState(() {
        _currentIndex = widget.initialTab;
      });
      if (_currentIndex == 2) {
        ref.read(budgetProvider.notifier).fetchSummary();
      } else if (_currentIndex == 1) {
        ref.read(creditProvider.notifier).fetchCredits();
      }
    }
  }

  final List<Widget> _screens = const [
    DashboardScreen(),
    CreditsScreen(),
    BudgetsScreen(),
    AnalyticsScreen(),
    ProfileSettingsScreen(),
  ];

  void _showQuickActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Quick Actions',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickActionButton(
                    icon: Icons.remove_circle_outline_rounded,
                    color: AppColors.expenseRose,
                    label: 'Expense',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/add-transaction?type=expense');
                    },
                  ),
                  _buildQuickActionButton(
                    icon: Icons.add_circle_outline_rounded,
                    color: AppColors.incomeEmerald,
                    label: 'Income',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/add-transaction?type=income');
                    },
                  ),
                  _buildQuickActionButton(
                    icon: Icons.swap_horiz_rounded,
                    color: AppColors.primaryViolet,
                    label: 'Transfer',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/add-transaction?type=transfer');
                    },
                  ),
                  _buildQuickActionButton(
                    icon: Icons.handshake_outlined,
                    color: AppColors.creditCyan,
                    label: 'Credit/Loan',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _currentIndex = 1; // Switch to Credits
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.5),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: _showQuickActionSheet,
            child: const Center(
              child: Icon(Icons.add_rounded, color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0C101F).withOpacity(0.96),
          border: const Border(
            top: BorderSide(color: Color(0x1AFFFFFF)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            if (index == 2) {
              ref.read(budgetProvider.notifier).fetchSummary();
            } else if (index == 1) {
              ref.read(creditProvider.notifier).fetchCredits();
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          unselectedItemColor: const Color(0xFF64748B),
          selectedLabelStyle: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.handshake_rounded),
              label: 'Credits',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_rounded),
              label: 'Budgets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded),
              label: 'Insights',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
