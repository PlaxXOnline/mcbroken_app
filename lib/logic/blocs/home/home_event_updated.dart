// filepath: /Users/janikkahle/Documents/Development/Projekte/Mobile/mcbroken_app/lib/logic/blocs/home/home_event_updated.dart
part of 'home_bloc_updated.dart';

/// Basisklasse für alle Events des HomeBloc
///
/// Alle Events, die der HomeBloc verarbeiten kann, müssen von dieser Klasse erben.
@immutable
abstract class HomeEvent {}

/// Event zum Anfordern von Daten
///
/// Wird ausgelöst, wenn neue Daten vom Server oder aus dem Cache geladen werden sollen.
class DataRequestEvent extends HomeEvent {
  /// Flag, ob ein Refresh erzwungen werden soll, auch wenn Daten gecached sind
  final bool forceRefresh;
  
  /// Erstellt ein neues DataRequestEvent
  ///
  /// [forceRefresh] bestimmt, ob ein Neuladen der Daten erzwungen werden soll,
  /// auch wenn bereits aktuelle Daten im Cache vorhanden sind. Standardmäßig false.
  DataRequestEvent({this.forceRefresh = false});
}

/// Event zum manuellen Aktualisieren der Daten
///
/// Wird ausgelöst, wenn der Benutzer aktiv eine Aktualisierung anfordert,
/// z.B. durch Pull-to-Refresh.
class RefreshDataEvent extends HomeEvent {}

/// Event zum Filtern von Standorten
///
/// Wird ausgelöst, wenn der Benutzer die Filtereinstellungen ändert.
class FilterLocationsEvent extends HomeEvent {
  /// Flag, ob nur defekte Standorte angezeigt werden sollen
  final bool? onlyBroken;
  
  /// Erstellt ein neues FilterLocationsEvent
  ///
  /// [onlyBroken] bestimmt, ob nur defekte Standorte angezeigt werden sollen.
  /// Wenn null, werden alle Standorte angezeigt.
  FilterLocationsEvent({this.onlyBroken});
}

/// Event zum Suchen von Standorten
///
/// Wird ausgelöst, wenn der Benutzer nach einem bestimmten Standort sucht.
class SearchLocationsEvent extends HomeEvent {
  /// Der Suchbegriff
  final String query;
  
  /// Erstellt ein neues SearchLocationsEvent
  ///
  /// [query] ist der Suchbegriff, der auf Standorte angewendet werden soll.
  SearchLocationsEvent(this.query);
}

/// Event zum Laden von Standorten in einem bestimmten Kartenbereich
///
/// Wird ausgelöst, wenn sich der sichtbare Kartenbereich ändert und
/// neue Standorte geladen werden sollen.
class LoadLocationsInViewEvent extends HomeEvent {
  /// Minimale Breitengrad-Koordinate
  final double minLat;
  
  /// Maximale Breitengrad-Koordinate
  final double maxLat;
  
  /// Minimale Längengrad-Koordinate
  final double minLng;
  
  /// Maximale Längengrad-Koordinate
  final double maxLng;
  
  /// Flag, ob ein Refresh erzwungen werden soll
  final bool forceRefresh;
  
  /// Erstellt ein neues LoadLocationsInViewEvent
  ///
  /// [minLat], [maxLat], [minLng], [maxLng] definieren den geografischen Bereich,
  /// für den Standorte geladen werden sollen.
  /// [forceRefresh] bestimmt, ob neue Daten vom Server geladen werden sollen.
  LoadLocationsInViewEvent({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
    this.forceRefresh = false,
  });
}
