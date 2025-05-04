// filepath: /Users/janikkahle/Documents/Development/Projekte/Mobile/mcbroken_app/lib/data/repository/mcdonalds_repository.dart
import 'dart:async';
import 'dart:convert';
import 'package:mcbroken/data/models/mcdonalds_location.dart';
import 'package:mcbroken/services/api/api_client.dart';
import 'package:mcbroken/services/api/api_error_handler.dart';
import 'package:mcbroken/services/database/database_service.dart';
import 'package:mcbroken/services/network/network_info.dart';

/// Abstraktion für das McDonald's-Repository
///
/// Bietet eine einheitliche Schnittstelle für den Zugriff auf McDonald's-Standortdaten,
/// unabhängig von der Datenquelle (API oder lokale Datenbank).
abstract class McDonaldsRepository {
  /// Holt alle McDonald's-Standorte
  ///
  /// [forceRefresh] erzwingt eine Aktualisierung der Daten von der API, falls true
  ///
  /// Gibt eine Liste aller McDonald's-Standorte zurück
  Future<List<McDonaldsLocation>> getAllLocations({bool forceRefresh = false});

  /// Holt McDonald's-Standorte innerhalb eines geografischen Bereichs
  ///
  /// [minLat], [maxLat], [minLng], [maxLng] definieren den geografischen Bereich
  /// [forceRefresh] erzwingt eine Aktualisierung der Daten von der API, falls true
  ///
  /// Gibt eine Liste der Standorte innerhalb des angegebenen Bereichs zurück
  Future<List<McDonaldsLocation>> getLocationsInBounds(
    double minLat,
    double maxLat,
    double minLng,
    double maxLng, {
    bool forceRefresh = false,
  });

  /// Sucht nach McDonald's-Standorten anhand einer Adresse oder Stadt
  ///
  /// [query] ist der Suchbegriff
  ///
  /// Gibt eine Liste von Standorten zurück, die dem Suchbegriff entsprechen
  Future<List<McDonaldsLocation>> searchLocations(String query);

  /// Aktualisiert die lokalen Daten mit den neuesten Daten von der API
  ///
  /// Gibt die Anzahl der aktualisierten Standorte zurück
  Future<int> refreshData();

  /// Gibt den Zeitpunkt der letzten Datenaktualisierung zurück
  ///
  /// Gibt den Zeitstempel der letzten Aktualisierung zurück oder null, wenn noch nie aktualisiert
  Future<DateTime?> getLastUpdateTime();
}

/// Implementierung des [McDonaldsRepository]
///
/// Diese Klasse verbindet die Daten aus der API und der lokalen Datenbank
/// und bietet eine einheitliche Schnittstelle für den Zugriff auf McDonald's-Standortdaten.
class McDonaldsRepositoryImpl implements McDonaldsRepository {
  static const String _apiUrl = 'https://raw.githubusercontent.com/rashiq/mcbroken-archive/main/mcbroken.json';

  final ApiClient apiClient;
  final DatabaseService databaseService;
  final NetworkInfo networkInfo;

  /// Zeitraum, nach dem die Daten als veraltet gelten (6 Stunden)
  final Duration _dataExpirationPeriod = const Duration(hours: 6);

  /// Erstellt eine neue Instanz von [McDonaldsRepositoryImpl]
  ///
  /// [apiClient] ist der HTTP-Client für API-Anfragen
  /// [databaseService] ist der Service für lokale Datenpersistenz
  /// [networkInfo] ist der Service für Netzwerkprüfungen
  McDonaldsRepositoryImpl({
    required this.apiClient,
    required this.databaseService,
    required this.networkInfo,
  });

  /// Holt alle McDonald's-Standorte
  ///
  /// [forceRefresh] erzwingt eine Aktualisierung der Daten von der API, falls true
  ///
  /// Gibt eine Liste aller McDonald's-Standorte zurück
  @override
  Future<List<McDonaldsLocation>> getAllLocations({bool forceRefresh = false}) async {
    // Prüfen, ob Daten aktualisiert werden müssen
    if (forceRefresh || await _shouldRefreshData()) {
      try {
        await refreshData();
      } catch (e) {
        // Fehler beim Aktualisieren der Daten, verwende lokale Daten
        print('Fehler beim Aktualisieren der Daten: $e');
      }
    }
    
    // Daten aus der lokalen Datenbank laden
    return await databaseService.getAllLocations();
  }

