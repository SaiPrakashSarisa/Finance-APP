import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';

/// Purpose: Main Financial Dashboard Screen
/// Author: Antigravity AI
/// Last Modified: 2026-08-03

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _showBalance = true;

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountProvider);
    final transactionState = ref.watch(transactionProvider);
    final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Financial Hub', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () {
              ref.read(accountProvider.notifier).fetchAccounts();
              ref.read(transactionProvider.notifier).fetchTransactions();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(accountProvider.notifier).fetchAccounts();
          await ref.read(transactionProvider.notifier).fetchTransactions();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Net Worth Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Color(0x406366F1), blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Net Worth', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        IconButton(
                          icon: Icon(_showBalance ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
                          onPressed: () => setState(() => _showBalance = !_showBalance),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _showBalance ? currencyFormatter.format(accountState.netWorth) : '••••••••',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Accounts', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => context.push('/accounts'),
                    child: const Text('View All', style: TextStyle(color: AppColors.primaryViolet)),
                  ),
                ],
              ),

              // Accounts Horizontal Scroll
              SizedBox(
                height: 100,
                child: accountState.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryViolet))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: accountState.accounts.length,
                        itemBuilder: (context, index) {
                          final acc = accountState.accounts[index];
                          return Container(
                            width: 160,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(acc.name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 6),
                                Text(
                                  _showBalance ? currencyFormatter.format(acc.balance) : '••••',
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Transactions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => context.push('/transactions'),
                    child: const Text('View All', style: TextStyle(color: AppColors.primaryViolet)),
                  ),
                ],
              ),

              // Transactions List
              transactionState.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryViolet))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactionState.transactions.take(5).length,
                      itemBuilder: (context, index) {
                        final tx = transactionState.transactions[index];
                        final isExpense = tx.type == 'expense';
                        return Card(
                          color: AppColors.surface,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isExpense ? AppColors.expenseRose.withOpacity(0.2) : AppColors.incomeEmerald.withOpacity(0.2),
                              child: Icon(
                                isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                                color: isExpense ? AppColors.expenseRose : AppColors.incomeEmerald,
                              ),
                            ),
                            title: Text(
                              tx.parentCategoryName ?? tx.categoryName ?? tx.type.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.semibold),
                            ),
                            subtitle: Text(
                              tx.note ?? tx.accountName ?? '',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            trailing: Text(
                              '${isExpense ? '-' : '+'}${currencyFormatter.format(tx.amount)}',
                              style: TextStyle(
                                color: isExpense ? AppColors.expenseRose : AppColors.incomeEmerald,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-transaction'),
        backgroundColor: AppColors.primaryViolet,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Transaction', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
