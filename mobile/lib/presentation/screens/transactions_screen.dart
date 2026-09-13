import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../providers/category_provider.dart';
import '../../data/models/transaction_model.dart';

import '../../core/constants/category_icons.dart';

/// Purpose: Ledger Transactions Screen
/// Author: Antigravity AI
/// Design System: Stitch Finance Hub Enterprise (Luminous Ledger)

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');
  final _searchController = TextEditingController();
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    ref.read(transactionProvider.notifier).fetchTransactions(type: _selectedType);
    ref.read(accountProvider.notifier).fetchAccounts();
    ref.read(categoryProvider.notifier).fetchCategories();
  }

  void _showEditTransactionSheet(TransactionModel tx) {
    final amountController = TextEditingController(text: tx.amount.toStringAsFixed(2));
    final noteController = TextEditingController(text: tx.note ?? '');
    String? selectedAccountId = tx.accountId;
    String? selectedCategoryId = tx.categoryId;
    DateTime selectedDate = DateTime.tryParse(tx.date) ?? DateTime.now();

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
            final accountState = ref.watch(accountProvider);
            final categoryState = ref.watch(categoryProvider);

            final filteredCategories = categoryState.getOrderedCategories(type: tx.type);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
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
                      'Edit Transaction',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Amount
                    Text('Amount (₹)', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.outfit(color: AppColors.onSurface, fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceContainerHigh,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Account
                    Text('Account', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedAccountId,
                          dropdownColor: AppColors.surfaceContainerHigh,
                          isExpanded: true,
                          style: GoogleFonts.outfit(color: AppColors.onSurface),
                          items: accountState.accounts.map((acc) {
                            return DropdownMenuItem(value: acc.id, child: Text('${acc.name} (₹${acc.balance})'));
                          }).toList(),
                          onChanged: (val) => setModalState(() => selectedAccountId = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Category
                    if (tx.type != 'transfer' && tx.type != 'credit_repay') ...[
                      Text('Category', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedCategoryId,
                            dropdownColor: AppColors.surfaceContainerHigh,
                            isExpanded: true,
                            style: GoogleFonts.outfit(color: AppColors.onSurface),
                            items: filteredCategories.map((c) {
                              final iconData = CategoryIcons.getIcon(c.icon);
                              final badgeColor = CategoryIcons.parseColor(c.color);
                              final isSub = c.parentCategoryId != null && c.parentCategoryId!.isNotEmpty;
                              return DropdownMenuItem(
                                value: c.id,
                                child: Row(
                                  children: [
                                    if (isSub) const SizedBox(width: 14),
                                    Icon(iconData, size: 16, color: badgeColor),
                                    const SizedBox(width: 8),
                                    Text(isSub ? '↳ ${c.name}' : c.name, style: GoogleFonts.outfit(color: AppColors.onSurface)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => setModalState(() => selectedCategoryId = val),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Date Selection
                    Text('Date', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (ctx, child) => Theme(
                            data: Theme.of(ctx).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.primaryViolet,
                                onPrimary: Colors.white,
                                surface: AppColors.surfaceContainer,
                                onSurface: AppColors.onSurface,
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setModalState(() {
                            selectedDate = DateTime(picked.year, picked.month, picked.day, selectedDate.hour, selectedDate.minute);
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('EEEE, dd MMM yyyy').format(selectedDate), style: GoogleFonts.outfit(color: AppColors.onSurface, fontSize: 13)),
                            const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Note
                    Text('Note / Description', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteController,
                      style: GoogleFonts.outfit(color: AppColors.onSurface, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceContainerHigh,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryViolet,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                        if (amt > 0 && selectedAccountId != null) {
                          final payload = <String, dynamic>{
                            'type': tx.type,
                            'amount': amt,
                            'accountId': selectedAccountId,
                            'note': noteController.text.trim(),
                            'date': selectedDate.toIso8601String(),
                          };
                          if (selectedCategoryId != null) {
                            payload['categoryId'] = selectedCategoryId;
                          }
                          final ok = await ref.read(transactionProvider.notifier).updateTransaction(tx.id, payload);
                          if (ok && mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Transaction Updated & Balance Re-adjusted!')),
                            );
                          }
                        }
                      },
                      child: Text('Update Transaction', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showItemizedDetailSheet(TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
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
                    color: AppColors.outline.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Receipt Details',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditTransactionSheet(tx);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expenseRose),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppColors.surfaceContainer,
                              title: Text('Delete Transaction?', style: GoogleFonts.outfit(color: AppColors.onSurface)),
                              content: Text('This will revert the balance effect on your accounts.', style: GoogleFonts.outfit(color: AppColors.onSurfaceVariant)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRose),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && mounted) {
                            await ref.read(transactionProvider.notifier).deleteTransaction(tx.id);
                            if (mounted) Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Total Amount: ${currencyFormatter.format(tx.amount)}',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
              const SizedBox(height: 4),
              Text(
                'Account: ${tx.accountName ?? "Default"} • Date: ${tx.date.length >= 10 ? tx.date.substring(0, 10) : tx.date}',
                style: GoogleFonts.outfit(fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
              if (tx.note != null && tx.note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Note: ${tx.note}', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.onSurface)),
              ],
              const SizedBox(height: 16),
              if (tx.items.isNotEmpty) ...[
                Text(
                  'Line Items',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tx.items.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.outlineVariant.withOpacity(0.3)),
                    itemBuilder: (ctx, i) {
                      final item = tx.items[i];
                      return ListTile(
                        dense: true,
                        title: Text(item.name, style: GoogleFonts.outfit(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${item.quantity} ${item.unit} @ ₹${item.unitPrice}',
                          style: GoogleFonts.outfit(color: AppColors.onSurfaceVariant, fontSize: 11),
                        ),
                        trailing: Text(
                          currencyFormatter.format(item.totalPrice),
                          style: GoogleFonts.outfit(color: AppColors.onSurface, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showCsvBackupSheet() {
    final csvController = TextEditingController();

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
                'CSV Backup & Restore',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.download_rounded, color: Colors.white),
                label: const Text('Export Transactions CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryViolet,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final csv = await ref.read(transactionProvider.notifier).exportCsv();
                  if (csv != null && mounted) {
                    csvController.text = csv;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('CSV Exported to Text Box below!')),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Import CSV Content',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: csvController,
                maxLines: 5,
                style: GoogleFonts.outfit(color: AppColors.onSurface, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Paste CSV rows here...',
                  hintStyle: GoogleFonts.outfit(color: AppColors.outline),
                  filled: true,
                  fillColor: AppColors.surfaceContainerHigh,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_rounded, color: Colors.white),
                label: const Text('Import & Restore State'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.incomeContainer,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final text = csvController.text.trim();
                  if (text.isNotEmpty) {
                    final ok = await ref.read(transactionProvider.notifier).importCsv(text, mode: 'replace');
                    if (ok && mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('CSV Restore Successful!')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Transactions Ledger',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onSurface),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.import_export_rounded, color: AppColors.primary),
            onPressed: _showCsvBackupSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.outfit(color: AppColors.onSurface),
                onChanged: (val) {
                  ref.read(transactionProvider.notifier).fetchTransactions(search: val);
                },
                decoration: InputDecoration(
                  hintText: 'Search note, category or line item...',
                  hintStyle: GoogleFonts.outfit(color: AppColors.outline, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.onSurfaceVariant),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Type Filter Chips (All, Expense, Income, Transfer)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  _buildTypeChip('all', 'All'),
                  const SizedBox(width: 8),
                  _buildTypeChip('expense', 'Expense'),
                  const SizedBox(width: 8),
                  _buildTypeChip('income', 'Income'),
                  const SizedBox(width: 8),
                  _buildTypeChip('transfer', 'Transfer'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Transactions List
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceContainerHigh,
                child: transactionState.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : transactionState.transactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.outline),
                                const SizedBox(height: 12),
                                Text(
                                  'No transactions found',
                                  style: GoogleFonts.outfit(fontSize: 15, color: AppColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: transactionState.transactions.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final tx = transactionState.transactions[index];
                              return _buildTransactionCard(tx);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, String label) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
        ref.read(transactionProvider.notifier).fetchTransactions(type: type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryViolet : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primaryViolet : AppColors.glassBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel tx) {
    final isIncome = tx.type == 'income';
    final isTransfer = tx.type == 'transfer';
    final isCreditRepay = tx.type == 'credit_repay';

    final Color color = isIncome
        ? AppColors.incomeEmerald
        : isTransfer
            ? AppColors.transferAmber
            : isCreditRepay
                ? AppColors.creditCyan
                : AppColors.expenseRose;

    return GestureDetector(
      onTap: () => _showItemizedDetailSheet(tx),
      child: Container(
        padding: const EdgeInsets.all(14),
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
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Icon(
                isIncome
                    ? Icons.arrow_downward_rounded
                    : isTransfer
                        ? Icons.swap_horiz_rounded
                        : isCreditRepay
                            ? Icons.handshake_outlined
                            : Icons.shopping_bag_outlined,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.note != null && tx.note!.isNotEmpty
                        ? tx.note!
                        : (tx.categoryName ?? (isTransfer ? 'Transfer' : 'Expense')),
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        tx.accountName ?? 'Account',
                        style: GoogleFonts.outfit(fontSize: 11, color: AppColors.onSurfaceVariant),
                      ),
                      if (tx.isItemized) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primaryViolet.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Itemized (${tx.items.length})',
                            style: GoogleFonts.outfit(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : (isTransfer || isCreditRepay) ? '' : '-'} ${currencyFormatter.format(tx.amount)}',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tx.date.length >= 10 ? tx.date.substring(0, 10) : tx.date,
                  style: GoogleFonts.outfit(fontSize: 11, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
