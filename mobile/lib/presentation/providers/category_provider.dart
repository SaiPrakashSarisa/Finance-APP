import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/api_endpoints.dart';
import '../../data/local/local_database_service.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/sync/sync_manager.dart';
import 'auth_provider.dart';

/// Purpose: Category State Management Provider (Direct-First + Sync Fallback)
/// Author: Antigravity AI
///
/// Architecture:
/// 1. Instant local SQLite write/read (<5ms)
/// 2. Direct API call to Render backend
/// 3. If direct call fails (offline/cold start) → drops to sync_queue
/// 4. UI updates instantly in all cases

const _uuid = Uuid();

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(apiClientProvider));
});

class CategoryState {
  final List<CategoryModel> categories;
  final bool isLoading;
  final String? error;

  CategoryState({
    required this.categories,
    required this.isLoading,
    this.error,
  });

  /// Returns categories organized hierarchically: Parent category followed immediately by its subcategories
  List<CategoryModel> getOrderedCategories({String? type}) {
    final filtered = categories.where((c) {
      if (type == 'expense') return c.type == 'expense';
      if (type == 'income') return c.type == 'income';
      return true;
    }).toList();

    final List<CategoryModel> result = [];
    final parents = filtered.where((c) => c.parentCategoryId == null || c.parentCategoryId!.isEmpty).toList();

    for (final parent in parents) {
      result.add(parent);
      final children = filtered.where((c) => c.parentCategoryId == parent.id).toList();
      result.addAll(children);
    }

    final addedIds = result.map((c) => c.id).toSet();
    final remaining = filtered.where((c) => !addedIds.contains(c.id)).toList();
    result.addAll(remaining);

    return result;
  }
}

class CategoryNotifier extends StateNotifier<CategoryState> {
  final CategoryRepository repository;

  CategoryNotifier(this.repository)
      : super(CategoryState(categories: [], isLoading: true)) {
    fetchCategories();
  }

  /// PRIMARY: Load categories from local SQLite (< 5ms)
  Future<void> _loadFromLocal() async {
    try {
      final rows = await LocalDatabaseService.getLocalCategories();
      final list = rows.map((row) => _mapRowToModel(row)).toList();
      state = CategoryState(categories: list, isLoading: false);
    } catch (e) {
      debugPrint('[CategoryProvider] Local read error: $e');
      state = CategoryState(categories: state.categories, isLoading: false, error: e.toString());
    }
  }

  /// Refresh categories: Instant local display + background network fetch
  Future<void> fetchCategories({String? type}) async {
    await _loadFromLocal();

    try {
      final remoteList = await repository.getCategories(type: type);
      if (remoteList.isNotEmpty) {
        state = CategoryState(categories: remoteList, isLoading: false);
        // Persist to local database
        final jsonList = remoteList.map((c) => {
          'id': c.id,
          'name': c.name,
          'type': c.type,
          'parentCategoryId': c.parentCategoryId,
          'color': c.color,
          'icon': c.icon,
        }).toList();
        await LocalDatabaseService.clearLocalCategories();
        await LocalDatabaseService.saveLocalCategories(jsonList);
      }
    } catch (e) {
      debugPrint('[CategoryProvider] Network fetch failed, using local DB: $e');
    }
  }

  /// DIRECT-FIRST + SYNC FALLBACK: Add category
  Future<bool> addCategory(Map<String, dynamic> data) async {
    try {
      final catId = _uuid.v4();
      final idempotencyKey = _uuid.v4();

      // 1. Save to local SQLite instantly
      final localCat = {
        'id': catId,
        ...data,
      };
      await LocalDatabaseService.saveLocalCategory(localCat, isSynced: false);

      // 2. Refresh UI immediately from local data
      await _loadFromLocal();

      // 3. Direct API Call First with fallback to sync_queue
      final response = await SyncManager.executeDirectWithQueueFallback(
        endpoint: ApiEndpoints.categories,
        method: 'POST',
        payload: data,
        customIdempotencyKey: idempotencyKey,
      );

      // 4. If direct call succeeded immediately, update local record with server ID if different
      if (response != null && response.statusCode != null && response.statusCode! < 400) {
        if (response.data != null && response.data['data'] is Map) {
          final serverCat = response.data['data'] as Map<String, dynamic>;
          if (serverCat['_id'] != null && serverCat['_id'] != catId) {
            final database = await LocalDatabaseService.db;
            await database.delete('categories', where: 'id = ?', whereArgs: [catId]);
            await LocalDatabaseService.saveLocalCategory(serverCat, isSynced: true);
            await _loadFromLocal();
          }
        }
      }

      return true;
    } catch (e) {
      debugPrint('[CategoryProvider] addCategory error: $e');
      return false;
    }
  }

  /// DIRECT-FIRST + SYNC FALLBACK: Delete category
  Future<bool> deleteCategory(String id) async {
    try {
      final idempotencyKey = _uuid.v4();
      final database = await LocalDatabaseService.db;

      // 1. Delete from local SQLite
      await database.delete('categories', where: 'id = ?', whereArgs: [id]);

      // 2. Refresh UI
      await _loadFromLocal();

      // 3. Direct API Call First with fallback to sync_queue
      await SyncManager.executeDirectWithQueueFallback(
        endpoint: '${ApiEndpoints.categories}/$id',
        method: 'DELETE',
        payload: {},
        customIdempotencyKey: idempotencyKey,
      );

      return true;
    } catch (e) {
      debugPrint('[CategoryProvider] deleteCategory error: $e');
      return false;
    }
  }

  /// Convert SQLite row to CategoryModel
  CategoryModel _mapRowToModel(Map<String, dynamic> row) {
    return CategoryModel(
      id: row['id'] as String,
      name: row['name'] as String? ?? '',
      type: row['type'] as String? ?? 'expense',
      parentCategoryId: row['parentCategoryId'] as String?,
      color: row['color'] as String?,
      icon: row['icon'] as String?,
    );
  }
}

final categoryProvider = StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
  final authState = ref.watch(authProvider);
  final notifier = CategoryNotifier(ref.watch(categoryRepositoryProvider));
  if (authState.isAuthenticated) {
    notifier._loadFromLocal();
  }
  return notifier;
});
