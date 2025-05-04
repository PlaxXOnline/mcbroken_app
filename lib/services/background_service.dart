// filepath: /Users/janikkahle/Documents/Development/Projekte/Mobile/mcbroken_app/lib/services/background_service.dart
import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:mcbroken/data/repository/mcdonalds_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
class BackgroundDataService {
  static const String _lastSyncKey = 'last_background_sync';
  static const Duration _defaultRefreshInterval = Duration(hours: 1);
  
  // Initialisiere den Hintergrund-Service
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
  
  // Starter für den iOS-Hintergrunddienst
  @pragma('vm:entry-point')
  static bool _onIosBackground(ServiceInstance service) {
    WidgetsFlutterBinding.ensureInitialized();
    log('iOS Hintergrunddienst gestartet');
    _onStart(service);
    return true;
  }
  
  // Hauptlogik des Hintergrunddienstes
  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }
    
    log('Hintergrunddienst gestartet');
    
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
  
  // Überprüfe, ob eine Aktualisierung erforderlich ist, und führe sie durch
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
  
  // Daten zwangsweise aktualisieren
  static Future<void> _forceRefreshData(ServiceInstance service) async {
    await _refreshData(service, force: true);
  }
  
  // Daten aktualisieren
  static Future<void> _refreshData(ServiceInstance service, {bool force = false}) async {
    try {
      log('Aktualisiere Daten im Hintergrund ${force ? "(erzwungen)" : ""}');
      
      final repository = McDonaldsRepository();
      await repository.getDataFromMcDonalds(forceRefresh: force);
      
      // Zeitstempel der letzten Aktualisierung speichern
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      
      service.invoke('refreshComplete', {
        'success': true,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      log('Hintergrundaktualisierung abgeschlossen');
    } catch (e) {
      log('Fehler bei der Hintergrundaktualisierung: $e');
      service.invoke('refreshComplete', {
        'success': false,
        'error': e.toString(),
      });
    }
  }
  
  // Prüfen, ob es Zeit für eine Aktualisierung ist
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
  
  // Manuelles Auslösen einer Hintergrundaktualisierung
  static Future<void> triggerRefresh() async {
    final service = FlutterBackgroundService();
    service.invoke('forceRefresh');
  }
  
  // Aktualisierungsintervall ändern
  static Future<void> setRefreshInterval(int minutes) async {
    final service = FlutterBackgroundService();
    service.invoke('updateRefreshInterval', {'interval': minutes});
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('refresh_interval_minutes', minutes);
  }
}
