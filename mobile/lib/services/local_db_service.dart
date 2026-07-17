import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Offline-first local cache for udhari data.
///
/// Reads always serve from here first (instant, works with no signal).
/// Writes (add credit / record payment) go here immediately too, marked
/// pending_sync = 1, then a background sync pushes them to the backend
/// once connectivity_plus reports we're back online. This is what makes
/// "add udhari with no internet, syncs later" actually work.
class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mykirana.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE udhari_transactions (
            id TEXT PRIMARY KEY,
            shop_id TEXT NOT NULL,
            customer_id TEXT NOT NULL,
            type TEXT NOT NULL,
            amount REAL NOT NULL,
            note TEXT,
            created_at TEXT NOT NULL,
            pending_sync INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE udhari_customers_cache (
            customer_id TEXT NOT NULL,
            shop_id TEXT NOT NULL,
            name TEXT,
            phone TEXT NOT NULL,
            balance REAL NOT NULL DEFAULT 0,
            PRIMARY KEY (customer_id, shop_id)
          )
        ''');
      },
    );
  }

  Future<void> cacheTransaction(Map<String, dynamic> row,
      {bool pendingSync = false}) async {
    final db = await database;
    await db.insert(
      'udhari_transactions',
      {...row, 'pending_sync': pendingSync ? 1 : 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getCachedHistory(
    String shopId,
    String customerId,
  ) async {
    final db = await database;
    return db.query(
      'udhari_transactions',
      where: 'shop_id = ? AND customer_id = ?',
      whereArgs: [shopId, customerId],
      orderBy: 'created_at DESC',
    );
  }

  Future<void> cacheCustomerList(
    String shopId,
    List<Map<String, dynamic>> rows,
  ) async {
    final db = await database;
    final batch = db.batch();
    for (final row in rows) {
      batch.insert(
        'udhari_customers_cache',
        {
          'customer_id': row['customer_id'],
          'shop_id': shopId,
          'name': row['name'],
          'phone': row['phone'],
          'balance': row['balance'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedCustomerList(
    String shopId,
  ) async {
    final db = await database;
    return db.query(
      'udhari_customers_cache',
      where: 'shop_id = ?',
      whereArgs: [shopId],
      orderBy: 'balance DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getPendingSyncTransactions() async {
    final db = await database;
    return db.query('udhari_transactions', where: 'pending_sync = 1');
  }

  Future<void> markSynced(String id) async {
    final db = await database;
    await db.update(
      'udhari_transactions',
      {'pending_sync': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

