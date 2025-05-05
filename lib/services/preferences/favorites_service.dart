import 'package:shared_preferences/shared_preferences.dart';

/// Service zur Verwaltung von favorisierten McDonald's-Standorten
///
/// Diese Klasse bietet Funktionalität zum Speichern, Abrufen, Hinzufügen und Entfernen
/// von Standorten aus der Liste der Favoriten.
class FavoritesService {
  /// Schlüssel für den Zugriff auf die Favoriten in den SharedPreferences
  static const String _favoritesKey = 'mcbroken_favorites';
  
  /// Shared Preferences Instanz für den Zugriff auf persistenten Speicher
  final SharedPreferences _preferences;
  
  /// Erstellt eine neue Instanz des FavoritesService
  ///
  /// [preferences] ist die SharedPreferences-Instanz, die für die Persistenz verwendet wird
  FavoritesService(this._preferences);
  
  /// Lädt alle gespeicherten Favoriten
  ///
  /// Gibt eine Liste von Standort-IDs zurück, die als Favoriten markiert sind
  Future<List<String>> loadFavorites() async {
    return _preferences.getStringList(_favoritesKey) ?? [];
  }
  
  /// Speichert die Liste der Favoriten
  ///
  /// [favorites] ist die Liste der Standort-IDs, die als Favoriten gespeichert werden sollen
  ///
  /// Gibt true zurück, wenn das Speichern erfolgreich war, sonst false
  Future<bool> saveFavorites(List<String> favorites) async {
    return _preferences.setStringList(_favoritesKey, favorites);
  }
  
  /// Fügt einen Standort zu den Favoriten hinzu
  ///
  /// [locationId] ist die ID des Standorts, der zu den Favoriten hinzugefügt werden soll
  ///
  /// Gibt die aktualisierte Liste der Favoriten zurück
  Future<List<String>> addFavorite(String locationId) async {
    final favorites = await loadFavorites();
    if (!favorites.contains(locationId)) {
      favorites.add(locationId);
      await saveFavorites(favorites);
    }
    return favorites;
  }
  
  /// Entfernt einen Standort aus den Favoriten
  ///
  /// [locationId] ist die ID des Standorts, der aus den Favoriten entfernt werden soll
  ///
  /// Gibt die aktualisierte Liste der Favoriten zurück
  Future<List<String>> removeFavorite(String locationId) async {
    final favorites = await loadFavorites();
    favorites.remove(locationId);
    await saveFavorites(favorites);
    return favorites;
  }
  
  /// Prüft, ob ein Standort als Favorit markiert ist
  ///
  /// [locationId] ist die ID des Standorts, dessen Favoritenstatus geprüft wird
  ///
  /// Gibt true zurück, wenn der Standort ein Favorit ist, sonst false
  Future<bool> isFavorite(String locationId) async {
    final favorites = await loadFavorites();
    return favorites.contains(locationId);
  }
  
  /// Lädt alle McDonald's-Standorte, die als Favoriten markiert sind
  ///
  /// [allLocations] ist die Liste aller verfügbaren Standorte
  ///
  /// Gibt eine Liste von McDonald's-Standorten zurück, die als Favoriten markiert sind
  Future<List<T>> loadFavoriteLocations<T>(
    List<T> allLocations, 
    String Function(T location) getLocationId
  ) async {
    final favorites = await loadFavorites();
    return allLocations
        .where((location) => favorites.contains(getLocationId(location)))
        .toList();
  }
}
