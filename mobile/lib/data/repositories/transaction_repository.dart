import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/transaction_model.dart';

/// Purpose: Transaction Data Repository
/// Author: Antigravity AI
/// Last Modified: 2026-08-03

class TransactionRepository {
  final ApiClient apiClient;

  TransactionRepository(this.apiClient);

  Future<List<TransactionModel>> getTransactions({Map<String, dynamic>? filters}) async {
    final response = await apiClient.get(ApiEndpoints.transactions, queryParameters: filters);
    if (response.data != null && response.data['success'] == true) {
      final list = (response.data['transactions'] as List<dynamic>?) ?? [];
      return list.map((item) => TransactionModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<TransactionModel?> createTransaction(Map<String, dynamic> data) async {
    final response = await apiClient.post(ApiEndpoints.transactions, data: data);
    if (response.data != null && response.data['success'] == true) {
      return TransactionModel.fromJson(response.data['data']);
    }
    return null;
  }

  Future<TransactionModel?> updateTransaction(String id, Map<String, dynamic> data) async {
    final response = await apiClient.put('${ApiEndpoints.transactions}/$id', data: data);
    if (response.data != null && response.data['success'] == true) {
      return TransactionModel.fromJson(response.data['data']);
    }
    return null;
  }

  Future<bool> deleteTransaction(String id) async {
    final response = await apiClient.delete('${ApiEndpoints.transactions}/$id');
    return response.data != null && response.data['success'] == true;
  }
}
