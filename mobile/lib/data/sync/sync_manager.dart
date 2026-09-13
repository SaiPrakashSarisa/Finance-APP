import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../local/local_database_service.dart';

/// Purpose: Reliable Offline-to-Online Synchronization Manager
/// Author: Antigravity AI

class SyncManager {
  static bool _isSyncing = false;
  static final ApiClient _apiClient = ApiClient();

  /// Drain pending offline sync items sequentially
  static Future<void> syncPendingItems() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pendingItems = await LocalDatabaseService.getPendingSyncItems();
      if (pendingItems.isEmpty) {
        _isSyncing = false;
        return;
      }

      for (final item in pendingItems) {
        final id = item['id'] as String;
        final idempotencyKey = item['idempotencyKey'] as String;
        final endpoint = item['endpoint'] as String;
        final method = (item['method'] as String).toUpperCase();
        final payload = jsonDecode(item['payload'] as String);
        final attempts = (item['attempts'] as int? ?? 0) + 1;

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
            // Successfully synchronized
            await LocalDatabaseService.updateSyncItemStatus(id, 'synced');
          } else if (response.statusCode == 409) {
            // 409 Conflict / Request already processed idempotently
            await LocalDatabaseService.updateSyncItemStatus(id, 'synced');
          } else {
            // Record failure attempt
            await LocalDatabaseService.updateSyncItemStatus(id, 'failed', attempts: attempts);
          }
        } catch (e) {
          // Network error or offline - keep in queue for next sync cycle
          await LocalDatabaseService.updateSyncItemStatus(id, 'failed', attempts: attempts);
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
