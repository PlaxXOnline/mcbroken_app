// filepath: /Users/janikkahle/Documents/Development/Projekte/Mobile/mcbroken_app/lib/logic/blocs/home/home_bloc_updated.dart
import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mcbroken/data/models/mcdonalds_location.dart';
import 'package:mcbroken/data/repository/mcdonalds_repository.dart';
import 'package:mcbroken/logic/cubits/connectivity/internet_cubit.dart';
import 'package:mcbroken/services/api/api_error_handler.dart';
import 'package:meta/meta.dart';

part 'home_event_updated.dart';
part 'home_state_updated.dart';

/// Bloc zur Verwaltung des Zustands der Startseite und der McDonald's-Standortdaten
///
/// Der HomeBloc ist verantwortlich für das Laden und Filtern von McDonald's-Standortdaten,
/// die Überwachung des Verbindungsstatus und die Aktualisierung der UI entsprechend des
/// aktuellen Datenstatus.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  /// Repository für den Zugriff auf McDonald's-Daten
  final McDonaldsRepository _repository;
  
  /// InternetCubit zur Überwachung der Internetverbindung
  final InternetCubit? _internetCubit;
  
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
  
  /// Zeitpunkt der letzten Aktualisierung der Daten
  DateTime? _lastUpdated;

  /// Erstellt eine neue Instanz des HomeBloc
  ///
  /// [repository] ist das Repository, das für den Zugriff auf die Daten verwendet wird.
  /// [internetCubit] ist optional und wird für die Überwachung des Netzwerkstatus verwendet.
  HomeBloc({
    required McDonaldsRepository repository,
    InternetCubit? internetCubit,
  }) : _repository = repository,
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
    
    // Filterung anwenden
    _applyFiltering();
    
    // State aktualisieren, wenn wir bereits geladen haben
    final currentState = state;
    
    if (currentState is HomeStateLoaded) {
      emit(HomeStateLoaded(
        _filteredMcDonaldsData, 
        currentState.position,
        filtered: _filterOnlyBroken != null,
        showOnlyBroken: _filterOnlyBroken,
        lastUpdated: _lastUpdated,
      ));
    } else if (currentState is HomeStateNoLocation) {
      emit(HomeStateNoLocation(
        _filteredMcDonaldsData,
        filtered: _filterOnlyBroken != null,
        showOnlyBroken: _filterOnlyBroken,
        lastUpdated: _lastUpdated,
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
      
      // Suche durchführen
      final searchResults = await _repository.searchLocations(event.query);
      _filteredMcDonaldsData = searchResults;
      
      // State aktualisieren
      if (_currentPosition != null) {
        emit(HomeStateLoaded(
          _filteredMcDonaldsData, 
          _currentPosition!,
          filtered: true, // Die Ergebnisse sind durch die Suche gefiltert
          showOnlyBroken: _filterOnlyBroken,
          lastUpdated: _lastUpdated,
          searchQuery: event.query,
        ));
      } else {
        emit(HomeStateNoLocation(
          _filteredMcDonaldsData,
          filtered: true, // Die Ergebnisse sind durch die Suche gefiltert
          showOnlyBroken: _filterOnlyBroken,
          lastUpdated: _lastUpdated,
          searchQuery: event.query,
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
  void _applyFiltering() {
    if (_filterOnlyBroken != null) {
      _filteredMcDonaldsData = _allMcDonaldsData
          .where((location) => location.properties.isBroken == _filterOnlyBroken)
          .toList();
    } else {
      _filteredMcDonaldsData = List.from(_allMcDonaldsData);
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
  
  /// Bereinigt Ressourcen beim Schließen des Bloc
  ///
  /// Stellt sicher, dass alle StreamSubscriptions abgemeldet werden
  @override
  Future<void> close() {
    _internetStreamSubscription?.cancel();
    return super.close();
  }
}
