/// Purpose: Credit / Debt Tracker Data Model
/// Author: Antigravity AI

class CreditModel {
  final String id;
  final String type; // 'given' or 'taken'
  final String? subType; // 'account_credit', 'emi_loan', or null
  final String personName;
  final double amount;
  final double remainingAmount;
  final double interestRate;
  final String? linkedAccountId;
  final String? linkedAccountName;
  final String status; // 'active', 'settled', 'partial'
  final String? dueDate;
  final String notes;

  CreditModel({
    required this.id,
    required this.type,
    this.subType,
    required this.personName,
    required this.amount,
    required this.remainingAmount,
    required this.interestRate,
    this.linkedAccountId,
    this.linkedAccountName,
    required this.status,
    this.dueDate,
    required this.notes,
  });

  factory CreditModel.fromJson(Map<String, dynamic> json) {
    String? accId;
    String? accName;

    if (json['linkedAccountId'] is Map) {
      accId = json['linkedAccountId']['_id'];
      accName = json['linkedAccountId']['name'];
    } else if (json['linkedAccountId'] != null) {
      accId = json['linkedAccountId'].toString();
    }

    return CreditModel(
      id: json['_id'] ?? '',
      type: json['type'] ?? 'given',
      subType: json['subType'],
      personName: json['personName'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      interestRate: (json['interestRate'] as num?)?.toDouble() ?? 0.0,
      linkedAccountId: accId,
      linkedAccountName: accName,
      status: json['status'] ?? 'active',
      dueDate: json['dueDate'],
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'subType': subType,
      'personName': personName,
      'amount': amount,
      'interestRate': interestRate,
      'linkedAccountId': linkedAccountId,
      'dueDate': dueDate,
      'notes': notes,
    };
  }
}

class CreditTotalsModel {
  final double totalReceivables;
  final double totalLiabilities;

  CreditTotalsModel({
    required this.totalReceivables,
    required this.totalLiabilities,
  });

  factory CreditTotalsModel.fromJson(Map<String, dynamic> json) {
    return CreditTotalsModel(
      totalReceivables: (json['totalReceivables'] as num?)?.toDouble() ?? 0.0,
      totalLiabilities: (json['totalLiabilities'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
