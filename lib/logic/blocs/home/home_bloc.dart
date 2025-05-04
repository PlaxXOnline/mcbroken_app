// filepath: /Users/janikkahle/Documents/Development/Projekte/Mobile/mcbroken_app/lib/logic/blocs/home/home_bloc.dart
import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mcbroken/data/models/mcdonalds_model.dart';
import 'package:mcbroken/data/repository/mcdonalds_repository.dart';
import 'package:mcbroken/logic/cubits/connectivity/internet_cubit.dart';
import 'package:meta/meta.dart';

part 'home_event.dart';
part 'home_state.dart';

/// Bloc zur Verwaltung des Zustands der Startseite und der Daten
///
/// Der HomeBloc ist verantwortlich für das Laden und Filtern von McDonald's-Standortdaten
/// sowie für die Überwachung des Verbindungsstatus.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  /// InternetCubit zur Überwachung der Internetverbindung
  final InternetCubit? internetCubit;
  
  /// Repository für den Zugriff auf McDonald's-Daten
  final McDonaldsRepository mcDonaldsRepository = McDonaldsRepository();
  
  /// Subscription für Internetstatus-Updates
  late StreamSubscription? internetStreamSubscription;
  
  /// Alle geladenen McDonald's-Standorte
  List<Mcdonalds_model> allMcDonaldsData = [];
  
  /// Gefilterte Liste der McDonald's-Standorte (z.B. basierend auf Defekt-Status)
  List<Mcdonalds_model> filteredMcDonaldsData = [];
  
  /// Aktuelle Position des Benutzers, falls verfügbar
  Position? currentPosition;
  
  /// Filter-Flag, ob nur Standorte mit defekten Eismaschinen angezeigt werden sollen
  bool? filterOnlyBroken;

  /// Konstruktor für den HomeBloc
  ///
  /// @param internetCubit Optional: Ein InternetCubit zur Überwachung der Internetverbindung
  HomeBloc({this.internetCubit}) : super(HomeStateInitial()) {
    log("HomeBloc initializing...");

    // Verbindung mit dem InternetCubit herstellen, um Netzwerkänderungen zu überwachen
    if (internetCubit != null) {
      internetStreamSubscription = internetCubit?.stream.listen((internetState) {
        if (internetState is InternetConnected && state is HomeStateError) {
          add(DataRequestEvent(forceRefresh: true));
        }
      });
    }

    // Event zum Anfordern von Daten
    on<DataRequestEvent>((event, emit) async {
      await _handleDataRequest(event, emit);
    });

    // Event zum manuellen Aktualisieren der Daten
    on<RefreshDataEvent>((event, emit) async {
      await _handleDataRefresh(emit);
    });

    // Event zum Filtern von Standorten
    on<FilterLocationsEvent>((event, emit) async {
      await _handleLocationFiltering(event, emit);
    });
  }
  
  /// Stellt sicher, dass alle Ressourcen beim Schließen des Blocs freigegeben werden
  ///
  /// Diese Methode wird aufgerufen, wenn der Bloc nicht mehr benötigt wird.
  /// @return Ein Future, das abgeschlossen wird, wenn alle Ressourcen freigegeben wurden
  @override
  Future<void> close() {
    internetStreamSubscription?.cancel();
    return super.close();
  }

  /// Verarbeitet Datenanfragen und lädt McDonald's-Daten
  ///
  /// Diese Methode lädt die Daten, bestimmt die Position des Benutzers (falls möglich)
  /// und gibt den entsprechenden Zustand zurück.
  ///
  /// @param event Das DataRequestEvent mit Parametern für die Anfrage
  /// @param emit Die Emitter-Funktion zum Aktualisieren des Zustands
  /// @return Ein Future, das abgeschlossen wird, wenn die Anfrage bearbeitet wurde
  Future<void> _handleDataRequest(DataRequestEvent event, Emitter<HomeState> emit) async {
    try {
      emit(HomeStateLoading());
      
      // Aktuelle Position bestimmen
      try {
        currentPosition = await _determinePosition();
        log("Position bestimmt: $currentPosition");
      } catch (e) {
        log("Fehler beim Bestimmen der Position: $e");
        // Wir setzen trotzdem fort, aber ohne Positionsangabe
      }
      
      // Daten aus dem Repository laden
      allMcDonaldsData = await mcDonaldsRepository.getDataFromMcDonalds(
        forceRefresh: event.forceRefresh,
      );
      
      // Daten filtern, falls ein Filter aktiv ist
      _applyFiltering();
      
      // State aktualisieren
      if (currentPosition != null) {
        emit(HomeStateLoaded(
          filteredMcDonaldsData, 
          currentPosition!,
          filtered: filterOnlyBroken != null,
          showOnlyBroken: filterOnlyBroken,
        ));
      } else {
        emit(HomeStateError("Standort konnte nicht bestimmt werden. Daten wurden trotzdem geladen."));
      }
      
      log('HomeState geladen mit ${filteredMcDonaldsData.length} Standorten');
    } catch (e) {
      log("Fehler beim Laden der Daten: $e");
      emit(HomeStateError("Fehler beim Laden der Daten: $e"));
    }
  }
  
  /// Verarbeitet Datenaktualisierungsanforderungen
  ///
  /// Lädt die Daten neu mit erzwungenem Refresh.
  ///
  /// @param emit Die Emitter-Funktion zum Aktualisieren des Zustands
  /// @return Ein Future, das abgeschlossen wird, wenn die Aktualisierung abgeschlossen ist
  Future<void> _handleDataRefresh(Emitter<HomeState> emit) async {
    try {
      emit(HomeStateLoading());
      
      // Daten mit erzwungenem Refresh laden
      allMcDonaldsData = await mcDonaldsRepository.getDataFromMcDonalds(
        forceRefresh: true,
      );
      
      // Filter anwenden
      _applyFiltering();
      
      // State aktualisieren
      if (currentPosition != null) {
        emit(HomeStateLoaded(
          filteredMcDonaldsData, 
          currentPosition!,
          filtered: filterOnlyBroken != null,
          showOnlyBroken: filterOnlyBroken,
        ));
      } else {
        emit(HomeStateError("Standort konnte nicht bestimmt werden. Daten wurden trotzdem geladen."));
      }
      
    } catch (e) {
      log("Fehler beim Aktualisieren der Daten: $e");
      emit(HomeStateError("Aktualisierung fehlgeschlagen: $e"));
    }
  }
  
  /// Verarbeitet Filteranforderungen
  ///
  /// Filtert die Standorte basierend auf dem angegebenen Filter.
  ///
  /// @param event Das FilterLocationsEvent mit dem anzuwendenden Filter
  /// @param emit Die Emitter-Funktion zum Aktualisieren des Zustands
  /// @return Ein Future, das abgeschlossen wird, wenn die Filterung abgeschlossen ist
  Future<void> _handleLocationFiltering(FilterLocationsEvent event, Emitter<HomeState> emit) async {
    // Filter speichern
    filterOnlyBroken = event.onlyBroken;
    
    // Filterung anwenden
    _applyFiltering();
    
    // State aktualisieren, wenn wir bereits geladen haben
    if (state is HomeStateLoaded && currentPosition != null) {
      emit(HomeStateLoaded(
        filteredMcDonaldsData, 
        currentPosition!,
        filtered: filterOnlyBroken != null,
        showOnlyBroken: filterOnlyBroken,
      ));
    }
  }
  
  /// Hilfsmethode zum Anwenden des Filters
  ///
  /// Filtert die allMcDonaldsData nach dem aktuellen filterOnlyBroken-Wert
  /// und speichert das Ergebnis in filteredMcDonaldsData.
  void _applyFiltering() {
    if (filterOnlyBroken != null) {
      filteredMcDonaldsData = allMcDonaldsData
          .where((location) => location.properties.is_broken == filterOnlyBroken)
          .toList();
    } else {
      filteredMcDonaldsData = List.from(allMcDonaldsData);
    }
  }

  /// Hilfsmethode zur Bestimmung der aktuellen Position
  ///
  /// Prüft die Berechtigungen und ruft die aktuelle Geräteposition ab, sofern erlaubt.
  ///
  /// @return Ein Future mit der aktuellen Position
  /// @throws Verschiedene Exceptions, wenn die Position nicht ermittelt werden kann
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Ortungsdienste sind deaktiviert.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Ortungsberechtigungen wurden verweigert.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Ortungsberechtigungen wurden dauerhaft verweigert. Wir können keine Berechtigungen anfordern.');
    }

    return await Geolocator.getCurrentPosition();
  }
}
