import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/user_provider.dart';
import '../../data/models/account_model.dart';
import '../../data/models/transaction_model.dart';

/// Purpose: Home Dashboard Screen
/// Author: Antigravity AI
/// Design System: Stitch Finance Hub Enterprise (Luminous Ledger)

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');
  bool _isBalanceVisible = true;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    final range = ref.read(userProvider).settings?.dashboardRange ?? '1m';
    ref.read(accountProvider.notifier).fetchAccounts();
    ref.read(transactionProvider.notifier).fetchTransactions();
    ref.read(analyticsProvider.notifier).fetchAll(range: range);
  }

  void _showAddAccountDialog() {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String selectedType = 'bank';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                    'Add New Account',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Account Name',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    style: GoogleFonts.outfit(color: AppColors.onSurface),
                    decoration: InputDecoration(
                      hintText: 'e.g. HDFC Salary, SBI Savings',
                      hintStyle: GoogleFonts.outfit(color: AppColors.outline),
                      filled: true,
                      fillColor: AppColors.surfaceContainerHigh,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Account Type',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedType,
                        dropdownColor: AppColors.surfaceContainerHigh,
                        isExpanded: true,
                        style: GoogleFonts.outfit(color: AppColors.onSurface),
                        items: const [
                          DropdownMenuItem(value: 'bank', child: Text('Bank Account')),
                          DropdownMenuItem(value: 'cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'credit_card', child: Text('Credit Card')),
                          DropdownMenuItem(value: 'wallet', child: Text('Digital Wallet')),
                          DropdownMenuItem(value: 'investment', child: Text('Investment')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedType = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Initial Balance (₹)',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: balanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.outfit(color: AppColors.onSurface),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: GoogleFonts.outfit(color: AppColors.outline),
                      filled: true,
                      fillColor: AppColors.surfaceContainerHigh,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final bal = double.tryParse(balanceController.text.trim()) ?? 0.0;
                      if (name.isNotEmpty) {
                        final ok = await ref.read(accountProvider.notifier).addAccount({
                          'name': name,
                          'type': selectedType,
                          'balance': bal,
                          'initialBalance': bal,
                          'currency': 'INR',
                        });
                        if (ok && context.mounted) {
                          Navigator.pop(context);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryViolet,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Save Account',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to profile settings changes (e.g. user toggles 1m/3m/6m/1y/all in profile)
    ref.listen<UserState>(userProvider, (previous, next) {
      final oldRange = previous?.settings?.dashboardRange;
      final newRange = next.settings?.dashboardRange;
      if (newRange != null && newRange != oldRange) {
        ref.read(analyticsProvider.notifier).fetchAll(range: newRange);
      }
    });

    final authState = ref.watch(authProvider);
    final userState = ref.watch(userProvider);
    final accountState = ref.watch(accountProvider);
    final transactionState = ref.watch(transactionProvider);
    final analyticsState = ref.watch(analyticsProvider);

    final userName = authState.user?.name ?? 'User';
    final currentRange = userState.settings?.dashboardRange ?? '1m';

    // Calculate real-time income & expense based on the user's selected dashboard range
    final now = DateTime.now();
    DateTime rangeStart;
    if (currentRange == '1m') {
      rangeStart = DateTime(now.year, now.month, 1);
    } else if (currentRange == '3m') {
      rangeStart = DateTime(now.year, now.month - 2, 1);
    } else if (currentRange == '6m') {
      rangeStart = DateTime(now.year, now.month - 5, 1);
    } else if (currentRange == '1y') {
      rangeStart = DateTime(now.year, now.month - 11, 1);
    } else {
      rangeStart = DateTime(2000, 1, 1);
    }

    final filteredTxs = transactionState.transactions.where((tx) {
      try {
        final dt = DateTime.parse(tx.date);
        return dt.isAfter(rangeStart.subtract(const Duration(seconds: 1)));
      } catch (_) {
        return false;
      }
    }).toList();

    final dynamicIncome = filteredTxs
        .where((t) => t.type == 'income')
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    final dynamicExpense = filteredTxs
        .where((t) => t.type == 'expense')
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    final displayIncome = (analyticsState.dashboard != null && analyticsState.dashboard!.income > 0)
        ? analyticsState.dashboard!.income
        : dynamicIncome;

    final displayExpense = (analyticsState.dashboard != null && analyticsState.dashboard!.expense > 0)
        ? analyticsState.dashboard!.expense
        : dynamicExpense;

    return Scaffold(
      backgroundColor: const Color(0xFF090D1A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.65),
            radius: 1.5,
            colors: [
              Color(0xFF161936),
              Color(0xFF090D1A),
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceContainerHigh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8083FF), Color(0xFF6366F1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(color: const Color(0x33FFFFFF)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withOpacity(0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WELCOME BACK,',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF908FA0),
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$userName 👋',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _refreshData,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF131828),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0x26FFFFFF)),
                              ),
                              child: const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _showNotificationsSheet,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF131828),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0x26FFFFFF)),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_none_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                Positioned(
                                  top: 1,
                                  right: 1,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF3366),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF090D1A), width: 1.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                // Hero Total Net Worth Card (Enhanced)
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF131B2E), Color(0xFF1A2238)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0x1FFFFFFF)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.15),
                        blurRadius: 28,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Total Net Worth',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFC7C4D7),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isBalanceVisible = !_isBalanceVisible;
                                  });
                                },
                                child: Icon(
                                  _isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  size: 18,
                                  color: const Color(0xFFC7C4D7),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF003824),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF00A572).withOpacity(0.35)),
                            ),
                            child: Text(
                              '▲ Active',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4EDEA3),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isBalanceVisible ? currencyFormatter.format(accountState.netWorth) : '₹ ••••••••',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Nested Income & Expense Cards
                      Row(
                        children: [
                          // Income Card
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D1B22),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF00A572).withOpacity(0.35)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF003824),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_downward_rounded,
                                      color: Color(0xFF4EDEA3),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'INCOME',
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF4EDEA3),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          currencyFormatter.format(displayIncome),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF4EDEA3),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Expense Card
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D1219),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFFF516A).withOpacity(0.35)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF380812),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_upward_rounded,
                                      color: Color(0xFFFF516A),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'EXPENSE',
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFFFF516A),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          currencyFormatter.format(displayExpense),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFFFF516A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // My Accounts Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Accounts',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/accounts'),
                      child: Text(
                        'View All',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!accountState.isLoading && accountState.accounts.isEmpty)
                  GestureDetector(
                    onTap: _showAddAccountDialog,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131B2E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0x1AFFFFFF)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primaryViolet.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'No Accounts Connected',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tap here to add your first Bank, Cash, or Savings account',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: const Color(0xFF908FA0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.add_circle_rounded, color: AppColors.primaryViolet, size: 24),
                        ],
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 135,
                    child: accountState.isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: accountState.accounts.length + 1,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              if (index == accountState.accounts.length) {
                                return _buildAddAccountCard();
                              }
                              final acc = accountState.accounts[index];
                              return _buildAccountCard(acc);
                            },
                          ),
                  ),
                const SizedBox(height: 24),

                // Recent Transactions Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/transactions'),
                      child: Text(
                        'View All',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (transactionState.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (transactionState.transactions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131B2E),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0x1AFFFFFF)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 40, color: Color(0xFF908FA0)),
                        const SizedBox(height: 10),
                        Text(
                          'No recent transactions',
                          style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF908FA0)),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF131B2E),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0x1AFFFFFF)),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactionState.transactions.take(5).length,
                      separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1, color: Color(0x14FFFFFF)),
                      itemBuilder: (context, index) {
                        final tx = transactionState.transactions[index];
                        return _buildTransactionTile(tx);
                      },
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131B2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF908FA0).withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications & Insights',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF516A).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '3 New',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF516A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildNotificationItem(
                icon: Icons.subscriptions_outlined,
                iconColor: const Color(0xFFC0C1FF),
                title: 'Recurring Subscriptions Detected',
                desc: 'WiFi, Rent, and other subscriptions are scheduled for this cycle.',
                time: 'Today',
              ),
              const SizedBox(height: 12),
              _buildNotificationItem(
                icon: Icons.trending_up_rounded,
                iconColor: const Color(0xFF4EDEA3),
                title: 'Monthly Savings Active',
                desc: 'Your cash flow is positive. Keep tracking expenses accurately!',
                time: 'Yesterday',
              ),
              const SizedBox(height: 12),
              _buildNotificationItem(
                icon: Icons.security_rounded,
                iconColor: const Color(0xFF06B6D4),
                title: 'End-to-End Vault Secured',
                desc: 'All device communications are pinned & idempotently secured.',
                time: '2 days ago',
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required String time,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    time,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF908FA0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFFC7C4D7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountCard(AccountModel acc) {
    final isCash = acc.type == 'cash';
    final isCreditCard = acc.type == 'credit_card';
    final isBank = acc.type == 'bank';

    final Gradient cardGradient = isCash
        ? const LinearGradient(
            colors: [Color(0xFF045D3B), Color(0xFF10B981)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : isCreditCard
            ? const LinearGradient(
                colors: [Color(0xFF4C0519), Color(0xFFBE123C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF26297D), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              );

    final String badgeText = isCash
        ? 'CASH'
        : isCreditCard
            ? 'CREDIT'
            : isBank
                ? 'BANK'
                : acc.type.toUpperCase();

    final Color badgeColor = isCash
        ? const Color(0xFF6FFBBE)
        : isCreditCard
            ? const Color(0xFFFFB2B7)
            : const Color(0xFFC0C1FF);

    return Container(
      width: 175,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.28),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (isCash)
                Icon(Icons.account_balance_wallet_outlined, size: 20, color: badgeColor)
              else if (isBank)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.contactless_outlined, size: 17, color: badgeColor),
                    const SizedBox(width: 4),
                    Icon(Icons.account_balance_outlined, size: 18, color: badgeColor),
                  ],
                )
              else
                Icon(Icons.credit_card_rounded, size: 20, color: badgeColor),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                acc.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                currencyFormatter.format(acc.balance),
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddAccountCard() {
    return GestureDetector(
      onTap: _showAddAccountDialog,
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: const Color(0xFF131B2E),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x1FFFFFFF)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryViolet.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              'Add Account',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF908FA0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionIcon(TransactionModel tx) {
    final note = (tx.note ?? '').toLowerCase();
    final cat = (tx.categoryName ?? '').toLowerCase();
    final isIncome = tx.type == 'income';
    final isTransfer = tx.type == 'transfer';

    Color bgColor;
    Color iconColor;
    IconData icon;

    if (isIncome) {
      bgColor = const Color(0xFF073322);
      iconColor = const Color(0xFF4EDEA3);
      icon = Icons.arrow_downward_rounded;
    } else if (isTransfer) {
      bgColor = const Color(0xFF202352);
      iconColor = const Color(0xFF8083FF);
      icon = Icons.swap_horiz_rounded;
    } else if (note.contains('subscri') ||
        cat.contains('subscri') ||
        note.contains('netflix') ||
        note.contains('spotify') ||
        cat.contains('entertain')) {
      bgColor = const Color(0xFF252654);
      iconColor = const Color(0xFFC0C1FF);
      icon = Icons.play_arrow_rounded;
    } else if (note.contains('brick') ||
        note.contains('tool') ||
        note.contains('repair') ||
        note.contains('construct') ||
        cat.contains('repair') ||
        cat.contains('fuel')) {
      bgColor = const Color(0xFF382914);
      iconColor = const Color(0xFFF59E0B);
      icon = Icons.construction_rounded;
    } else if (note.contains('bag') ||
        note.contains('pack') ||
        note.contains('shop') ||
        cat.contains('shop') ||
        cat.contains('grocer') ||
        note.contains('market')) {
      bgColor = const Color(0xFF0E303D);
      iconColor = const Color(0xFF06B6D4);
      icon = Icons.inventory_2_outlined;
    } else if (note.contains('homam') ||
        note.contains('temple') ||
        note.contains('tent') ||
        note.contains('rent') ||
        cat.contains('hous') ||
        cat.contains('charit') ||
        cat.contains('person')) {
      bgColor = const Color(0xFF38141F);
      iconColor = const Color(0xFFFF516A);
      icon = Icons.account_balance_outlined;
    } else {
      bgColor = const Color(0xFF222A3D);
      iconColor = const Color(0xFFDAE2FD);
      icon = Icons.credit_card_outlined;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }

  Widget _buildTransactionTile(TransactionModel tx) {
    final isIncome = tx.type == 'income';
    final isTransfer = tx.type == 'transfer';
    final isCreditRepay = tx.type == 'credit_repay';

    final Color amountColor = isIncome
        ? const Color(0xFF4EDEA3)
        : (isTransfer || isCreditRepay)
            ? const Color(0xFFF59E0B)
            : const Color(0xFFFF516A);

    final String prefix = isIncome ? '+' : (isTransfer || isCreditRepay) ? '' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _buildTransactionIcon(tx),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.note != null && tx.note!.isNotEmpty
                      ? tx.note!
                      : (tx.categoryName ?? (isTransfer ? 'Transfer' : 'Expense')),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${tx.accountName ?? 'Account'} • ${tx.date.length >= 10 ? tx.date.substring(0, 10) : tx.date}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: const Color(0xFF908FA0),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$prefix ${currencyFormatter.format(tx.amount)}',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
