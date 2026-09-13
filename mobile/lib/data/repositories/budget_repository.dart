import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/budget_model.dart';

/// Purpose: Monthly Budget Data Repository
/// Author: Antigravity AI

class BudgetRepository {
  final ApiClient apiClient;

  BudgetRepository(this.apiClient);

  Future<BudgetSummaryModel?> getSummary({int? month, int? year}) async {
    final Map<String, dynamic> params = {};
    if (month != null) params['month'] = month;
    if (year != null) params['year'] = year;

    final response = await apiClient.get(ApiEndpoints.budgets, queryParameters: params);
    if (response.data != null && response.data['success'] == true) {
      return BudgetSummaryModel.fromJson(response.data['data']);
    }
    return null;
  }

  Future<bool> upsertBudget({
    required String categoryId,
    required double amount,
    required int month,
    required int year,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.budgets,
      data: {
        'categoryId': categoryId,
        'amount': amount,
        'month': month,
        'year': year,
      },
    );
    return response.data != null && response.data['success'] == true;
  }

  Future<bool> deleteBudget(String budgetId) async {
    final response = await apiClient.delete('${ApiEndpoints.budgets}/$budgetId');
    return response.data != null && response.data['success'] == true;
  }
}
