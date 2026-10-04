import 'dart:convert';
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
import 'analytics_provider.dart';

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

    state = state.copyWith(
      isLoading: true,
      activeType: curType,
      accountId: curAcc,
      categoryId: curCat,
      searchQuery: curSearch,
    );

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

  /// Public method: refresh transactions from local DB (called after sync)
  Future<void> fetchTransactions({
    String? type,
    String? accountId,
    String? categoryId,
    String? search,
  }) async {
    await _loadFromLocal(
      type: type,
      accountId: accountId,
      categoryId: categoryId,
      search: search,
    );
  }

  /// OFFLINE-FIRST: Add transaction to local DB instantly, enqueue sync
  Future<bool> addTransaction(Map<String, dynamic> data) async {
    try {
      final txId = _uuid.v4();
      final idempotencyKey = _uuid.v4();

      // 1. Save to local SQLite instantly (< 5ms)
      final localTx = {
        'id': txId,
        'idempotencyKey': idempotencyKey,
        ...data,
        'date': data['date'] ?? DateTime.now().toIso8601String(),
      };
      await LocalDatabaseService.saveLocalTransaction(localTx, isSynced: false);

      // 2. Update local account balance optimistically
      final amount = (data['amount'] as num).toDouble();
      final txType = data['type'] as String;
      if (data['accountId'] != null) {
        final balanceDelta = txType == 'income' ? amount : -amount;
        await LocalDatabaseService.updateLocalAccountBalance(
          data['accountId'] as String,
          balanceDelta,
        );
      }

      // 3. Enqueue sync operation for background push to server
      await LocalDatabaseService.enqueueOperation(
        endpoint: ApiEndpoints.transactions,
        method: 'POST',
        payload: data,
        customIdempotencyKey: idempotencyKey,
      );

      // 4. Refresh UI immediately from local data
      await _loadFromLocal();
      ref.read(accountProvider.notifier).fetchAccounts();

      // 5. Non-blocking: Flush sync queue in background
      SyncManager.syncPendingItems();

      return true;
    } catch (e) {
      debugPrint('[TransactionProvider] addTransaction error: $e');
      return false;
    }
  }

  /// OFFLINE-FIRST: Update transaction in local DB, enqueue sync
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

      // 2. Enqueue sync
      await LocalDatabaseService.enqueueOperation(
        endpoint: '${ApiEndpoints.transactions}/$id',
        method: 'PUT',
        payload: data,
        customIdempotencyKey: idempotencyKey,
      );

      // 3. Refresh UI
      await _loadFromLocal();
      ref.read(accountProvider.notifier).fetchAccounts();

      // 4. Background sync
      SyncManager.syncPendingItems();

      return true;
    } catch (e) {
      debugPrint('[TransactionProvider] updateTransaction error: $e');
      return false;
    }
  }

  /// OFFLINE-FIRST: Delete transaction from local DB, enqueue sync
  Future<bool> deleteTransaction(String id) async {
    try {
      final idempotencyKey = _uuid.v4();

      // 1. Delete from local SQLite instantly
      await LocalDatabaseService.deleteLocalTransaction(id);

      // 2. Enqueue sync
      await LocalDatabaseService.enqueueOperation(
        endpoint: '${ApiEndpoints.transactions}/$id',
        method: 'DELETE',
        payload: {},
        customIdempotencyKey: idempotencyKey,
      );

      // 3. Refresh UI
      await _loadFromLocal();
      ref.read(accountProvider.notifier).fetchAccounts();

      // 4. Background sync
      SyncManager.syncPendingItems();

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
      categoryId: row['categoryId'] as String?,
      categoryName: row['categoryName'] as String?,
      parentCategoryName: row['parentCategoryName'] as String?,
      subCategoryName: row['subCategoryName'] as String?,
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
