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
  final String? toAccountId;
  final String? categoryId;
  final String? categoryName;
  final String? parentCategoryName;
  final String? subCategoryName;
  final String? creditId;
  final String? creditType; // 'given' (receivable) or 'taken' (liability)
  final String? merchantName;
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
    this.toAccountId,
    this.categoryId,
    this.categoryName,
    this.parentCategoryName,
    this.subCategoryName,
    this.creditId,
    this.creditType,
    this.merchantName,
    this.note,
    required this.date,
    required this.isItemized,
    required this.items,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    String? accName;
    if (json['accountId'] is Map) {
      accName = json['accountId']['name'];
    } else if (json['accountName'] != null) {
      accName = json['accountName'];
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
    } else {
      catName = json['categoryName'];
      pCatName = json['parentCategoryName'];
      sCatName = json['subCategoryName'];
    }

    String? cId;
    String? cType;
    if (json['creditId'] is Map) {
      cId = json['creditId']['_id'];
      cType = json['creditId']['type'];
    } else if (json['creditId'] != null) {
      cId = json['creditId'].toString();
    }
    if (cType == null && json['creditType'] != null) {
      cType = json['creditType'].toString();
    }

    String? mName;
    if (json['merchantId'] is Map) {
      mName = json['merchantId']['name'];
    } else if (json['merchantName'] != null) {
      mName = json['merchantName'].toString();
    }

    final itemList = (json['items'] as List<dynamic>?)
            ?.map((i) => TransactionItemModel.fromJson(i))
            .toList() ??
        [];

    return TransactionModel(
      id: json['_id'] ?? json['id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] ?? 'expense',
      accountId: json['accountId'] is Map ? json['accountId']['_id'] : json['accountId'],
      accountName: accName,
      toAccountId: json['toAccountId'] is Map ? json['toAccountId']['_id'] : json['toAccountId'],
      categoryId: json['categoryId'] is Map ? json['categoryId']['_id'] : json['categoryId'],
      categoryName: catName,
      parentCategoryName: pCatName,
      subCategoryName: sCatName,
      creditId: cId,
      creditType: cType,
      merchantName: mName,
      note: json['note'] ?? json['notes'],
      date: json['date'] ?? '',
      isItemized: json['isItemized'] ?? false,
      items: itemList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'accountId': accountId,
      'accountName': accountName,
      'toAccountId': toAccountId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'parentCategoryName': parentCategoryName,
      'subCategoryName': subCategoryName,
      'creditId': creditId,
      'creditType': creditType,
      'merchantName': merchantName,
      'note': note,
      'date': date,
      'isItemized': isItemized,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}
