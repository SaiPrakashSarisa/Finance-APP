import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/category_repository.dart';
import 'auth_provider.dart';

/// Purpose: Category State Management Provider
/// Author: Antigravity AI

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

  Future<void> fetchCategories({String? type}) async {
    state = CategoryState(categories: state.categories, isLoading: true);
    try {
      final list = await repository.getCategories(type: type);
      state = CategoryState(categories: list, isLoading: false);
    } catch (e) {
      state = CategoryState(categories: state.categories, isLoading: false, error: e.toString());
    }
  }

  Future<bool> addCategory(Map<String, dynamic> data) async {
    try {
      final cat = await repository.createCategory(data);
      if (cat != null) {
        await fetchCategories();
        return true;
      }
    } catch (_) {}
    return false;
  }
}

final categoryProvider = StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
  final authState = ref.watch(authProvider);
  final notifier = CategoryNotifier(ref.watch(categoryRepositoryProvider));
  if (authState.isAuthenticated) {
    notifier.fetchCategories();
  }
  return notifier;
});
