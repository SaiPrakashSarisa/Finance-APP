/// Purpose: Transaction & Receipt Item Data Models
/// Author: Antigravity AI

class TransactionItemModel {
  final String name;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double totalPrice;

  TransactionItemModel({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory TransactionItemModel.fromJson(Map<String, dynamic> json) {
    return TransactionItemModel(
      name: json['name'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit'] ?? 'unit',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }
}

class TransactionModel {
  final String id;
  final double amount;
  final String type;
  final String? accountId;
  final String? accountName;
  final String? categoryId;
  final String? categoryName;
  final String? parentCategoryName;
  final String? subCategoryName;
  final String? creditId;
  final String? note;
  final String date;
  final bool isItemized;
  final List<TransactionItemModel> items;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    this.accountId,
    this.accountName,
    this.categoryId,
    this.categoryName,
    this.parentCategoryName,
    this.subCategoryName,
    this.creditId,
    this.note,
    required this.date,
    required this.isItemized,
    required this.items,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    String? accName;
    if (json['accountId'] is Map) {
      accName = json['accountId']['name'];
    }

    String? catName;
    String? pCatName;
    String? sCatName;
    if (json['categoryId'] is Map) {
      final cObj = json['categoryId'];
      catName = cObj['name'];
      if (cObj['parentCategoryId'] is Map) {
        pCatName = cObj['parentCategoryId']['name'];
        sCatName = cObj['name'];
      } else {
        pCatName = cObj['name'];
      }
    }

    String? cId;
    if (json['creditId'] is Map) {
      cId = json['creditId']['_id'];
    } else if (json['creditId'] != null) {
      cId = json['creditId'].toString();
    }

    final itemList = (json['items'] as List<dynamic>?)
            ?.map((i) => TransactionItemModel.fromJson(i))
            .toList() ??
        [];

    return TransactionModel(
      id: json['_id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] ?? 'expense',
      accountId: json['accountId'] is Map ? json['accountId']['_id'] : json['accountId'],
      accountName: accName,
      categoryId: json['categoryId'] is Map ? json['categoryId']['_id'] : json['categoryId'],
      categoryName: catName,
      parentCategoryName: pCatName,
      subCategoryName: sCatName,
      creditId: cId,
      note: json['note'] ?? json['notes'],
      date: json['date'] ?? '',
      isItemized: json['isItemized'] ?? false,
      items: itemList,
    );
  }
}
