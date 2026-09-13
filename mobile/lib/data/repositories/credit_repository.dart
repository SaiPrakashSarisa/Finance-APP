import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/credit_model.dart';

/// Purpose: Credit & Debt Tracker Repository
/// Author: Antigravity AI

class CreditRepository {
  final ApiClient apiClient;

  CreditRepository(this.apiClient);

  Future<List<CreditModel>> getCredits({String? type, String? status}) async {
    final Map<String, dynamic> query = {};
    if (type != null) query['type'] = type;
    if (status != null) query['status'] = status;

    final response = await apiClient.get(ApiEndpoints.credits, queryParameters: query);
    if (response.data != null && response.data['success'] == true) {
      final list = (response.data['data'] as List<dynamic>?) ?? [];
      return list.map((item) => CreditModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<CreditTotalsModel?> getTotals() async {
    final response = await apiClient.get(ApiEndpoints.creditTotals);
    if (response.data != null && response.data['success'] == true) {
      return CreditTotalsModel.fromJson(response.data['data']);
    }
    return null;
  }

  Future<CreditModel?> createCredit(Map<String, dynamic> data) async {
    final response = await apiClient.post(ApiEndpoints.credits, data: data);
    if (response.data != null && response.data['success'] == true) {
      return CreditModel.fromJson(response.data['data']);
    }
    return null;
  }

  Future<CreditModel?> updateCredit(String id, Map<String, dynamic> data) async {
    final response = await apiClient.put('${ApiEndpoints.credits}/$id', data: data);
    if (response.data != null && response.data['success'] == true) {
      return CreditModel.fromJson(response.data['data']);
    }
    return null;
  }
}
