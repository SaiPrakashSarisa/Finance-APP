import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/api_endpoints.dart';
import '../../data/local/local_database_service.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/sync/sync_manager.dart';
import 'auth_provider.dart';
import 'account_provider.dart';
import 'credit_provider.dart';
import 'analytics_provider.dart';
import 'budget_provider.dart';

/// Purpose: Offline-First Transaction State Management Provider
/// Author: Antigravity AI
///
/// Architecture: Local-First Read/Write
/// ─────────────────────────────────────
/// READ:  Always from local SQLite (< 5ms)
/// WRITE: Save to local SQLite → enqueue sync → flush queue if online
/// UI:    Updates instantly without waiting for network

const _uuid = Uuid();

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
    _loadFromLocal();
  }

  /// PRIMARY: Load transactions from local SQLite database (< 5ms)
  Future<void> _loadFromLocal({
    String? type,
    String? accountId,
    String? categoryId,
    String? search,
  }) async {
    final curType = type ?? state.activeType;
    final curAcc = accountId ?? state.accountId;
    final curCat = categoryId ?? state.categoryId;
    final curSearch = search ?? state.searchQuery;

    if (state.transactions.isEmpty) {
      state = state.copyWith(
        isLoading: true,
        activeType: curType,
        accountId: curAcc,
        categoryId: curCat,
        searchQuery: curSearch,
      );
    } else {
      state = state.copyWith(
        activeType: curType,
        accountId: curAcc,
        categoryId: curCat,
        searchQuery: curSearch,
      );
    }

    try {
      final rows = await LocalDatabaseService.getLocalTransactions(
        type: curType != 'all' ? curType : null,
        accountId: curAcc,
        categoryId: curCat,
      );

      final list = rows.map((row) => _mapRowToModel(row)).toList();

      // Client-side search filtering by note or category name
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
      debugPrint('[TransactionProvider] Local read error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Public method: refresh transactions from local DB and downstream sync with backend
  Future<void> fetchTransactions({
    String? type,
    String? accountId,
    String? categoryId,
    String? search,
  }) async {
    // 1. Instant local render (< 5ms)
    await _loadFromLocal(
      type: type,
      accountId: accountId,
      categoryId: categoryId,
      search: search,
    );

    // 2. Downstream sync: fetch active records & tombstones from server
    try {
      final filters = <String, dynamic>{
        'limit': 200,
        if (type != null && type != 'all') 'type': type,
        if (accountId != null) 'accountId': accountId,
        if (categoryId != null) 'categoryId': categoryId,
      };

      final remote = await repository.fetchRemoteTransactions(filters: filters);

      bool changed = false;

      // Purge soft-deleted tombstones locally
      if (remote.deletedIds.isNotEmpty) {
        await LocalDatabaseService.deleteLocalTransactions(remote.deletedIds);
        changed = true;
      }

      // Upsert server records into SQLite
      if (remote.transactions.isNotEmpty) {
        await LocalDatabaseService.saveLocalTransactions(
          remote.transactions.map((t) => t.toJson()).toList(),
        );
        changed = true;
      }

      // 3. If records were modified or deleted, update UI state
      if (changed) {
        await _loadFromLocal(
          type: type,
          accountId: accountId,
          categoryId: categoryId,
          search: search,
        );
      }
    } catch (e) {
      debugPrint('[TransactionProvider] Remote sync error: $e');
    }
  }

  /// DIRECT-FIRST + SYNC QUEUE FALLBACK: Add transaction with instant optimistic UI
  Future<bool> addTransaction(Map<String, dynamic> data) async {
    try {
      final txId = _uuid.v4();
      final idempotencyKey = _uuid.v4();

      final amount = (data['amount'] as num).toDouble();
      final txType = data['type'] as String;

      // Determine creditType if this is a credit repayment
      String? creditType = data['creditType'] as String?;
      if (txType == 'credit_repay' && data['creditId'] != null) {
        final creditId = data['creditId'] as String;
        final matchingCredit = ref.read(creditProvider).credits.firstWhereOrNull((c) => c.id == creditId);
        creditType ??= matchingCredit?.type ?? 'taken';
      }

      // Validate sufficient account balance for non-credit-card debits
      final isDeduction = txType == 'expense' || txType == 'transfer' || (txType == 'credit_repay' && creditType == 'taken');
      if (isDeduction && data['accountId'] != null) {
        final accounts = ref.read(accountProvider).accounts;
        final acc = accounts.firstWhereOrNull((a) => a.id == data['accountId']);
        if (acc != null && acc.type != 'credit_card' && acc.balance < amount) {
          state = state.copyWith(
            isLoading: false,
            error: 'Insufficient funds in "${acc.name}". Available balance: ₹${acc.balance.toStringAsFixed(2)}',
          );
          return false;
        }
      }

      // 1. Save to local SQLite instantly (< 5ms)
      final localTx = {
        'id': txId,
        'idempotencyKey': idempotencyKey,
        ...data,
        if (creditType != null) 'creditType': creditType,
        'date': data['date'] ?? DateTime.now().toIso8601String(),
      };
      await LocalDatabaseService.saveLocalTransaction(localTx, isSynced: false);

      // 2. Update local account balances optimistically matching backend operations
      if (txType == 'income') {
        if (data['accountId'] != null) {
          await LocalDatabaseService.updateLocalAccountBalance(data['accountId'] as String, amount);
        }
      } else if (txType == 'expense') {
        if (data['accountId'] != null) {
          await LocalDatabaseService.updateLocalAccountBalance(data['accountId'] as String, -amount);
        }
      } else if (txType == 'transfer') {
        if (data['accountId'] != null) {
          await LocalDatabaseService.updateLocalAccountBalance(data['accountId'] as String, -amount);
        }
        if (data['toAccountId'] != null) {
          await LocalDatabaseService.updateLocalAccountBalance(data['toAccountId'] as String, amount);
        }
      } else if (txType == 'credit_repay') {
        // If credit is 'given' (receivable repaid to us), cash inflow (+amount)
        // If credit is 'taken' (debt we repaid), cash outflow (-amount)
        final isReceivable = creditType == 'given';
        final balanceDelta = isReceivable ? amount : -amount;
        if (data['accountId'] != null) {
          await LocalDatabaseService.updateLocalAccountBalance(data['accountId'] as String, balanceDelta);
        }
        if (data['creditId'] != null) {
          ref.read(creditProvider.notifier).recordRepaymentOptimistic(data['creditId'] as String, amount);
        }
      }

      // 3. Refresh UI immediately from local data (<5ms!)
      await _loadFromLocal();
      await ref.read(accountProvider.notifier).loadFromLocal();
      ref.read(analyticsProvider.notifier).fetchAll();
      ref.read(budgetProvider.notifier).fetchSummary();

      // 4. Background direct API call / queue fallback (Optimistic UI - does NOT block user!)
      unawaited(() async {
        try {
          final payloadWithCreditType = {
            ...data,
            if (creditType != null) 'creditType': creditType,
          };
          final response = await SyncManager.executeDirectWithQueueFallback(
            endpoint: ApiEndpoints.transactions,
            method: 'POST',
            payload: payloadWithCreditType,
            customIdempotencyKey: idempotencyKey,
          );

          if (response != null && response.statusCode != null && response.statusCode! < 400) {
            final respData = response.data;
            final serverTx = (respData is Map && respData['data'] is Map)
                ? respData['data'] as Map<String, dynamic>
                : (respData is Map && respData['transaction'] is Map)
                    ? respData['transaction'] as Map<String, dynamic>
                    : null;

            if (serverTx != null && serverTx['_id'] != null) {
              await LocalDatabaseService.deleteLocalTransaction(txId);
              await LocalDatabaseService.saveLocalTransaction(serverTx, isSynced: true);
              await _loadFromLocal();
            }
          }
          ref.read(accountProvider.notifier).fetchAccounts();
          ref.read(creditProvider.notifier).fetchCredits();
          ref.read(analyticsProvider.notifier).fetchAll();
          ref.read(budgetProvider.notifier).fetchSummary();
        } catch (e) {
          debugPrint('[TransactionProvider] Background sync error: $e');
        }
      }());

      return true;
    } catch (e) {
      debugPrint('[TransactionProvider] addTransaction error: $e');
      return false;
    }
  }

  /// DIRECT-FIRST + SYNC QUEUE FALLBACK: Update transaction
  Future<bool> updateTransaction(String id, Map<String, dynamic> data) async {
    try {
      final idempotencyKey = _uuid.v4();

      // 1. Update local SQLite instantly
      final localTx = {
        'id': id,
        'idempotencyKey': idempotencyKey,
        ...data,
      };
      await LocalDatabaseService.saveLocalTransaction(localTx, isSynced: false);

      // 2. Refresh UI immediately
      await _loadFromLocal();
      await ref.read(accountProvider.notifier).loadFromLocal();
      ref.read(analyticsProvider.notifier).fetchAll();
      ref.read(budgetProvider.notifier).fetchSummary();

      // 3. Direct API Call in background with fallback to sync_queue
      unawaited(() async {
        try {
          final response = await SyncManager.executeDirectWithQueueFallback(
            endpoint: '${ApiEndpoints.transactions}/$id',
            method: 'PUT',
            payload: data,
            customIdempotencyKey: idempotencyKey,
          );
          if (response != null && response.statusCode != null && response.statusCode! < 400) {
            await LocalDatabaseService.saveLocalTransaction(localTx, isSynced: true);
          }
          ref.read(accountProvider.notifier).fetchAccounts();
          ref.read(creditProvider.notifier).fetchCredits();
          ref.read(analyticsProvider.notifier).fetchAll();
          ref.read(budgetProvider.notifier).fetchSummary();
        } catch (e) {
          debugPrint('[TransactionProvider] Update background sync error: $e');
        }
      }());

      return true;
    } catch (e) {
      debugPrint('[TransactionProvider] updateTransaction error: $e');
      return false;
    }
  }

  /// DIRECT-FIRST + SYNC QUEUE FALLBACK: Delete transaction
  Future<bool> deleteTransaction(String id) async {
    try {
      final idempotencyKey = _uuid.v4();

      // Revert balance effect locally on SQLite
      final existingTx = state.transactions.firstWhereOrNull((t) => t.id == id);
      if (existingTx != null) {
        final amount = existingTx.amount;
        if (existingTx.type == 'income') {
          if (existingTx.accountId != null) {
            await LocalDatabaseService.updateLocalAccountBalance(existingTx.accountId!, -amount);
          }
        } else if (existingTx.type == 'expense') {
          if (existingTx.accountId != null) {
            await LocalDatabaseService.updateLocalAccountBalance(existingTx.accountId!, amount);
          }
        } else if (existingTx.type == 'transfer') {
          if (existingTx.accountId != null) {
            await LocalDatabaseService.updateLocalAccountBalance(existingTx.accountId!, amount);
          }
          if (existingTx.toAccountId != null) {
            await LocalDatabaseService.updateLocalAccountBalance(existingTx.toAccountId!, -amount);
          }
        } else if (existingTx.type == 'credit_repay') {
          final isReceivable = existingTx.creditType == 'given';
          final balanceDelta = isReceivable ? -amount : amount;
          if (existingTx.accountId != null) {
            await LocalDatabaseService.updateLocalAccountBalance(existingTx.accountId!, balanceDelta);
          }
          if (existingTx.creditId != null) {
            ref.read(creditProvider.notifier).recordRepaymentOptimistic(existingTx.creditId!, -amount);
          }
        }
      }

      // 1. Delete from local SQLite instantly
      await LocalDatabaseService.deleteLocalTransaction(id);

      // 2. Refresh UI immediately from local
      await _loadFromLocal();
      await ref.read(accountProvider.notifier).loadFromLocal();
      ref.read(analyticsProvider.notifier).fetchAll();
      ref.read(budgetProvider.notifier).fetchSummary();

      // 3. Direct API Call First with fallback to sync_queue in background
      unawaited(() async {
        try {
          await SyncManager.executeDirectWithQueueFallback(
            endpoint: '${ApiEndpoints.transactions}/$id',
            method: 'DELETE',
            payload: {},
            customIdempotencyKey: idempotencyKey,
          );
          ref.read(accountProvider.notifier).fetchAccounts();
          ref.read(creditProvider.notifier).fetchCredits();
          ref.read(analyticsProvider.notifier).fetchAll();
          ref.read(budgetProvider.notifier).fetchSummary();
        } catch (e) {
          debugPrint('[TransactionProvider] Delete background sync error: $e');
        }
      }());

      return true;
    } catch (e) {
      debugPrint('[TransactionProvider] deleteTransaction error: $e');
      return false;
    }
  }

  /// CSV export still hits the backend directly (needs server-side processing)
  Future<String?> exportCsv() async {
    return await repository.exportCsv();
  }

  /// CSV import: push to server, then full sync to update local DB
  Future<bool> importCsv(String csvText, {String mode = 'replace'}) async {
    final res = await repository.importCsv(csvText, mode: mode);
    if (res != null && res['success'] == true) {
      // After server-side import, do a full sync to get updated data
      await SyncManager.fullSync();
      await _loadFromLocal();
      ref.read(accountProvider.notifier).fetchAccounts();
      ref.read(analyticsProvider.notifier).fetchAll();
      return true;
    }
    return false;
  }

  /// Convert SQLite row to TransactionModel
  TransactionModel _mapRowToModel(Map<String, dynamic> row) {
    List<TransactionItemModel> items = [];
    if (row['items'] != null && (row['items'] as String).isNotEmpty) {
      try {
        final parsed = jsonDecode(row['items'] as String) as List;
        items = parsed.map((i) => TransactionItemModel.fromJson(i)).toList();
      } catch (_) {}
    }

    return TransactionModel(
      id: row['id'] as String,
      amount: (row['amount'] as num?)?.toDouble() ?? 0.0,
      type: row['type'] as String? ?? 'expense',
      accountId: row['accountId'] as String?,
      accountName: row['accountName'] as String?,
      toAccountId: row['toAccountId'] as String?,
      categoryId: row['categoryId'] as String?,
      categoryName: row['categoryName'] as String?,
      parentCategoryName: row['parentCategoryName'] as String?,
      subCategoryName: row['subCategoryName'] as String?,
      creditId: row['creditId'] as String?,
      creditType: row['creditType'] as String?,
      merchantName: row['merchantName'] as String?,
      note: row['note'] as String?,
      date: row['date'] as String? ?? '',
      isItemized: (row['isItemized'] as int?) == 1,
      items: items,
    );
  }
}

final transactionProvider = StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  return TransactionNotifier(ref.watch(transactionRepositoryProvider), ref);
});
