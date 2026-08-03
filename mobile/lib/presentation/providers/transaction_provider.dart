import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';
import 'auth_provider.dart';

/// Purpose: Transaction State Provider
/// Author: Antigravity AI
/// Last Modified: 2026-08-03

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(apiClientProvider));
});

class TransactionState {
  final List<TransactionModel> transactions;
  final bool isLoading;
  final String activeType;
  final String? error;

  TransactionState({
    required this.transactions,
    required this.isLoading,
    this.activeType = 'all',
    this.error,
  });
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  final TransactionRepository repository;

  TransactionNotifier(this.repository)
      : super(TransactionState(transactions: [], isLoading: true)) {
    fetchTransactions();
  }

  Future<void> fetchTransactions({String type = 'all'}) async {
    state = TransactionState(transactions: state.transactions, isLoading: true, activeType: type);
    try {
      final filters = <String, dynamic>{};
      if (type != 'all') filters['type'] = type;
      final list = await repository.getTransactions(filters: filters);
      state = TransactionState(transactions: list, isLoading: false, activeType: type);
    } catch (e) {
      state = TransactionState(transactions: state.transactions, isLoading: false, activeType: type, error: e.toString());
    }
  }

  Future<bool> addTransaction(Map<String, dynamic> data) async {
    try {
      final tx = await repository.createTransaction(data);
      if (tx != null) {
        await fetchTransactions(type: state.activeType);
        return true;
      }
    } catch (_) {}
    return false;
  }
}

final transactionProvider = StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  return TransactionNotifier(ref.watch(transactionRepositoryProvider));
});
