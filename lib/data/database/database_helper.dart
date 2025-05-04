// filepath: /Users/janikkahle/Documents/Development/Projekte/Mobile/mcbroken_app/lib/data/database/database_helper.dart
import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mcbroken/data/models/mcdonalds_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'mcbroken.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE mcdonalds_locations(
        id TEXT PRIMARY KEY,
        latitude REAL,
        longitude REAL,
        is_broken INTEGER,
        is_active INTEGER,
        state TEXT,
        city TEXT,
        street TEXT,
        country TEXT,
        last_checked TEXT,
        last_synced TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_location ON mcdonalds_locations(latitude, longitude);
    ''');
    
    await db.execute('''
      CREATE INDEX idx_broken ON mcdonalds_locations(is_broken);
    ''');
  }

  // CRUD Operations
  
  // Insert a location
  Future<int> insertLocation(Map<String, dynamic> location) async {
    final db = await database;
    return await db.insert(
      'mcdonalds_locations',
      location,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  // Insert multiple locations in a transaction for better performance
  Future<void> insertLocations(List<Mcdonalds_model> locations) async {
    final db = await database;
    final batch = db.batch();
    
    for (var location in locations) {
      final Map<String, dynamic> row = {
        'id': '${location.geometry.coordinates[0]}_${location.geometry.coordinates[1]}',
        'latitude': location.geometry.coordinates[1], // In GeoJSON, format is [longitude, latitude]
        'longitude': location.geometry.coordinates[0],
        'is_broken': location.properties.is_broken ? 1 : 0,
        'is_active': location.properties.is_active ? 1 : 0,
        'state': location.properties.state,
        'city': location.properties.city,
        'street': location.properties.street,
        'country': location.properties.country,
        'last_checked': location.properties.last_checked,
        'last_synced': DateTime.now().toIso8601String(),
      };
      batch.insert(
        'mcdonalds_locations',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit();
  }
  
  // Query all locations
  Future<List<Map<String, dynamic>>> getLocations() async {
    final db = await database;
    return await db.query('mcdonalds_locations');
  }
  
  // Query locations within a specific area (for map viewport)
  Future<List<Map<String, dynamic>>> getLocationsInArea(
    double minLat, double maxLat, double minLng, double maxLng) async {
    final db = await database;
    return await db.query(
      'mcdonalds_locations',
      where: 'latitude >= ? AND latitude <= ? AND longitude >= ? AND longitude <= ?',
      whereArgs: [minLat, maxLat, minLng, maxLng],
    );
  }
  
  // Query locations with a specific filter
  Future<List<Map<String, dynamic>>> getFilteredLocations(bool? isBroken) async {
    final db = await database;
    if (isBroken != null) {
      return await db.query(
        'mcdonalds_locations',
        where: 'is_broken = ?',
        whereArgs: [isBroken ? 1 : 0],
      );
    }
    return await db.query('mcdonalds_locations');
  }
  
  // Get location by id
  Future<Map<String, dynamic>?> getLocationById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mcdonalds_locations',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }
  
  // Update a location
  Future<int> updateLocation(Map<String, dynamic> location) async {
    final db = await database;
    return await db.update(
      'mcdonalds_locations',
      location,
      where: 'id = ?',
      whereArgs: [location['id']],
    );
  }
  
  // Delete a location
  Future<int> deleteLocation(String id) async {
    final db = await database;
    return await db.delete(
      'mcdonalds_locations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Delete all locations
  Future<int> deleteAllLocations() async {
    final db = await database;
    return await db.delete('mcdonalds_locations');
  }
  
  // Check if database needs refresh (data is older than the specified duration)
  Future<bool> needsRefresh(Duration maxAge) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT last_synced FROM mcdonalds_locations 
      ORDER BY last_synced DESC LIMIT 1
    ''');
    
    if (result.isEmpty) return true;
    
    final lastSynced = DateTime.parse(result.first['last_synced'] as String);
    final now = DateTime.now();
    return now.difference(lastSynced) > maxAge;
  }
  
  // Convert database data to Mcdonalds_model objects
  Mcdonalds_model mapToModel(Map<String, dynamic> map) {
    bool isBroken = map['is_broken'] == 1;
    return Mcdonalds_model(
      geometry: Geometry(
        coordinates: [map['longitude'], map['latitude']],
        type: 'Point',
      ),
      properties: Properties(
        is_broken: isBroken,
        is_active: map['is_active'] == 1,
        dot: isBroken ? 'broken' : 'working',
        state: map['state'],
        city: map['city'],
        street: map['street'],
        country: map['country'],
        last_checked: map['last_checked'],
      ),
      type: 'Feature',
    );
  }
}
