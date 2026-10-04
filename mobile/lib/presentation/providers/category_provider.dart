import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/api_endpoints.dart';
import '../../data/local/local_database_service.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/sync/sync_manager.dart';
import 'auth_provider.dart';

/// Purpose: Offline-First Category State Management Provider
/// Author: Antigravity AI
///
/// Architecture: Local-First Read/Write
/// ─────────────────────────────────────
/// READ:  Always from local SQLite (< 5ms)
/// WRITE: Save to local SQLite → enqueue sync → flush queue if online

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
    _loadFromLocal();
  }

  /// PRIMARY: Load categories from local SQLite (< 5ms)
  Future<void> _loadFromLocal() async {
    state = CategoryState(categories: state.categories, isLoading: true);
    try {
      final rows = await LocalDatabaseService.getLocalCategories();
      final list = rows.map((row) => _mapRowToModel(row)).toList();
      state = CategoryState(categories: list, isLoading: false);
    } catch (e) {
      debugPrint('[CategoryProvider] Local read error: $e');
      state = CategoryState(categories: state.categories, isLoading: false, error: e.toString());
    }
  }

  /// Public method: refresh categories from local DB (called after sync)
  Future<void> fetchCategories({String? type}) async {
    await _loadFromLocal();
  }

  /// OFFLINE-FIRST: Add category to local DB instantly, enqueue sync
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

      // 2. Enqueue sync
      await LocalDatabaseService.enqueueOperation(
        endpoint: ApiEndpoints.categories,
        method: 'POST',
        payload: data,
        customIdempotencyKey: idempotencyKey,
      );

      // 3. Refresh UI from local data
      await _loadFromLocal();

      // 4. Background sync
      SyncManager.syncPendingItems();

      return true;
    } catch (e) {
      debugPrint('[CategoryProvider] addCategory error: $e');
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
