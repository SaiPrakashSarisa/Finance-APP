import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/category_icons.dart';
import '../providers/budget_provider.dart';
import '../providers/credit_provider.dart';
import '../providers/category_provider.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/analytics_provider.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/credit_model.dart';
import '../../data/models/transaction_model.dart';
import '../widgets/add_category_dialog.dart';
import '../widgets/skeleton_loaders.dart';

/// Purpose: Budgets & Debt Tracker Financial Hub Screen
/// Author: Antigravity AI
/// Design System: Stitch Finance Hub Enterprise (Luminous Ledger)

class BudgetsCreditsScreen extends ConsumerStatefulWidget {
  final int initialTab;
  final bool isCreditsOnly;
  final bool isBudgetsOnly;

  const BudgetsCreditsScreen({
    super.key,
    this.initialTab = 0,
    this.isCreditsOnly = false,
    this.isBudgetsOnly = false,
  });

  @override
  ConsumerState<BudgetsCreditsScreen> createState() => _BudgetsCreditsScreenState();
}

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BudgetsCreditsScreen(isBudgetsOnly: true);
  }
}

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BudgetsCreditsScreen(isCreditsOnly: true);
  }
}

class _BudgetsCreditsScreenState extends ConsumerState<BudgetsCreditsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');
  final shortCurrencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');
  final dateFormatter = DateFormat('dd MMM yyyy');

  String _creditFilter = 'all'; // 'all', 'given', 'taken', 'active', 'settled'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.isCreditsOnly ? 1 : widget.initialTab.clamp(0, 1),
    );
    _refresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.read(budgetProvider.notifier).fetchSummary();
    ref.read(creditProvider.notifier).fetchCredits();
    ref.read(categoryProvider.notifier).fetchCategories();
    ref.read(accountProvider.notifier).fetchAccounts();
    ref.read(transactionProvider.notifier).fetchTransactions();
    ref.read(analyticsProvider.notifier).fetchAll();
  }

  void _showSetBudgetSheet(CategoryBudgetSummaryModel item) {
    final amountController = TextEditingController(
      text: item.budgetAmount > 0 ? item.budgetAmount.toStringAsFixed(0) : '',
    );
    bool isSaving = false;

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Edit Budget: ${item.categoryName}',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.budgetId != null)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expenseRose, size: 20),
                            tooltip: 'Remove Budget',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppColors.surfaceContainerHigh,
                                  title: Text('Remove Budget', style: GoogleFonts.outfit(color: AppColors.onSurface)),
                                  content: Text(
                                    'Remove the monthly budget limit for ${item.categoryName}?',
                                    style: GoogleFonts.outfit(color: AppColors.onSurfaceVariant),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.outline)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text('Remove', style: GoogleFonts.outfit(color: AppColors.expenseRose, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref.read(budgetProvider.notifier).removeBudget(item.budgetId!);
                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Budget removed for ${item.categoryName}', style: GoogleFonts.outfit()),
                                      backgroundColor: AppColors.outline,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Monthly Limit (₹)',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.outfit(color: AppColors.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: 'e.g. 5000',
                        hintStyle: GoogleFonts.outfit(color: AppColors.outline),
                        filled: true,
                        fillColor: AppColors.surfaceContainerHigh,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [2000, 5000, 10000, 20000, 50000].map((preset) {
                        return ActionChip(
                          label: Text(
                            '₹${NumberFormat('#,##,###', 'en_IN').format(preset)}',
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryViolet),
                          ),
                          backgroundColor: AppColors.primaryViolet.withOpacity(0.12),
                          side: BorderSide(color: AppColors.primaryViolet.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          onPressed: () {
                            setModalState(() {
                              amountController.text = preset.toString();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                              if (amt > 0) {
                                setModalState(() => isSaving = true);
                                final ok = await ref.read(budgetProvider.notifier).setBudget(
                                      categoryId: item.categoryId,
                                      amount: amt,
                                    );
                                if (ok && mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Budget updated successfully!', style: GoogleFonts.outfit()),
                                      backgroundColor: AppColors.incomeEmerald,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } else {
                                  setModalState(() => isSaving = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryViolet,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Save Budget', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
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

  void _showCreateBudgetSheet() {
    ref.read(categoryProvider.notifier).fetchCategories();
    final budgetState = ref.read(budgetProvider);
    final amountController = TextEditingController();
    String? selectedCategoryId;
    bool isSaving = false;

    final monthName = DateFormat('MMMM yyyy').format(
      DateTime(budgetState.selectedYear, budgetState.selectedMonth),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final categoryState = ref.watch(categoryProvider);
            final expenseCats = categoryState.categories
                .where((c) => c.type == 'expense' && (c.parentCategoryId == null || c.parentCategoryId!.isEmpty))
                .toList();
            final List<Map<String, dynamic>> availableCategories = [];

            if (expenseCats.isNotEmpty) {
              for (final c in expenseCats) {
                availableCategories.add({
                  'id': c.id,
                  'name': c.name,
                  'color': c.color,
                  'icon': c.icon,
                });
              }
            } else if (budgetState.summary?.categories.isNotEmpty ?? false) {
              for (final c in budgetState.summary!.categories) {
                availableCategories.add({
                  'id': c.categoryId,
                  'name': c.categoryName,
                  'color': c.categoryColor,
                  'icon': c.categoryIcon,
                });
              }
            }

            if (availableCategories.isNotEmpty &&
                (selectedCategoryId == null || !availableCategories.any((c) => c['id'] == selectedCategoryId))) {
              selectedCategoryId = availableCategories.first['id'] as String;
            }

            return StatefulBuilder(
              builder: (context, setModalState) {
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Create Category Budget',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryViolet.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.primaryViolet.withOpacity(0.3)),
                              ),
                              child: Text(
                                monthName,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Select Category',
                              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () async {
                                await showDialog(
                                  context: context,
                                  builder: (ctx) => AddCategoryDialog(
                                    initialType: 'expense',
                                    onCategoryCreated: (newCatId) {
                                      setModalState(() {
                                        selectedCategoryId = newCatId;
                                      });
                                    },
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Text(
                                  '+ New Category',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryViolet,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (categoryState.isLoading && availableCategories.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            alignment: Alignment.center,
                            child: const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryViolet),
                            ),
                          )
                        else if (availableCategories.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'No expense categories found yet.',
                                  style: GoogleFonts.outfit(color: AppColors.outline, fontSize: 13),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.add, size: 16, color: AppColors.primaryViolet),
                                  label: Text('Create First Category', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.primaryViolet)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.primaryViolet),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () async {
                                    await showDialog(
                                      context: context,
                                      builder: (ctx) => AddCategoryDialog(
                                        initialType: 'expense',
                                        onCategoryCreated: (newCatId) {
                                          setModalState(() {
                                            selectedCategoryId = newCatId;
                                          });
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          )
                        else
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
                                items: availableCategories.map((c) {
                                  final catColor = CategoryIcons.parseColor(c['color'] as String?);
                                  final iconData = CategoryIcons.getIcon(c['icon'] as String?);
                                  return DropdownMenuItem<String>(
                                    value: c['id'] as String,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            color: catColor.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(iconData, color: catColor, size: 14),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            c['name'] as String,
                                            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() => selectedCategoryId = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        const SizedBox(height: 14),
                        Text(
                          'Monthly Budget Limit (₹)',
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.outfit(color: AppColors.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: 'e.g. 5000',
                            hintStyle: GoogleFonts.outfit(color: AppColors.outline),
                            filled: true,
                            fillColor: AppColors.surfaceContainerHigh,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [2000, 5000, 10000, 20000, 50000].map((preset) {
                            return ActionChip(
                              label: Text(
                                '₹${NumberFormat('#,##,###', 'en_IN').format(preset)}',
                                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryViolet),
                              ),
                              backgroundColor: AppColors.primaryViolet.withOpacity(0.12),
                              side: BorderSide(color: AppColors.primaryViolet.withOpacity(0.3)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              onPressed: () {
                                setModalState(() {
                                  amountController.text = preset.toString();
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 22),
                        ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                                  if (selectedCategoryId != null && amt > 0) {
                                    setModalState(() => isSaving = true);
                                    final ok = await ref.read(budgetProvider.notifier).setBudget(
                                          categoryId: selectedCategoryId!,
                                          amount: amt,
                                        );
                                    if (ok && mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Budget saved successfully!', style: GoogleFonts.outfit()),
                                          backgroundColor: AppColors.incomeEmerald,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    } else {
                                      setModalState(() => isSaving = false);
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryViolet,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isSaving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(
                                  'Save Budget',
                                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAddCreditSheet() {
    final personController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final interestController = TextEditingController();

    String type = 'given'; // 'given' or 'taken'
    String subType = 'account_credit'; // 'account_credit' or 'emi_loan'
    String? selectedAccountId;
    DateTime? selectedDueDate;
    bool isSubmitting = false;

    final accountState = ref.read(accountProvider);
    if (accountState.accounts.isNotEmpty) {
      selectedAccountId = accountState.accounts.first.id;
    }

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
                      'Record Credit / Loan',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 16),

                    // Type Segment (Given vs Taken)
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => type = 'given'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: type == 'given' ? AppColors.incomeEmerald.withOpacity(0.2) : AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: type == 'given' ? AppColors.incomeEmerald : AppColors.glassBorder),
                              ),
                              child: Center(
                                child: Text(
                                  'Money Given (Receivable)',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: type == 'given' ? FontWeight.bold : FontWeight.w500,
                                    color: type == 'given' ? AppColors.incomeEmerald : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => type = 'taken'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: type == 'taken' ? AppColors.expenseRose.withOpacity(0.2) : AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: type == 'taken' ? AppColors.expenseRose : AppColors.glassBorder),
                              ),
                              child: Center(
                                child: Text(
                                  'Money Taken (Liability)',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: type == 'taken' ? FontWeight.bold : FontWeight.w500,
                                    color: type == 'taken' ? AppColors.expenseRose : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Subtype selector
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: Text('Account Credit', style: GoogleFonts.outfit(fontSize: 11)),
                            selected: subType == 'account_credit',
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            onSelected: (val) => setModalState(() => subType = 'account_credit'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: Text('EMI / Loan', style: GoogleFonts.outfit(fontSize: 11)),
                            selected: subType == 'emi_loan',
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            onSelected: (val) => setModalState(() => subType = 'emi_loan'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Person Name Input
                    TextField(
                      controller: personController,
                      style: GoogleFonts.outfit(color: AppColors.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Person / Lender Name',
                        labelStyle: GoogleFonts.outfit(color: AppColors.outline),
                        hintText: 'e.g. John Doe / HDFC Loan',
                        hintStyle: GoogleFonts.outfit(color: AppColors.outline),
                        filled: true,
                        fillColor: AppColors.surfaceContainerHigh,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Amount Input
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.outfit(color: AppColors.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Amount (₹)',
                        labelStyle: GoogleFonts.outfit(color: AppColors.outline),
                        hintText: '0.00',
                        hintStyle: GoogleFonts.outfit(color: AppColors.outline),
                        filled: true,
                        fillColor: AppColors.surfaceContainerHigh,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Due Date Selector
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppColors.primary,
                                  onPrimary: Colors.white,
                                  surface: AppColors.surfaceContainerHigh,
                                  onSurface: AppColors.onSurface,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setModalState(() => selectedDueDate = picked);
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
                            Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  selectedDueDate == null
                                      ? 'Set Repayment Due Date (Optional)'
                                      : 'Due: ${dateFormatter.format(selectedDueDate!)}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: selectedDueDate == null ? AppColors.outline : AppColors.onSurface,
                                    fontWeight: selectedDueDate == null ? FontWeight.normal : FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.arrow_drop_down, color: AppColors.outline),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Account Selector (if applicable)
                    if (subType == 'account_credit') ...[
                      DropdownButtonFormField<String>(
                        value: selectedAccountId,
                        dropdownColor: AppColors.surfaceContainerHigh,
                        style: GoogleFonts.outfit(color: AppColors.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Linked Account',
                          labelStyle: GoogleFonts.outfit(color: AppColors.outline),
                          filled: true,
                          fillColor: AppColors.surfaceContainerHigh,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: accountState.accounts.map((acc) {
                          return DropdownMenuItem(value: acc.id, child: Text(acc.name));
                        }).toList(),
                        onChanged: (val) => setModalState(() => selectedAccountId = val),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Notes Input
                    TextField(
                      controller: notesController,
                      style: GoogleFonts.outfit(color: AppColors.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Notes (Optional)',
                        labelStyle: GoogleFonts.outfit(color: AppColors.outline),
                        filled: true,
                        fillColor: AppColors.surfaceContainerHigh,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final person = personController.text.trim();
                              final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                              if (person.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter a person name.')),
                                );
                                return;
                              }
                              if (amt <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter a valid amount.')),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);

                              final Map<String, dynamic> body = {
                                'type': type,
                                'subType': subType,
                                'personName': person,
                                'amount': amt,
                                'notes': notesController.text.trim(),
                                if (subType == 'account_credit' && selectedAccountId != null) 'linkedAccountId': selectedAccountId,
                                if (selectedDueDate != null) 'dueDate': selectedDueDate!.toIso8601String(),
                              };

                              final ok = await ref.read(creditProvider.notifier).addCredit(body);
                              if (ok && mounted) {
                                ref.read(accountProvider.notifier).fetchAccounts();
                                ref.read(analyticsProvider.notifier).fetchAll();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Credit record for $person saved!'),
                                    backgroundColor: AppColors.incomeEmerald,
                                  ),
                                );
                              } else if (mounted) {
                                setModalState(() => isSubmitting = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryViolet,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Save Record', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
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

  void _showRecordRepaymentSheet(CreditModel credit) {
    final amountController = TextEditingController(text: credit.remainingAmount.toStringAsFixed(0));
    final noteController = TextEditingController();
    String? selectedAccountId;
    DateTime selectedDate = DateTime.now();
    bool isSubmitting = false;

    final accountState = ref.read(accountProvider);
    if (accountState.accounts.isNotEmpty) {
      selectedAccountId = credit.linkedAccountId ?? accountState.accounts.first.id;
    }

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
                      'Record Repayment: ${credit.personName}',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Remaining Due: ${currencyFormatter.format(credit.remainingAmount)}',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),

                    // Amount Input
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.outfit(color: AppColors.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Repayment Amount (₹)',
                        labelStyle: GoogleFonts.outfit(color: AppColors.outline),
                        filled: true,
                        fillColor: AppColors.surfaceContainerHigh,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Account Selector
                    DropdownButtonFormField<String>(
                      value: selectedAccountId,
                      dropdownColor: AppColors.surfaceContainerHigh,
                      style: GoogleFonts.outfit(color: AppColors.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Payment Account',
                        labelStyle: GoogleFonts.outfit(color: AppColors.outline),
                        filled: true,
                        fillColor: AppColors.surfaceContainerHigh,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: accountState.accounts.map((acc) {
                        return DropdownMenuItem(value: acc.id, child: Text('${acc.name} (₹${acc.balance})'));
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedAccountId = val),
                    ),
                    const SizedBox(height: 12),

                    // Repayment Date Selector
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppColors.primary,
                                  onPrimary: Colors.white,
                                  surface: AppColors.surfaceContainerHigh,
                                  onSurface: AppColors.onSurface,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
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
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                                const SizedBox(width: 10),
                                Text(
                                  'Date: ${dateFormatter.format(selectedDate)}',
                                  style: GoogleFonts.outfit(fontSize: 13, color: AppColors.onSurface, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const Icon(Icons.arrow_drop_down, color: AppColors.outline),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Note Input
                    TextField(
                      controller: noteController,
                      style: GoogleFonts.outfit(color: AppColors.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Repayment Note (Optional)',
                        labelStyle: GoogleFonts.outfit(color: AppColors.outline),
                        hintText: 'e.g. Partial repayment via UPI',
                        filled: true,
                        fillColor: AppColors.surfaceContainerHigh,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Repayment Button
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                              if (amt <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter a valid repayment amount.')),
                                );
                                return;
                              }
                              if (amt > credit.remainingAmount) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Repayment amount exceeds remaining due of ₹${credit.remainingAmount}.')),
                                );
                                return;
                              }
                              if (selectedAccountId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please select a payment account.')),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);

                              final ok = await ref.read(transactionProvider.notifier).addTransaction({
                                'type': 'credit_repay',
                                'amount': amt,
                                'accountId': selectedAccountId,
                                'creditId': credit.id,
                                'creditType': credit.type,
                                'date': selectedDate.toIso8601String(),
                                'note': noteController.text.trim().isNotEmpty
                                    ? noteController.text.trim()
                                    : 'Repayment towards ${credit.personName}',
                              });

                              if (ok && mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Repayment of ₹$amt recorded successfully!'),
                                    backgroundColor: AppColors.incomeEmerald,
                                  ),
                                );
                              } else if (mounted) {
                                setModalState(() => isSubmitting = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryViolet,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Confirm Repayment', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
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

  void _showCreditDetailModal(CreditModel credit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final transactions = ref.watch(transactionProvider).transactions;
        final creditRepayments = transactions.where((t) => t.type == 'credit_repay' && t.creditId == credit.id).toList();

        final isGiven = credit.type == 'given';
        final paidAmount = (credit.amount - credit.remainingAmount).clamp(0.0, credit.amount);
        final percentPaid = credit.amount > 0 ? (paidAmount / credit.amount * 100).clamp(0.0, 100.0) : 0.0;

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

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            credit.personName,
                            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isGiven ? 'Money Given (Receivable)' : 'Money Taken (Liability / Debt)',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isGiven ? AppColors.incomeEmerald : AppColors.expenseRose,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(credit.status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        credit.status.toUpperCase(),
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: _getStatusColor(credit.status)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Financial Progress Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Original Amount', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.onSurfaceVariant)),
                              Text(currencyFormatter.format(credit.amount), style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('Paid So Far', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.onSurfaceVariant)),
                              Text(currencyFormatter.format(paidAmount), style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.incomeEmerald)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Remaining Due', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.onSurfaceVariant)),
                              Text(currencyFormatter.format(credit.remainingAmount), style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.expenseRose)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: percentPaid / 100.0,
                          minHeight: 8,
                          backgroundColor: AppColors.surfaceContainer,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            credit.status == 'settled' ? AppColors.incomeEmerald : AppColors.primaryViolet,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${percentPaid.toStringAsFixed(0)}% Repaid',
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Details List
                if (credit.dueDate != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.event_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('Due Date: ', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.onSurfaceVariant)),
                      Text(
                        dateFormatter.format(DateTime.parse(credit.dueDate!)),
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                if (credit.linkedAccountName != null && credit.linkedAccountName!.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.account_balance_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('Linked Account: ', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.onSurfaceVariant)),
                      Text(
                        credit.linkedAccountName!,
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                if (credit.notes.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Notes: ${credit.notes}',
                          style: GoogleFonts.outfit(fontSize: 13, color: AppColors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Repayment History Timeline
                Text(
                  'Repayment History Timeline',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                ),
                const SizedBox(height: 8),
                if (creditRepayments.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'No repayments recorded yet.',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: creditRepayments.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.outlineVariant.withOpacity(0.3)),
                      itemBuilder: (context, index) {
                        final tx = creditRepayments[index];
                        final parsedDate = DateTime.tryParse(tx.date) ?? DateTime.now();
                        final isReceivable = tx.creditType == 'given' || credit.type == 'given';
                        final sign = isReceivable ? '+' : '-';
                        final color = isReceivable ? AppColors.incomeEmerald : AppColors.expenseRose;

                        return ListTile(
                          dense: true,
                          leading: Icon(Icons.check_circle_outline_rounded, color: color, size: 20),
                          title: Text(
                            '$sign ${currencyFormatter.format(tx.amount)}',
                            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                          ),
                          subtitle: Text(
                            '${dateFormatter.format(parsedDate)} • ${tx.accountName ?? "Account"}${tx.note != null && tx.note!.isNotEmpty ? " • ${tx.note}" : ""}',
                            style: GoogleFonts.outfit(fontSize: 11, color: AppColors.onSurfaceVariant),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 20),

                // Record Repayment Button (if not settled)
                if (credit.status != 'settled')
                  ElevatedButton.icon(
                    icon: const Icon(Icons.payments_outlined, size: 18, color: Colors.white),
                    label: Text('Record Repayment', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryViolet,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _showRecordRepaymentSheet(credit);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'settled':
        return AppColors.incomeEmerald;
      case 'partial':
        return AppColors.transferAmber;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = ref.watch(budgetProvider);
    final creditState = ref.watch(creditProvider);

    if (widget.isBudgetsOnly) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text(
            'Budgets',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onSurface),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
              tooltip: 'Create Budget',
              onPressed: _showCreateBudgetSheet,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: _buildBudgetsTab(budgetState),
          ),
        ),
      );
    }

    if (widget.isCreditsOnly) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text(
            'Credits',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onSurface),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
              tooltip: 'Add Credit/Loan',
              onPressed: _showAddCreditSheet,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: _buildCreditsTab(creditState),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Budgets & Credits',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onSurface),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            tooltip: 'Create Budget or Record',
            onPressed: () {
              if (_tabController.index == 0) {
                _showCreateBudgetSheet();
              } else {
                _showAddCreditSheet();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Monthly Budgets'),
            Tab(text: 'Debt & Credits'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Category Monthly Budgets
            RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.primary,
              child: _buildBudgetsTab(budgetState),
            ),

            // Tab 2: Debt & Credits Tracker
            RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.primary,
              child: _buildCreditsTab(creditState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetsTab(BudgetState budgetState) {
    if (budgetState.isLoading) {
      return const BudgetsTabSkeleton();
    }

    final summary = budgetState.summary;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Budget Summary Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Budgeted', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.onSurfaceVariant)),
                    Text('Spent', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currencyFormatter.format(summary?.totalBudgeted ?? 0),
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                    ),
                    Text(
                      currencyFormatter.format(summary?.totalSpent ?? 0),
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.expenseRose),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (summary?.overallPercentage ?? 0) / 100.0,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      (summary?.overallPercentage ?? 0) > 100 ? AppColors.expenseRose : AppColors.primaryViolet,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section Header
          Text(
            'Category Budgets',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
          ),
          const SizedBox(height: 10),

          if (summary?.categories.isEmpty ?? true)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.pie_chart_outline_rounded, size: 48, color: AppColors.outline.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    Text(
                      'No category budgets configured yet',
                      style: GoogleFonts.outfit(color: AppColors.onSurfaceVariant, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap + above to create one',
                      style: GoogleFonts.outfit(color: AppColors.outline, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: summary!.categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final cat = summary.categories[index];
                return _buildCategoryBudgetTile(cat);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryBudgetTile(CategoryBudgetSummaryModel cat) {
    final isOver = cat.percentage > 100;
    final catColor = CategoryIcons.parseColor(cat.categoryColor);
    final iconData = CategoryIcons.getIcon(cat.categoryIcon);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showSetBudgetSheet(cat),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(iconData, color: catColor, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      cat.categoryName,
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                  onPressed: () => _showSetBudgetSheet(cat),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent: ${currencyFormatter.format(cat.spent)} / ${currencyFormatter.format(cat.budgetAmount)}',
                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
                Text(
                  '${cat.percentage.toStringAsFixed(0)}%',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isOver ? AppColors.expenseRose : AppColors.incomeEmerald,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (cat.percentage / 100.0).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppColors.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(isOver ? AppColors.expenseRose : AppColors.incomeEmerald),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditsTab(CreditState creditState) {
    if (creditState.isLoading) {
      return const CreditsTabSkeleton();
    }

    final filteredCredits = creditState.credits.where((c) {
      if (_creditFilter == 'given') return c.type == 'given';
      if (_creditFilter == 'taken') return c.type == 'taken';
      if (_creditFilter == 'active') return c.status != 'settled';
      if (_creditFilter == 'settled') return c.status == 'settled';
      return true;
    }).toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Receivables vs Liabilities Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Receivables (Given)', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormatter.format(creditState.totals?.totalReceivables ?? 0),
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.incomeEmerald),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Liabilities (Taken)', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormatter.format(creditState.totals?.totalLiabilities ?? 0),
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.expenseRose),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Header & New Record Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Credit Records',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: Text('New Record', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryViolet,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _showAddCreditSheet,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All'),
                const SizedBox(width: 8),
                _buildFilterChip('given', 'Receivables (Given)'),
                const SizedBox(width: 8),
                _buildFilterChip('taken', 'Liabilities (Taken)'),
                const SizedBox(width: 8),
                _buildFilterChip('active', 'Active / Pending'),
                const SizedBox(width: 8),
                _buildFilterChip('settled', 'Settled'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (filteredCredits.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('No credit or loan records found', style: GoogleFonts.outfit(color: AppColors.onSurfaceVariant)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredCredits.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final credit = filteredCredits[index];
                return _buildCreditCard(credit);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _creditFilter == filterKey;
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: AppColors.primary.withOpacity(0.2),
      backgroundColor: AppColors.surfaceContainer,
      onSelected: (val) {
        if (val) setState(() => _creditFilter = filterKey);
      },
    );
  }

  Widget _buildCreditCard(CreditModel credit) {
    final isGiven = credit.type == 'given';
    final Color badgeColor = isGiven ? AppColors.incomeEmerald : AppColors.expenseRose;
    final paidAmount = (credit.amount - credit.remainingAmount).clamp(0.0, credit.amount);
    final percentPaid = credit.amount > 0 ? (paidAmount / credit.amount * 100).clamp(0.0, 100.0) : 0.0;

    // Due Date Status Widget
    Widget dueDateWidget = const SizedBox.shrink();
    if (credit.status != 'settled' && credit.dueDate != null) {
      final due = DateTime.parse(credit.dueDate!);
      final now = DateTime.now();
      final diffDays = due.difference(DateTime(now.year, now.month, now.day)).inDays;

      if (diffDays < 0) {
        dueDateWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: AppColors.expenseRose.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
          child: Text('Overdue by ${diffDays.abs()} days', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.expenseRose)),
        );
      } else if (diffDays <= 7) {
        dueDateWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: AppColors.transferAmber.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
          child: Text('Due in $diffDays days', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.transferAmber)),
        );
      } else {
        dueDateWidget = Text('Due: ${dateFormatter.format(due)}', style: GoogleFonts.outfit(fontSize: 10, color: AppColors.onSurfaceVariant));
      }
    }

    return GestureDetector(
      onTap: () => _showCreditDetailModal(credit),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isGiven ? Icons.arrow_outward_rounded : Icons.call_received_rounded,
                    color: badgeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            credit.personName,
                            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                          ),
                          const SizedBox(width: 6),
                          dueDateWidget,
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${isGiven ? "Receivable" : "Liability"} • Status: ${credit.status.toUpperCase()}',
                        style: GoogleFonts.outfit(fontSize: 11, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormatter.format(credit.remainingAmount),
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: badgeColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Orig: ₹${credit.amount.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(fontSize: 10, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentPaid / 100.0,
                minHeight: 4,
                backgroundColor: AppColors.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${percentPaid.toStringAsFixed(0)}% Repaid',
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                ),
                Row(
                  children: [
                    if (credit.status != 'settled')
                      GestureDetector(
                        onTap: () => _showRecordRepaymentSheet(credit),
                        child: Text(
                          '⚡ Record Repayment',
                          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    if (credit.status != 'settled') const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _showCreditDetailModal(credit),
                      child: Text(
                        'View Details ➔',
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
