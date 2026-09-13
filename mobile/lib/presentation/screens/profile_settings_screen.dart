import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';

/// Purpose: Profile & User Settings Screen
/// Author: Antigravity AI
/// Design System: Stitch Finance Hub Enterprise

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(userProvider.notifier).fetchProfile();
  }

  void _showEditProfileSheet() {
    final userState = ref.read(userProvider);
    final nameController = TextEditingController(text: userState.profile?.name ?? '');
    final phoneController = TextEditingController(text: userState.profile?.phone ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Edit Profile',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface),
              ),
              const SizedBox(height: 14),
              Text('Full Name', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                style: GoogleFonts.outfit(color: AppColors.onSurface),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceContainerHigh,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              Text('Phone Number', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 6),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.outfit(color: AppColors.onSurface),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceContainerHigh,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    final ok = await ref.read(userProvider.notifier).updateProfile({
                      'name': name,
                      'phone': phoneController.text.trim(),
                    });
                    if (ok && mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryViolet,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Save Profile', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: Text('Change Password', style: GoogleFonts.outfit(color: AppColors.onSurface, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              style: GoogleFonts.outfit(color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Current Password',
                hintStyle: GoogleFonts.outfit(color: AppColors.outline),
                filled: true,
                fillColor: AppColors.surfaceContainerHigh,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newController,
              obscureText: true,
              style: GoogleFonts.outfit(color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'New Password',
                hintStyle: GoogleFonts.outfit(color: AppColors.outline),
                filled: true,
                fillColor: AppColors.surfaceContainerHigh,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryViolet),
            onPressed: () async {
              final curr = currentController.text.trim();
              final next = newController.text.trim();
              if (curr.isNotEmpty && next.isNotEmpty) {
                final res = await ref.read(userProvider.notifier).changePassword(curr, next);
                if (mounted) {
                  Navigator.pop(context);
                  if (res != null && res['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully!')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res?['error'] ?? 'Failed to update password')));
                  }
                }
              }
            },
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final profile = userState.profile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Profile & Settings',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onSurface),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // User Avatar Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryViolet, AppColors.primaryContainer],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          (profile?.name != null && profile!.name.isNotEmpty) ? profile.name[0].toUpperCase() : 'U',
                          style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile?.name ?? 'User Name',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile?.email ?? '',
                            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                      onPressed: _showEditProfileSheet,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Settings Options List
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                      title: Text('Change Password', style: GoogleFonts.outfit(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant),
                      onTap: _showChangePasswordDialog,
                    ),
                    Divider(height: 1, color: AppColors.outlineVariant.withOpacity(0.3)),
                    ListTile(
                      leading: const Icon(Icons.category_outlined, color: AppColors.primary),
                      title: Text('Manage Categories', style: GoogleFonts.outfit(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant),
                      onTap: () => context.push('/categories'),
                    ),
                    Divider(height: 1, color: AppColors.outlineVariant.withOpacity(0.3)),
                    ListTile(
                      leading: const Icon(Icons.date_range_rounded, color: AppColors.primary),
                      title: Text('Dashboard Date Range', style: GoogleFonts.outfit(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
                      trailing: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: userState.settings?.dashboardRange ?? '1m',
                          dropdownColor: AppColors.surfaceContainerHigh,
                          style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold),
                          items: const [
                            DropdownMenuItem(value: '1m', child: Text('This Month')),
                            DropdownMenuItem(value: '3m', child: Text('3 Months')),
                            DropdownMenuItem(value: '6m', child: Text('6 Months')),
                            DropdownMenuItem(value: '1y', child: Text('1 Year')),
                            DropdownMenuItem(value: 'all', child: Text('All Time')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(userProvider.notifier).updateSettings({'dashboardRange': val});
                            }
                          },
                        ),
                      ),
                    ),
                    Divider(height: 1, color: AppColors.outlineVariant.withOpacity(0.3)),
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                      title: Text('Budget Limit Alerts', style: GoogleFonts.outfit(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
                      activeTrackColor: AppColors.primaryViolet,
                      value: userState.settings?.budgetEnabled ?? true,
                      onChanged: (val) {
                        ref.read(userProvider.notifier).updateSettings({'budgetEnabled': val});
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  label: Text('Sign Out', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.expenseRose,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (mounted) {
                      context.go('/login');
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
