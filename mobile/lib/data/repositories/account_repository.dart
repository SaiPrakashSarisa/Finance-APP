import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/account_model.dart';

/// Purpose: Account Data Repository with Full CRUD
/// Author: Antigravity AI

class AccountRepository {
  final ApiClient apiClient;

  AccountRepository(this.apiClient);

  Future<List<AccountModel>> getAccounts() async {
    final response = await apiClient.get(ApiEndpoints.accounts);
    if (response.data != null && response.data['success'] == true) {
      final list = (response.data['data'] as List<dynamic>?) ?? [];
      return list.map((item) => AccountModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<AccountModel?> createAccount(Map<String, dynamic> data) async {
    final response = await apiClient.post(ApiEndpoints.accounts, data: data);
    if (response.data != null && response.data['success'] == true) {
      return AccountModel.fromJson(response.data['data']);
    }
    return null;
  }

  Future<AccountModel?> updateAccount(String id, Map<String, dynamic> data) async {
    final response = await apiClient.put('${ApiEndpoints.accounts}/$id', data: data);
    if (response.data != null && response.data['success'] == true) {
      return AccountModel.fromJson(response.data['data']);
    }
    return null;
  }

  Future<bool> deleteAccount(String id) async {
    final response = await apiClient.delete('${ApiEndpoints.accounts}/$id');
    return response.data != null && response.data['success'] == true;
  }
}
