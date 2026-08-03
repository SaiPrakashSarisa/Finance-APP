/// Purpose: Account Data Model
/// Author: Antigravity AI
/// Last Modified: 2026-08-03

class AccountModel {
  final String id;
  final String name;
  final String type;
  final double balance;
  final double initialBalance;
  final String currency;

  AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.initialBalance,
    required this.currency,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'bank',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'INR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'type': type,
      'balance': balance,
      'initialBalance': initialBalance,
      'currency': currency,
    };
  }
}
