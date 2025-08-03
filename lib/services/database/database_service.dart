// filepath: /Users/janikkahle/Documents/Development/Projekte/Mobile/mcbroken_app/lib/services/database/database_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mcbroken/data/models/mcdonalds_location.dart';

/// Abstraktion für den Datenbankservice
///
/// Bietet eine einheitliche Schnittstelle für Datenbankoperationen,
/// unabhängig von der verwendeten Datenbanktechnologie.
abstract class DatabaseService {
  /// Initialisiert die Datenbank
  ///
  /// Diese Methode muss vor dem ersten Zugriff auf die Datenbank aufgerufen werden.
  Future<void> init();

  /// Speichert eine Liste von McDonald's-Standorten in der Datenbank
  ///
  /// [locations] ist die Liste der zu speichernden Standorte
  ///
  /// Gibt die Anzahl der gespeicherten Einträge zurück
  Future<int> saveLocations(List<McDonaldsLocation> locations);

  /// Holt alle McDonald's-Standorte aus der Datenbank
  ///
  /// Gibt eine Liste aller Standorte zurück
  Future<List<McDonaldsLocation>> getAllLocations();

  /// Holt McDonald's-Standorte innerhalb eines geografischen Bereichs
  ///
  /// [minLat], [maxLat], [minLng], [maxLng] definieren den geografischen Bereich
  ///
  /// Gibt eine Liste der Standorte innerhalb des angegebenen Bereichs zurück
  Future<List<McDonaldsLocation>> getLocationsInBounds(
    double minLat,
    double maxLat,
    double minLng,
    double maxLng,
  );

  /// Sucht nach McDonald's-Standorten anhand einer Adresse oder Stadt
  ///
  /// [query] ist der Suchbegriff
  ///
  /// Gibt eine Liste von Standorten zurück, die dem Suchbegriff entsprechen
  Future<List<McDonaldsLocation>> searchLocations(String query);

  /// Löscht alle Daten aus der Datenbank
  ///
  /// Gibt die Anzahl der gelöschten Einträge zurück
  Future<int> clearAllData();

  /// Speichert den Zeitpunkt der letzten Datenaktualisierung
  ///
  /// [timestamp] ist der zu speichernde Zeitstempel
  Future<void> saveLastUpdateTime(DateTime timestamp);

  /// Holt den Zeitpunkt der letzten Datenaktualisierung
  ///
  /// Gibt den gespeicherten Zeitstempel zurück oder null, wenn keiner vorhanden ist
  Future<DateTime?> getLastUpdateTime();

  /// Schließt die Datenbankverbindung
  ///
  /// Diese Methode sollte aufgerufen werden, wenn die Datenbank nicht mehr benötigt wird.
  Future<void> close();

  /// Fügt einen Standort zu den Favoriten hinzu
  ///
  /// [locationId] ist die eindeutige ID des Standorts
  ///
  /// Gibt true zurück, wenn das Hinzufügen erfolgreich war
  Future<bool> addFavorite(String locationId);

  /// Entfernt einen Standort aus den Favoriten
  ///
  /// [locationId] ist die eindeutige ID des Standorts
  ///
  /// Gibt true zurück, wenn das Entfernen erfolgreich war
  Future<bool> removeFavorite(String locationId);

  /// Holt alle favorisierten Standort-IDs
  ///
  /// Gibt eine Liste aller favorisierten Standort-IDs zurück
  Future<List<String>> getAllFavorites();

  /// Prüft, ob ein Standort als Favorit markiert ist
  ///
  /// [locationId] ist die eindeutige ID des Standorts
  ///
  /// Gibt true zurück, wenn der Standort favorisiert ist
  Future<bool> isFavorite(String locationId);

  /// Holt alle favorisierten McDonald's-Standorte
  ///
  /// Gibt eine Liste aller favorisierten Standorte zurück
  Future<List<McDonaldsLocation>> getFavoriteLocations();
}

/// Implementierung des [DatabaseService] mit SQLite
///
/// Diese Klasse verwendet die sqflite-Bibliothek für lokale Datenpersistenz.
class DatabaseServiceImpl implements DatabaseService {
  static const String _dbName = 'mcbroken_db.db';
  static const int _dbVersion = 1;
  
