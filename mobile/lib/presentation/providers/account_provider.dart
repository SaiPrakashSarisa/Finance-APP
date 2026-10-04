import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/api_endpoints.dart';
import '../../data/local/local_database_service.dart';
import '../../data/models/account_model.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/sync/sync_manager.dart';
import 'auth_provider.dart';

/// Purpose: Offline-First Accounts State Management Provider
/// Author: Antigravity AI
///
/// Architecture: Local-First Read/Write
/// ─────────────────────────────────────
/// READ:  Always from local SQLite (< 5ms)
/// WRITE: Save to local SQLite → enqueue sync → flush queue if online

const _uuid = Uuid();

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.watch(apiClientProvider));
});

class AccountState {
  final List<AccountModel> accounts;
  final bool isLoading;
  final String? error;

  AccountState({
    required this.accounts,
    required this.isLoading,
    this.error,
  });

  double get netWorth => accounts.fold(0.0, (sum, acc) => sum + acc.balance);
}

class AccountNotifier extends StateNotifier<AccountState> {
  final AccountRepository repository;

  AccountNotifier(this.repository)
      : super(AccountState(accounts: [], isLoading: true)) {
    _loadFromLocal();
  }

  /// PRIMARY: Load accounts from local SQLite (< 5ms)
  Future<void> _loadFromLocal() async {
    state = AccountState(accounts: state.accounts, isLoading: true);
    try {
      final rows = await LocalDatabaseService.getLocalAccounts();
      final list = rows.map((row) => _mapRowToModel(row)).toList();
      state = AccountState(accounts: list, isLoading: false);
    } catch (e) {
      debugPrint('[AccountProvider] Local read error: $e');
      state = AccountState(accounts: state.accounts, isLoading: false, error: e.toString());
    }
  }

  /// Public method: refresh accounts from local DB (called after sync)
  Future<void> fetchAccounts() async {
    await _loadFromLocal();
  }

  /// OFFLINE-FIRST: Add account to local DB instantly, enqueue sync
  Future<bool> addAccount(Map<String, dynamic> data) async {
    try {
      final accId = _uuid.v4();
      final idempotencyKey = _uuid.v4();

      // 1. Save to local SQLite instantly
      final localAcc = {
        'id': accId,
        ...data,
        'balance': data['initialBalance'] ?? data['balance'] ?? 0.0,
      };
      await LocalDatabaseService.saveLocalAccount(localAcc, isSynced: false);

      // 2. Enqueue sync
      await LocalDatabaseService.enqueueOperation(
        endpoint: ApiEndpoints.accounts,
        method: 'POST',
        payload: data,
        customIdempotencyKey: idempotencyKey,
      );

      // 3. Refresh UI from local data
      await _loadFromLocal();

      // 4. Background sync
      SyncManager.syncPendingItems();

      return true;
    } catch (e) {
      debugPrint('[AccountProvider] addAccount error: $e');
      return false;
    }
  }

  /// OFFLINE-FIRST: Update account in local DB, enqueue sync
  Future<bool> updateAccount(String id, Map<String, dynamic> data) async {
    try {
      final idempotencyKey = _uuid.v4();

      // 1. Update local SQLite
      final localAcc = {'id': id, ...data};
      await LocalDatabaseService.saveLocalAccount(localAcc, isSynced: false);

      // 2. Enqueue sync
      await LocalDatabaseService.enqueueOperation(
        endpoint: '${ApiEndpoints.accounts}/$id',
        method: 'PUT',
        payload: data,
        customIdempotencyKey: idempotencyKey,
      );

      // 3. Refresh UI
      await _loadFromLocal();

      // 4. Background sync
      SyncManager.syncPendingItems();

      return true;
    } catch (e) {
      debugPrint('[AccountProvider] updateAccount error: $e');
      return false;
    }
  }

  /// OFFLINE-FIRST: Delete account from local DB, enqueue sync
  Future<bool> deleteAccount(String id) async {
    try {
      final idempotencyKey = _uuid.v4();
      final database = await LocalDatabaseService.db;

      // 1. Delete from local SQLite
      await database.delete('accounts', where: 'id = ?', whereArgs: [id]);

      // 2. Enqueue sync
      await LocalDatabaseService.enqueueOperation(
        endpoint: '${ApiEndpoints.accounts}/$id',
        method: 'DELETE',
        payload: {},
        customIdempotencyKey: idempotencyKey,
      );

      // 3. Refresh UI
      await _loadFromLocal();

      // 4. Background sync
      SyncManager.syncPendingItems();

      return true;
    } catch (e) {
      debugPrint('[AccountProvider] deleteAccount error: $e');
      return false;
    }
  }

  /// Convert SQLite row to AccountModel
  AccountModel _mapRowToModel(Map<String, dynamic> row) {
    return AccountModel(
      id: row['id'] as String,
      name: row['name'] as String? ?? '',
      type: row['type'] as String? ?? 'bank',
      balance: (row['balance'] as num?)?.toDouble() ?? 0.0,
      initialBalance: (row['initialBalance'] as num?)?.toDouble() ?? 0.0,
      currency: row['currency'] as String? ?? 'INR',
    );
  }
}

final accountProvider = StateNotifierProvider<AccountNotifier, AccountState>((ref) {
  final authState = ref.watch(authProvider);
  final notifier = AccountNotifier(ref.watch(accountRepositoryProvider));
  if (authState.isAuthenticated) {
    notifier._loadFromLocal();
  }
  return notifier;
});