  /// Holt McDonald's-Standorte innerhalb eines geografischen Bereichs
  ///
  /// [minLat], [maxLat], [minLng], [maxLng] definieren den geografischen Bereich
  /// [forceRefresh] erzwingt eine Aktualisierung der Daten von der API, falls true
  ///
  /// Gibt eine Liste der Standorte innerhalb des angegebenen Bereichs zurück
  @override
  Future<List<McDonaldsLocation>> getLocationsInBounds(
    double minLat,
    double maxLat,
    double minLng,
    double maxLng, {
    bool forceRefresh = false,
  }) async {
    // Prüfen, ob Daten aktualisiert werden müssen
    if (forceRefresh || await _shouldRefreshData()) {
      try {
        await refreshData();
      } catch (e) {
        // Fehler beim Aktualisieren der Daten, verwende lokale Daten
        print('Fehler beim Aktualisieren der Daten: $e');
      }
    }
    
    // Daten aus der lokalen Datenbank laden
    return await databaseService.getLocationsInBounds(
      minLat,
      maxLat,
      minLng,
      maxLng,
    );
  }

  /// Sucht nach McDonald's-Standorten anhand einer Adresse oder Stadt
  ///
  /// [query] ist der Suchbegriff
  ///
  /// Gibt eine Liste von Standorten zurück, die dem Suchbegriff entsprechen
  @override
  Future<List<McDonaldsLocation>> searchLocations(String query) async {
    // Stellt sicher, dass aktuelle Daten vorhanden sind
    if (await _shouldRefreshData()) {
      try {
        await refreshData();
      } catch (e) {
        // Fehler beim Aktualisieren der Daten, verwende lokale Daten
        print('Fehler beim Aktualisieren der Daten: $e');
      }
    }
    
    // Daten aus der lokalen Datenbank suchen
    return await databaseService.searchLocations(query);
  }

  /// Aktualisiert die lokalen Daten mit den neuesten Daten von der API
  ///
  /// Ruft die neuesten Daten von der McBroken API ab und speichert sie lokal in der Datenbank.
  /// Die Methode verarbeitet verschiedene mögliche API-Antwortformate und wandelt die Rohdaten
  /// in McDonaldsLocation-Objekte um.
  ///
  /// Gibt die Anzahl der erfolgreich aktualisierten Standorte zurück
  /// 
  /// Wirft eine [ApiException], wenn keine Internetverbindung besteht oder
  /// wenn bei der Verarbeitung der API-Antwort Fehler auftreten.
  @override
  Future<int> refreshData() async {
    // Prüfen, ob eine Internetverbindung besteht
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      throw ApiException(
        message: 'Keine Internetverbindung. Daten können nicht aktualisiert werden.',
      );
    }
    
