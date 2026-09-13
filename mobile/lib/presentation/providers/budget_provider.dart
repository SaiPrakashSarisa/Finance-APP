import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/budget_model.dart';
import '../../data/repositories/budget_repository.dart';
import 'auth_provider.dart';

/// Purpose: Monthly Budget State Management Provider
/// Author: Antigravity AI

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(apiClientProvider));
});

class BudgetState {
  final BudgetSummaryModel? summary;
  final bool isLoading;
  final int selectedMonth;
  final int selectedYear;
  final String? error;

  BudgetState({
    this.summary,
    required this.isLoading,
    required this.selectedMonth,
    required this.selectedYear,
    this.error,
  });
}

class BudgetNotifier extends StateNotifier<BudgetState> {
  final BudgetRepository repository;

  BudgetNotifier(this.repository)
      : super(
          BudgetState(
            isLoading: true,
            selectedMonth: DateTime.now().month,
            selectedYear: DateTime.now().year,
          ),
        ) {
    fetchSummary();
  }

  Future<void> fetchSummary({int? month, int? year}) async {
    final m = month ?? state.selectedMonth;
    final y = year ?? state.selectedYear;

    state = BudgetState(
      summary: state.summary,
      isLoading: true,
      selectedMonth: m,
      selectedYear: y,
    );

    try {
      final summary = await repository.getSummary(month: m, year: y);
      state = BudgetState(
        summary: summary,
        isLoading: false,
        selectedMonth: m,
        selectedYear: y,
      );
    } catch (e) {
      state = BudgetState(
        summary: state.summary,
        isLoading: false,
        selectedMonth: m,
        selectedYear: y,
        error: e.toString(),
      );
    }
  }

  Future<bool> setBudget({
    required String categoryId,
    required double amount,
  }) async {
    try {
      final ok = await repository.upsertBudget(
        categoryId: categoryId,
        amount: amount,
        month: state.selectedMonth,
        year: state.selectedYear,
      );
      if (ok) {
        await fetchSummary();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> removeBudget(String budgetId) async {
    try {
      final ok = await repository.deleteBudget(budgetId);
      if (ok) {
        await fetchSummary();
        return true;
      }
    } catch (_) {}
    return false;
  }
}

final budgetProvider = StateNotifierProvider<BudgetNotifier, BudgetState>((ref) {
  return BudgetNotifier(ref.watch(budgetRepositoryProvider));
});
