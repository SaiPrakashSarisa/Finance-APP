import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/api_endpoints.dart';
import '../../data/local/local_database_service.dart';
import '../../data/models/account_model.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/sync/sync_manager.dart';
import 'auth_provider.dart';

/// Purpose: Accounts State Management Provider (Direct-First + Sync Fallback)
/// Author: Antigravity AI
///
/// Architecture:
/// 1. Instant local SQLite write/read (<5ms)
/// 2. Direct API call to Render backend
/// 3. If direct call fails (offline/cold start) → drops to sync_queue
/// 4. UI updates instantly in all cases

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
    fetchAccounts();
  }

  /// PRIMARY: Load accounts from local SQLite (< 5ms)
  Future<void> loadFromLocal() async {
    try {
      final rows = await LocalDatabaseService.getLocalAccounts();
      final list = rows.map((row) => _mapRowToModel(row)).toList();
      state = AccountState(accounts: list, isLoading: false);
    } catch (e) {
      debugPrint('[AccountProvider] Local read error: $e');
      state = AccountState(accounts: state.accounts, isLoading: false, error: e.toString());
    }
  }

  Future<void> _loadFromLocal() => loadFromLocal();

  /// Refresh accounts: Instant local display + background network fetch
  Future<void> fetchAccounts() async {
    await loadFromLocal();

    try {
      final remoteList = await repository.getAccounts();
      state = AccountState(accounts: remoteList, isLoading: false);
      // Persist to local database
      final jsonList = remoteList.map((a) => {
        'id': a.id,
        'name': a.name,
        'type': a.type,
        'balance': a.balance,
        'initialBalance': a.initialBalance,
        'currency': a.currency,
        'isActive': 1,
      }).toList();
      await LocalDatabaseService.clearLocalAccounts();
      if (jsonList.isNotEmpty) {
        await LocalDatabaseService.saveLocalAccounts(jsonList);
      }
    } catch (e) {
      debugPrint('[AccountProvider] Network fetch failed, using local DB: $e');
    }
  }

  /// DIRECT-FIRST + SYNC FALLBACK: Add account
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

      // 2. Refresh UI immediately from local data
      await _loadFromLocal();

      // 3. Direct API Call First with fallback to sync_queue
      final response = await SyncManager.executeDirectWithQueueFallback(
        endpoint: ApiEndpoints.accounts,
        method: 'POST',
        payload: data,
        customIdempotencyKey: idempotencyKey,
      );

      // 4. If direct call succeeded immediately, update local ID if backend generated one
      if (response != null && response.statusCode != null && response.statusCode! < 400) {
        if (response.data != null && response.data['data'] is Map) {
          final serverAcc = response.data['data'] as Map<String, dynamic>;
          if (serverAcc['_id'] != null && serverAcc['_id'] != accId) {
            final database = await LocalDatabaseService.db;
            await database.delete('accounts', where: 'id = ?', whereArgs: [accId]);
            await LocalDatabaseService.saveLocalAccount(serverAcc, isSynced: true);
            await _loadFromLocal();
          }
        }
      }

      return true;
    } catch (e) {
      debugPrint('[AccountProvider] addAccount error: $e');
      return false;
    }
  }

  /// DIRECT-FIRST + SYNC FALLBACK: Update account
  Future<bool> updateAccount(String id, Map<String, dynamic> data) async {
    try {
      final idempotencyKey = _uuid.v4();

      // 1. Update local SQLite
      final localAcc = {'id': id, ...data};
      await LocalDatabaseService.saveLocalAccount(localAcc, isSynced: false);

      // 2. Refresh UI
      await _loadFromLocal();

      // 3. Direct API Call First with fallback to sync_queue
      final response = await SyncManager.executeDirectWithQueueFallback(
        endpoint: '${ApiEndpoints.accounts}/$id',
        method: 'PUT',
        payload: data,
        customIdempotencyKey: idempotencyKey,
      );

      if (response != null && response.statusCode != null && response.statusCode! < 400) {
        await LocalDatabaseService.saveLocalAccount(localAcc, isSynced: true);
      }

      return true;
    } catch (e) {
      debugPrint('[AccountProvider] updateAccount error: $e');
      return false;
    }
  }

  /// DIRECT-FIRST + SYNC FALLBACK: Delete account
  Future<bool> deleteAccount(String id) async {
    try {
      final idempotencyKey = _uuid.v4();
      final database = await LocalDatabaseService.db;

      // 1. Delete from local SQLite
      await database.delete('accounts', where: 'id = ?', whereArgs: [id]);

      // 2. Refresh UI
      await _loadFromLocal();

      // 3. Direct API Call First with fallback to sync_queue
      await SyncManager.executeDirectWithQueueFallback(
        endpoint: '${ApiEndpoints.accounts}/$id',
        method: 'DELETE',
        payload: {},
        customIdempotencyKey: idempotencyKey,
      );

      return true;
    } catch (e) {
      debugPrint('[AccountProvider] deleteAccount error: $e');
      return false;
    }
  }

  /// Convert SQLite row to AccountModel
  AccountModel _mapRowToModel(Map<String, dynamic> row) {
    return AccountModel(
      id: row['id'] as String? ?? '',
      name: row['name'] as String? ?? '',
      type: row['type'] as String? ?? 'cash',
      balance: (row['balance'] as num?)?.toDouble() ?? 0.0,
      initialBalance: (row['initialBalance'] as num?)?.toDouble() ?? 0.0,
      currency: row['currency'] as String? ?? 'INR',
    );
  }
}

final accountProvider = StateNotifierProvider<AccountNotifier, AccountState>((ref) {
  return AccountNotifier(ref.watch(accountRepositoryProvider));
});
