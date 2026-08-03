import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';

/// Purpose: Add Transaction Screen with Itemized Receipt Support
/// Author: Antigravity AI
/// Last Modified: 2026-08-03

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  String _selectedType = 'expense';
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedAccountId;
  bool _isItemized = false;
  bool _isSubmitting = false;

  final List<Map<String, String>> _items = [];

  void _addItemRow() {
    setState(() {
      _items.add({'name': '', 'quantity': '1', 'unit': 'unit', 'unitPrice': '0'});
    });
  }

  Future<void> _handleSubmit() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0 || _selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount and select an account.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final payload = {
      'type': _selectedType,
      'amount': amount,
      'accountId': _selectedAccountId,
      'note': _noteController.text.trim(),
      'isItemized': _isItemized,
      'items': _isItemized
          ? _items.map((i) => {
                'name': i['name'],
                'quantity': double.tryParse(i['quantity'] ?? '1') ?? 1.0,
                'unit': i['unit'],
                'unitPrice': double.tryParse(i['unitPrice'] ?? '0') ?? 0.0,
                'totalPrice': (double.tryParse(i['quantity'] ?? '1') ?? 1.0) * (double.tryParse(i['unitPrice'] ?? '0') ?? 0.0),
              }).toList()
          : [],
      'date': DateTime.now().toIso8601String(),
    };

    final success = await ref.read(transactionProvider.notifier).addTransaction(payload);
    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ref.read(accountProvider.notifier).fetchAccounts();
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Add Transaction', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Segmented Type Picker
            Row(
              children: ['expense', 'income', 'transfer'].map((type) {
                final isSelected = _selectedType == type;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? AppColors.primaryViolet : AppColors.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => setState(() => _selectedType = type),
                      child: Text(type.toUpperCase(), style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Amount (₹)',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.currency_rupee, color: AppColors.primaryViolet),
              ),
            ),

            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedAccountId,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Account',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.account_balance_wallet, color: AppColors.primaryViolet),
              ),
              items: accountState.accounts.map((acc) {
                return DropdownMenuItem(value: acc.id, child: Text(acc.name));
              }).toList(),
              onChanged: (val) => setState(() => _selectedAccountId = val),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Note (optional)',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.note_outlined, color: AppColors.primaryViolet),
              ),
            ),

            const SizedBox(height: 16),
            SwitchListTile(
              activeColor: AppColors.primaryViolet,
              title: const Text('Itemized Receipt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Add individual product items and unit prices', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              value: _isItemized,
              onChanged: (val) => setState(() => _isItemized = val),
            ),

            if (_isItemized) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _addItemRow,
                icon: const Icon(Icons.add, color: AppColors.primaryViolet),
                label: const Text('Add Item Row', style: TextStyle(color: AppColors.primaryViolet)),
              ),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryViolet,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Transaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
