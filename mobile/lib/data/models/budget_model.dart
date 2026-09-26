/// Purpose: Category Monthly Budget Data Model
/// Author: Antigravity AI

class CategoryBudgetSummaryModel {
  final String categoryId;
  final String categoryName;
  final String categoryColor;
  final String categoryIcon;
  final String? budgetId;
  final double budgetAmount;
  final double spent;
  final double remaining;
  final double percentage;

  CategoryBudgetSummaryModel({
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
    this.budgetId,
    required this.budgetAmount,
    required this.spent,
    required this.remaining,
    required this.percentage,
  });

  factory CategoryBudgetSummaryModel.fromJson(Map<String, dynamic> json) {
    // Backend populates 'category': { _id, name, color, icon }
    final categoryObj = json['category'];
    String catId = '';
    String catName = '';
    String catColor = '#6366f1';
    String catIcon = 'folder';

    if (categoryObj is Map<String, dynamic>) {
      catId = categoryObj['_id']?.toString() ?? '';
      catName = categoryObj['name']?.toString() ?? '';
      catColor = categoryObj['color']?.toString() ?? '#6366f1';
      catIcon = categoryObj['icon']?.toString() ?? 'folder';
    } else if (categoryObj is String) {
      catId = categoryObj;
    }

    if (catId.isEmpty) {
      catId = json['categoryId']?.toString() ?? '';
    }
    if (catName.isEmpty) {
      catName = json['categoryName']?.toString() ?? '';
    }
    if (json['categoryColor'] != null) {
      catColor = json['categoryColor'].toString();
    }
    if (json['categoryIcon'] != null) {
      catIcon = json['categoryIcon'].toString();
    }

    final amt = (json['amount'] ?? json['budgetAmount'] as num?)?.toDouble() ?? 0.0;
    final sp = (json['spent'] as num?)?.toDouble() ?? 0.0;
    final rem = (json['remaining'] as num?)?.toDouble() ?? (amt - sp);
    final pct = (json['percentage'] as num?)?.toDouble() ?? (amt > 0 ? (sp / amt) * 100 : 0.0);

    return CategoryBudgetSummaryModel(
      categoryId: catId,
      categoryName: catName,
      categoryColor: catColor,
      categoryIcon: catIcon,
      budgetId: json['_id']?.toString() ?? json['budgetId']?.toString(),
      budgetAmount: amt,
      spent: sp,
      remaining: rem,
      percentage: pct,
    );
  }
}

class BudgetSummaryModel {
  final double totalBudgeted;
  final double totalSpent;
  final double overallPercentage;
  final List<CategoryBudgetSummaryModel> categories;

  BudgetSummaryModel({
    required this.totalBudgeted,
    required this.totalSpent,
    required this.overallPercentage,
    required this.categories,
  });

  factory BudgetSummaryModel.fromJson(dynamic data) {
    if (data is List) {
      // Backend returns a List of populated budget items
      final catList = data
          .whereType<Map<String, dynamic>>()
          .map((c) => CategoryBudgetSummaryModel.fromJson(c))
          .toList();

      final totalBud = catList.fold<double>(0.0, (sum, c) => sum + c.budgetAmount);
      final totalSp = catList.fold<double>(0.0, (sum, c) => sum + c.spent);
      final overallPct = totalBud > 0 ? (totalSp / totalBud) * 100 : 0.0;

      return BudgetSummaryModel(
        totalBudgeted: totalBud,
        totalSpent: totalSp,
        overallPercentage: overallPct,
        categories: catList,
      );
    } else if (data is Map<String, dynamic>) {
      final catList = (data['categories'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map((c) => CategoryBudgetSummaryModel.fromJson(c))
              .toList() ??
          [];

      final totalBud = (data['totalBudgeted'] as num?)?.toDouble() ??
          catList.fold<double>(0.0, (sum, c) => sum + c.budgetAmount);
      final totalSp = (data['totalSpent'] as num?)?.toDouble() ??
          catList.fold<double>(0.0, (sum, c) => sum + c.spent);
      final overallPct = (data['overallPercentage'] as num?)?.toDouble() ??
          (totalBud > 0 ? (totalSp / totalBud) * 100 : 0.0);

      return BudgetSummaryModel(
        totalBudgeted: totalBud,
        totalSpent: totalSp,
        overallPercentage: overallPct,
        categories: catList,
      );
    }

    return BudgetSummaryModel(
      totalBudgeted: 0.0,
      totalSpent: 0.0,
      overallPercentage: 0.0,
      categories: [],
    );
  }
}
