import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/analytics_model.dart';
import '../../data/repositories/analytics_repository.dart';
import 'auth_provider.dart';

/// Purpose: Financial Analytics & Insights State Management Provider
/// Author: Antigravity AI

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
    fetchAll();
  }

  Future<void> fetchAll({int? month, int? year}) async {
    state = AnalyticsState(
      dashboard: state.dashboard,
      insights: state.insights,
      categories: state.categories,
      monthlyTrends: state.monthlyTrends,
      inflationItems: state.inflationItems,
      subscriptions: state.subscriptions,
      isLoading: true,
    );

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
      state = AnalyticsState(
        dashboard: state.dashboard,
        insights: state.insights,
        categories: state.categories,
        monthlyTrends: state.monthlyTrends,
        inflationItems: state.inflationItems,
        subscriptions: state.subscriptions,
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  return AnalyticsNotifier(ref.watch(analyticsRepositoryProvider));
});
