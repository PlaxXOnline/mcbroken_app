// filepath: /Users/janikkahle/Documents/Development/Projekte/Mobile/mcbroken_app/lib/services/background_service.dart
import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:mcbroken/core/di/injection_container.dart';
import 'package:mcbroken/data/repository/mcdonalds_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service zum Ausführen von Hintergrundaktualisierungen der McDonald's-Daten
///
/// Dieser Service aktualisiert die Daten regelmäßig im Hintergrund,
/// auch wenn die App nicht aktiv ist.
@pragma('vm:entry-point')
class BackgroundDataService {
  /// Schlüssel zum Speichern des Zeitpunkts der letzten Synchronisierung
  static const String _lastSyncKey = 'last_background_sync';
  
  /// Standardintervall für Aktualisierungen, falls keine Einstellung vorhanden ist
  static const Duration _defaultRefreshInterval = Duration(hours: 1);
  
  /// Initialisiert den Hintergrund-Service
  ///
  /// Konfiguriert den Service für Android und iOS mit den entsprechenden
  /// Einstellungen und Callback-Funktionen.
  ///
  /// Diese Methode sollte vor dem Start der App aufgerufen werden.
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();
    
    // Service konfigurieren
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: true,
        isForegroundMode: false,
        notificationChannelId: 'mcbroken_channel',
        initialNotificationTitle: 'McBroken App',
        initialNotificationContent: 'Aktualisiere McDonalds-Daten',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }
  
  /// Callback für iOS-Hintergrunddienste
  ///
  /// Diese Methode wird auf iOS-Geräten aufgerufen, wenn der Dienst
  /// im Hintergrund ausgeführt wird.
  ///
  /// [service] Die Service-Instanz
  ///
  /// Gibt `true` zurück, wenn der Service erfolgreich initialisiert wurde
  @pragma('vm:entry-point')
  static bool _onIosBackground(ServiceInstance service) {
    WidgetsFlutterBinding.ensureInitialized();
    log('iOS Hintergrunddienst gestartet');
    _onStart(service);
    return true;
  }
  
  /// Hauptlogik des Hintergrunddienstes
  ///
  /// Diese Methode wird aufgerufen, wenn der Dienst gestartet wird.
  /// Sie richtet Timer und Event-Listener ein und startet die periodischen
  /// Datenaktualisierungen.
  ///
  /// [service] Die Service-Instanz
  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    // Plugin-Registrierung sicherstellen
    DartPluginRegistrant.ensureInitialized();
    
    // Für Android als Foreground-Service markieren
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }
    
    log('Hintergrunddienst gestartet');
    
    // Dependency Injection initialisieren
    await initDependencies();
    
    // Timer für regelmäßige Aktualisierungen
    Timer.periodic(
      const Duration(minutes: 15), // Überprüfe alle 15 Minuten
      (timer) async {
        await _checkAndRefreshData(service);
      },
    );
    
    // Service-Ereignisse empfangen
    service.on('forceRefresh').listen((event) async {
      await _forceRefreshData(service);
    });
    
    service.on('updateRefreshInterval').listen((event) async {
      if (event != null && event['interval'] != null) {
        final int minutes = event['interval'];
        log('Aktualisierungsintervall auf $minutes Minuten gesetzt');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('refresh_interval_minutes', minutes);
      }
    });
  }
  
  /// Überprüft, ob eine Aktualisierung erforderlich ist und führt sie durch
  ///
  /// Diese Methode prüft, ob seit der letzten Aktualisierung genug
  /// Zeit vergangen ist, und aktualisiert die Daten, falls nötig.
  ///
  /// [service] Die Service-Instanz
  static Future<void> _checkAndRefreshData(ServiceInstance service) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString(_lastSyncKey);
    
    final refreshInterval = Duration(
      minutes: prefs.getInt('refresh_interval_minutes') ?? 
        _defaultRefreshInterval.inMinutes
    );
    
    final now = DateTime.now();
    
    // Überprüfen, ob eine Aktualisierung erforderlich ist
    if (lastSync == null || 
        now.difference(DateTime.parse(lastSync)) > refreshInterval) {
      await _refreshData(service);
    }
  }
  
  /// Daten zwangsweise aktualisieren
  ///
  /// Diese Methode aktualisiert die Daten, unabhängig vom letzten
  /// Aktualisierungszeitpunkt.
  ///
  /// [service] Die Service-Instanz
  static Future<void> _forceRefreshData(ServiceInstance service) async {
    await _refreshData(service, force: true);
  }
  
  /// Daten aktualisieren
  ///
  /// Diese Methode führt die eigentliche Datenaktualisierung durch.
  ///
  /// [service] Die Service-Instanz
  /// [force] Optional: Ob ein Refresh erzwungen werden soll (standardmäßig false)
  static Future<void> _refreshData(ServiceInstance service, {bool force = false}) async {
    try {
      log('Aktualisiere Daten im Hintergrund ${force ? "(erzwungen)" : ""}');
      
      // Repository aus dem Service Locator holen
      final repository = serviceLocator<McDonaldsRepository>();
      
      // Daten aktualisieren
      await repository.getAllLocations(forceRefresh: force);
      
      // Zeitstempel der letzten Aktualisierung speichern
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      
      // Service über erfolgreiche Aktualisierung informieren
      service.invoke('refreshComplete', {
        'success': true,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      log('Hintergrundaktualisierung abgeschlossen');
    } catch (e) {
      log('Fehler bei der Hintergrundaktualisierung: $e');
      
      // Service über Fehler informieren
      service.invoke('refreshComplete', {
        'success': false,
        'error': e.toString(),
      });
    }
  }
  
  /// Prüft, ob es Zeit für eine Aktualisierung ist
  ///
  /// Diese Methode prüft, ob seit der letzten Aktualisierung genug
  /// Zeit vergangen ist.
  ///
  /// Gibt `true` zurück, wenn eine Aktualisierung nötig ist, sonst `false`
  static Future<bool> isRefreshNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString(_lastSyncKey);
    
    final refreshInterval = Duration(
      minutes: prefs.getInt('refresh_interval_minutes') ?? 
        _defaultRefreshInterval.inMinutes
    );
    
    if (lastSync == null) return true;
    
    final lastSyncTime = DateTime.parse(lastSync);
    final now = DateTime.now();
    return now.difference(lastSyncTime) > refreshInterval;
  }
  
  /// Manuelles Auslösen einer Hintergrundaktualisierung
  ///
  /// Diese Methode ermöglicht es, eine sofortige Aktualisierung
  /// über die UI zu starten.
  static Future<void> triggerRefresh() async {
    final service = FlutterBackgroundService();
    service.invoke('forceRefresh');
  }
  
  /// Aktualisierungsintervall ändern
  ///
  /// Diese Methode ändert das Intervall zwischen automatischen Aktualisierungen.
  ///
  /// [minutes] Das neue Intervall in Minuten
  static Future<void> setRefreshInterval(int minutes) async {
    final service = FlutterBackgroundService();
    service.invoke('updateRefreshInterval', {'interval': minutes});
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('refresh_interval_minutes', minutes);
  }
}
