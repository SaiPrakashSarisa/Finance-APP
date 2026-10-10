import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../local/local_database_service.dart';

/// Purpose: Reliable Offline-to-Online Synchronization Manager
/// Author: Antigravity AI
///
/// Architecture: Direct API First + Fallback to Sync Queue on Failure
/// ──────────────────────────────────────────────────────────────────
/// 1. Action executes: Writes to Local SQLite immediately (<5ms, 0ms latency)
/// 2. If existing items in sync_queue → triggers opportunistic background drain
/// 3. Direct API call is attempted immediately to Render backend
/// 4. If direct call succeeds:
///    - Local record marked as synced (isSynced = 1)
/// 5. If direct call fails (offline, timeout, Render cold start):
///    - Operation is enqueued in `sync_queue` table
///    - Local SQLite copy remains completely intact so user never loses data
/// 6. Queue retry triggers:
///    - Piggybacked on ANY subsequent successful API call across the app
///    - Periodic timing loop (every 3 minutes)
///    - Connectivity restore listener
///    - App foreground resume

class SyncManager {
  static bool _isSyncing = false;
  static bool _isFullSyncing = false;
  static final ApiClient _apiClient = ApiClient();
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  static Timer? _timer;
  static bool _isInitialized = false;
  static const _uuid = Uuid();

  /// Sync status stream for UI indicators
  static final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();
  static Stream<SyncStatus> get statusStream => _statusController.stream;

  /// Initialize connectivity monitoring & recurring timing loop — call once from main.dart
  static void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    // 1. Connectivity restore listener
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        debugPrint('[SyncManager] Network restored → flushing sync queue');
        syncPendingItems();
      }
    });

    // 2. Periodic timing loop (Heartbeat every 3 minutes)
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 3), (_) {
      debugPrint('[SyncManager] Heartbeat timing loop triggered');
      syncPendingItems();
    });

    // 3. Piggyback on every successful API call across the entire app
    ApiClient.onSuccessfulResponse = opportunisticSync;

    debugPrint('[SyncManager] Initialized with connectivity monitoring, 3-min timing loop & piggyback sync');
  }

  /// Dispose connectivity subscription and timer (cleanup)
  static void dispose() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _timer?.cancel();
    _timer = null;
    ApiClient.onSuccessfulResponse = null;
    _isInitialized = false;
    _statusController.close();
  }

  /// Check if device currently has network connectivity
  static Future<bool> hasNetwork() async {
    final result = await Connectivity().checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }

  /// Opportunistically drain queue in background if not already syncing
  /// Called when any API call succeeds or is triggered across the app
  static void opportunisticSync() {
    if (!_isSyncing) {
      syncPendingItems();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  DIRECT CALL FIRST + FALLBACK TO SYNC QUEUE ON FAILURE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Executes a direct API call first.
  /// If it succeeds, returns the response.
  /// If it fails (offline, connection timeout, server 5xx), enqueues into
  /// `sync_queue` table and returns null without throwing error.
  static Future<Response?> executeDirectWithQueueFallback({
    required String endpoint,
    required String method,
    required Map<String, dynamic> payload,
    String? customIdempotencyKey,
  }) async {
    // 1. Opportunistic trigger: flush any previous queued items
    opportunisticSync();

    final idempotencyKey = customIdempotencyKey ?? _uuid.v4();
    final headers = {'X-Idempotency-Key': idempotencyKey};

    // 2. Attempt direct API call immediately
    try {
      Response response;
      final upperMethod = method.toUpperCase();

      if (upperMethod == 'POST') {
        response = await _apiClient.post(endpoint, data: payload, headers: headers);
      } else if (upperMethod == 'PUT') {
        response = await _apiClient.put(endpoint, data: payload, headers: headers);
      } else if (upperMethod == 'PATCH') {
        response = await _apiClient.patch(endpoint, data: payload, headers: headers);
      } else if (upperMethod == 'DELETE') {
        response = await _apiClient.delete(endpoint, headers: headers);
      } else {
        response = await _apiClient.get(endpoint);
      }

      // Check if successful (< 400)
      if (response.statusCode != null && response.statusCode! < 400) {
        debugPrint('[SyncManager] Direct API call succeeded: $upperMethod $endpoint');
        return response;
      } else if (response.statusCode == 409) {
        // Idempotency duplicate - already recorded
        debugPrint('[SyncManager] Direct API call 409 conflict (already recorded): $upperMethod $endpoint');
        return response;
      } else {
        // Server returned 4xx or 5xx: enqueue for background retry
        debugPrint('[SyncManager] Direct API call returned ${response.statusCode}, enqueuing to sync_queue');
        await LocalDatabaseService.enqueueOperation(
          endpoint: endpoint,
          method: method,
          payload: payload,
          customIdempotencyKey: idempotencyKey,
        );
        return null;
      }
    } catch (e) {
      // Network failure, offline, connection timeout, or Render sleeping
      debugPrint('[SyncManager] Direct API call failed ($e), enqueuing to sync_queue');
      await LocalDatabaseService.enqueueOperation(
        endpoint: endpoint,
        method: method,
        payload: payload,
        customIdempotencyKey: idempotencyKey,
      );
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  INCREMENTAL SYNC: Drain pending queue items sequentially
  // ═══════════════════════════════════════════════════════════════════════════

  /// Drain pending offline sync items sequentially.
  /// Called automatically on connectivity restore, timing loop, and piggybacking.
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
  /// Ensures mobile picks up changes made from other devices (e.g. web app).
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
        final txResp = await _apiClient.get(ApiEndpoints.transactions, queryParameters: {'limit': 500});
        if (txResp.data != null && txResp.data['success'] == true) {
          final transactions = txResp.data['transactions'] as List<dynamic>? ?? [];
          final deletedIds = (txResp.data['deletedIds'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];

          if (deletedIds.isNotEmpty) {
            await LocalDatabaseService.deleteLocalTransactions(deletedIds);
            debugPrint('[SyncManager] Purged ${deletedIds.length} deleted transaction tombstones');
          }

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
      _statusController.add(SyncStatus.partialError);
      return false;
    } finally {
      _isFullSyncing = false;
    }
  }

  /// Check if a full sync is needed (> 5 minutes since last full sync)
  static Future<bool> needsFullSync() async {
    final lastSyncStr = await LocalDatabaseService.getSyncMeta('lastFullSync');
    if (lastSyncStr == null) return true;
    final lastSync = DateTime.tryParse(lastSyncStr);
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync).inMinutes >= 5;
  }

  /// Trigger sync if needed (called on app foreground)
  static Future<void> syncIfNeeded() async {
    final pendingCount = await LocalDatabaseService.getPendingSyncCount();
    if (pendingCount > 0) {
      await syncPendingItems();
    }
    if (await needsFullSync()) {
      await fullSync();
    }
  }
}

enum SyncStatus {
  idle,
  syncing,
  fullSync,
  offline,
  partialError,
}
