import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../providers/transaction_provider.dart';

/// Purpose: Filterable Transactions Screen with Subcategory Badges
/// Author: Antigravity AI
/// Last Modified: 2026-08-03

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionState = ref.watch(transactionProvider);
    final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final types = ['all', 'income', 'expense', 'transfer', 'credit_repay'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Transactions History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: types.length,
              itemBuilder: (context, index) {
                final type = types[index];
                final isSelected = transactionState.activeType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(type.toUpperCase()),
                    selected: isSelected,
                    selectedColor: AppColors.primaryViolet,
                    backgroundColor: AppColors.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      ref.read(transactionProvider.notifier).fetchTransactions(type: type);
                    },
                  ),
                );
              },
            ),
          ),

          // Transactions List
          Expanded(
            child: transactionState.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryViolet))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: transactionState.transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactionState.transactions[index];
                      final isExpense = tx.type == 'expense';
                      return Card(
                        color: AppColors.surface,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.between,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: isExpense
                                            ? AppColors.expenseRose.withOpacity(0.2)
                                            : AppColors.incomeEmerald.withOpacity(0.2),
                                        child: Icon(
                                          isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                                          color: isExpense ? AppColors.expenseRose : AppColors.incomeEmerald,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tx.parentCategoryName ?? tx.categoryName ?? tx.type.toUpperCase(),
                                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                          if (tx.subCategoryName != null)
                                            Text(
                                              tx.subCategoryName!,
                                              style: const TextStyle(color: AppColors.primaryViolet, fontSize: 12, fontWeight: FontWeight.w600),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${isExpense ? '-' : '+'}${currencyFormatter.format(tx.amount)}',
                                    style: TextStyle(
                                      color: isExpense ? AppColors.expenseRose : AppColors.incomeEmerald,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (tx.isItemized && tx.items.isNotEmpty) ...[
                                const Divider(color: AppColors.cardBorder, height: 16),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: tx.items
                                      .map((item) => Chip(
                                            backgroundColor: AppColors.surfaceLight,
                                            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                                            label: Text(
                                              '${item.name} (${item.quantity}${item.unit} @ ₹${item.unitPrice})',
                                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
