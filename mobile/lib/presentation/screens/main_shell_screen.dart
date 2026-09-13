import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'budgets_credits_screen.dart';
import 'analytics_screen.dart';
import 'profile_settings_screen.dart';

/// Purpose: Main Navigation Shell with Persistent Bottom Bar & FAB Quick Action Sheet
/// Author: Antigravity AI
/// Design System: Stitch Finance Hub Enterprise

class MainShellScreen extends StatefulWidget {
  final int initialTab;
  const MainShellScreen({super.key, this.initialTab = 0});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  final List<Widget> _screens = const [
    DashboardScreen(),
    TransactionsScreen(),
    BudgetsCreditsScreen(),
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
                        _currentIndex = 2; // Switch to Budgets & Credits
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickActionSheet,
        backgroundColor: AppColors.primaryViolet,
        elevation: 6,
        shape: const CircleBorder(),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryViolet.withOpacity(0.4),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.85),
          border: const Border(
            top: BorderSide(color: AppColors.glassBorder),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryViolet.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.onSurfaceVariant,
          selectedLabelStyle: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Ledger',
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
