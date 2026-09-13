import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/analytics_model.dart';

/// Purpose: Analytics & Financial Insights Data Repository
/// Author: Antigravity AI

class AnalyticsRepository {
  final ApiClient apiClient;

  AnalyticsRepository(this.apiClient);

  Future<DashboardSummaryModel?> getDashboard({int? month, int? year}) async {
    final Map<String, dynamic> params = {};
    if (month != null) params['month'] = month;
    if (year != null) params['year'] = year;

    final response = await apiClient.get(ApiEndpoints.analyticsDashboard, queryParameters: params);
    if (response.data != null && response.data['success'] == true) {
      return DashboardSummaryModel.fromJson(response.data['data']);
    }
    return null;
  }

  Future<InsightsModel?> getInsights({int? month, int? year}) async {
    final Map<String, dynamic> params = {};
    if (month != null) params['month'] = month;
    if (year != null) params['year'] = year;

    final response = await apiClient.get(ApiEndpoints.analyticsInsights, queryParameters: params);
    if (response.data != null && response.data['success'] == true && response.data['data'] != null) {
      return InsightsModel.fromJson(response.data['data']);
    }
    return null;
  }

  Future<List<CategoryBreakdownModel>> getCategoryBreakdown({int? month, int? year}) async {
    final Map<String, dynamic> params = {};
    if (month != null) params['month'] = month;
    if (year != null) params['year'] = year;

    final response = await apiClient.get(ApiEndpoints.analyticsCategories, queryParameters: params);
    if (response.data != null && response.data['success'] == true) {
      final list = (response.data['data'] as List<dynamic>?) ?? [];
      return list.map((item) => CategoryBreakdownModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<List<MonthlyTrendModel>> getMonthlyTrend() async {
    final response = await apiClient.get(ApiEndpoints.analyticsMonthlyTrend);
    if (response.data != null && response.data['success'] == true) {
      final list = (response.data['data'] as List<dynamic>?) ?? [];
      return list.map((item) => MonthlyTrendModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<List<ItemInflationModel>> getInflationTracker() async {
    final response = await apiClient.get(ApiEndpoints.analyticsInflation);
    if (response.data != null && response.data['success'] == true && response.data['data'] != null) {
      final rawData = response.data['data'];
      List<dynamic> list = [];
      if (rawData is Map) {
        list = (rawData['items'] as List<dynamic>?) ?? [];
      } else if (rawData is List) {
        list = rawData;
      }
      return list.map((item) => ItemInflationModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<SubscriptionModel>> getSubscriptions() async {
    final response = await apiClient.get(ApiEndpoints.analyticsSubscriptions);
    if (response.data != null && response.data['success'] == true) {
      final list = (response.data['data'] as List<dynamic>?) ?? [];
      return list.map((item) => SubscriptionModel.fromJson(item)).toList();
    }
    return [];
  }
}
