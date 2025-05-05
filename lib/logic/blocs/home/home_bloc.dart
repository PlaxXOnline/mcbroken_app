// filepath: /Users/janikkahle/Documents/Development/Projekte/Mobile/mcbroken_app/lib/logic/blocs/home/home_bloc.dart
import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mcbroken/data/models/mcdonalds_location.dart';
import 'package:mcbroken/data/repository/mcdonalds_repository.dart';
import 'package:mcbroken/logic/cubits/connectivity/internet_cubit.dart';
import 'package:mcbroken/services/api/api_error_handler.dart';
import 'package:mcbroken/services/preferences/favorites_service.dart';
import 'package:meta/meta.dart';

part 'home_event.dart';
part 'home_state.dart';

/// Bloc zur Verwaltung des Zustands der Startseite und der McDonald's-Standortdaten
///
/// Der HomeBloc ist verantwortlich für das Laden und Filtern von McDonald's-Standortdaten,
/// die Überwachung des Verbindungsstatus, die Suche nach Standorten und 
/// die Aktualisierung der UI entsprechend des aktuellen Datenstatus.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  /// Repository für den Zugriff auf McDonald's-Daten
  final McDonaldsRepository _repository;
  
  /// InternetCubit zur Überwachung der Internetverbindung
  final InternetCubit? _internetCubit;
  
  /// Service zur Verwaltung der Favoriten
  final FavoritesService _favoritesService;
  
  /// Subscription für Internetstatus-Updates
  StreamSubscription? _internetStreamSubscription;
  
  /// Alle geladenen McDonald's-Standorte
  List<McDonaldsLocation> _allMcDonaldsData = [];
  
  /// Gefilterte Liste der McDonald's-Standorte (z.B. basierend auf Defekt-Status)
  List<McDonaldsLocation> _filteredMcDonaldsData = [];
  
  /// Aktuelle Position des Benutzers, falls verfügbar
  Position? _currentPosition;
  
  /// Filter-Flag, ob nur Standorte mit defekten Eismaschinen angezeigt werden sollen
  bool? _filterOnlyBroken;
  
  /// Filter-Flag, ob nur Standorte mit funktionierenden Eismaschinen angezeigt werden sollen
  bool? _filterOnlyWorking;
  
  /// Liste der favorisierten Standorte
  List<String> _favorites = [];
  
  /// Zeitpunkt der letzten Aktualisierung der Daten
  DateTime? _lastUpdated;

  /// Erstellt eine neue Instanz des HomeBloc
  ///
  /// [repository] ist das Repository, das für den Zugriff auf die Daten verwendet wird.
  /// [internetCubit] ist optional und wird für die Überwachung des Netzwerkstatus verwendet.
  /// [favoritesService] ist der Service zur Verwaltung der Favoriten.
  HomeBloc({
    required McDonaldsRepository repository,
    required FavoritesService favoritesService,
    InternetCubit? internetCubit,
  }) : _repository = repository,
       _favoritesService = favoritesService,
       _internetCubit = internetCubit,
       super(HomeStateInitial()) {
    log("HomeBloc initializing...");

    // Verbindung mit dem InternetCubit herstellen, um Netzwerkänderungen zu überwachen
    if (_internetCubit != null) {
      _internetStreamSubscription = _internetCubit!.stream.listen((internetState) {
        if (internetState is InternetConnected && 
            (state is HomeStateError || state is HomeStateOffline)) {
          add(DataRequestEvent(forceRefresh: true));
        }
      });
    }

    // Event zum Anfordern von Daten
    on<DataRequestEvent>(_onDataRequest);

    // Event zum manuellen Aktualisieren der Daten
    on<RefreshDataEvent>(_onRefreshData);

    // Event zum Filtern von Standorten
    on<FilterLocationsEvent>(_onFilterLocations);
    
    // Event zum Suchen von Standorten
    on<SearchLocationsEvent>(_onSearchLocations);
    
    // Event zum Zurücksetzen der Suche
    on<ResetSearchEvent>(_onResetSearch);
    
    // Event zum Hinzufügen eines Standorts zu Favoriten
    on<AddToFavoritesEvent>(_onAddToFavorites);
    
    // Event zum Entfernen eines Standorts aus Favoriten
    on<RemoveFromFavoritesEvent>(_onRemoveFromFavorites);
    
    // Event zum Laden von Standorten in einem Kartenbereich
    on<LoadLocationsInViewEvent>(_onLoadLocationsInView);
  }
  
  /// Verarbeitet eine Datenanforderung
  ///
  /// [event] enthält die Parameter für die Anfrage
  /// [emit] wird verwendet, um neue Zustände zu emittieren
  Future<void> _onDataRequest(
    DataRequestEvent event, 
    Emitter<HomeState> emit
  ) async {
    try {
      emit(HomeStateLoading());
      
      // Favoriten laden
      _favorites = await _favoritesService.loadFavorites();
      
      // Position bestimmen, falls möglich
      try {
        _currentPosition = await _determinePosition();
        log("Position bestimmt: $_currentPosition");
      } catch (e) {
        log("Fehler beim Bestimmen der Position: $e");
        // Wir setzen trotzdem fort, aber ohne Positionsangabe
      }
      
      // Daten aus dem Repository laden
      _allMcDonaldsData = await _repository.getAllLocations(
        forceRefresh: event.forceRefresh,
      );
      _lastUpdated = await _repository.getLastUpdateTime();
      
      // Filter anwenden
      _applyFiltering();
      
      // Länderstatistik loggen
      logCountryStatistics();
      
      // State aktualisieren
      if (_currentPosition != null) {
        emit(HomeStateLoaded(
          _filteredMcDonaldsData, 
          _currentPosition!,
          filtered: _filterOnlyBroken != null,
          showOnlyBroken: _filterOnlyBroken,
          lastUpdated: _lastUpdated,
        ));
      } else {
        emit(HomeStateNoLocation(
          _filteredMcDonaldsData,
          filtered: _filterOnlyBroken != null,
          showOnlyBroken: _filterOnlyBroken,
          lastUpdated: _lastUpdated,
        ));
      }
      
      log('HomeState geladen mit ${_filteredMcDonaldsData.length} Standorten');
    } on ApiException catch (e) {
      log("API-Fehler beim Laden der Daten: ${e.message}");
      
      // Bei Verbindungsproblemen, aber mit lokalen Daten, einen anderen State zurückgeben
      if (_allMcDonaldsData.isNotEmpty) {
        emit(HomeStateOffline(
          message: e.message,
          locations: _filteredMcDonaldsData,
          position: _currentPosition,
          lastUpdated: _lastUpdated,
        ));
      } else {
        emit(HomeStateError(e.message));
      }
    } catch (e) {
      log("Fehler beim Laden der Daten: $e");
      emit(HomeStateError("Fehler beim Laden der Daten: $e"));
    }
  }

  /// Verarbeitet eine Datenaktualisierungsanforderung
  ///
  /// [event] enthält die Parameter für die Aktualisierung
  /// [emit] wird verwendet, um neue Zustände zu emittieren
  Future<void> _onRefreshData(
    RefreshDataEvent event, 
    Emitter<HomeState> emit
  ) async {
    try {
      emit(HomeStateLoading());
      
      // Daten mit erzwungenem Refresh laden
      _allMcDonaldsData = await _repository.getAllLocations(
        forceRefresh: true,
      );
      _lastUpdated = DateTime.now();
      
      // Filter anwenden
      _applyFiltering();
      
      // State aktualisieren
      if (_currentPosition != null) {
        emit(HomeStateLoaded(
          _filteredMcDonaldsData, 
          _currentPosition!,
          filtered: _filterOnlyBroken != null,
          showOnlyBroken: _filterOnlyBroken,
          lastUpdated: _lastUpdated,
        ));
      } else {
        emit(HomeStateNoLocation(
          _filteredMcDonaldsData,
          filtered: _filterOnlyBroken != null,
          showOnlyBroken: _filterOnlyBroken,
          lastUpdated: _lastUpdated,
        ));
      }
    } on ApiException catch (e) {
      log("API-Fehler beim Aktualisieren der Daten: ${e.message}");
      
      // Bei Verbindungsproblemen, aber mit lokalen Daten, einen anderen State zurückgeben
      if (_allMcDonaldsData.isNotEmpty) {
        emit(HomeStateOffline(
          message: e.message,
          locations: _filteredMcDonaldsData,
          position: _currentPosition,
          lastUpdated: _lastUpdated,
        ));
      } else {
        emit(HomeStateError(e.message));
      }
    } catch (e) {
      log("Fehler beim Aktualisieren der Daten: $e");
      emit(HomeStateError("Aktualisierung fehlgeschlagen: $e"));
    }
  }
  
  /// Verarbeitet eine Filteranforderung
  ///
  /// [event] enthält den anzuwendenden Filter
  /// [emit] wird verwendet, um neue Zustände zu emittieren
  Future<void> _onFilterLocations(
    FilterLocationsEvent event, 
    Emitter<HomeState> emit
  ) async {
    // Filter speichern
    _filterOnlyBroken = event.onlyBroken;
    _filterOnlyWorking = event.onlyWorking;
    bool onlyFavorites = event.onlyFavorites;
    
    // Filterung anwenden
    if (_filterOnlyBroken != null && _filterOnlyWorking != null) {
      // Beide Filter können nicht gleichzeitig aktiv sein
      if (_filterOnlyBroken!) {
        _filterOnlyWorking = false;
      } else if (_filterOnlyWorking!) {
        _filterOnlyBroken = false;
      }
    }
    
    // Filterung anwenden
    _applyFiltering(onlyWorking: _filterOnlyWorking, onlyFavorites: onlyFavorites);
    
    // State aktualisieren, wenn wir bereits geladen haben
    final currentState = state;
    
    if (currentState is HomeStateLoaded) {
      final favoritesList = currentState.favorites;
      final searchQ = currentState.searchQuery;
      
      emit(HomeStateLoaded(
        _filteredMcDonaldsData, 
        currentState.position,
        filtered: _filterOnlyBroken != null || _filterOnlyWorking != null,
        showOnlyBroken: _filterOnlyBroken,
        showOnlyWorking: _filterOnlyWorking,
        lastUpdated: _lastUpdated,
        searchQuery: searchQ,
        favorites: favoritesList,
      ));
    } else if (currentState is HomeStateNoLocation) {
      final favoritesList = currentState.favorites;
      final searchQ = currentState.searchQuery;
      
      emit(HomeStateNoLocation(
        _filteredMcDonaldsData,
        filtered: _filterOnlyBroken != null || _filterOnlyWorking != null,
        showOnlyBroken: _filterOnlyBroken,
        showOnlyWorking: _filterOnlyWorking,
        lastUpdated: _lastUpdated,
        searchQuery: searchQ,
        favorites: favoritesList,
      ));
    } else if (currentState is HomeStateOffline) {
      emit(HomeStateOffline(
        message: currentState.message,
        locations: _filteredMcDonaldsData,
        position: _currentPosition,
        lastUpdated: _lastUpdated,
      ));
    }
  }
  
  /// Verarbeitet eine Suchanfrage
  ///
  /// [event] enthält den Suchbegriff
  /// [emit] wird verwendet, um neue Zustände zu emittieren
  Future<void> _onSearchLocations(
    SearchLocationsEvent event, 
    Emitter<HomeState> emit
  ) async {
    try {
      emit(HomeStateLoading());
      
      // Suche durchführen, nur wenn Suchbegriff nicht leer ist
      if (event.query.trim().isEmpty) {
        add(ResetSearchEvent());
        return;
      }
      
      final searchResults = await _repository.searchLocations(event.query);
      _filteredMcDonaldsData = searchResults;
      
      // State aktualisieren
      if (_currentPosition != null) {
        final currentState = state is HomeStateLoaded ? state as HomeStateLoaded : null;
        final favoritesList = currentState?.favorites ?? [];
        
        emit(HomeStateLoaded(
          _filteredMcDonaldsData, 
          _currentPosition!,
          filtered: true, // Die Ergebnisse sind durch die Suche gefiltert
          showOnlyBroken: _filterOnlyBroken,
          showOnlyWorking: null,
          lastUpdated: _lastUpdated,
          searchQuery: event.query,
          favorites: favoritesList,
        ));
      } else {
        final currentState = state is HomeStateNoLocation ? state as HomeStateNoLocation : null;
        final favoritesList = currentState?.favorites ?? [];
        
        emit(HomeStateNoLocation(
          _filteredMcDonaldsData,
          filtered: true, // Die Ergebnisse sind durch die Suche gefiltert
          showOnlyBroken: _filterOnlyBroken,
          showOnlyWorking: null,
          lastUpdated: _lastUpdated,
          searchQuery: event.query,
          favorites: favoritesList,
        ));
      }
    } catch (e) {
      log("Fehler bei der Suche: $e");
      emit(HomeStateError("Suche fehlgeschlagen: $e"));
    }
  }
  
  /// Verarbeitet eine Anforderung zum Laden von Standorten in einem Kartenbereich
  ///
  /// [event] enthält die Grenzen des Kartenbereichs
  /// [emit] wird verwendet, um neue Zustände zu emittieren
  Future<void> _onLoadLocationsInView(
    LoadLocationsInViewEvent event, 
    Emitter<HomeState> emit
  ) async {
    try {
      // Wir setzen keinen Loading-State, um die UI nicht flackern zu lassen
      
      // Standorte innerhalb der Grenzen laden
      final locationsInView = await _repository.getLocationsInBounds(
        event.minLat, 
        event.maxLat, 
        event.minLng, 
        event.maxLng,
        forceRefresh: event.forceRefresh,
      );
      
      // Wenn wir einen Filter haben, wenden wir ihn auf die neuen Daten an
      List<McDonaldsLocation> filteredLocationsInView;
      if (_filterOnlyBroken != null) {
        filteredLocationsInView = locationsInView
            .where((location) => location.properties.isBroken == _filterOnlyBroken)
            .toList();
      } else {
        filteredLocationsInView = locationsInView;
      }
      
      // State aktualisieren, ohne den vorherigen komplett zu ersetzen
      final currentState = state;
      
      if (currentState is HomeStateLoaded) {
        emit(currentState.copyWith(
          mcdonalds_data: filteredLocationsInView,
          lastUpdated: _lastUpdated,
        ));
      } else if (currentState is HomeStateNoLocation) {
        emit(HomeStateNoLocation(
          filteredLocationsInView,
          filtered: _filterOnlyBroken != null,
          showOnlyBroken: _filterOnlyBroken,
          lastUpdated: _lastUpdated,
        ));
      } else if (_currentPosition != null) {
        emit(HomeStateLoaded(
          filteredLocationsInView,
          _currentPosition!,
          filtered: _filterOnlyBroken != null,
          showOnlyBroken: _filterOnlyBroken,
          lastUpdated: _lastUpdated,
        ));
      } else {
        emit(HomeStateNoLocation(
          filteredLocationsInView,
          filtered: _filterOnlyBroken != null,
          showOnlyBroken: _filterOnlyBroken,
          lastUpdated: _lastUpdated,
        ));
      }
    } catch (e) {
      log("Fehler beim Laden der Standorte im Kartenbereich: $e");
      // Wir emittieren keinen Fehler-State, um die Benutzererfahrung nicht zu stören
      // Stattdessen behalten wir den aktuellen Zustand bei
    }
  }

  /// Wendet den aktuellen Filter auf die geladenen Daten an
  ///
  /// Aktualisiert die _filteredMcDonaldsData-Liste basierend auf dem
  /// aktuellen _filterOnlyBroken-Wert
  void _applyFiltering({bool? onlyWorking, bool onlyFavorites = false}) {
    _filteredMcDonaldsData = List.from(_allMcDonaldsData);
    
    // Filter nach Status der Eismaschine
    if (_filterOnlyBroken != null) {
      // Nur defekte anzeigen
      _filteredMcDonaldsData = _filteredMcDonaldsData
          .where((location) => location.properties.isBroken == _filterOnlyBroken)
          .toList();
    } else if (onlyWorking != null && onlyWorking) {
      // Nur funktionierende anzeigen
      _filteredMcDonaldsData = _filteredMcDonaldsData
          .where((location) => location.properties.isBroken == false)
          .toList();
    }
    
    // Filter nach Favoriten
    if (onlyFavorites && _favorites.isNotEmpty) {
      _filteredMcDonaldsData = _filteredMcDonaldsData
          .where((location) {
            final String locationId = '${location.geometry.coordinates[0]}_${location.geometry.coordinates[1]}';
            return _favorites.contains(locationId);
          })
          .toList();
    }
  }

  /// Bestimmt die aktuelle Position des Geräts
  ///
  /// Überprüft Berechtigungen und Verfügbarkeit der Ortungsdienste,
  /// bevor die aktuelle Position abgerufen wird.
  ///
  /// Gibt die aktuelle [Position] zurück oder wirft einen Fehler,
  /// wenn die Position nicht bestimmt werden kann
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Überprüfen, ob der Ortungsdienst aktiviert ist
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Ortungsdienste sind deaktiviert.');
    }

    // Überprüfen oder Anfordern von Berechtigungen
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Ortungsberechtigungen wurden verweigert.');
      }
    }

    // Wenn die Berechtigungen dauerhaft verweigert wurden
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Ortungsberechtigungen wurden dauerhaft verweigert. Wir können keine Berechtigungen anfordern.');
    }

    // Aktuelle Position abrufen
    return await Geolocator.getCurrentPosition();
  }
  
  /// Verarbeitet ein Zurücksetzen der Suche
  ///
  /// [event] enthält die Parameter für das Event
  /// [emit] wird verwendet, um neue Zustände zu emittieren
  Future<void> _onResetSearch(
    ResetSearchEvent event,
    Emitter<HomeState> emit
  ) async {
    try {
      if (state is HomeStateLoaded) {
        final currentState = state as HomeStateLoaded;

        // Filter aufheben und alle Daten anzeigen
        emit(currentState.copyWith(
          mcdonalds_data: _allMcDonaldsData, 
          searchQuery: null,
        ));
      }
    } catch (e) {
      log("Fehler beim Zurücksetzen der Suche: $e");
    }
  }
  
  /// Verarbeitet das Hinzufügen eines Standorts zu Favoriten
  ///
  /// [event] enthält die Parameter für das Event
  /// [emit] wird verwendet, um neue Zustände zu emittieren
  Future<void> _onAddToFavorites(
    AddToFavoritesEvent event,
    Emitter<HomeState> emit
  ) async {
    try {
      if (state is HomeStateLoaded) {
        final currentState = state as HomeStateLoaded;
        
        // Prüfen, ob der Standort bereits als Favorit markiert ist
        if (!currentState.favorites.contains(event.locationId)) {
          // Favoriten-Liste aktualisieren und persistieren
          _favorites = await _favoritesService.addFavorite(event.locationId);
          
          // Neuen Zustand emittieren
          emit(currentState.copyWith(favorites: _favorites));
        }
      } else if (state is HomeStateNoLocation) {
        final currentState = state as HomeStateNoLocation;
        
        // Favoriten-Liste aktualisieren und persistieren
        _favorites = await _favoritesService.addFavorite(event.locationId);
        
        // Neuen Zustand emittieren
        emit(HomeStateNoLocation(
          currentState.mcdonalds_data,
          filtered: currentState.filtered,
          showOnlyBroken: currentState.showOnlyBroken,
          showOnlyWorking: currentState.showOnlyWorking,
          lastUpdated: currentState.lastUpdated,
          searchQuery: currentState.searchQuery,
          favorites: _favorites,
        ));
      }
    } catch (e) {
      log("Fehler beim Hinzufügen zu Favoriten: $e");
    }
  }
  
  /// Verarbeitet das Entfernen eines Standorts aus Favoriten
  ///
  /// [event] enthält die Parameter für das Event
  /// [emit] wird verwendet, um neue Zustände zu emittieren
  Future<void> _onRemoveFromFavorites(
    RemoveFromFavoritesEvent event,
    Emitter<HomeState> emit
  ) async {
    try {
      if (state is HomeStateLoaded) {
        final currentState = state as HomeStateLoaded;
        
        // Favoriten-Liste aktualisieren und persistieren
        _favorites = await _favoritesService.removeFavorite(event.locationId);
        
        // Neuen Zustand emittieren
        emit(currentState.copyWith(favorites: _favorites));
      } else if (state is HomeStateNoLocation) {
        final currentState = state as HomeStateNoLocation;
        
        // Favoriten-Liste aktualisieren und persistieren
        _favorites = await _favoritesService.removeFavorite(event.locationId);
        
        // Neuen Zustand emittieren
        emit(HomeStateNoLocation(
          currentState.mcdonalds_data,
          filtered: currentState.filtered,
          showOnlyBroken: currentState.showOnlyBroken,
          showOnlyWorking: currentState.showOnlyWorking,
          lastUpdated: currentState.lastUpdated,
          searchQuery: currentState.searchQuery,
          favorites: _favorites,
        ));
      }
    } catch (e) {
      log("Fehler beim Entfernen aus Favoriten: $e");
    }
  }

  /// Analysiert die McDonaldsLocation-Daten und gibt eine Zusammenfassung der Länderverteilung aus
  ///
  /// Diese Methode zählt die verschiedenen Länder und gibt eine Zusammenfassung im Log aus.
  void logCountryStatistics() {
    if (_allMcDonaldsData.isEmpty) {
      log("Keine McDonaldsLocation-Daten verfügbar für die Länderanalyse.");
      return;
    }

    // Zähle die Anzahl der Standorte pro Land
    final Map<String, int> countryCounts = {};
    
    for (var location in _allMcDonaldsData) {
      final country = location.properties.country;
      
      // Überspringe leere Länderbezeichnungen
      if (country.isEmpty) continue;
      
      // Zähler für das Land erhöhen oder initialisieren
      countryCounts[country] = (countryCounts[country] ?? 0) + 1;
    }

    // Sortiere die Länder nach Anzahl der Standorte (absteigend)
    final sortedCountries = countryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Logge eine Zusammenfassung
    final int totalCountries = countryCounts.length;
    final int totalLocations = _allMcDonaldsData.length;
    
    log("===== LÄNDERSTATISTIK =====");
    log("Standorte aus $totalCountries verschiedenen Ländern gefunden (gesamt: $totalLocations)");
    
    for (var entry in sortedCountries) {
      final percentage = (entry.value / totalLocations * 100).toStringAsFixed(1);
      log("${entry.key}: ${entry.value} Standorte ($percentage%)");
    }
    
    log("==========================");
  }

  /// Bereinigt Ressourcen beim Schließen des Bloc
  ///
  /// Stellt sicher, dass alle StreamSubscriptions abgemeldet werden
  @override
  Future<void> close() {
    _internetStreamSubscription?.cancel();
    return super.close();
  }
}
