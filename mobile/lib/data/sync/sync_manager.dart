import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../local/local_database_service.dart';

/// Purpose: Reliable Offline-to-Online Synchronization Manager
/// Author: Antigravity AI
///
/// Architecture: Optimistic Write-Through + Background Queue
/// ─────────────────────────────────────────────────────────
/// 1. User action → write to local SQLite instantly (< 5ms) → UI updates immediately
/// 2. Enqueue sync job into `sync_queue` table
/// 3. If network available → flush queue in background immediately (non-blocking)
/// 4. If offline → keep queued → auto-sync on connectivity resume or app foreground
///
/// Full Sync: On app startup or when coming to foreground after extended period,
/// pull latest data from backend and hydrate local DB to stay in sync with
/// changes made from other devices (e.g. web app).

class SyncManager {
  static bool _isSyncing = false;
  static bool _isFullSyncing = false;
  static final ApiClient _apiClient = ApiClient();
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  static bool _isInitialized = false;

  /// Sync status stream for UI indicators
  static final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();
  static Stream<SyncStatus> get statusStream => _statusController.stream;

  /// Initialize connectivity monitoring — call once from main.dart
  static void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        debugPrint('[SyncManager] Network restored → flushing sync queue');
        syncPendingItems();
      }
    });

    debugPrint('[SyncManager] Initialized with connectivity monitoring');
  }

  /// Dispose connectivity subscription (cleanup)
  static void dispose() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _isInitialized = false;
    _statusController.close();
  }

  /// Check if device currently has network connectivity
  static Future<bool> hasNetwork() async {
    final result = await Connectivity().checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  INCREMENTAL SYNC: Drain pending queue items sequentially
  // ═══════════════════════════════════════════════════════════════════════════

  /// Drain pending offline sync items sequentially.
  /// Called automatically on connectivity restore, and can be triggered manually.
  static Future<void> syncPendingItems() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _statusController.add(SyncStatus.syncing);

    try {
      final pendingItems = await LocalDatabaseService.getPendingSyncItems();
      if (pendingItems.isEmpty) {
        _isSyncing = false;
        _statusController.add(SyncStatus.idle);
        return;
      }

      debugPrint('[SyncManager] Flushing ${pendingItems.length} pending sync items...');
      int successCount = 0;

      for (final item in pendingItems) {
        final id = item['id'] as String;
        final idempotencyKey = item['idempotencyKey'] as String;
        final endpoint = item['endpoint'] as String;
        final method = (item['method'] as String).toUpperCase();
        final payload = jsonDecode(item['payload'] as String);
        final attempts = (item['attempts'] as int? ?? 0) + 1;

        // Give up after 10 failed attempts to prevent infinite retries
        if (attempts > 10) {
          await LocalDatabaseService.updateSyncItemStatus(id, 'abandoned');
          continue;
        }

        try {
          Response response;
          final headers = {'X-Idempotency-Key': idempotencyKey};

          if (method == 'POST') {
            response = await _apiClient.post(endpoint, data: payload, headers: headers);
          } else if (method == 'PUT') {
            response = await _apiClient.put(endpoint, data: payload, headers: headers);
          } else if (method == 'PATCH') {
            response = await _apiClient.patch(endpoint, data: payload, headers: headers);
          } else if (method == 'DELETE') {
            response = await _apiClient.delete(endpoint, headers: headers);
          } else {
            response = await _apiClient.get(endpoint);
          }

          if (response.statusCode != null && response.statusCode! < 400) {
            await LocalDatabaseService.updateSyncItemStatus(id, 'synced');
            successCount++;
          } else if (response.statusCode == 409) {
            // 409 Conflict / Request already processed idempotently
            await LocalDatabaseService.updateSyncItemStatus(id, 'synced');
            successCount++;
          } else {
            await LocalDatabaseService.updateSyncItemStatus(id, 'failed', attempts: attempts);
          }
        } catch (e) {
          // Network error or offline - keep in queue for next sync cycle
          await LocalDatabaseService.updateSyncItemStatus(id, 'failed', attempts: attempts);
          debugPrint('[SyncManager] Sync item failed: $e');
          // If we can't connect, stop trying the rest of the queue
          break;
        }
      }

      debugPrint('[SyncManager] Sync complete: $successCount/${pendingItems.length} items synced');
      _statusController.add(SyncStatus.idle);
    } finally {
      _isSyncing = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  FULL SYNC: Pull all data from backend → hydrate local DB
  // ═══════════════════════════════════════════════════════════════════════════

  /// Full downstream sync: fetch latest data from backend and update local DB.
  /// This ensures the mobile app picks up changes made from other devices
  /// (e.g. the web app at ss-money-manager.vercel.app).
  ///
  /// Called on:
  /// - First app launch (no local data yet)
  /// - App coming to foreground after > 5 minutes
  /// - Manual pull-to-refresh
  static Future<bool> fullSync() async {
    if (_isFullSyncing) return false;
    _isFullSyncing = true;
    _statusController.add(SyncStatus.fullSync);

    try {
      final network = await hasNetwork();
      if (!network) {
        debugPrint('[SyncManager] No network for full sync — using local cache');
        _statusController.add(SyncStatus.offline);
        return false;
      }

      // 1. First, flush any pending local changes to backend
      await syncPendingItems();

      // 2. Pull latest data from backend
      debugPrint('[SyncManager] Starting full downstream sync...');

      bool success = true;

      // Sync Categories
      try {
        final catResp = await _apiClient.get(ApiEndpoints.categories);
        if (catResp.data != null && catResp.data['success'] == true) {
          final categories = catResp.data['data'] as List<dynamic>? ?? [];
          await LocalDatabaseService.clearLocalCategories();
          await LocalDatabaseService.saveLocalCategories(categories);
          debugPrint('[SyncManager] Synced ${categories.length} categories');
        }
      } catch (e) {
        debugPrint('[SyncManager] Category sync failed: $e');
        success = false;
      }

      // Sync Accounts
      try {
        final accResp = await _apiClient.get(ApiEndpoints.accounts);
        if (accResp.data != null && accResp.data['success'] == true) {
          final accounts = accResp.data['data'] as List<dynamic>? ?? [];
          await LocalDatabaseService.clearLocalAccounts();
          await LocalDatabaseService.saveLocalAccounts(accounts);
          debugPrint('[SyncManager] Synced ${accounts.length} accounts');
        }
      } catch (e) {
        debugPrint('[SyncManager] Account sync failed: $e');
        success = false;
      }

      // Sync Transactions
      try {
        final txResp = await _apiClient.get(ApiEndpoints.transactions);
        if (txResp.data != null && txResp.data['success'] == true) {
          final transactions = txResp.data['transactions'] as List<dynamic>? ?? [];
          await LocalDatabaseService.clearLocalTransactions();
          await LocalDatabaseService.saveLocalTransactions(transactions);
          debugPrint('[SyncManager] Synced ${transactions.length} transactions');
        }
      } catch (e) {
        debugPrint('[SyncManager] Transaction sync failed: $e');
        success = false;
      }

      // Sync Budgets
      try {
        final now = DateTime.now();
        final budgetResp = await _apiClient.get(
          ApiEndpoints.budgets,
          queryParameters: {'month': now.month, 'year': now.year},
        );
        if (budgetResp.data != null && budgetResp.data['success'] == true) {
          final budgetData = budgetResp.data['data'];
          List<dynamic>? budgets;
          if (budgetData is List) {
            budgets = budgetData;
          } else if (budgetData is Map) {
            budgets = (budgetData['budgets'] ?? budgetData['categories']) as List<dynamic>?;
          }

          if (budgets != null) {
            await LocalDatabaseService.clearLocalBudgets();
            await LocalDatabaseService.saveLocalBudgets(budgets);
            debugPrint('[SyncManager] Synced ${budgets.length} budgets');
          }
        }
      } catch (e) {
        debugPrint('[SyncManager] Budget sync failed: $e');
        success = false;
      }

      // Record sync timestamp
      await LocalDatabaseService.setSyncMeta(
        'lastFullSync',
        DateTime.now().toIso8601String(),
      );

      _statusController.add(success ? SyncStatus.idle : SyncStatus.partialError);
      debugPrint('[SyncManager] Full sync completed (success=$success)');
      return success;
    } catch (e) {
      debugPrint('[SyncManager] Full sync error: $e');
      _statusController.add(SyncStatus.error);
      return false;
    } finally {
      _isFullSyncing = false;
    }
  }

  /// Check if a full sync is needed based on elapsed time since last sync
  static Future<bool> needsFullSync({Duration threshold = const Duration(minutes: 5)}) async {
    final lastSync = await LocalDatabaseService.getSyncMeta('lastFullSync');
    if (lastSync == null) return true; // Never synced before

    final lastSyncTime = DateTime.tryParse(lastSync);
    if (lastSyncTime == null) return true;

    return DateTime.now().difference(lastSyncTime) > threshold;
  }

  /// Trigger sync if needed — called on app foreground
  static Future<void> syncIfNeeded() async {
    if (await needsFullSync()) {
      await fullSync();
    } else {
      // Just flush any pending local writes
      await syncPendingItems();
    }
  }
}

/// Sync status for UI indicators
enum SyncStatus {
  idle,
  syncing,
  fullSync,
  offline,
  partialError,
  error,
}
