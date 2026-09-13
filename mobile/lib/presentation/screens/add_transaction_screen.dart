import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../providers/account_provider.dart';
import '../providers/category_provider.dart';
import '../providers/credit_provider.dart';
import '../providers/transaction_provider.dart';
import '../../core/constants/category_icons.dart';
import '../widgets/add_category_dialog.dart';

/// Purpose: Add Transaction & Receipt Builder Screen
/// Author: Antigravity AI
/// Design System: Stitch Finance Hub Enterprise (Add Transaction & Receipt Builder)

class AddTransactionScreen extends ConsumerStatefulWidget {
  final String initialType;
  const AddTransactionScreen({super.key, this.initialType = 'expense'});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  late String _selectedType;
  DateTime _selectedDate = DateTime.now();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _merchantController = TextEditingController();

  String? _selectedAccountId;
  String? _selectedToAccountId;
  String? _selectedCategoryId;
  String? _selectedCreditId;

  bool _isItemized = false;
  bool _isSubmitting = false;

  final List<Map<String, TextEditingController>> _items = [];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    ref.read(accountProvider.notifier).fetchAccounts();
    ref.read(categoryProvider.notifier).fetchCategories();
    ref.read(creditProvider.notifier).fetchCredits();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryViolet,
              onPrimary: Colors.white,
              surface: AppColors.surfaceContainer,
              onSurface: AppColors.onSurface,
            ),
            dialogBackgroundColor: AppColors.surfaceContainer,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          DateTime.now().hour,
          DateTime.now().minute,
        );
      });
    }
  }

  void _addItemRow() {
    setState(() {
      _items.add({
        'name': TextEditingController(),
        'quantity': TextEditingController(text: '1'),
        'unit': TextEditingController(text: 'unit'),
        'unitPrice': TextEditingController(text: '0'),
      });
    });
  }

  void _removeItemRow(int index) {
    setState(() {
      _items.removeAt(index);
    });
    _recalculateItemTotal();
  }

  void _recalculateItemTotal() {
    if (!_isItemized) return;
    double sum = 0.0;
    for (final item in _items) {
      final q = double.tryParse(item['quantity']!.text) ?? 1.0;
      final p = double.tryParse(item['unitPrice']!.text) ?? 0.0;
      sum += (q * p);
    }
    if (sum > 0) {
      _amountController.text = sum.toStringAsFixed(2);
    }
  }

  Future<void> _handleSubmit() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0 || _selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount and select a source account.')),
      );
      return;
    }

    if (_selectedType == 'transfer' && _selectedToAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination account for transfer.')),
      );
      return;
    }

    if (_selectedType == 'credit_repay' && _selectedCreditId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a credit record to repay.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final payload = <String, dynamic>{
      'type': _selectedType,
      'amount': amount,
      'accountId': _selectedAccountId,
      'note': _noteController.text.trim(),
      'merchantName': _merchantController.text.trim(),
      'isItemized': _isItemized,
      'date': _selectedDate.toIso8601String(),
    };

    if (_selectedType == 'transfer') {
      payload['toAccountId'] = _selectedToAccountId;
    } else if (_selectedType == 'credit_repay') {
      payload['creditId'] = _selectedCreditId;
    } else if (_selectedCategoryId != null) {
      payload['categoryId'] = _selectedCategoryId;
    }

    if (_isItemized && _items.isNotEmpty) {
      payload['items'] = _items.map((i) {
        final q = double.tryParse(i['quantity']!.text) ?? 1.0;
        final p = double.tryParse(i['unitPrice']!.text) ?? 0.0;
        return {
          'name': i['name']!.text.trim(),
          'quantity': q,
          'unit': i['unit']!.text.trim(),
          'unitPrice': p,
          'totalPrice': q * p,
          'categoryId': _selectedCategoryId,
        };
      }).toList();
    }

    final success = await ref.read(transactionProvider.notifier).addTransaction(payload);
    setState(() => _isSubmitting = false);

    if (success && mounted) {
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save transaction. Check inputs.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountProvider);
    final categoryState = ref.watch(categoryProvider);
    final creditState = ref.watch(creditProvider);

    final filteredCategories = categoryState.getOrderedCategories(type: _selectedType);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Record Transaction',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segmented Type Selector (Expense, Income, Transfer, Credit Repay)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTypeSegment('expense', 'Expense', AppColors.expenseRose),
                    const SizedBox(width: 8),
                    _buildTypeSegment('income', 'Income', AppColors.incomeEmerald),
                    const SizedBox(width: 8),
                    _buildTypeSegment('transfer', 'Transfer', AppColors.transferAmber),
                    const SizedBox(width: 8),
                    _buildTypeSegment('credit_repay', 'Repay Loan', AppColors.creditCyan),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Amount Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount (₹)',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.outfit(color: AppColors.onSurface, fontSize: 28, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: GoogleFonts.outfit(color: AppColors.outline),
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.currency_rupee_rounded, color: AppColors.primary, size: 28),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Transaction Date Selector Card
              Text(
                'Transaction Date',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
                            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryViolet.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Change',
                          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Source Account Selector
              Text(
                'Source Account',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAccountId,
                    hint: Text('Select Account', style: GoogleFonts.outfit(color: AppColors.outline)),
                    dropdownColor: AppColors.surfaceContainerHigh,
                    isExpanded: true,
                    style: GoogleFonts.outfit(color: AppColors.onSurface),
                    items: accountState.accounts.map((acc) {
                      return DropdownMenuItem(value: acc.id, child: Text('${acc.name} (₹${acc.balance})'));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedAccountId = val),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Destination Account for Transfer
              if (_selectedType == 'transfer') ...[
                Text(
                  'Destination Account',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedToAccountId,
                      hint: Text('Select Destination Account', style: GoogleFonts.outfit(color: AppColors.outline)),
                      dropdownColor: AppColors.surfaceContainerHigh,
                      isExpanded: true,
                      style: GoogleFonts.outfit(color: AppColors.onSurface),
                      items: accountState.accounts.where((a) => a.id != _selectedAccountId).map((acc) {
                        return DropdownMenuItem(value: acc.id, child: Text('${acc.name} (₹${acc.balance})'));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedToAccountId = val),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Credit Record for Repayment
              if (_selectedType == 'credit_repay') ...[
                Text(
                  'Select Credit / Loan to Repay',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCreditId,
                      hint: Text('Select Credit Record', style: GoogleFonts.outfit(color: AppColors.outline)),
                      dropdownColor: AppColors.surfaceContainerHigh,
                      isExpanded: true,
                      style: GoogleFonts.outfit(color: AppColors.onSurface),
                      items: creditState.credits.where((c) => c.status != 'settled').map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.personName} - ${c.type.toUpperCase()} (Due: ₹${c.remainingAmount})'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCreditId = val),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Category Selector
              if (_selectedType != 'transfer' && _selectedType != 'credit_repay') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Category',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                    ),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AddCategoryDialog(
                            initialType: _selectedType,
                            onCategoryCreated: (newId) {
                              setState(() => _selectedCategoryId = newId);
                            },
                          ),
                        );
                      },
                      child: Text(
                        '+ Add Category',
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategoryId,
                      hint: Text('Select Category', style: GoogleFonts.outfit(color: AppColors.outline)),
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
                              if (isSub) const SizedBox(width: 16),
                              Icon(iconData, size: isSub ? 16 : 18, color: badgeColor),
                              const SizedBox(width: 10),
                              Text(
                                isSub ? '↳ ${c.name}' : c.name,
                                style: GoogleFonts.outfit(
                                  color: AppColors.onSurface,
                                  fontWeight: isSub ? FontWeight.normal : FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCategoryId = val),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Merchant Name Input
              Text(
                'Merchant / Store Name',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _merchantController,
                style: GoogleFonts.outfit(color: AppColors.onSurface),
                decoration: InputDecoration(
                  hintText: 'e.g. D-Mart, Amazon, Uber',
                  hintStyle: GoogleFonts.outfit(color: AppColors.outline),
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.storefront_outlined, color: AppColors.primary, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              // Note Input
              Text(
                'Note / Remarks',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _noteController,
                style: GoogleFonts.outfit(color: AppColors.onSurface),
                decoration: InputDecoration(
                  hintText: 'Optional description...',
                  hintStyle: GoogleFonts.outfit(color: AppColors.outline),
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.note_alt_outlined, color: AppColors.primary, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              // Switch for Itemized Receipt Builder
              SwitchListTile(
                activeColor: AppColors.primaryViolet,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Itemized Line Items',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                ),
                subtitle: Text(
                  'Add detailed products, quantities & unit prices',
                  style: GoogleFonts.outfit(fontSize: 11, color: AppColors.onSurfaceVariant),
                ),
                value: _isItemized,
                onChanged: (val) {
                  setState(() {
                    _isItemized = val;
                    if (val && _items.isEmpty) {
                      _addItemRow();
                    }
                  });
                },
              ),

              // Line Items Dynamic Builder
              if (_isItemized) ...[
                const SizedBox(height: 10),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    return _buildLineItemRow(i);
                  },
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _addItemRow,
                  icon: const Icon(Icons.add_rounded, color: AppColors.primary),
                  label: Text('Add Item Row', style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
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
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Save Transaction', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSegment(String type, String label, Color accentColor) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.2) : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? accentColor : AppColors.glassBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? accentColor : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildLineItemRow(int index) {
    final itemMap = _items[index];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: itemMap['name'],
                  style: GoogleFonts.outfit(color: AppColors.onSurface, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Item Name (e.g. Rice, Soap)',
                    hintStyle: GoogleFonts.outfit(color: AppColors.outline, fontSize: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.expenseRose, size: 20),
                onPressed: () => _removeItemRow(index),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: itemMap['quantity'],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _recalculateItemTotal(),
                  style: GoogleFonts.outfit(color: AppColors.onSurface, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Qty',
                    labelStyle: GoogleFonts.outfit(color: AppColors.outline, fontSize: 11),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: itemMap['unit'],
                  style: GoogleFonts.outfit(color: AppColors.onSurface, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Unit (kg/L)',
                    labelStyle: GoogleFonts.outfit(color: AppColors.outline, fontSize: 11),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: itemMap['unitPrice'],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _recalculateItemTotal(),
                  style: GoogleFonts.outfit(color: AppColors.onSurface, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Unit Price (₹)',
                    labelStyle: GoogleFonts.outfit(color: AppColors.outline, fontSize: 11),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
