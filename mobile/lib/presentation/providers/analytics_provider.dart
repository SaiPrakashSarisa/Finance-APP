import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/local_database_service.dart';
import '../../data/models/analytics_model.dart';
import '../../data/repositories/analytics_repository.dart';
import 'auth_provider.dart';

/// Purpose: Financial Analytics & Insights State Management Provider (Offline-First)
/// Author: Antigravity AI
/// Provides instant local dashboard computation with zero cold-start delay

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(ref.watch(apiClientProvider));
});

class AnalyticsState {
  final DashboardSummaryModel? dashboard;
  final InsightsModel? insights;
  final List<CategoryBreakdownModel> categories;
  final List<MonthlyTrendModel> monthlyTrends;
  final List<ItemInflationModel> inflationItems;
  final List<SubscriptionModel> subscriptions;
  final bool isLoading;
  final String? error;

  AnalyticsState({
    this.dashboard,
    this.insights,
    required this.categories,
    required this.monthlyTrends,
    required this.inflationItems,
    required this.subscriptions,
    required this.isLoading,
    this.error,
  });
}

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final AnalyticsRepository repository;

  AnalyticsNotifier(this.repository)
      : super(
          AnalyticsState(
            categories: [],
            monthlyTrends: [],
            inflationItems: [],
            subscriptions: [],
            isLoading: true,
          ),
        ) {
    _initLocalAndFetch();
  }

  Future<void> _initLocalAndFetch() async {
    await _computeLocalDashboard();
    await fetchAll();
  }

  /// Instant local dashboard calculation from SQLite (<5ms)
  Future<void> _computeLocalDashboard({String? range, int? month, int? year}) async {
    try {
      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate;

      if (month != null && year != null) {
        startDate = DateTime(year, month, 1, 0, 0, 0);
        endDate = DateTime(year, month + 1, 0, 23, 59, 59);
      } else {
        final r = range ?? '1m';
        if (r == '1m') {
          startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
          endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        } else if (r == '3m') {
          startDate = DateTime(now.year, now.month - 2, 1, 0, 0, 0);
          endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        } else if (r == '6m') {
          startDate = DateTime(now.year, now.month - 5, 1, 0, 0, 0);
          endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        } else if (r == '1y') {
          startDate = DateTime(now.year, now.month - 11, 1, 0, 0, 0);
          endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        } else {
          // 'all'
          startDate = DateTime(2000, 1, 1);
          endDate = DateTime(now.year + 5, 12, 31, 23, 59, 59);
        }
      }

      final accounts = await LocalDatabaseService.getLocalAccounts();
      final incomes = await LocalDatabaseService.getLocalTransactions(
        type: 'income',
        startDate: startDate,
        endDate: endDate,
      );
      final expenses = await LocalDatabaseService.getLocalTransactions(
        type: 'expense',
        startDate: startDate,
        endDate: endDate,
      );

      final netWorth = accounts.fold<double>(
        0.0,
        (sum, a) => sum + ((a['balance'] as num?)?.toDouble() ?? 0.0),
      );
      final incomeTotal = incomes.fold<double>(
        0.0,
        (sum, tx) => sum + ((tx['amount'] as num?)?.toDouble() ?? 0.0),
      );
      final expenseTotal = expenses.fold<double>(
        0.0,
        (sum, tx) => sum + ((tx['amount'] as num?)?.toDouble() ?? 0.0),
      );

      final localDashboard = DashboardSummaryModel(
        income: incomeTotal,
        expense: expenseTotal,
        netSavings: incomeTotal - expenseTotal,
        totalReceivables: 0.0,
        totalLiabilities: 0.0,
        netWorth: netWorth,
        accounts: accounts,
      );

      // Instant local paint
      state = AnalyticsState(
        dashboard: localDashboard,
        insights: state.insights,
        categories: state.categories,
        monthlyTrends: state.monthlyTrends,
        inflationItems: state.inflationItems,
        subscriptions: state.subscriptions,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('[AnalyticsNotifier] Error computing local dashboard: $e');
    }
  }

  Future<void> fetchAll({String? range, int? month, int? year}) async {
    // 1. Instant local computation (<5ms)
    await _computeLocalDashboard(range: range, month: month, year: year);

    // 2. Fetch live data from backend
    try {
      final d = await repository.getDashboard(month: month, year: year);
      final ins = await repository.getInsights(month: month, year: year);
      final c = await repository.getCategoryBreakdown(month: month, year: year);
      final t = await repository.getMonthlyTrend();
      final inf = await repository.getInflationTracker();
      final sub = await repository.getSubscriptions();

      state = AnalyticsState(
        dashboard: d,
        insights: ins,
        categories: c,
        monthlyTrends: t,
        inflationItems: inf,
        subscriptions: sub,
        isLoading: false,
      );
    } catch (e) {
      // Offline / network timeout / Render cold start: retain existing local data
      debugPrint('[AnalyticsNotifier] Network fetch failed, retaining local state: $e');
    }
  }
}

final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  return AnalyticsNotifier(ref.watch(analyticsRepositoryProvider));
});
