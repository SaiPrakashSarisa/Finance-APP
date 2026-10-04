import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/api_endpoints.dart';
import '../../data/local/local_database_service.dart';
import '../../data/models/budget_model.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/sync/sync_manager.dart';
import 'auth_provider.dart';

/// Purpose: Monthly Budget State Management Provider (Offline-First)
/// Author: Antigravity AI
/// Architecture: Local SQLite as primary source of truth + background sync

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
  static const _uuid = Uuid();

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

  /// 1. Load instantly from local SQLite (<5ms)
  Future<void> _loadFromLocal(int month, int year) async {
    try {
      final localBudgets = await LocalDatabaseService.getLocalBudgets(month: month, year: year);
      final localCategories = await LocalDatabaseService.getLocalCategories();
      final catMap = {for (final c in localCategories) c['id'] as String: c};

      final catSummaryList = <CategoryBudgetSummaryModel>[];
      for (final b in localBudgets) {
        final catId = b['categoryId'] as String? ?? '';
        final cat = catMap[catId];
        final catName = (cat?['name'] as String?) ?? (b['categoryName'] as String?) ?? 'Budget';
        final catColor = (cat?['color'] as String?) ?? '#6366f1';
        final catIcon = (cat?['icon'] as String?) ?? 'folder';
        final amount = (b['amount'] as num?)?.toDouble() ?? 0.0;
        final spent = (b['spent'] as num?)?.toDouble() ?? 0.0;
        final remaining = amount - spent;
        final percentage = amount > 0 ? (spent / amount) * 100 : 0.0;

        catSummaryList.add(CategoryBudgetSummaryModel(
          categoryId: catId,
          categoryName: catName,
          categoryColor: catColor,
          categoryIcon: catIcon,
          budgetId: b['id'] as String?,
          budgetAmount: amount,
          spent: spent,
          remaining: remaining,
          percentage: percentage,
        ));
      }

      final totalBud = catSummaryList.fold<double>(0.0, (sum, c) => sum + c.budgetAmount);
      final totalSp = catSummaryList.fold<double>(0.0, (sum, c) => sum + c.spent);
      final overallPct = totalBud > 0 ? (totalSp / totalBud) * 100 : 0.0;

      state = BudgetState(
        summary: BudgetSummaryModel(
          totalBudgeted: totalBud,
          totalSpent: totalSp,
          overallPercentage: overallPct,
          categories: catSummaryList,
        ),
        isLoading: false,
        selectedMonth: month,
        selectedYear: year,
      );
    } catch (e) {
      debugPrint('[BudgetNotifier] Error loading local budgets: $e');
    }
  }

  /// Fetch budget summary: instant local display + background network fetch
  Future<void> fetchSummary({int? month, int? year}) async {
    final m = month ?? state.selectedMonth;
    final y = year ?? state.selectedYear;

    // 1. Instant local read
    await _loadFromLocal(m, y);

    // 2. Fetch from backend if network is available
    try {
      final summary = await repository.getSummary(month: m, year: y);
      if (summary != null) {
        state = BudgetState(
          summary: summary,
          isLoading: false,
          selectedMonth: m,
          selectedYear: y,
        );

        // Update local DB cache with latest populated data
        final budgetsJson = summary.categories.map((c) => {
          'id': c.budgetId,
          'categoryId': c.categoryId,
          'categoryName': c.categoryName,
          'amount': c.budgetAmount,
          'spent': c.spent,
          'month': m,
          'year': y,
        }).toList();
        await LocalDatabaseService.saveLocalBudgets(budgetsJson);
      }
    } catch (e) {
      // Offline / network failure: keep local state without destroying UI
      debugPrint('[BudgetNotifier] Network fetch failed, using local DB: $e');
    }
  }

  /// DIRECT-FIRST + SYNC FALLBACK: Set / upsert budget
  Future<bool> setBudget({
    required String categoryId,
    required double amount,
  }) async {
    try {
      final m = state.selectedMonth;
      final y = state.selectedYear;

      // Check existing budget for ID
      final existing = await LocalDatabaseService.getLocalBudgets(month: m, year: y);
      final match = existing.where((b) => b['categoryId'] == categoryId).firstOrNull;
      final budgetId = match != null ? (match['id'] as String) : _uuid.v4();

      final budgetMap = {
        'id': budgetId,
        'categoryId': categoryId,
        'amount': amount,
        'month': m,
        'year': y,
      };

      // 1. Write to local SQLite immediately (<5ms)
      await LocalDatabaseService.saveLocalBudget(budgetMap, isSynced: false);

      // 2. Refresh UI instantly from local DB
      await _loadFromLocal(m, y);

      // 3. Direct API Call First with fallback to sync_queue
      final response = await SyncManager.executeDirectWithQueueFallback(
        endpoint: ApiEndpoints.budgets,
        method: 'POST',
        payload: {
          'categoryId': categoryId,
          'amount': amount,
          'month': m,
          'year': y,
        },
      );

      if (response != null && response.statusCode != null && response.statusCode! < 400) {
        await LocalDatabaseService.saveLocalBudget(budgetMap, isSynced: true);
      }

      return true;
    } catch (e) {
      debugPrint('[BudgetNotifier] Error setting budget: $e');
      return false;
    }
  }

  /// DIRECT-FIRST + SYNC FALLBACK: Delete budget
  Future<bool> removeBudget(String budgetId) async {
    try {
      // 1. Delete from local SQLite
      await LocalDatabaseService.deleteLocalBudget(budgetId);

      // 2. Refresh UI instantly
      await _loadFromLocal(state.selectedMonth, state.selectedYear);

      // 3. Direct API Call First with fallback to sync_queue
      await SyncManager.executeDirectWithQueueFallback(
        endpoint: '${ApiEndpoints.budgets}/$budgetId',
        method: 'DELETE',
        payload: {},
      );

      return true;
    } catch (e) {
      debugPrint('[BudgetNotifier] Error removing budget: $e');
      return false;
    }
  }
}

final budgetProvider = StateNotifierProvider<BudgetNotifier, BudgetState>((ref) {
  return BudgetNotifier(ref.watch(budgetRepositoryProvider));
});
