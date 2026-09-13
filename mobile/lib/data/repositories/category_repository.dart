import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/category_model.dart';

/// Purpose: Category Data Repository
/// Author: Antigravity AI

class CategoryRepository {
  final ApiClient apiClient;

  CategoryRepository(this.apiClient);

  Future<List<CategoryModel>> getCategories({String? type, bool tree = false}) async {
    final Map<String, dynamic> params = {};
    if (type != null) params['type'] = type;
    if (tree) params['tree'] = 'true';

    final response = await apiClient.get(ApiEndpoints.categories, queryParameters: params);
    if (response.data != null && response.data['success'] == true) {
      final list = (response.data['data'] as List<dynamic>?) ?? [];
      return list.map((item) => CategoryModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<CategoryModel?> createCategory(Map<String, dynamic> data) async {
    final response = await apiClient.post(ApiEndpoints.categories, data: data);
    if (response.data != null && response.data['success'] == true) {
      return CategoryModel.fromJson(response.data['data']);
    }
    return null;
  }

  Future<CategoryModel?> updateCategory(String id, Map<String, dynamic> data) async {
    final response = await apiClient.put('${ApiEndpoints.categories}/$id', data: data);
    if (response.data != null && response.data['success'] == true) {
      return CategoryModel.fromJson(response.data['data']);
    }
    return null;
  }

  Future<bool> deleteCategory(String id) async {
    final response = await apiClient.delete('${ApiEndpoints.categories}/$id');
    return response.data != null && response.data['success'] == true;
  }
}
