import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/account_model.dart';

/// Purpose: Account Data Repository
/// Author: Antigravity AI
/// Last Modified: 2026-08-03

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
}
