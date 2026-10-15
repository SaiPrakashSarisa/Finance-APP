import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Purpose: Offline-First SQLite Local Persistence Engine
/// Author: Antigravity AI
///
/// Design: This service is the PRIMARY data source for the UI layer.
/// All reads come from here (< 5ms latency). Writes go here first,
/// then a sync_queue entry is created for background replication to
/// the remote backend. The backend serves as a remote backup & multi-device sync hub.

class LocalDatabaseService {
  static Database? _db;
  static const _uuid = Uuid();
  static const int _dbVersion = 3; // v3: adds creditId, creditType, merchantName columns

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'finance_app_offline.db');

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (Database db, int version) async {
        await _createAllTables(db);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          // Migration: Add budgets and sync_meta tables
          await db.execute('''
            CREATE TABLE IF NOT EXISTS budgets (
              id TEXT PRIMARY KEY,
              categoryId TEXT NOT NULL,
              categoryName TEXT,
              amount REAL NOT NULL,
              spent REAL DEFAULT 0,
              month INTEGER NOT NULL,
              year INTEGER NOT NULL,
              isSynced INTEGER DEFAULT 1
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS sync_meta (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 3) {
          // Migration: Add creditId, creditType, merchantName columns
          try {
            await db.execute('ALTER TABLE transactions ADD COLUMN creditId TEXT;');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE transactions ADD COLUMN creditType TEXT;');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE transactions ADD COLUMN merchantName TEXT;');
          } catch (_) {}
        }
      },
    );
  }

  static Future<void> _createAllTables(Database db) async {
    // Local Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT,
        color TEXT,
        parentCategoryId TEXT,
        isSynced INTEGER DEFAULT 1
      )
    ''');

    // Local Accounts Table
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL DEFAULT 0,
        initialBalance REAL DEFAULT 0,
        currency TEXT DEFAULT 'INR',
        isActive INTEGER DEFAULT 1,
        isSynced INTEGER DEFAULT 1
      )
    ''');

    // Local Transactions Table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        idempotencyKey TEXT UNIQUE NOT NULL,
        accountId TEXT NOT NULL,
        accountName TEXT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        categoryId TEXT,
        categoryName TEXT,
        parentCategoryName TEXT,
        subCategoryName TEXT,
        creditId TEXT,
        creditType TEXT,
        merchantName TEXT,
        note TEXT,
        date TEXT NOT NULL,
        toAccountId TEXT,
        isItemized INTEGER DEFAULT 0,
        items TEXT,
        isSynced INTEGER DEFAULT 1
      )
    ''');

    // Budgets Table
    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        categoryId TEXT NOT NULL,
        categoryName TEXT,
        amount REAL NOT NULL,
        spent REAL DEFAULT 0,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        isSynced INTEGER DEFAULT 1
      )
    ''');

    // Sync Queue Table
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        idempotencyKey TEXT UNIQUE NOT NULL,
        endpoint TEXT NOT NULL,
        method TEXT NOT NULL,
        payload TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        attempts INTEGER DEFAULT 0
      )
    ''');

    // Sync Metadata Table (tracks last-synced timestamps per entity)
    await db.execute('''
      CREATE TABLE sync_meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // ==========================================================================
  //  SYNC QUEUE OPERATIONS
  // ==========================================================================

  /// Enqueue an offline operation into the sync queue table with a unique idempotency key
  static Future<String> enqueueOperation({
    required String endpoint,
    required String method,
    required Map<String, dynamic> payload,
    String? customIdempotencyKey,
  }) async {
    final database = await db;
    final id = _uuid.v4();
    final idempotencyKey = customIdempotencyKey ?? _uuid.v4();
    final createdAt = DateTime.now().toIso8601String();

    await database.insert(
      'sync_queue',
      {
        'id': id,
        'idempotencyKey': idempotencyKey,
        'endpoint': endpoint,
        'method': method,
        'payload': jsonEncode(payload),
        'createdAt': createdAt,
        'status': 'pending',
        'attempts': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return idempotencyKey;
  }

  /// Get pending operations from sync queue ordered by creation timestamp
  static Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final database = await db;
    return await database.query(
      'sync_queue',
      where: 'status = ? OR status = ?',
      whereArgs: ['pending', 'failed'],
      orderBy: 'createdAt ASC',
    );
  }

  /// Get count of pending sync items
  static Future<int> getPendingSyncCount() async {
    final database = await db;
    final result = await database.rawQuery(
      "SELECT COUNT(*) as count FROM sync_queue WHERE status = 'pending' OR status = 'failed'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Mark queue item as synced (completed) or update status/attempts
  static Future<void> updateSyncItemStatus(String id, String status, {int? attempts}) async {
    final database = await db;
    final values = <String, dynamic>{'status': status};
    if (attempts != null) values['attempts'] = attempts;

    if (status == 'synced') {
      // Remove successfully synced item from queue to keep table small
      await database.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
    } else {
      await database.update('sync_queue', values, where: 'id = ?', whereArgs: [id]);
    }
  }

  /// Clear all synced items from queue (cleanup)
  static Future<void> clearSyncedItems() async {
    final database = await db;
    await database.delete('sync_queue', where: "status = 'synced'");
  }

  // ==========================================================================
  //  SYNC METADATA
  // ==========================================================================

  static Future<void> setSyncMeta(String key, String value) async {
    final database = await db;
    await database.insert(
      'sync_meta',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String?> getSyncMeta(String key) async {
    final database = await db;
    final result = await database.query('sync_meta', where: 'key = ?', whereArgs: [key]);
    if (result.isNotEmpty) return result.first['value'] as String?;
    return null;
  }

  // ==========================================================================
  //  TRANSACTIONS - Full Offline CRUD
  // ==========================================================================

  static Future<void> saveLocalTransaction(Map<String, dynamic> tx, {bool isSynced = true}) async {
    final database = await db;

    // Serialize items list to JSON string for storage
    String? itemsJson;
    if (tx['items'] != null && tx['items'] is List) {
      itemsJson = jsonEncode(tx['items']);
    }

    await database.insert(
      'transactions',
      {
        'id': tx['id'] ?? tx['_id'] ?? _uuid.v4(),
        'idempotencyKey': tx['idempotencyKey'] ?? _uuid.v4(),
        'accountId': tx['accountId'] is Map ? tx['accountId']['_id'] : (tx['accountId'] ?? ''),
        'accountName': tx['accountName'] ?? (tx['accountId'] is Map ? tx['accountId']['name'] : null),
        'type': tx['type'] ?? 'expense',
        'amount': (tx['amount'] as num).toDouble(),
        'categoryId': tx['categoryId'] is Map ? tx['categoryId']['_id'] : tx['categoryId'],
        'categoryName': tx['categoryName'] ?? (tx['categoryId'] is Map ? tx['categoryId']['name'] : null),
        'parentCategoryName': tx['parentCategoryName'],
        'subCategoryName': tx['subCategoryName'],
        'creditId': tx['creditId'] is Map ? tx['creditId']['_id'] : tx['creditId'],
        'creditType': tx['creditType'] ?? (tx['creditId'] is Map ? tx['creditId']['type'] : null),
        'merchantName': tx['merchantName'] ?? (tx['merchantId'] is Map ? tx['merchantId']['name'] : null),
        'note': tx['note'] ?? tx['notes'] ?? '',
        'date': tx['date'] ?? DateTime.now().toIso8601String(),
        'toAccountId': tx['toAccountId'] is Map ? tx['toAccountId']['_id'] : tx['toAccountId'],
        'isItemized': (tx['isItemized'] == true) ? 1 : 0,
        'items': itemsJson,
        'isSynced': isSynced ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Batch-save transactions from backend (replaces local copies during full sync)
  static Future<void> saveLocalTransactions(List<dynamic> transactions) async {
    final database = await db;
    final batch = database.batch();
    for (final tx in transactions) {
      String? itemsJson;
      if (tx['items'] != null && tx['items'] is List) {
        itemsJson = jsonEncode(tx['items']);
      }

      batch.insert(
        'transactions',
        {
          'id': tx['_id'] ?? tx['id'] ?? _uuid.v4(),
          'idempotencyKey': tx['idempotencyKey'] ?? _uuid.v4(),
          'accountId': tx['accountId'] is Map ? tx['accountId']['_id'] : (tx['accountId'] ?? ''),
          'accountName': tx['accountId'] is Map ? tx['accountId']['name'] : tx['accountName'],
          'type': tx['type'] ?? 'expense',
          'amount': (tx['amount'] as num?)?.toDouble() ?? 0.0,
          'categoryId': tx['categoryId'] is Map ? tx['categoryId']['_id'] : tx['categoryId'],
          'categoryName': tx['categoryId'] is Map ? tx['categoryId']['name'] : tx['categoryName'],
          'parentCategoryName': tx['categoryId'] is Map && tx['categoryId']['parentCategoryId'] is Map
              ? tx['categoryId']['parentCategoryId']['name']
              : tx['parentCategoryName'],
          'subCategoryName': tx['categoryId'] is Map && tx['categoryId']['parentCategoryId'] is Map
              ? tx['categoryId']['name']
              : tx['subCategoryName'],
          'creditId': tx['creditId'] is Map ? tx['creditId']['_id'] : tx['creditId'],
          'creditType': tx['creditType'] ?? (tx['creditId'] is Map ? tx['creditId']['type'] : null),
          'merchantName': tx['merchantName'] ?? (tx['merchantId'] is Map ? tx['merchantId']['name'] : null),
          'note': tx['note'] ?? tx['notes'] ?? '',
          'date': tx['date'] ?? DateTime.now().toIso8601String(),
          'toAccountId': tx['toAccountId'] is Map ? tx['toAccountId']['_id'] : tx['toAccountId'],
          'isItemized': (tx['isItemized'] == true) ? 1 : 0,
          'items': itemsJson,
          'isSynced': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    await deduplicateTransactions();
  }

  /// Purge orphaned optimistic transactions that have a matching synced transaction from server
  static Future<void> deduplicateTransactions() async {
    try {
      final database = await db;
      await database.rawDelete('''
        DELETE FROM transactions 
        WHERE isSynced = 0 
          AND id IN (
            SELECT t1.id FROM transactions t1
            JOIN transactions t2 ON t1.accountId = t2.accountId 
              AND t1.amount = t2.amount 
              AND t1.type = t2.type 
              AND t1.isSynced = 0 
              AND t2.isSynced = 1
              AND t1.id != t2.id
              AND SUBSTR(t1.date, 1, 10) = SUBSTR(t2.date, 1, 10)
          )
      ''');
    } catch (e) {
      debugPrint('[LocalDatabaseService] deduplicate error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getLocalTransactions({
    String? type,
    String? accountId,
    String? categoryId,
    String? creditId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final database = await db;
    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (type != null && type != 'all' && type.isNotEmpty) {
      if (type == 'income') {
        where.add("(type = 'income' OR (type = 'credit_repay' AND creditType = 'given'))");
      } else if (type == 'expense') {
        where.add("(type = 'expense' OR (type = 'credit_repay' AND (creditType = 'taken' OR creditType IS NULL)))");
      } else {
        where.add('type = ?');
        whereArgs.add(type);
      }
    }
    if (accountId != null && accountId.isNotEmpty) {
      where.add('(accountId = ? OR toAccountId = ?)');
      whereArgs.add(accountId);
      whereArgs.add(accountId);
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      where.add('categoryId = ?');
      whereArgs.add(categoryId);
    }
    if (creditId != null && creditId.isNotEmpty) {
      where.add('creditId = ?');
      whereArgs.add(creditId);
    }
    if (startDate != null) {
      where.add('date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      where.add('date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    return await database.query(
      'transactions',
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC',
    );
  }

  static Future<void> deleteLocalTransaction(String id) async {
    final database = await db;
    await database.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  /// Batch-delete transactions (e.g. tombstones received from server)
  static Future<void> deleteLocalTransactions(List<String> ids) async {
    if (ids.isEmpty) return;
    final database = await db;
    final batch = database.batch();
    for (final id in ids) {
      batch.delete('transactions', where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  static Future<void> clearLocalTransactions() async {
    final database = await db;
    await database.delete('transactions');
  }

  // ==========================================================================
  //  CATEGORIES - Full Offline CRUD
  // ==========================================================================

  static Future<void> saveLocalCategories(List<dynamic> categories) async {
    final database = await db;
    final batch = database.batch();
    for (final c in categories) {
      batch.insert(
        'categories',
        {
          'id': c['_id'] ?? c['id'],
          'name': c['name'],
          'type': c['type'],
          'icon': c['icon'] ?? '📁',
          'color': c['color'] ?? '#6366F1',
          'parentCategoryId': c['parentCategoryId'] is Map
              ? c['parentCategoryId']['_id']
              : c['parentCategoryId'],
          'isSynced': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<void> saveLocalCategory(Map<String, dynamic> c, {bool isSynced = true}) async {
    final database = await db;
    await database.insert(
      'categories',
      {
        'id': c['_id'] ?? c['id'] ?? _uuid.v4(),
        'name': c['name'],
        'type': c['type'],
        'icon': c['icon'] ?? '📁',
        'color': c['color'] ?? '#6366F1',
        'parentCategoryId': c['parentCategoryId'] is Map
            ? c['parentCategoryId']['_id']
            : c['parentCategoryId'],
        'isSynced': isSynced ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getLocalCategories() async {
    final database = await db;
    return await database.query('categories', orderBy: 'name ASC');
  }

  static Future<void> clearLocalCategories() async {
    final database = await db;
    await database.delete('categories');
  }

  // ==========================================================================
  //  ACCOUNTS - Full Offline CRUD
  // ==========================================================================

  static Future<void> saveLocalAccounts(List<dynamic> accounts) async {
    final database = await db;
    final batch = database.batch();
    for (final a in accounts) {
      batch.insert(
        'accounts',
        {
          'id': a['_id'] ?? a['id'],
          'name': a['name'],
          'type': a['type'],
          'balance': (a['balance'] as num).toDouble(),
          'initialBalance': (a['initialBalance'] as num? ?? 0).toDouble(),
          'currency': a['currency'] ?? 'INR',
          'isActive': (a['isActive'] == 1 || a['isActive'] == true || a['isActive'] == null) ? 1 : 0,
          'isSynced': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<void> saveLocalAccount(Map<String, dynamic> a, {bool isSynced = true}) async {
    final database = await db;
    await database.insert(
      'accounts',
      {
        'id': a['_id'] ?? a['id'] ?? _uuid.v4(),
        'name': a['name'],
        'type': a['type'],
        'balance': (a['balance'] as num?)?.toDouble() ?? 0.0,
        'initialBalance': (a['initialBalance'] as num?)?.toDouble() ?? 0.0,
        'currency': a['currency'] ?? 'INR',
        'isActive': (a['isActive'] ?? true) == true ? 1 : 0,
        'isSynced': isSynced ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update account balance locally (used for optimistic UI updates after transactions)
  static Future<void> updateLocalAccountBalance(String accountId, double delta) async {
    final database = await db;
    await database.rawUpdate(
      'UPDATE accounts SET balance = balance + ? WHERE id = ?',
      [delta, accountId],
    );
  }

  static Future<List<Map<String, dynamic>>> getLocalAccounts() async {
    final database = await db;
    return await database.query('accounts', orderBy: 'name ASC');
  }

  static Future<void> clearLocalAccounts() async {
    final database = await db;
    await database.delete('accounts');
  }

  // ==========================================================================
  //  BUDGETS - Full Offline CRUD
  // ==========================================================================

  static Future<void> saveLocalBudget(Map<String, dynamic> b, {bool isSynced = true}) async {
    final database = await db;
    final catObj = b['category'] ?? b['categoryId'];
    final catId = catObj is Map ? catObj['_id'] : (catObj ?? '');
    final catName = catObj is Map ? catObj['name'] : (b['categoryName'] ?? '');

    await database.insert(
      'budgets',
      {
        'id': b['_id'] ?? b['id'] ?? _uuid.v4(),
        'categoryId': catId,
        'categoryName': catName,
        'amount': (b['amount'] as num?)?.toDouble() ?? 0.0,
        'spent': (b['spent'] as num?)?.toDouble() ?? 0.0,
        'month': b['month'] ?? DateTime.now().month,
        'year': b['year'] ?? DateTime.now().year,
        'isSynced': isSynced ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteLocalBudget(String id) async {
    final database = await db;
    await database.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> saveLocalBudgets(List<dynamic> budgets) async {
    final database = await db;
    final batch = database.batch();
    for (final b in budgets) {
      final catObj = b['category'] ?? b['categoryId'];
      final catId = catObj is Map ? catObj['_id'] : (catObj ?? '');
      final catName = catObj is Map ? catObj['name'] : (b['categoryName'] ?? '');

      batch.insert(
        'budgets',
        {
          'id': b['_id'] ?? b['id'] ?? _uuid.v4(),
          'categoryId': catId,
          'categoryName': catName,
          'amount': (b['amount'] as num?)?.toDouble() ?? 0.0,
          'spent': (b['spent'] as num?)?.toDouble() ?? 0.0,
          'month': b['month'] ?? DateTime.now().month,
          'year': b['year'] ?? DateTime.now().year,
          'isSynced': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getLocalBudgets({int? month, int? year}) async {
    final database = await db;
    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (month != null) {
      where.add('month = ?');
      whereArgs.add(month);
    }
    if (year != null) {
      where.add('year = ?');
      whereArgs.add(year);
    }

    return await database.query(
      'budgets',
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'categoryName ASC',
    );
  }

  static Future<void> clearLocalBudgets() async {
    final database = await db;
    await database.delete('budgets');
  }

  // ==========================================================================
  //  FULL DATABASE RESET (used on logout)
  // ==========================================================================

  static Future<void> clearAllData() async {
    final database = await db;
    await database.delete('transactions');
    await database.delete('categories');
    await database.delete('accounts');
    await database.delete('budgets');
    await database.delete('sync_queue');
    await database.delete('sync_meta');
  }
}
