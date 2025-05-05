// filepath: /Users/janikkahle/Documents/Development/Projekte/Mobile/mcbroken_app/lib/logic/blocs/home/home_event.dart
part of 'home_bloc.dart';

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
/// Wird ausgelöst, wenn der Benutzer nach Standorten basierend auf den Status der Eismaschine filtert.
class FilterLocationsEvent extends HomeEvent {
  /// Flag, ob nur defekte Eismaschinen angezeigt werden sollen
  final bool? onlyBroken;
  
  /// Flag, ob nur funktionierende Eismaschinen angezeigt werden sollen
  final bool? onlyWorking;
  
  /// Flag, ob nur favorisierte Standorte angezeigt werden sollen
  final bool onlyFavorites;
  
  /// Erstellt ein neues FilterLocationsEvent
  ///
  /// [onlyBroken] bestimmt, ob nur Standorte mit defekten Eismaschinen angezeigt werden sollen.
  /// [onlyWorking] bestimmt, ob nur Standorte mit funktionierenden Eismaschinen angezeigt werden sollen.
  /// [onlyFavorites] bestimmt, ob nur favorisierte Standorte angezeigt werden sollen.
  FilterLocationsEvent({this.onlyBroken, this.onlyWorking, this.onlyFavorites = false});
}

/// Event zum Suchen nach Standorten
///
/// Wird ausgelöst, wenn der Benutzer nach bestimmten Standorten sucht.
class SearchLocationsEvent extends HomeEvent {
  /// Der Suchbegriff, nach dem gefiltert werden soll
  final String query;
  
  /// Erstellt ein neues SearchLocationsEvent
  ///
  /// [query] ist der Suchbegriff, nach dem gesucht werden soll.
  /// Die Suche umfasst Straße, Stadt, Bundesland und Land.
  SearchLocationsEvent({required this.query});
}

/// Event zum Zurücksetzen der Suche
///
/// Wird ausgelöst, wenn der Benutzer die Suche zurücksetzt oder das Suchfeld leert.
class ResetSearchEvent extends HomeEvent {}

/// Event zum Hinzufügen eines Standorts zu Favoriten
///
/// Wird ausgelöst, wenn der Benutzer einen Standort zu seinen Favoriten hinzufügt.
class AddToFavoritesEvent extends HomeEvent {
  /// Die ID des Standorts, der zu Favoriten hinzugefügt werden soll
  final String locationId;
  
  /// Erstellt ein neues AddToFavoritesEvent
  ///
  /// [locationId] ist die eindeutige ID des Standorts, der als Favorit markiert werden soll.
  AddToFavoritesEvent({required this.locationId});
}

/// Event zum Entfernen eines Standorts aus Favoriten
///
/// Wird ausgelöst, wenn der Benutzer einen Standort aus seinen Favoriten entfernt.
class RemoveFromFavoritesEvent extends HomeEvent {
  /// Die ID des Standorts, der aus Favoriten entfernt werden soll
  final String locationId;
  
  /// Erstellt ein neues RemoveFromFavoritesEvent
  ///
  /// [locationId] ist die eindeutige ID des Standorts, der aus Favoriten entfernt werden soll.
  RemoveFromFavoritesEvent({required this.locationId});
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
