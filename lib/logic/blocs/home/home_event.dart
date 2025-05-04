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
  
  /// Konstruktor für DataRequestEvent
  ///
  /// @param forceRefresh Optional: Ob ein Neuladen der Daten erzwungen werden soll
  DataRequestEvent({this.forceRefresh = false});
}

/// Event zum manuellen Aktualisieren der Daten
///
/// Wird ausgelöst, wenn der Benutzer aktiv eine Aktualisierung anfordert.
class RefreshDataEvent extends HomeEvent {}

/// Event zum Filtern von Standorten
///
/// Wird ausgelöst, wenn der Benutzer die Filtereinstellungen ändert.
class FilterLocationsEvent extends HomeEvent {
  /// Flag, ob nur defekte Standorte angezeigt werden sollen
  final bool? onlyBroken;
  
  /// Konstruktor für FilterLocationsEvent
  ///
  /// @param onlyBroken Optional: Ob nur defekte Standorte angezeigt werden sollen.
  ///                            Null bedeutet, dass alle Standorte angezeigt werden.
  FilterLocationsEvent({this.onlyBroken});
}
