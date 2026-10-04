import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/favorite_route.dart';

class RouteDatabase {
  RouteDatabase._();

  static final RouteDatabase instance = RouteDatabase._();

  Database? _database;

  Future<Database> get database async {
    return _database ??= await _createDatabase();
  }

  Future<Database> _createDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'favorite_routes.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE favorite_routes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            startText TEXT NOT NULL,
            endText TEXT NOT NULL,
            startLat REAL NOT NULL,
            startLng REAL NOT NULL,
            endLat REAL NOT NULL,
            endLng REAL NOT NULL,
            mode TEXT NOT NULL,
            distance TEXT NOT NULL,
            duration TEXT NOT NULL,
            encodedPolyline TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertRoute(FavoriteRoute route) async {
    final db = await database;

    final data = route.toMap();
    data.remove('id');

    return db.insert('favorite_routes', data);
  }

  Future<List<FavoriteRoute>> getRoutes() async {
    final db = await database;

    final result = await db.query(
      'favorite_routes',
      orderBy: 'id DESC',
    );

    return result.map(FavoriteRoute.fromMap).toList();
  }

  Future<void> deleteRoute(int id) async {
    final db = await database;

    await db.delete(
      'favorite_routes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}