    // Daten von der API holen
    try {
      final responseData = await apiClient.get(_apiUrl);
      
      // JSON-Daten verarbeiten - flexibel für verschiedene API-Antwortformate
      List<McDonaldsLocation> locations = [];
      
      // Konvertiere String-Antwort zu JSON, falls nötig
      dynamic jsonData = responseData is String ? json.decode(responseData) : responseData;
      
      // Fallunterscheidung basierend auf dem Datenformat der API-Antwort
      if (jsonData is List) {
        // Wenn die API direkt eine Liste von Standorten liefert
        locations = _safelyParseLocationList(jsonData);
      } else if (jsonData is Map<String, dynamic>) {
        // Wenn die API eine Map mit einem 'features'-Array liefert
        if (jsonData.containsKey('features')) {
          final List<dynamic> features = jsonData['features'];
          locations = _safelyParseLocationList(features);
        } else {
          // Versuchen, die Map direkt als einzelnen Standort zu parsen
          try {
            // Koordinaten sicher konvertieren, falls sie als Strings vorliegen
            final location = _safelyParseLocation(jsonData);
            locations = [location];
          } catch (e) {
            throw ApiException(
              message: 'Unerwartetes API-Antwortformat: ${e.toString()}',
              originalError: e,
            );
          }
        }
      } else {
        throw ApiException(
          message: 'Unbekanntes API-Antwortformat: ${jsonData.runtimeType}',
        );
      }
      
      // Daten in der lokalen Datenbank speichern
      final savedCount = await databaseService.saveLocations(locations);
      
      // Aktualisierungszeitstempel speichern
      await databaseService.saveLastUpdateTime(DateTime.now());
      
      return savedCount;
    } catch (e) {
      throw ApiException(
        message: 'Fehler beim Aktualisieren der Daten: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Gibt den Zeitpunkt der letzten Datenaktualisierung zurück
  ///
  /// Gibt den Zeitstempel der letzten Aktualisierung zurück oder null, wenn noch nie aktualisiert
  @override
  Future<DateTime?> getLastUpdateTime() async {
    return await databaseService.getLastUpdateTime();
  }

  /// Prüft, ob die Daten aktualisiert werden sollten
  ///
  /// Analysiert den Zeitpunkt der letzten Aktualisierung und entscheidet,
  /// ob eine neue Aktualisierung erforderlich ist.
  ///
  /// Gibt true zurück, wenn die Daten aktualisiert werden sollten, sonst false
  Future<bool> _shouldRefreshData() async {
    final lastUpdateTime = await databaseService.getLastUpdateTime();
    
    // Wenn noch nie aktualisiert wurde, aktualisiere jetzt
    if (lastUpdateTime == null) {
      return true;
    }
    
    // Wenn die letzte Aktualisierung zu lange her ist, aktualisiere
    final now = DateTime.now();
    final difference = now.difference(lastUpdateTime);
    return difference > _dataExpirationPeriod;
  }
  
  /// Verarbeitet eine Liste von Location-Daten sicher und wandelt sie in McDonaldsLocation-Objekte um
  ///
  /// Diese Methode handhabt Fehler bei der Konvertierung und gibt eine leere Liste zurück,
  /// falls Probleme auftreten.
  ///
  /// [rawLocations] ist die unverarbeitete Liste von API-Daten
  ///
  /// Gibt eine Liste von [McDonaldsLocation]-Objekten zurück
  List<McDonaldsLocation> _safelyParseLocationList(List<dynamic> rawLocations) {
    final List<McDonaldsLocation> results = [];
    
    for (var item in rawLocations) {
      try {
        if (item is Map<String, dynamic>) {
          // Verarbeite die Location mit Typkonvertierung
          final location = _safelyParseLocation(item);
          results.add(location);
        }
      } catch (e) {
        print('Fehler beim Parsen eines Standorts: $e');
        // Überspringe den fehlerhaften Eintrag, fange aber nicht den gesamten Prozess ab
        continue;
      }
    }
    
    return results;
  }
  
  /// Verarbeitet ein einzelnes Location-Objekt sicher
  ///
  /// Stellt sicher, dass die Koordinaten korrekt als numerische Werte verarbeitet werden,
  /// auch wenn sie als Strings in der API-Antwort vorliegen.
  /// Handhabt außerdem null-Werte für Eigenschaften wie state, city, street etc.
  ///
  /// [rawLocation] ist die unverarbeitete Map mit Standortdaten aus der API
  ///
  /// Gibt ein korrekt konvertiertes [McDonaldsLocation]-Objekt zurück
  McDonaldsLocation _safelyParseLocation(Map<String, dynamic> rawLocation) {
    // Sicherstellen, dass die Geometry-Map korrekt gehandhabt wird
    if (rawLocation.containsKey('geometry')) {
      Map<String, dynamic> geometryMap = rawLocation['geometry'];
      
      // Koordinaten sichern
      if (geometryMap.containsKey('coordinates')) {
        List<dynamic> rawCoordinates = geometryMap['coordinates'];
        
        // Konvertiere die Koordinaten sicher zu double
        List<double> safeCoordinates = [];
        
        for (var coord in rawCoordinates) {
          if (coord is String) {
            // Wenn die Koordinate als String vorliegt, konvertieren
            try {
              safeCoordinates.add(double.parse(coord));
            } catch (e) {
              print('Fehler beim Parsen der Koordinate "$coord": $e');
              safeCoordinates.add(0.0); // Fallback-Wert
            }
          } else if (coord is double) {
            safeCoordinates.add(coord);
          } else if (coord is int) {
            safeCoordinates.add(coord.toDouble());
          } else {
            print('Unbekannter Koordinatentyp: ${coord.runtimeType}');
            safeCoordinates.add(0.0); // Fallback-Wert
          }
        }
        
        // Aktualisierte Koordinaten zurück in die Map schreiben
        geometryMap['coordinates'] = safeCoordinates;
        rawLocation['geometry'] = geometryMap;
      }
    }
    
    // Auch die Properties überprüfen und null-Werte ersetzen
    if (rawLocation.containsKey('properties')) {
      Map<String, dynamic> propertiesMap = rawLocation['properties'] as Map<String, dynamic>;
      
      // Sicherstellen, dass alle erforderlichen String-Eigenschaften vorhanden sind
      final stringProperties = ['state', 'city', 'street', 'country', 'last_checked', 'dot'];
      for (var prop in stringProperties) {
        if (propertiesMap[prop] == null) {
          propertiesMap[prop] = ''; // Leerer String als Fallback
        }
      }
      
      // Sicherstellen, dass Boolean-Eigenschaften korrekt sind
      if (propertiesMap['is_broken'] == null) {
        propertiesMap['is_broken'] = false;
      }
      if (propertiesMap['is_active'] == null) {
        propertiesMap['is_active'] = true;
      }
      
      rawLocation['properties'] = propertiesMap;
    }
    
    // Jetzt sollte die Map sicher sein für die JSON-Deserialisierung
    try {
      return McDonaldsLocation.fromJson(rawLocation);
    } catch (e) {
      print('Fehler bei der Deserialisierung des Standorts: $e');
      
      // Fallback: Ein minimales Objekt zurückgeben
      return McDonaldsLocation(
        geometry: Geometry(coordinates: [0.0, 0.0], type: 'Point'),
        properties: McProperties(
          isBroken: false,
          isActive: true,
          dot: 'unknown',
          state: '',
          city: '',
          street: '',
          country: '',
          lastChecked: '',
        ),
        type: 'Feature'
      );
    }
  }
}
