// filepath: /Users/janikkahle/Documents/Development/Projekte/Mobile/mcbroken_app/lib/services/api/api_error_handler.dart
import 'dart:io';
import 'package:dio/dio.dart';

/// Fehlerklasse für API-Fehler
///
/// Diese Klasse repräsentiert einen standardisierten Fehler,
/// der bei API-Aufrufen auftreten kann.
class ApiException implements Exception {
  /// Der HTTP-Statuscode des Fehlers (wenn vorhanden)
  final int? statusCode;
  
  /// Die Nachricht, die den Fehler beschreibt
  final String message;
  
  /// Der ursprüngliche Fehler, der aufgetreten ist
  final dynamic originalError;

  /// Erstellt eine neue [ApiException]
  ///
  /// [statusCode] ist der HTTP-Statuscode des Fehlers (optional)
  /// [message] ist eine benutzerfreundliche Fehlermeldung
  /// [originalError] ist der ursprüngliche Fehler (optional)
  ApiException({
    this.statusCode,
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'ApiException: $message (Statuscode: $statusCode)';
}

/// Interface für die API-Fehlerbehandlung
///
/// Diese Klasse bietet eine einheitliche Methode zum Umgang mit
/// verschiedenen Arten von API-Fehlern und konvertiert sie in
/// standardisierte [ApiException]-Objekte.
abstract class ApiErrorHandler {
  /// Verarbeitet einen Fehler und konvertiert ihn in eine [ApiException]
  ///
  /// [error] ist der zu verarbeitende Fehler
  /// 
  /// Gibt eine [ApiException] mit einer benutzerfreundlichen Nachricht zurück
  ApiException handleError(dynamic error);
}

/// Implementierung des [ApiErrorHandler] für die Fehlerbehandlung
///
/// Diese Klasse behandelt verschiedene Arten von Fehlern, 
/// die bei Netzwerkanfragen auftreten können.
class ApiErrorHandlerImpl implements ApiErrorHandler {
  /// Verarbeitet einen Fehler und konvertiert ihn in eine [ApiException]
  ///
  /// [error] ist der zu verarbeitende Fehler
  /// 
  /// Gibt eine [ApiException] mit einer benutzerfreundlichen Nachricht zurück
  @override
  ApiException handleError(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is SocketException) {
      return ApiException(
        message: 'Netzwerkfehler: Keine Internetverbindung.',
        originalError: error,
      );
    } else if (error is FormatException) {
      return ApiException(
        message: 'Fehler bei der Formatierung der Daten.',
        originalError: error,
      );
    } else if (error is ApiException) {
      return error;
    } else {
      return ApiException(
        message: 'Ein unerwarteter Fehler ist aufgetreten.',
        originalError: error,
      );
    }
  }

  /// Behandelt spezifisch [DioException]-Fehler
  ///
  /// [dioError] ist der aufgetretene Dio-Fehler
  ///
  /// Gibt eine [ApiException] mit spezifischen Informationen zum Dio-Fehler zurück
  ApiException _handleDioError(DioException dioError) {
    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
        return ApiException(
          statusCode: dioError.response?.statusCode,
          message: 'Verbindungs-Timeout. Bitte überprüfen Sie Ihre Internetverbindung.',
          originalError: dioError,
        );
      case DioExceptionType.sendTimeout:
        return ApiException(
          statusCode: dioError.response?.statusCode,
          message: 'Timeout beim Senden der Anfrage.',
          originalError: dioError,
        );
      case DioExceptionType.receiveTimeout:
        return ApiException(
          statusCode: dioError.response?.statusCode,
          message: 'Timeout beim Empfangen der Antwort.',
          originalError: dioError,
        );
      case DioExceptionType.badCertificate:
        return ApiException(
          statusCode: dioError.response?.statusCode,
          message: 'Ungültiges SSL-Zertifikat.',
          originalError: dioError,
        );
      case DioExceptionType.badResponse:
        return _handleBadResponse(dioError);
      case DioExceptionType.cancel:
        return ApiException(
          statusCode: dioError.response?.statusCode,
          message: 'Anfrage wurde abgebrochen.',
          originalError: dioError,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          statusCode: dioError.response?.statusCode,
          message: 'Verbindungsfehler. Bitte überprüfen Sie Ihre Internetverbindung.',
          originalError: dioError,
        );
      case DioExceptionType.unknown:
        if (dioError.error is SocketException) {
          return ApiException(
            statusCode: dioError.response?.statusCode,
            message: 'Keine Internetverbindung.',
            originalError: dioError,
          );
        }
        return ApiException(
          statusCode: dioError.response?.statusCode,
          message: 'Ein unbekannter Fehler ist aufgetreten.',
          originalError: dioError,
        );
    }
  }

  /// Verarbeitet fehlerhafte HTTP-Antworten
  ///
  /// [dioError] ist der aufgetretene Dio-Fehler mit einer HTTP-Antwort
  ///
  /// Gibt eine [ApiException] basierend auf dem HTTP-Statuscode zurück
  ApiException _handleBadResponse(DioException dioError) {
    final statusCode = dioError.response?.statusCode;
    String message;

    switch (statusCode) {
      case 400:
        message = 'Ungültige Anfrage.';
        break;
      case 401:
        message = 'Nicht autorisiert.';
        break;
      case 403:
        message = 'Zugriff verweigert.';
        break;
      case 404:
        message = 'Ressource nicht gefunden.';
        break;
      case 408:
        message = 'Request Timeout.';
        break;
      case 500:
        message = 'Interner Serverfehler.';
        break;
      case 503:
        message = 'Service nicht verfügbar.';
        break;
      default:
        message = 'Fehler beim Empfangen der Daten. Statuscode: $statusCode';
    }

    return ApiException(
      statusCode: statusCode,
      message: message,
      originalError: dioError,
    );
  }
}
