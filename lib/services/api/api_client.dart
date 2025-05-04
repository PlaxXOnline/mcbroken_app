// filepath: /Users/janikkahle/Documents/Development/Projekte/Mobile/mcbroken_app/lib/services/api/api_client.dart
import 'package:dio/dio.dart';
import 'package:mcbroken/services/api/api_error_handler.dart';

/// Abstrakte Klasse für HTTP-Anfragen
///
/// Stellt eine einheitliche Schnittstelle für HTTP-Anfragen bereit,
/// unabhängig von der gewählten HTTP-Bibliothek.
abstract class ApiClient {
  /// Führt eine GET-Anfrage aus
  ///
  /// [url] ist die URL für die Anfrage
  /// [queryParameters] sind optionale Query-Parameter für die URL
  /// [options] sind zusätzliche Optionen für die Anfrage
  ///
  /// Gibt die Antwortdaten zurück oder wirft eine [ApiException]
  Future<dynamic> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  });

  /// Führt eine POST-Anfrage aus
  ///
  /// [url] ist die URL für die Anfrage
  /// [data] sind die zu sendenden Daten im Body der Anfrage
  /// [queryParameters] sind optionale Query-Parameter für die URL
  /// [options] sind zusätzliche Optionen für die Anfrage
  ///
  /// Gibt die Antwortdaten zurück oder wirft eine [ApiException]
  Future<dynamic> post(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  });

  /// Setzt die Standardkonfiguration für alle Anfragen
  ///
  /// [baseUrl] ist die neue Basis-URL für alle Anfragen
  /// [headers] sind die neuen Standard-Header für alle Anfragen
  void configure({
    String? baseUrl,
    Map<String, dynamic>? headers,
  });
}

/// Implementierung des [ApiClient] mit Dio
///
/// Diese Klasse verwendet die Dio-Bibliothek für HTTP-Anfragen und
/// bietet eine einheitliche Fehlerbehandlung mit Retry-Mechanismen.
class ApiClientImpl implements ApiClient {
  final Dio dio;
  final ApiErrorHandler errorHandler;
  
  /// Die maximale Anzahl von Versuchen bei Fehlern
  final int _maxRetries = 3;

  /// Erstellt eine neue Instanz des [ApiClientImpl]
  ///
  /// [dio] ist die Dio-Instanz für HTTP-Anfragen
  /// [errorHandler] ist der Handler für API-Fehler
  ApiClientImpl({
    required this.dio,
    required this.errorHandler,
  });

  @override
  void configure({String? baseUrl, Map<String, dynamic>? headers}) {
    if (baseUrl != null) {
      dio.options.baseUrl = baseUrl;
    }
    
    if (headers != null) {
      dio.options.headers = headers;
    }
  }

  /// Führt eine GET-Anfrage mit Retry-Mechanismus aus
  ///
  /// [url] ist die URL für die Anfrage
  /// [queryParameters] sind optionale Query-Parameter für die URL
  /// [options] sind zusätzliche Optionen für die Anfrage
  ///
  /// Gibt die Antwortdaten zurück oder wirft eine [ApiException]
  @override
  Future<dynamic> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _executeRequest(
      () => dio.get(
        url,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  /// Führt eine POST-Anfrage mit Retry-Mechanismus aus
  ///
  /// [url] ist die URL für die Anfrage
  /// [data] sind die zu sendenden Daten im Body der Anfrage
  /// [queryParameters] sind optionale Query-Parameter für die URL
  /// [options] sind zusätzliche Optionen für die Anfrage
  ///
  /// Gibt die Antwortdaten zurück oder wirft eine [ApiException]
  @override
  Future<dynamic> post(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _executeRequest(
      () => dio.post(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  /// Führt eine HTTP-Anfrage mit Retry-Mechanismus aus
  ///
  /// [requestFunction] ist die auszuführende HTTP-Anfrage als Funktion
  ///
  /// Gibt die Antwortdaten zurück oder wirft eine [ApiException]
  Future<dynamic> _executeRequest(
    Future<Response<dynamic>> Function() requestFunction,
  ) async {
    int attempts = 0;
    while (attempts < _maxRetries) {
      try {
        attempts++;
        final response = await requestFunction();
        return response.data;
      } catch (error) {
        // Bei letztem Versuch Fehler werfen, sonst erneut versuchen
        if (attempts >= _maxRetries) {
          throw errorHandler.handleError(error);
        }
        
        // Nur bei bestimmten Fehlern erneut versuchen (z.B. Verbindungsfehler)
        if (error is DioException) {
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError ||
              (error.type == DioExceptionType.badResponse &&
                  error.response?.statusCode == 500) ||
              (error.type == DioExceptionType.badResponse &&
                  error.response?.statusCode == 503)) {
            // Exponentielles Backoff: Wartezeit zwischen Versuchen erhöhen
            final waitTime = Duration(milliseconds: 1000 * attempts);
            await Future.delayed(waitTime);
            continue;
          }
        }
        
        // Bei anderen Fehlern sofort abbrechen
        throw errorHandler.handleError(error);
      }
    }
    
    // Sollte nie erreicht werden
    throw errorHandler.handleError(
      Exception('Maximale Anzahl an Wiederholungen erreicht'),
    );
  }
}
