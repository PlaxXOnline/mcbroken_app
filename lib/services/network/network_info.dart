// filepath: /Users/janikkahle/Documents/Development/Projekte/Mobile/mcbroken_app/lib/services/network/network_info.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

/// Abstrakte Klasse für Netzwerkinformationen
///
/// Diese Klasse bietet eine Abstraktion für die Überprüfung der Netzwerkverbindung.
/// Durch die Verwendung eines Interfaces können wir die Implementierung leicht
/// für Tests mocken oder bei Bedarf ändern.
abstract class NetworkInfo {
  /// Überprüft, ob eine aktive Internetverbindung besteht
  ///
  /// Gibt [true] zurück, wenn eine Internetverbindung besteht, sonst [false]
  Future<bool> get isConnected;
  
  /// Überprüft, ob WLAN verfügbar ist
  ///
  /// Gibt [true] zurück, wenn WLAN verbunden ist, sonst [false]
  Future<bool> get isWifiConnected;

  /// Überprüft, ob mobile Daten verfügbar sind
  ///
  /// Gibt [true] zurück, wenn mobile Daten verbunden sind, sonst [false]
  Future<bool> get isMobileConnected;

  /// Stream für Änderungen in der Konnektivität
  ///
  /// Ermöglicht das Abonnieren von Änderungen im Verbindungsstatus
  Stream<ConnectivityResult> get connectivityStream;
}

/// Implementierung der [NetworkInfo] mit realen Netzwerkprüfungen
///
/// Verwendet [Connectivity] und [InternetConnectionChecker] für ausführliche
/// und zuverlässige Netzwerkinformationen.
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;
  final InternetConnectionChecker connectionChecker;

  /// Erstellt eine neue Instanz von [NetworkInfoImpl]
  ///
  /// [connectivity] wird für die Überprüfung der Art der Verbindung verwendet (WLAN, Mobile, etc.)
  /// [connectionChecker] wird verwendet, um die tatsächliche Internetverbindung zu überprüfen
  NetworkInfoImpl({
    required this.connectivity,
    required this.connectionChecker,
  });

  /// Überprüft, ob eine aktive Internetverbindung besteht
  ///
  /// Gibt [true] zurück, wenn eine Internetverbindung besteht, sonst [false]
  /// Diese Prüfung umfasst einen tatsächlichen Verbindungstest zu einem Server
  @override
  Future<bool> get isConnected => connectionChecker.hasConnection;

  /// Überprüft, ob WLAN verfügbar ist
  ///
  /// Gibt [true] zurück, wenn WLAN verbunden ist, sonst [false]
  @override
  Future<bool> get isWifiConnected async {
    final connectivityResult = await connectivity.checkConnectivity();
    return connectivityResult == ConnectivityResult.wifi;
  }

  /// Überprüft, ob mobile Daten verfügbar sind
  ///
  /// Gibt [true] zurück, wenn mobile Daten verbunden sind, sonst [false]
  @override
  Future<bool> get isMobileConnected async {
    final connectivityResult = await connectivity.checkConnectivity();
    return connectivityResult == ConnectivityResult.mobile;
  }

  /// Stream für Änderungen in der Konnektivität
  ///
  /// Ermöglicht das Abonnieren von Änderungen im Verbindungsstatus
  @override
  Stream<ConnectivityResult> get connectivityStream => 
      connectivity.onConnectivityChanged;
}
