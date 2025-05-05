// filepath: /Users/janikkahle/Documents/Development/Projekte/Mobile/mcbroken_app/lib/logic/blocs/home/home_state.dart
part of 'home_bloc.dart';

/// Basisklasse für alle Zustände des HomeBloc
///
/// Alle Zustände, die der HomeBloc emittieren kann, müssen von dieser Klasse erben.
@immutable
abstract class HomeState {}

/// Initialer Zustand des HomeBloc
///
/// Dieser Zustand wird beim Start der Anwendung angezeigt, bevor Daten geladen wurden.
class HomeStateInitial extends HomeState {}

/// Ladezustand des HomeBloc
///
/// Dieser Zustand wird angezeigt, während Daten geladen werden.
class HomeStateLoading extends HomeState {}

/// Geladener Zustand des HomeBloc
///
/// Dieser Zustand wird angezeigt, wenn Daten erfolgreich geladen wurden
/// und eine Benutzerposition verfügbar ist.
class HomeStateLoaded extends HomeState {
  /// Liste der McDonald's-Standorte
  final List<McDonaldsLocation> mcdonalds_data;
  
  /// Position des Benutzers
  final Position position;
  
  /// Flag, ob die Daten gefiltert wurden
  final bool filtered;
  
  /// Flag, ob nur defekte Standorte angezeigt werden (null = alle anzeigen)
  final bool? showOnlyBroken;
  
  /// Flag, ob nur funktionierende Standorte angezeigt werden (null = alle anzeigen)
  final bool? showOnlyWorking;
  
  /// Zeitpunkt der letzten Aktualisierung der Daten
  final DateTime? lastUpdated;
  
  /// Aktueller Suchbegriff, falls eine Suche aktiv ist
  final String? searchQuery;
  
  /// Liste der favorisierten Standort-IDs
  final List<String> favorites;

  /// Erstellt einen neuen HomeStateLoaded
  ///
  /// [mcdonalds_data] ist die Liste der anzuzeigenden McDonald's-Standorte.
  /// [position] ist die aktuelle Position des Benutzers.
  /// [filtered] gibt an, ob die Daten gefiltert wurden.
  /// [showOnlyBroken] gibt an, ob nur defekte Standorte angezeigt werden.
  /// [lastUpdated] ist der Zeitpunkt der letzten Datenaktualisierung.
  /// [searchQuery] ist der aktuelle Suchbegriff, falls eine Suche aktiv ist.
  HomeStateLoaded(
    this.mcdonalds_data, 
    this.position, {
    this.filtered = false,
    this.showOnlyBroken,
    this.showOnlyWorking,
    this.lastUpdated,
    this.searchQuery,
    this.favorites = const [],
  });
  
  /// Erstellt eine Kopie dieses Zustands mit möglicherweise aktualisierten Werten
  ///
  /// Alle nicht angegebenen Parameter behalten ihre ursprünglichen Werte.
  HomeStateLoaded copyWith({
    List<McDonaldsLocation>? mcdonalds_data,
    Position? position,
    bool? filtered,
    bool? showOnlyBroken,
    bool? showOnlyWorking,
    DateTime? lastUpdated,
    String? searchQuery,
    List<String>? favorites,
  }) {
    return HomeStateLoaded(
      mcdonalds_data ?? this.mcdonalds_data,
      position ?? this.position,
      filtered: filtered ?? this.filtered,
      showOnlyBroken: showOnlyBroken ?? this.showOnlyBroken,
      showOnlyWorking: showOnlyWorking ?? this.showOnlyWorking,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      searchQuery: searchQuery ?? this.searchQuery,
      favorites: favorites ?? this.favorites,
    );
  }
}

/// Geladener Zustand ohne Benutzerposition
///
/// Dieser Zustand wird angezeigt, wenn Daten erfolgreich geladen wurden,
/// aber keine Benutzerposition verfügbar ist.
class HomeStateNoLocation extends HomeState {
  /// Liste der McDonald's-Standorte
  final List<McDonaldsLocation> mcdonalds_data;
  
  /// Flag, ob die Daten gefiltert wurden
  final bool filtered;
  
  /// Flag, ob nur defekte Standorte angezeigt werden (null = alle anzeigen)
  final bool? showOnlyBroken;
  
  /// Flag, ob nur funktionierende Standorte angezeigt werden (null = alle anzeigen)
  final bool? showOnlyWorking;
  
  /// Zeitpunkt der letzten Aktualisierung der Daten
  final DateTime? lastUpdated;
  
  /// Aktueller Suchbegriff, falls eine Suche aktiv ist
  final String? searchQuery;
  
  /// Liste der favorisierten Standort-IDs
  final List<String> favorites;

  /// Erstellt einen neuen HomeStateNoLocation
  ///
  /// [mcdonalds_data] ist die Liste der anzuzeigenden McDonald's-Standorte.
  /// [filtered] gibt an, ob die Daten gefiltert wurden.
  /// [showOnlyBroken] gibt an, ob nur defekte Standorte angezeigt werden.
  /// [showOnlyWorking] gibt an, ob nur funktionierende Standorte angezeigt werden.
  /// [lastUpdated] ist der Zeitpunkt der letzten Datenaktualisierung.
  /// [searchQuery] ist der aktuelle Suchbegriff, falls eine Suche aktiv ist.
  /// [favorites] ist die Liste der favorisierten Standort-IDs.
  HomeStateNoLocation(
    this.mcdonalds_data, {
    this.filtered = false,
    this.showOnlyBroken,
    this.showOnlyWorking,
    this.lastUpdated,
    this.searchQuery,
    this.favorites = const [],
  });
}

/// Offline-Zustand des HomeBloc
///
/// Dieser Zustand wird angezeigt, wenn keine Internetverbindung besteht,
/// aber lokale Daten aus dem Cache verfügbar sind.
class HomeStateOffline extends HomeState {
  /// Fehlermeldung zur Erklärung des Offline-Status
  final String message;
  
  /// Liste der aus dem Cache geladenen McDonald's-Standorte
  final List<McDonaldsLocation> locations;
  
  /// Position des Benutzers, falls verfügbar
  final Position? position;
  
  /// Zeitpunkt der letzten Aktualisierung der Daten
  final DateTime? lastUpdated;

  /// Erstellt einen neuen HomeStateOffline
  ///
  /// [message] ist die Fehlermeldung zur Erklärung des Offline-Status.
  /// [locations] ist die Liste der aus dem Cache geladenen McDonald's-Standorte.
  /// [position] ist die aktuelle Position des Benutzers, falls verfügbar.
  /// [lastUpdated] ist der Zeitpunkt der letzten Datenaktualisierung.
  HomeStateOffline({
    required this.message,
    required this.locations,
    this.position,
    this.lastUpdated,
  });
}

/// Fehlerzustand des HomeBloc
///
/// Dieser Zustand wird angezeigt, wenn ein Fehler beim Laden der Daten aufgetreten ist
/// und keine Daten angezeigt werden können.
class HomeStateError extends HomeState {
  /// Die Fehlermeldung
  final String message;
  
  /// Flag, ob ein erneuter Versuch möglich ist
  final bool canRetry;

  /// Erstellt einen neuen HomeStateError
  ///
  /// [message] ist die anzuzeigende Fehlermeldung.
  /// [canRetry] gibt an, ob ein erneuter Versuch möglich ist.
  HomeStateError(this.message, {this.canRetry = true});
}