  static const String _tableLocations = 'locations';
  static const String _tableSettings = 'settings';
  static const String _tableFavorites = 'favorites';
  
  Database? _db;

  /// Initialisiert die SQLite-Datenbank
  ///
  /// Erstellt die Datenbank und die erforderlichen Tabellen, falls sie nicht existieren.
  @override
  Future<void> init() async {
    if (_db != null) return;
    
    final appDocDir = await getApplicationDocumentsDirectory();
    final dbPath = join(appDocDir.path, _dbName);
    
    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// Erstellt die erforderlichen Tabellen in der Datenbank
  Future<void> _createDB(Database db, int version) async {
    // Tabelle für McDonald's-Standorte
    await db.execute('''
      CREATE TABLE $_tableLocations (
        id TEXT PRIMARY KEY,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        is_broken INTEGER NOT NULL,
        is_active INTEGER NOT NULL,
        state TEXT,
        city TEXT,
        street TEXT,
        country TEXT,
        last_checked TEXT,
        json_data TEXT NOT NULL
      )
    ''');
    
    // Tabelle für Einstellungen
    await db.execute('''
      CREATE TABLE $_tableSettings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Tabelle für Favoriten
    await db.execute('''
      CREATE TABLE $_tableFavorites (
        location_id TEXT PRIMARY KEY,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Indizes für bessere Performance
    await db.execute('CREATE INDEX idx_locations_coords ON $_tableLocations(latitude, longitude)');
    await db.execute('CREATE INDEX idx_locations_broken ON $_tableLocations(is_broken)');
    await db.execute('CREATE INDEX idx_locations_city ON $_tableLocations(city)');
  }

  /// Aktualisiert die Datenbankstruktur bei einer Version-Änderung
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Hier können Migrationen hinzugefügt werden, wenn sich das Datenbankschema ändert
    // if (oldVersion < 2) {
    //   // Migration zu Version 2
    // }
  }

  /// Speichert eine Liste von McDonald's-Standorten in der Datenbank
  ///
  /// [locations] ist die Liste der zu speichernden Standorte
  ///
  /// Gibt die Anzahl der gespeicherten Einträge zurück
  @override
  Future<int> saveLocations(List<McDonaldsLocation> locations) async {
    if (_db == null) await init();
    
    final batch = _db!.batch();
    
    for (final location in locations) {
      try {
        final coordinates = location.geometry.coordinates;
      
        if (coordinates.length < 2) continue;
      
        // JSON in einen String umwandeln, damit SQLite ihn speichern kann
        final String jsonDataString = jsonEncode(location.toJson());
      
        batch.insert(
          _tableLocations,
          {
            'id': '${coordinates[0]}_${coordinates[1]}', // Eindeutige ID aus Koordinaten
            'latitude': coordinates[1],
            'longitude': coordinates[0],
            'is_broken': location.properties.isBroken ? 1 : 0,
            'is_active': location.properties.isActive ? 1 : 0,
            'state': location.properties.state,
            'city': location.properties.city,
            'street': location.properties.street,
            'country': location.properties.country,
            'last_checked': location.properties.lastChecked,
            'json_data': jsonDataString, // Als String gespeichert
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (e) {
        // Fehler stillschweigend ignorieren für Produktionsumgebung
        continue;
      }
    }
    
    final results = await batch.commit();
    return results.length;
  }

  /// Holt alle McDonald's-Standorte aus der Datenbank
  ///
  /// Gibt eine Liste aller Standorte zurück
  @override
  Future<List<McDonaldsLocation>> getAllLocations() async {
    if (_db == null) await init();
    
    final records = await _db!.query(_tableLocations);
    return _mapToLocations(records);
  }

  /// Holt McDonald's-Standorte innerhalb eines geografischen Bereichs
  ///
  /// [minLat], [maxLat], [minLng], [maxLng] definieren den geografischen Bereich
  ///
  /// Gibt eine Liste der Standorte innerhalb des angegebenen Bereichs zurück
  @override
  Future<List<McDonaldsLocation>> getLocationsInBounds(
    double minLat,
    double maxLat,
    double minLng,
    double maxLng,
  ) async {
    if (_db == null) await init();
    
    final records = await _db!.query(
      _tableLocations,
      where: 'latitude >= ? AND latitude <= ? AND longitude >= ? AND longitude <= ?',
      whereArgs: [minLat, maxLat, minLng, maxLng],
    );
    
    return _mapToLocations(records);
  }

  /// Sucht nach McDonald's-Standorten anhand einer Adresse oder Stadt
  ///
  /// [query] ist der Suchbegriff
  ///
  /// Gibt eine Liste von Standorten zurück, die dem Suchbegriff entsprechen
  @override
  Future<List<McDonaldsLocation>> searchLocations(String query) async {
    if (_db == null) await init();
    
    // Query in Kleinbuchstaben für case-insensitive Suche umwandeln
    final String normalizedQuery = query.toLowerCase().trim();
    
    // Spezifische Suchbegriffe für verschiedene Arten von Übereinstimmungen
    final exactTerm = normalizedQuery;
    final startsTerm = '$normalizedQuery%';
    final containsTerm = '%$normalizedQuery%';
    
    // Optimierte SQL-Abfrage mit Gewichtung der Treffer
    final records = await _db!.rawQuery('''
      SELECT * FROM $_tableLocations 
      WHERE 
        LOWER(city) LIKE ? OR 
        LOWER(street) LIKE ? OR 
        LOWER(state) LIKE ? OR 
        LOWER(country) LIKE ?
      ORDER BY
        CASE 
          WHEN LOWER(city) = ? THEN 1
          WHEN LOWER(street) = ? THEN 2
          WHEN LOWER(city) LIKE ? THEN 3
          WHEN LOWER(street) LIKE ? THEN 4
          WHEN LOWER(state) = ? THEN 5
          WHEN LOWER(country) = ? THEN 6
          ELSE 7
        END,
        LENGTH(city) ASC
      LIMIT 50
    ''', [
      containsTerm, containsTerm, containsTerm, containsTerm,  // WHERE-Bedingungen
      exactTerm, exactTerm, startsTerm, startsTerm, exactTerm, exactTerm  // ORDER BY-Bedingungen
    ]);
    
    return _mapToLocations(records);
  }

  /// Löscht alle Daten aus der Datenbank
  ///
  /// Gibt die Anzahl der gelöschten Einträge zurück
  @override
  Future<int> clearAllData() async {
    if (_db == null) await init();
    
    return await _db!.delete(_tableLocations);
  }

  /// Speichert den Zeitpunkt der letzten Datenaktualisierung
  ///
  /// [timestamp] ist der zu speichernde Zeitstempel
  @override
  Future<void> saveLastUpdateTime(DateTime timestamp) async {
    if (_db == null) await init();
    
    await _db!.insert(
      _tableSettings,
      {
        'key': 'last_update_time',
        'value': timestamp.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Holt den Zeitpunkt der letzten Datenaktualisierung
  ///
  /// Gibt den gespeicherten Zeitstempel zurück oder null, wenn keiner vorhanden ist
  @override
  Future<DateTime?> getLastUpdateTime() async {
    if (_db == null) await init();
    
    final records = await _db!.query(
      _tableSettings,
      where: 'key = ?',
      whereArgs: ['last_update_time'],
    );
    
    if (records.isEmpty) return null;
    
    final timeString = records.first['value'] as String;
    return DateTime.tryParse(timeString);
  }

  /// Schließt die Datenbankverbindung
  ///
  /// Diese Methode sollte aufgerufen werden, wenn die Datenbank nicht mehr benötigt wird.
  @override
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  /// Fügt einen Standort zu den Favoriten hinzu
  ///
  /// [locationId] ist die eindeutige ID des Standorts
  ///
  /// Gibt true zurück, wenn das Hinzufügen erfolgreich war
  @override
  Future<bool> addFavorite(String locationId) async {
    if (_db == null) await init();
    
    try {
      await _db!.insert(
        _tableFavorites,
        {
          'location_id': locationId,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      return true;
    } catch (e) {
      // Fehler stillschweigend ignorieren für Produktionsumgebung
      return false;
    }
  }

  /// Entfernt einen Standort aus den Favoriten
  ///
  /// [locationId] ist die eindeutige ID des Standorts
  ///
  /// Gibt true zurück, wenn das Entfernen erfolgreich war
  @override
  Future<bool> removeFavorite(String locationId) async {
    if (_db == null) await init();
    
    try {
      final rowsAffected = await _db!.delete(
        _tableFavorites,
        where: 'location_id = ?',
        whereArgs: [locationId],
      );
      return rowsAffected > 0;
    } catch (e) {
      // Fehler stillschweigend ignorieren für Produktionsumgebung
      return false;
    }
  }

  /// Holt alle favorisierten Standort-IDs
  ///
  /// Gibt eine Liste aller favorisierten Standort-IDs zurück
  @override
  Future<List<String>> getAllFavorites() async {
    if (_db == null) await init();
    
    try {
      final records = await _db!.query(
        _tableFavorites,
        columns: ['location_id'],
        orderBy: 'created_at DESC',
      );
      
      return records.map((record) => record['location_id'] as String).toList();
    } catch (e) {
      // Fehler stillschweigend ignorieren für Produktionsumgebung
      return [];
    }
  }

  /// Prüft, ob ein Standort als Favorit markiert ist
  ///
  /// [locationId] ist die eindeutige ID des Standorts
  ///
  /// Gibt true zurück, wenn der Standort favorisiert ist
  @override
  Future<bool> isFavorite(String locationId) async {
    if (_db == null) await init();
    
    try {
      final records = await _db!.query(
        _tableFavorites,
        where: 'location_id = ?',
        whereArgs: [locationId],
        limit: 1,
      );
      
      return records.isNotEmpty;
    } catch (e) {
      // Fehler stillschweigend ignorieren für Produktionsumgebung
      return false;
    }
  }

  /// Holt alle favorisierten McDonald's-Standorte
  ///
  /// Gibt eine Liste aller favorisierten Standorte zurück
  @override
  Future<List<McDonaldsLocation>> getFavoriteLocations() async {
    if (_db == null) await init();
    
    try {
      final records = await _db!.rawQuery('''
        SELECT l.* FROM $_tableLocations l
        INNER JOIN $_tableFavorites f ON l.id = f.location_id
        ORDER BY f.created_at DESC
      ''');
      
      return _mapToLocations(records);
    } catch (e) {
      // Fehler stillschweigend ignorieren für Produktionsumgebung
      return [];
    }
  }
  
  /// Konvertiert Datenbankeinträge in [McDonaldsLocation]-Objekte
  ///
  /// [records] ist eine Liste von Datenbankeinträgen
  ///
  /// Gibt eine Liste von [McDonaldsLocation]-Objekten zurück
  List<McDonaldsLocation> _mapToLocations(List<Map<String, dynamic>> records) {
    return records.map((record) {
      try {
        // JSON-String aus der Datenbank parsen
        final jsonString = record['json_data'] as String;
        final jsonData = jsonDecode(jsonString);
        
        // McDonaldsLocation aus dem geparsten JSON erstellen
        return McDonaldsLocation.fromJson(jsonData);
      } catch (e) {
        // Fehler stillschweigend ignorieren für Produktionsumgebung
        
        // Fallback: Manuelle Erstellung des Objekts aus den Einzelfeldern
        try {
          final double lat = record['latitude'] as double;
          final double lng = record['longitude'] as double;
          final bool isBroken = (record['is_broken'] as int) == 1;
          final bool isActive = (record['is_active'] as int) == 1;
          final String state = record['state'] as String;
          final String city = record['city'] as String;
          final String street = record['street'] as String;
          final String country = record['country'] as String;
          final String lastChecked = record['last_checked'] as String;
          
          return McDonaldsLocation(
            geometry: Geometry(
              coordinates: [lng, lat],
              type: 'Point',
            ),
            properties: McProperties(
              isBroken: isBroken,
              isActive: isActive,
              dot: isBroken ? 'broken' : 'working',
              state: state,
              city: city,
              street: street,
              country: country,
              lastChecked: lastChecked,
            ),
            type: 'Feature',
          );
        } catch (fallbackError) {
          // Fehler stillschweigend ignorieren für Produktionsumgebung
          return null;
        }
      }
    }).whereType<McDonaldsLocation>().toList();
  }
}
