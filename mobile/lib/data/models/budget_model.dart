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
    return CategoryBudgetSummaryModel(
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      categoryColor: json['categoryColor'] ?? '#6366f1',
      categoryIcon: json['categoryIcon'] ?? '📁',
      budgetId: json['budgetId'],
      budgetAmount: (json['budgetAmount'] as num?)?.toDouble() ?? 0.0,
      spent: (json['spent'] as num?)?.toDouble() ?? 0.0,
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
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

  factory BudgetSummaryModel.fromJson(Map<String, dynamic> json) {
    final catList = (json['categories'] as List<dynamic>?)
            ?.map((c) => CategoryBudgetSummaryModel.fromJson(c))
            .toList() ??
        [];

    return BudgetSummaryModel(
      totalBudgeted: (json['totalBudgeted'] as num?)?.toDouble() ?? 0.0,
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0.0,
      overallPercentage: (json['overallPercentage'] as num?)?.toDouble() ?? 0.0,
      categories: catList,
    );
  }
}
