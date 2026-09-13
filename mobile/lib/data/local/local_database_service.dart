import 'dart:convert';
import 'package:path/path me';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Purpose: Offline-First SQLite Local Persistence Engine
/// Author: Antigravity AI

class LocalDatabaseService {
  static Database? _db;
  static const _uuid = Uuid();

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
      version: 1,
      onCreate: (Database db, int version) async {
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
            type TEXT NOT NULL,
            amount REAL NOT NULL,
            categoryId TEXT,
            note TEXT,
            date TEXT NOT NULL,
            toAccountId TEXT,
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
      },
    );
  }

  // --- Sync Queue Helper Methods ---

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

  // --- Local Record Persistence ---

  static Future<void> saveLocalTransaction(Map<String, dynamic> tx, {bool isSynced = true}) async {
    final database = await db;
    await database.insert(
      'transactions',
      {
        'id': tx['id'] ?? tx['_id'] ?? _uuid.v4(),
        'idempotencyKey': tx['idempotencyKey'] ?? _uuid.v4(),
        'accountId': tx['accountId'],
        'type': tx['type'],
        'amount': (tx['amount'] as num).toDouble(),
        'categoryId': tx['categoryId'],
        'note': tx['note'] ?? '',
        'date': tx['date'] ?? DateTime.now().toIso8601String(),
        'toAccountId': tx['toAccountId'],
        'isSynced': isSynced ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getLocalTransactions() async {
    final database = await db;
    return await database.query('transactions', orderBy: 'date DESC');
  }

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
          'parentCategoryId': c['parentCategoryId'],
          'isSynced': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getLocalCategories() async {
    final database = await db;
    return await database.query('categories', orderBy: 'name ASC');
  }

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
          'isActive': (a['isActive'] ?? true) ? 1 : 0,
          'isSynced': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getLocalAccounts() async {
    final database = await db;
    return await database.query('accounts', orderBy: 'name ASC');
  }
}
