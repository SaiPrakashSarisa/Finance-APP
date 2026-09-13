import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';
import 'auth_provider.dart';
import 'account_provider.dart';
import 'analytics_provider.dart';

/// Purpose: Transaction State Management Provider
/// Author: Antigravity AI

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(apiClientProvider));
});

class TransactionState {
  final List<TransactionModel> transactions;
  final bool isLoading;
  final String activeType;
  final String? accountId;
  final String? categoryId;
  final String? searchQuery;
  final String? error;

  TransactionState({
    required this.transactions,
    required this.isLoading,
    this.activeType = 'all',
    this.accountId,
    this.categoryId,
    this.searchQuery,
    this.error,
  });

  TransactionState copyWith({
    List<TransactionModel>? transactions,
    bool? isLoading,
    String? activeType,
    String? accountId,
    String? categoryId,
    String? searchQuery,
    String? error,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      activeType: activeType ?? this.activeType,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      error: error,
    );
  }
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  final TransactionRepository repository;
  final Ref ref;

  TransactionNotifier(this.repository, this.ref)
      : super(TransactionState(transactions: [], isLoading: true)) {
    fetchTransactions();
  }

  Future<void> fetchTransactions({
    String? type,
    String? accountId,
    String? categoryId,
    String? search,
  }) async {
    final curType = type ?? state.activeType;
    final curAcc = accountId ?? state.accountId;
    final curCat = categoryId ?? state.categoryId;
    final curSearch = search ?? state.searchQuery;

    state = state.copyWith(
      isLoading: true,
      activeType: curType,
      accountId: curAcc,
      categoryId: curCat,
      searchQuery: curSearch,
    );

    try {
      final filters = <String, dynamic>{};
      if (curType != 'all' && curType.isNotEmpty) filters['type'] = curType;
      if (curAcc != null && curAcc.isNotEmpty) filters['accountId'] = curAcc;
      if (curCat != null && curCat.isNotEmpty) filters['categoryId'] = curCat;

      final list = await repository.getTransactions(filters: filters);
      
      // Client-side search filtering by note or merchant or item name
      List<TransactionModel> filtered = list;
      if (curSearch != null && curSearch.trim().isNotEmpty) {
        final query = curSearch.trim().toLowerCase();
        filtered = list.where((t) {
          final noteMatch = t.note?.toLowerCase().contains(query) ?? false;
          final catMatch = t.categoryName?.toLowerCase().contains(query) ?? false;
          final itemMatch = t.items.any((i) => i.name.toLowerCase().contains(query));
          return noteMatch || catMatch || itemMatch;
        }).toList();
      }

      state = state.copyWith(transactions: filtered, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addTransaction(Map<String, dynamic> data) async {
    try {
      final tx = await repository.createTransaction(data);
      if (tx != null) {
        await fetchTransactions();
        ref.read(accountProvider.notifier).fetchAccounts();
        ref.read(analyticsProvider.notifier).fetchAll();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> updateTransaction(String id, Map<String, dynamic> data) async {
    try {
      final tx = await repository.updateTransaction(id, data);
      if (tx != null) {
        await fetchTransactions();
        ref.read(accountProvider.notifier).fetchAccounts();
        ref.read(analyticsProvider.notifier).fetchAll();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteTransaction(String id) async {
    try {
      final ok = await repository.deleteTransaction(id);
      if (ok) {
        await fetchTransactions();
        ref.read(accountProvider.notifier).fetchAccounts();
        ref.read(analyticsProvider.notifier).fetchAll();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<String?> exportCsv() async {
    return await repository.exportCsv();
  }

  Future<bool> importCsv(String csvText, {String mode = 'replace'}) async {
    final res = await repository.importCsv(csvText, mode: mode);
    if (res != null && res['success'] == true) {
      await fetchTransactions();
      ref.read(accountProvider.notifier).fetchAccounts();
      ref.read(analyticsProvider.notifier).fetchAll();
      return true;
    }
    return false;
  }
}

final transactionProvider = StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  return TransactionNotifier(ref.watch(transactionRepositoryProvider), ref);
});
