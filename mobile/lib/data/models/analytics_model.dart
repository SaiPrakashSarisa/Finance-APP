/// Purpose: Analytics & Financial Insights Data Models
/// Author: Antigravity AI

class DashboardSummaryModel {
  final double income;
  final double expense;
  final double netSavings;
  final double totalReceivables;
  final double totalLiabilities;
  final double netWorth;
  final List<dynamic> accounts;

  DashboardSummaryModel({
    required this.income,
    required this.expense,
    required this.netSavings,
    required this.totalReceivables,
    required this.totalLiabilities,
    required this.netWorth,
    required this.accounts,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      income: (json['income'] as num?)?.toDouble() ?? 0.0,
      expense: (json['expense'] as num?)?.toDouble() ?? 0.0,
      netSavings: (json['netSavings'] as num?)?.toDouble() ?? 0.0,
      totalReceivables: (json['totalReceivables'] as num?)?.toDouble() ?? 0.0,
      totalLiabilities: (json['totalLiabilities'] as num?)?.toDouble() ?? 0.0,
      netWorth: (json['netWorth'] as num?)?.toDouble() ?? 0.0,
      accounts: json['accounts'] as List<dynamic>? ?? [],
    );
  }
}

class InsightsModel {
  final double savingsRate;
  final double avgDailyExpense;
  final int burnRate;
  final double emergencyFundMonths;
  final double creditExposureRatio;
  final String highestCategoryName;
  final double highestCategoryTotal;
  final double income;
  final double expense;
  final double totalBalance;
  final double totalReceivables;
  final double totalLiabilities;

  InsightsModel({
    required this.savingsRate,
    required this.avgDailyExpense,
    required this.burnRate,
    required this.emergencyFundMonths,
    required this.creditExposureRatio,
    required this.highestCategoryName,
    required this.highestCategoryTotal,
    required this.income,
    required this.expense,
    required this.totalBalance,
    required this.totalReceivables,
    required this.totalLiabilities,
  });

  factory InsightsModel.fromJson(Map<String, dynamic> json) {
    final highest = json['highestSpendingCategory'];
    String catName = 'N/A';
    double catTotal = 0.0;
    if (highest is Map) {
      catName = highest['name'] ?? 'N/A';
      catTotal = (highest['total'] as num?)?.toDouble() ?? 0.0;
    }

    return InsightsModel(
      savingsRate: (json['savingsRate'] as num?)?.toDouble() ?? 0.0,
      avgDailyExpense: (json['avgDailyExpense'] as num?)?.toDouble() ?? 0.0,
      burnRate: (json['burnRate'] as num?)?.toInt() ?? 0,
      emergencyFundMonths: (json['emergencyFundMonths'] as num?)?.toDouble() ?? 0.0,
      creditExposureRatio: (json['creditExposureRatio'] as num?)?.toDouble() ?? 0.0,
      highestCategoryName: catName,
      highestCategoryTotal: catTotal,
      income: (json['income'] as num?)?.toDouble() ?? 0.0,
      expense: (json['expense'] as num?)?.toDouble() ?? 0.0,
      totalBalance: (json['totalBalance'] as num?)?.toDouble() ?? 0.0,
      totalReceivables: (json['totalReceivables'] as num?)?.toDouble() ?? 0.0,
      totalLiabilities: (json['totalLiabilities'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SubcategoryBreakdownModel {
  final String categoryId;
  final String name;
  final String color;
  final String icon;
  final double total;

  SubcategoryBreakdownModel({
    required this.categoryId,
    required this.name,
    required this.color,
    required this.icon,
    required this.total,
  });

  factory SubcategoryBreakdownModel.fromJson(Map<String, dynamic> json) {
    return SubcategoryBreakdownModel(
      categoryId: json['categoryId'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      color: json['color'] ?? '#94a3b8',
      icon: json['icon'] ?? 'folder',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CategoryBreakdownModel {
  final String categoryId;
  final String name;
  final String color;
  final String icon;
  final double total;
  final List<SubcategoryBreakdownModel> subcategories;

  CategoryBreakdownModel({
    required this.categoryId,
    required this.name,
    required this.color,
    required this.icon,
    required this.total,
    this.subcategories = const [],
  });

  factory CategoryBreakdownModel.fromJson(Map<String, dynamic> json) {
    final subList = (json['subcategories'] as List<dynamic>?)
            ?.map((s) => SubcategoryBreakdownModel.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];

    return CategoryBreakdownModel(
      categoryId: json['_id'] ?? json['categoryId'] ?? '',
      name: json['name'] ?? '',
      color: json['color'] ?? '#6366f1',
      icon: json['icon'] ?? 'folder',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      subcategories: subList,
    );
  }
}

class MonthlyTrendModel {
  final int month;
  final int year;
  final String type;
  final double total;

  MonthlyTrendModel({
    required this.month,
    required this.year,
    required this.type,
    required this.total,
  });

  factory MonthlyTrendModel.fromJson(Map<String, dynamic> json) {
    int m = 1;
    int y = 2026;
    String t = 'expense';

    if (json['_id'] is Map) {
      m = json['_id']['month'] ?? 1;
      y = json['_id']['year'] ?? 2026;
      t = json['_id']['type'] ?? 'expense';
    }

    return MonthlyTrendModel(
      month: m,
      year: y,
      type: t,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ItemInflationModel {
  final String itemName;
  final double firstUnitPrice;
  final double lastUnitPrice;
  final double priceChange;
  final double percentageChange;

  ItemInflationModel({
    required this.itemName,
    required this.firstUnitPrice,
    required this.lastUnitPrice,
    required this.priceChange,
    required this.percentageChange,
  });

  factory ItemInflationModel.fromJson(Map<String, dynamic> json) {
    return ItemInflationModel(
      itemName: json['name'] ?? json['_id'] ?? json['itemName'] ?? '',
      firstUnitPrice: (json['firstPrice'] as num?)?.toDouble() ?? (json['firstUnitPrice'] as num?)?.toDouble() ?? 0.0,
      lastUnitPrice: (json['lastPrice'] as num?)?.toDouble() ?? (json['lastUnitPrice'] as num?)?.toDouble() ?? 0.0,
      priceChange: (json['priceDiff'] as num?)?.toDouble() ?? (json['priceChange'] as num?)?.toDouble() ?? 0.0,
      percentageChange: (json['inflationPercent'] as num?)?.toDouble() ?? (json['percentageChange'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SubscriptionModel {
  final String merchantName;
  final double amount;
  final String frequency;

  SubscriptionModel({
    required this.merchantName,
    required this.amount,
    required this.frequency,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      merchantName: json['merchantName'] ?? json['name'] ?? json['_id'] ?? 'Subscription',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      frequency: json['frequency'] ?? 'Monthly',
    );
  }
}
