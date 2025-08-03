import 'package:shared_preferences/shared_preferences.dart';
import 'package:mcbroken/services/database/database_service.dart';
import 'package:mcbroken/data/models/mcdonalds_location.dart';

/// Service zur Verwaltung von favorisierten McDonald's-Standorten
///
/// Diese Klasse bietet Funktionalität zum Speichern, Abrufen, Hinzufügen und Entfernen
/// von Standorten aus der Liste der Favoriten. Verwendet sowohl SQLite-Datenbank
/// als auch SharedPreferences für Backward-Kompatibilität.
class FavoritesService {
  /// Schlüssel für den Zugriff auf die Favoriten in den SharedPreferences
  static const String _favoritesKey = 'mcbroken_favorites';
  
  /// Shared Preferences Instanz für den Zugriff auf persistenten Speicher
  final SharedPreferences _preferences;
  
  /// Datenbank-Service für erweiterte Persistierung
  final DatabaseService _databaseService;
  
  /// Erstellt eine neue Instanz des FavoritesService
  ///
  /// [preferences] ist die SharedPreferences-Instanz, die für die Persistenz verwendet wird
  /// [databaseService] ist der Datenbank-Service für die SQLite-Persistierung
  FavoritesService(this._preferences, this._databaseService);
  
  /// Initialisiert den Service und migriert Daten falls nötig
  ///
  /// Lädt vorhandene Favoriten aus SharedPreferences und migriert sie zur Datenbank
  Future<void> init() async {
    await _databaseService.init();
    await _migrateFavoritesToDatabase();
  }
  
  /// Migriert Favoriten von SharedPreferences zur Datenbank
  ///
  /// Diese Methode wird nur einmal ausgeführt und stellt sicher,
  /// dass bestehende Favoriten nicht verloren gehen
  Future<void> _migrateFavoritesToDatabase() async {
    try {
      // Prüfen, ob Migration bereits erfolgt ist
      final migrated = _preferences.getBool('favorites_migrated') ?? false;
      if (migrated) return;
      
      // Alte Favoriten aus SharedPreferences laden
      final oldFavorites = _preferences.getStringList(_favoritesKey) ?? [];
      
      // Favoriten zur Datenbank hinzufügen
      for (final favoriteId in oldFavorites) {
        await _databaseService.addFavorite(favoriteId);
      }
      
      // Migration als abgeschlossen markieren
      await _preferences.setBool('favorites_migrated', true);
      
    } catch (e) {
      // Fehler stillschweigend ignorieren für Produktionsumgebung
    }
  }
  
  /// Lädt alle gespeicherten Favoriten
  ///
  /// Gibt eine Liste von Standort-IDs zurück, die als Favoriten markiert sind
  Future<List<String>> loadFavorites() async {
    try {
      return await _databaseService.getAllFavorites();
    } catch (e) {
      // Fehler stillschweigend ignorieren für Produktionsumgebung
      // Fallback zu SharedPreferences
      return _preferences.getStringList(_favoritesKey) ?? [];
    }
  }
  
  /// Speichert die Liste der Favoriten (deprecated - verwende addFavorite/removeFavorite)
  ///
  /// [favorites] ist die Liste der Standort-IDs, die als Favoriten gespeichert werden sollen
  ///
  /// Gibt true zurück, wenn das Speichern erfolgreich war, sonst false
  @Deprecated('Verwende addFavorite() und removeFavorite() für bessere Performance')
  Future<bool> saveFavorites(List<String> favorites) async {
    // Für Backward-Kompatibilität beibehalten
    return _preferences.setStringList(_favoritesKey, favorites);
  }
  
  /// Fügt einen Standort zu den Favoriten hinzu
  ///
  /// [locationId] ist die ID des Standorts, der zu den Favoriten hinzugefügt werden soll
  ///
  /// Gibt die aktualisierte Liste der Favoriten zurück
  Future<List<String>> addFavorite(String locationId) async {
    try {
      final success = await _databaseService.addFavorite(locationId);
      if (success) {
        return await loadFavorites();
      }
    } catch (e) {
      // Fehler stillschweigend ignorieren für Produktionsumgebung
    }
    
    // Fallback zu SharedPreferences
    final favorites = _preferences.getStringList(_favoritesKey) ?? [];
    if (!favorites.contains(locationId)) {
      favorites.add(locationId);
      await _preferences.setStringList(_favoritesKey, favorites);
    }
    return favorites;
  }
  
  /// Entfernt einen Standort aus den Favoriten
  ///
  /// [locationId] ist die ID des Standorts, der aus den Favoriten entfernt werden soll
  ///
  /// Gibt die aktualisierte Liste der Favoriten zurück
  Future<List<String>> removeFavorite(String locationId) async {
    try {
      final success = await _databaseService.removeFavorite(locationId);
      if (success) {
        return await loadFavorites();
      }
    } catch (e) {
      // Fehler stillschweigend ignorieren für Produktionsumgebung
    }
    
    // Fallback zu SharedPreferences
    final favorites = _preferences.getStringList(_favoritesKey) ?? [];
    favorites.remove(locationId);
    await _preferences.setStringList(_favoritesKey, favorites);
    return favorites;
  }
  
  /// Prüft, ob ein Standort als Favorit markiert ist
  ///
  /// [locationId] ist die ID des Standorts, dessen Favoritenstatus geprüft wird
  ///
  /// Gibt true zurück, wenn der Standort ein Favorit ist, sonst false
  Future<bool> isFavorite(String locationId) async {
    try {
      return await _databaseService.isFavorite(locationId);
    } catch (e) {
      // Fehler stillschweigend ignorieren für Produktionsumgebung
      // Fallback zu SharedPreferences
      final favorites = _preferences.getStringList(_favoritesKey) ?? [];
      return favorites.contains(locationId);
    }
  }
  
  /// Lädt alle McDonald's-Standorte, die als Favoriten markiert sind
  ///
  /// Gibt eine Liste von McDonald's-Standorten zurück, die als Favoriten markiert sind
  Future<List<McDonaldsLocation>> loadFavoriteLocations() async {
    try {
      return await _databaseService.getFavoriteLocations();
    } catch (e) {
      // Fehler stillschweigend ignorieren für Produktionsumgebung
      return [];
    }
  }
  
  /// Lädt alle McDonald's-Standorte, die als Favoriten markiert sind (deprecated)
  ///
  /// [allLocations] ist die Liste aller verfügbaren Standorte
  ///
  /// Gibt eine Liste von McDonald's-Standorten zurück, die als Favoriten markiert sind
  @Deprecated('Verwende loadFavoriteLocations() für bessere Performance')
  Future<List<T>> loadFavoriteLocationsOld<T>(
    List<T> allLocations, 
    String Function(T location) getLocationId
  ) async {
    final favorites = await loadFavorites();
    return allLocations
        .where((location) => favorites.contains(getLocationId(location)))
        .toList();
  }
}
