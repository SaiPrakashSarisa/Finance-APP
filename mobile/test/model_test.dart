import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app_mobile/data/models/account_model.dart';
import 'package:finance_app_mobile/data/models/transaction_model.dart';
import 'package:finance_app_mobile/data/models/user_model.dart';
import 'package:finance_app_mobile/data/models/credit_model.dart';
import 'package:finance_app_mobile/data/models/budget_model.dart';

void main() {
  group('Data Model Parsing Tests', () {
    test('AccountModel.fromJson parses correctly', () {
      final json = {
        '_id': 'acc_123',
        'name': 'HDFC Salary',
        'type': 'bank',
        'balance': 55000.50,
        'initialBalance': 10000.0,
        'currency': 'INR',
      };
      final account = AccountModel.fromJson(json);

      expect(account.id, equals('acc_123'));
      expect(account.name, equals('HDFC Salary'));
      expect(account.type, equals('bank'));
      expect(account.balance, equals(55000.50));
      expect(account.currency, equals('INR'));
    });

    test('TransactionModel.fromJson parses itemized items', () {
      final json = {
        '_id': 'tx_456',
        'amount': 1061.0,
        'type': 'expense',
        'accountId': {'_id': 'acc_123', 'name': 'HDFC Salary'},
        'categoryId': {'_id': 'cat_789', 'name': 'Groceries'},
        'note': 'D-Mart Monthly Refill',
        'date': '2026-08-01T00:00:00.000Z',
        'isItemized': true,
        'items': [
          {'name': 'Rice', 'quantity': 5.0, 'unit': 'kg', 'unitPrice': 70.0, 'totalPrice': 350.0},
          {'name': 'Milk', 'quantity': 2.0, 'unit': 'L', 'unitPrice': 33.0, 'totalPrice': 66.0},
        ],
      };

      final tx = TransactionModel.fromJson(json);

      expect(tx.id, equals('tx_456'));
      expect(tx.amount, equals(1061.0));
      expect(tx.accountName, equals('HDFC Salary'));
      expect(tx.categoryName, equals('Groceries'));
      expect(tx.isItemized, isTrue);
      expect(tx.items.length, equals(2));
      expect(tx.items[0].name, equals('Rice'));
      expect(tx.items[0].totalPrice, equals(350.0));
    });

    test('UserModel.fromJson parses user profile & settings', () {
      final json = {
        '_id': 'usr_999',
        'name': 'Demo User',
        'email': 'demo@financeapp.com',
        'settings': {'dashboardRange': '3m', 'budgetEnabled': true},
      };

      final user = UserModel.fromJson(json);

      expect(user.id, equals('usr_999'));
      expect(user.name, equals('Demo User'));
      expect(user.email, equals('demo@financeapp.com'));
      expect(user.settings.dashboardRange, equals('3m'));
    });

    test('CreditModel.fromJson parses debt records', () {
      final json = {
        '_id': 'c_111',
        'type': 'given',
        'personName': 'Rahul Sharma',
        'amount': 15000.0,
        'remainingAmount': 15000.0,
        'interestRate': 0.0,
        'status': 'active',
        'notes': 'Emergency loan',
      };

      final credit = CreditModel.fromJson(json);

      expect(credit.id, equals('c_111'));
      expect(credit.personName, equals('Rahul Sharma'));
      expect(credit.type, equals('given'));
      expect(credit.remainingAmount, equals(15000.0));
    });

    test('BudgetSummaryModel.fromJson parses overall budget progress', () {
      final json = {
        'totalBudgeted': 20000.0,
        'totalSpent': 12000.0,
        'overallPercentage': 60.0,
        'categories': [
          {
            'categoryId': 'cat_1',
            'categoryName': 'Food & Dining',
            'categoryColor': '#f43f5e',
            'categoryIcon': '🍕',
            'budgetAmount': 10000.0,
            'spent': 6000.0,
            'remaining': 4000.0,
            'percentage': 60.0,
          }
        ],
      };

      final summary = BudgetSummaryModel.fromJson(json);

      expect(summary.totalBudgeted, equals(20000.0));
      expect(summary.totalSpent, equals(12000.0));
      expect(summary.categories.length, equals(1));
      expect(summary.categories[0].categoryName, equals('Food & Dining'));
    });
  });
}
