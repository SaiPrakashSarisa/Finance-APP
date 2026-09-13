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

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    ref.read(accountProvider.notifier).fetchAccounts();
    ref.read(transactionProvider.notifier).fetchTransactions();
    ref.read(analyticsProvider.notifier).fetchAll();
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
    final authState = ref.watch(authProvider);
    final accountState = ref.watch(accountProvider);
    final transactionState = ref.watch(transactionProvider);
    final analyticsState = ref.watch(analyticsProvider);

    final userName = authState.user?.name ?? 'User';

    // Calculate real-time current month income & expense from transactions as fallback
    final now = DateTime.now();
    final currentMonthTxs = transactionState.transactions.where((tx) {
      try {
        final dt = DateTime.parse(tx.date);
        return dt.month == now.month && dt.year == now.year;
      } catch (_) {
        return false;
      }
    }).toList();

    final dynamicIncome = currentMonthTxs
        .where((t) => t.type == 'income')
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    final dynamicExpense = currentMonthTxs
        .where((t) => t.type == 'expense')
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    final displayIncome = (analyticsState.dashboard != null && analyticsState.dashboard!.income > 0)
        ? analyticsState.dashboard!.income
        : dynamicIncome;

    final displayExpense = (analyticsState.dashboard != null && analyticsState.dashboard!.expense > 0)
        ? analyticsState.dashboard!.expense
        : dynamicExpense;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppColors.primaryViolet, AppColors.primaryContainer],
                            ),
                            border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                          ),
                          child: Center(
                            child: Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
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
                              'Welcome back,',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurfaceVariant,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              '$userName 👋',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: AppColors.onSurfaceVariant),
                          onPressed: _refreshData,
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_none_rounded, color: AppColors.onSurfaceVariant),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Hero Net Worth Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.glassPanelBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.glassBorder),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryViolet.withOpacity(0.12),
                        blurRadius: 24,
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
                          Text(
                            'Total Net Worth',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          Icon(Icons.visibility_outlined, size: 18, color: AppColors.onSurfaceVariant),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            currencyFormatter.format(accountState.netWorth),
                            style: GoogleFonts.outfit(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.incomeEmerald.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '▲ Active',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.incomeEmerald,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Monthly Income vs Expense Summary Pills
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.incomeEmerald.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.incomeEmerald.withOpacity(0.25)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.arrow_downward_rounded, color: AppColors.incomeEmerald, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Income',
                                          style: GoogleFonts.outfit(fontSize: 10, color: AppColors.onSurfaceVariant),
                                        ),
                                        Text(
                                          currencyFormatter.format(displayIncome),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.incomeEmerald),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.expenseRose.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.expenseRose.withOpacity(0.25)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.arrow_upward_rounded, color: AppColors.expenseRose, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Expense',
                                          style: GoogleFonts.outfit(fontSize: 10, color: AppColors.onSurfaceVariant),
                                        ),
                                        Text(
                                          currencyFormatter.format(displayExpense),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.expenseRose),
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

                // Accounts Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Accounts',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/accounts'),
                      child: Text(
                        'View All',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (!accountState.isLoading && accountState.accounts.isEmpty)
                  GestureDetector(
                    onTap: _showAddAccountDialog,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.glassBorder),
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
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                Text(
                                  'Tap here to add your first Bank, Cash, or Savings account',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: AppColors.onSurfaceVariant,
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
                    height: 120,
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
                        color: AppColors.onSurface,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/transactions'),
                      child: Text(
                        'View All',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
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
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.outline),
                        const SizedBox(height: 8),
                        Text(
                          'No recent transactions',
                          style: GoogleFonts.outfit(fontSize: 14, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactionState.transactions.take(5).length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.outlineVariant.withOpacity(0.3)),
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
    );
  }

  Widget _buildAccountCard(AccountModel acc) {
    final isCreditCard = acc.type == 'credit_card';
    final isCash = acc.type == 'cash';
    final isSavings = acc.type == 'savings';

    final Gradient cardGradient = isCreditCard
        ? const LinearGradient(
            colors: [Color(0xFF4C0519), Color(0xFFBE123C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : isCash
            ? const LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : isSavings
                ? const LinearGradient(
                    colors: [Color(0xFF164E63), Color(0xFF0891B2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  );

    final IconData typeIcon = acc.type == 'bank'
        ? Icons.account_balance_rounded
        : acc.type == 'credit_card'
            ? Icons.credit_card_rounded
            : acc.type == 'cash'
                ? Icons.payments_rounded
                : acc.type == 'savings'
                    ? Icons.savings_rounded
                    : Icons.account_balance_wallet_rounded;

    return Container(
      width: 210,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  acc.type.toUpperCase().replaceAll('_', ' '),
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Icon(typeIcon, size: 20, color: Colors.white.withOpacity(0.9)),
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
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                currencyFormatter.format(acc.balance),
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
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
        width: 120,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow.withOpacity(0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.glassBorder, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryViolet.withOpacity(0.15),
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
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(TransactionModel tx) {
    final isIncome = tx.type == 'income';
    final isTransfer = tx.type == 'transfer';
    final isCreditRepay = tx.type == 'credit_repay';

    final Color amountColor = isIncome
        ? AppColors.incomeEmerald
        : isTransfer
            ? AppColors.transferAmber
            : isCreditRepay
                ? AppColors.creditCyan
                : AppColors.expenseRose;

    final String prefix = isIncome ? '+' : (isTransfer || isCreditRepay) ? '' : '-';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(
          isIncome
              ? Icons.arrow_downward_rounded
              : isTransfer
                  ? Icons.swap_horiz_rounded
                  : isCreditRepay
                      ? Icons.handshake_outlined
                      : Icons.shopping_bag_outlined,
          color: amountColor,
          size: 20,
        ),
      ),
      title: Text(
        tx.note != null && tx.note!.isNotEmpty
            ? tx.note!
            : (tx.categoryName ?? (isTransfer ? 'Transfer' : 'Expense')),
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
      ),
      subtitle: Text(
        '${tx.accountName ?? 'Account'} • ${tx.date.length >= 10 ? tx.date.substring(0, 10) : tx.date}',
        style: GoogleFonts.outfit(
          fontSize: 11,
          color: AppColors.onSurfaceVariant,
        ),
      ),
      trailing: Text(
        '$prefix ${currencyFormatter.format(tx.amount)}',
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: amountColor,
        ),
      ),
    );
  }
}
