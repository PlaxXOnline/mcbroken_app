import 'dart:convert';
import 'dart:isolate';
import 'dart:developer';
import 'dart:math' as math;

import 'package:mcbroken/data/models/mcdonalds_model.dart';
import 'package:mcbroken/data/provider/mcdonalds.provider.dart';
import 'package:mcbroken/data/database/database_helper.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class McDonaldsRepository {
  final McDonaldsDataProvider mcDonaldsDataProvider = McDonaldsDataProvider();
  final DatabaseHelper databaseHelper = DatabaseHelper();

  // Die Standard-Cache-Dauer beträgt 1 Stunde
  static const Duration defaultCacheDuration = Duration(hours: 1);
  
  // Methode zum Abrufen von Daten mit Caching-Strategie
  Future<List<Mcdonalds_model>> getDataFromMcDonalds({
    bool forceRefresh = false,
    LatLng? viewportCenter,
    double? viewportRadius,
  }) async {
    // Überprüfen, ob ein Refresh erforderlich ist
    bool needsRefresh = forceRefresh;
    
    if (!needsRefresh) {
      needsRefresh = await databaseHelper.needsRefresh(defaultCacheDuration);
    }

    List<Mcdonalds_model> mcDonaldsData = [];
    
    try {
      if (needsRefresh) {
        // Daten vom Server laden
        log('Lade Daten vom Server...');
        mcDonaldsData = await _fetchDataFromRemote();
        
        // In der Datenbank speichern
        await databaseHelper.deleteAllLocations();
        await databaseHelper.insertLocations(mcDonaldsData);
        
        // Zeitstempel der letzten Aktualisierung speichern
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_data_refresh', DateTime.now().toIso8601String());
      } else {
        // Daten aus der Datenbank laden
        log('Lade Daten aus der Datenbank...');
        
        if (viewportCenter != null && viewportRadius != null) {
          // Lade nur Standorte im sichtbaren Bereich
          final boundingBox = _calculateBoundingBox(viewportCenter, viewportRadius);
          mcDonaldsData = await _fetchDataFromLocalByViewport(
            boundingBox[0], boundingBox[1], boundingBox[2], boundingBox[3]
          );
        } else {
          // Lade alle gespeicherten Standorte
          mcDonaldsData = await _fetchDataFromLocal();
        }
      }
    } catch (e) {
      log('Fehler beim Laden der Daten: $e');
      // Bei Fehlern versuchen wir, aus dem lokalen Cache zu laden
      mcDonaldsData = await _fetchDataFromLocal();
    }

    return mcDonaldsData;
  }

  // Daten vom Remote-Server abrufen und in einem isolate parsen
  Future<List<Mcdonalds_model>> _fetchDataFromRemote() async {
    final rawData = await mcDonaldsDataProvider.fetchData();
    
    // Verwende einen Isolate für CPU-intensive JSON-Parsing
    return await _parseInIsolate(rawData);
  }
  
  // Daten aus der lokalen Datenbank abrufen
  Future<List<Mcdonalds_model>> _fetchDataFromLocal() async {
    final locations = await databaseHelper.getLocations();
    return locations.map((location) => databaseHelper.mapToModel(location)).toList();
  }
  
  // Daten aus der lokalen Datenbank basierend auf dem Viewport abrufen
  Future<List<Mcdonalds_model>> _fetchDataFromLocalByViewport(
      double minLat, double maxLat, double minLng, double maxLng) async {
    final locations = await databaseHelper.getLocationsInArea(minLat, maxLat, minLng, maxLng);
    return locations.map((location) => databaseHelper.mapToModel(location)).toList();
  }
  
  // JSON-Parsing in einem separaten Isolate für bessere Performance
  Future<List<Mcdonalds_model>> _parseInIsolate(String jsonStr) async {
    final ReceivePort receivePort = ReceivePort();
    await Isolate.spawn(_parseJson, [receivePort.sendPort, jsonStr]);
    
    // Warten auf das Ergebnis vom Isolate
    final List<dynamic> parsedJson = await receivePort.first;
    
    // Konvertieren der geparsten JSON-Daten in Modelobjekte
    return parsedJson.map((item) => Mcdonalds_model.fromMap(item)).toList();
  }
  
  // Hilfsfunktion für den Isolate
  static void _parseJson(List<dynamic> args) {
    final SendPort sendPort = args[0];
    final String jsonStr = args[1];
    
    // Parse JSON im Isolate
    final parsedData = json.decode(jsonStr);
    
    // Ergebnisse zurücksenden
    Isolate.exit(sendPort, parsedData);
  }
  
  // Berechnet die Bounding Box für eine gegebene Mitte und einen Radius
  List<double> _calculateBoundingBox(LatLng center, double radiusKm) {
    const double earthRadiusKm = 6371.0;
    final double latRadians = center.latitude * (pi / 180);
    
    final double latDelta = (radiusKm / earthRadiusKm) * (180 / pi);
    final double lonDelta = (radiusKm / earthRadiusKm) * (180 / pi) / math.cos(latRadians);
    
    final double minLat = center.latitude - latDelta;
    final double maxLat = center.latitude + latDelta;
    final double minLng = center.longitude - lonDelta;
    final double maxLng = center.longitude + lonDelta;
    
    return [minLat, maxLat, minLng, maxLng];
  }
}
