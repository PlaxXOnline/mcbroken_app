// filepath: /Users/janikkahle/Documents/Development/Projekte/Mobile/mcbroken_app/lib/presentation/widgets/map.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster_plus/flutter_map_marker_cluster_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mcbroken/data/models/mcdonalds_location.dart';
import 'package:mcbroken/logic/blocs/home/home_bloc.dart';
import 'package:mcbroken/l10n/app_localizations.dart';
import 'package:mcbroken/logic/cubits/settings/settings_cubit.dart';
import 'package:mcbroken/presentation/widgets/facilitymarker.dart';
import 'package:mcbroken/presentation/widgets/infopopup.dart';

/// Widget zur Darstellung von McDonald's-Standorten auf einer interaktiven Karte.
///
/// Diese Kartenansicht zeigt alle McDonald's-Standorte mit farblichen Markierungen,
/// die den Zustand der Eismaschinen anzeigen (grün für funktionierend, rot für defekt).
/// Die Karte unterstützt Clustering, um bei vielen sichtbaren Markern eine übersichtliche
/// Darstellung zu gewährleisten.
class McDonaldsMap extends StatefulWidget {
  /// Erstellt eine neue McDonaldsMap-Instanz.
  ///
  /// @param key Optionaler Widget-Key zur Identifikation.
  const McDonaldsMap({Key? key}) : super(key: key);

  @override
  State<McDonaldsMap> createState() => _McDonaldsMapState();
}

/// Der Zustand des McDonaldsMap-Widgets.
///
/// Verwaltet den lokalen Status der Karte, einschließlich der Controller
/// für die Kartennavigation und die Popup-Anzeigen.
class _McDonaldsMapState extends State<McDonaldsMap> {
  /// Controller für die Kartenansicht.
  ///
  /// Ermöglicht programmatisches Steuern der Kartenposition und des Zoom-Levels.
  late final MapController _mapController;
  
  /// Controller für Popup-Anzeigen.
  ///
  /// Wird verwendet, um Popups programmatisch zu steuern (anzeigen/ausblenden).
  final PopupController _popupController = PopupController();
  
  /// Controller für das Suchfeld.
  ///
  /// Verwaltet den Text im Suchfeld und ermöglicht das Löschen des Texts.
  final TextEditingController _searchController = TextEditingController();
  
  /// Timer für verzögerte Suche (Debouncing).
  ///
  /// Verhindert zu häufige Aktualisierungen während der Texteingabe.
  Timer? _debounceTimer;

  /// Standardposition für die Karte (Stuttgart, Deutschland).
  ///
  /// Diese Position wird verwendet, wenn keine aktuelle Benutzerposition verfügbar ist.
  static const LatLng _defaultPosition = LatLng(48.7758, 9.1829);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Aktueller HomeState, um Suchtext zu synchronisieren
    final homeState = context.read<HomeBloc>().state;
    String? searchQuery;
    
    if (homeState is HomeStateLoaded) {
      searchQuery = homeState.searchQuery;
    } else if (homeState is HomeStateNoLocation) {
      searchQuery = homeState.searchQuery;
    }
    
    if (searchQuery != null && _searchController.text != searchQuery) {
      _searchController.text = searchQuery;
    }
  }

    @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Zoomt automatisch zu den Suchergebnissen
  ///
  /// Diese Methode berechnet den optimalen Kartenausschnitt basierend auf den
  /// gefundenen McDonald's-Standorten und zoomt entsprechend heran.
  /// Zusätzlich wird sichergestellt, dass die Map-Tiles korrekt geladen werden.
  ///
  /// [locations] Liste der gefundenen Standorte
  void _zoomToSearchResults(List<McDonaldsLocation> locations) {
    if (locations.isEmpty) return;

    if (locations.length == 1) {
      // Bei einem Ergebnis: Direkt zu diesem Standort zoomen
      final location = locations.first;
      final coordinates = location.geometry.coordinates;
      if (coordinates.length >= 2) {
        final targetPosition = LatLng(coordinates[1], coordinates[0]);
        const targetZoom = 15.0;
        
        // Force tile loading durch kleine Bewegung und dann zur korrekten Position
        _forceTileRefresh(targetPosition, targetZoom);
      }
    } else {
      // Bei mehreren Ergebnissen: Berechne Bounding Box und zoome entsprechend
      double minLat = double.infinity;
      double maxLat = -double.infinity;
      double minLng = double.infinity;
      double maxLng = -double.infinity;

      for (final location in locations) {
        final coordinates = location.geometry.coordinates;
        if (coordinates.length >= 2) {
          final lat = coordinates[1];
          final lng = coordinates[0];
          
          minLat = lat < minLat ? lat : minLat;
          maxLat = lat > maxLat ? lat : maxLat;
          minLng = lng < minLng ? lng : minLng;
          maxLng = lng > maxLng ? lng : maxLng;
        }
      }

      // Sicherheitsabstand hinzufügen (10% der Spanne)
      final latPadding = (maxLat - minLat) * 0.1;
      final lngPadding = (maxLng - minLng) * 0.1;
      
      minLat -= latPadding;
      maxLat += latPadding;
      minLng -= lngPadding;
      maxLng += lngPadding;

      // Zentrum der Bounding Box berechnen
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;

      // Zoom-Level basierend auf der Spanne berechnen
      final latDiff = maxLat - minLat;
      final lngDiff = maxLng - minLng;
      final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
      
      double zoomLevel = 15.0; // Standard-Zoom
      if (maxDiff > 1.0) {
        zoomLevel = 8.0;
      } else if (maxDiff > 0.5) {
        zoomLevel = 10.0;
      } else if (maxDiff > 0.1) {
        zoomLevel = 12.0;
      } else if (maxDiff > 0.05) {
        zoomLevel = 13.0;
      } else if (maxDiff > 0.01) {
        zoomLevel = 14.0;
      }

      final targetPosition = LatLng(centerLat, centerLng);
      
      // Force tile loading durch kleine Bewegung und dann zur korrekten Position
      _forceTileRefresh(targetPosition, zoomLevel);
    }
  }

  /// Erzwingt das Neuladen der Map-Tiles durch eine Sequenz von Bewegungen
  ///
  /// Diese Methode umgeht das Problem, dass Flutter Map nach einem programmatischen
  /// move() die Tiles nicht automatisch neu lädt, indem sie eine kleine Bewegung
  /// macht und dann zur korrekten Position zurückkehrt.
  ///
  /// [targetPosition] Die finale Position der Karte
  /// [targetZoom] Das finale Zoom-Level
  void _forceTileRefresh(LatLng targetPosition, double targetZoom) {
    // Schritt 1: Kleine Verschiebung um Tile-Loading zu aktivieren
    final offsetPosition = LatLng(
      targetPosition.latitude + 0.001, // Minimale Verschiebung
      targetPosition.longitude + 0.001,
    );
    
    // Erste kleine Bewegung
    _mapController.move(offsetPosition, targetZoom);
    
    // Schritt 2: Nach kurzer Verzögerung zur korrekten Position
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _mapController.move(targetPosition, targetZoom);
        
        // Schritt 3: Zusätzlicher "Wackler" um sicherzustellen, dass Tiles geladen werden
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            final microOffset = LatLng(
              targetPosition.latitude + 0.0001,
              targetPosition.longitude + 0.0001,
            );
            _mapController.move(microOffset, targetZoom);
            
            // Schritt 4: Finale Position
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                _mapController.move(targetPosition, targetZoom);
              }
            });
          }
        });
      }
    });
  }

  /// Erstellt eine modern gestylte Suchleiste mit verzögerter Suche und Filter-Button
  ///
  /// Diese Suchleiste wird über der Karte platziert und ermöglicht das Suchen
  /// und Filtern von McDonald's-Standorten mit verbesserter Optik.
  Widget _buildSearchBar(BuildContext context, AppLocalizations locale) {
    final homeBloc = context.read<HomeBloc>();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Hauptsuchfeld
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: locale.searchHint,
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 16.0,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(12.0),
                    child: Icon(
                      Icons.search_rounded,
                      color: Colors.grey[600],
                      size: 22.0,
                    ),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? Container(
                          margin: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: Colors.grey[600],
                              size: 20.0,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              homeBloc.add(ResetSearchEvent());
                              setState(() {});
                            },
                            splashRadius: 20.0,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 14.0,
                  ),
                  isDense: true,
                ),
                onChanged: (value) {
                  // UI aktualisieren für den Clear-Button
                  setState(() {});
                  
                  // Debouncing: Suche erst starten, wenn der Benutzer aufhört zu tippen
                  if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
                  
                  if (value.isEmpty) {
                    homeBloc.add(ResetSearchEvent());
                  } else if (value.length >= 2) { // Schon ab 2 Zeichen suchen
                    // Längere Verzögerung für ein stabileres Verhalten
                    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
                      // Nur suchen, wenn der Text im Suchfeld noch der gleiche ist
                      if (_searchController.text == value) {
                        homeBloc.add(SearchLocationsEvent(query: value));
                      }
                    });
                  }
                },
                onSubmitted: (value) {
                  // Bei explizitem Suchen per Enter, immer sofort suchen ohne Debounce
                  if (value.isNotEmpty) {
                    // Debounce-Timer abbrechen, um doppelte Suchen zu vermeiden
                    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
                    homeBloc.add(SearchLocationsEvent(query: value, isExplicitSearch: true));
                  } else {
                    homeBloc.add(ResetSearchEvent());
                  }
                },
              ),
            ),
          ),
          
          // Trennlinie
          Container(
            height: 24.0,
            width: 1.0,
            color: Colors.grey[300],
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
          ),
          
          // Filter-Button mit verbesserter Optik
          Container(
            margin: const EdgeInsets.only(right: 8.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20.0),
                onTap: () => _showFilterDialog(context, locale),
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  child: Icon(
                    Icons.tune_rounded,
                    color: Colors.grey[700],
                    size: 22.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Zeigt einen Dialog mit Filteroptionen an
  Future<void> _showFilterDialog(BuildContext context, AppLocalizations locale) async {
    bool onlyFavorites = false;
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final homeBloc = context.read<HomeBloc>();
        final currentState = homeBloc.state;
        
        bool? showOnlyBroken;
        bool? showOnlyWorking;
        
        if (currentState is HomeStateLoaded) {
          showOnlyBroken = currentState.showOnlyBroken;
          showOnlyWorking = currentState.showOnlyWorking;
        } else if (currentState is HomeStateNoLocation) {
          showOnlyBroken = currentState.showOnlyBroken;
          showOnlyWorking = currentState.showOnlyWorking;
        }
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(locale.filterTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(locale.showAll),
                    leading: Radio<bool?>(
                      value: null,
                      groupValue: showOnlyBroken == null && showOnlyWorking == null ? null : false,
                      onChanged: (value) {
                        setState(() {
                          showOnlyBroken = null;
                          showOnlyWorking = null;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: Text(locale.showOnlyDefect),
                    leading: Radio<bool?>(
                      value: true,
                      groupValue: showOnlyBroken,
                      onChanged: (value) {
                        setState(() {
                          showOnlyBroken = value;
                          showOnlyWorking = null;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: Text(locale.showOnlyWorking),
                    leading: Radio<bool?>(
                      value: true,
                      groupValue: showOnlyWorking,
                      onChanged: (value) {
                        setState(() {
                          showOnlyWorking = value;
                          showOnlyBroken = null;
                        });
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: Text(locale.favorites),
                    leading: Checkbox(
                      value: onlyFavorites,
                      onChanged: (value) {
                        setState(() {
                          onlyFavorites = value ?? false;
                        });
                      },
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(locale.cancel),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(locale.apply),
                  onPressed: () {
                    homeBloc.add(FilterLocationsEvent(
                      onlyBroken: showOnlyBroken,
                      onlyWorking: showOnlyWorking,
                      onlyFavorites: onlyFavorites,
                    ));
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Konvertiert eine Liste von McDonald's-Modellen in eine Liste von Kartenmarkern.
  ///
  /// Diese Methode transformiert die Rohdaten in Marker für die Kartenansicht und
  /// setzt die Farbe basierend auf dem Status der Eismaschine (grün/rot).
  ///
  /// @param data Liste der McDonald's-Standortdaten als Modellobjekte.
  /// @param size Bildschirmgröße für responsive Darstellung.
  /// @return Liste von Markern zur Darstellung auf der Karte.
  List<Marker> _buildMarkers(List<McDonaldsLocation> data, Size size) {
    // Sicherstellen, dass wir nur valide Daten verarbeiten
    if (data.isEmpty) {
      return [];
    }
    
    final List<Marker> resultMarkers = [];
    
    for (final location in data) {
      // Koordinaten aus dem Datensatz extrahieren und konvertieren
      double? latitude;
      double? longitude;
      
      try {
        // Längen- und Breitengrade aus den Koordinaten extrahieren
        longitude = location.geometry.coordinates[0];
        latitude = location.geometry.coordinates[1];
            
        // Koordinaten-Vertauschung erkennen und korrigieren
        if (latitude > 90 || latitude < -90) {
          // Wenn der Breitengrad außerhalb des gültigen Bereichs liegt, könnten die Werte vertauscht sein
          final temp = latitude;
          latitude = longitude;
          longitude = temp;
        }
      } catch (e) {
        // Bei Konvertierungsfehlern diesen Marker überspringen
        continue;
      }
      
      // Marker-Status (rot oder grün) festlegen basierend auf dem Status der Eismaschine
      final String dotStatus = location.properties.isBroken ? 'broken' : 'working';
      
      // Gültigen Marker erstellen
      final marker = FacilityMarker(
        width: 30, // Feste Werte für stabile Darstellung
        height: 30,
        point: LatLng(latitude, longitude),
        city: location.properties.city,
        street: location.properties.street,
        dot: dotStatus,
        child: Icon(
          Icons.location_on,
          color: dotStatus == 'working' ? Colors.green : Colors.red,
          size: 30.0,
        ),
      );
      
      resultMarkers.add(marker);
    }
    
    return resultMarkers;
  }

  /// Erstellt einen Container mit einer Attribution für OpenStreetMap.
  /// 
  /// Diese Attributionsanzeige ist gemäß den Nutzungsbedingungen von OpenStreetMap erforderlich.
  ///
  /// @return Ein Widget, das die erforderlichen Attributionsinformationen anzeigt.
  Widget _buildAttribution() {
    return Positioned(
      left: 5,
      bottom: 5,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          children: [
            Text(
              '© ',
              style: TextStyle(fontSize: 10),
            ),
            Text(
              'OpenStreetMap contributors',
              style: TextStyle(fontSize: 10, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Bildschirmgröße und Lokalisierung für responsive Gestaltung
    final Size size = MediaQuery.sizeOf(context);
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    
    return BlocBuilder<HomeBloc, HomeState>(
      buildWhen: (previous, current) => 
        current is HomeStateLoaded || current is HomeStateNoLocation || 
        current is HomeStateError || current is HomeStateInitial,
      builder: (context, homeState) {
        // Position und Markerdaten basierend auf dem HomeState definieren
        Position? currentPosition;
        List<McDonaldsLocation> mcdonaldsData = [];
        
        // Je nach Zustand die entsprechenden Daten extrahieren
        if (homeState is HomeStateLoaded) {
          currentPosition = homeState.position;
          mcdonaldsData = homeState.mcdonalds_data;
          
          // Bei einer Suche automatisch zu den Ergebnissen zoomen
          if (homeState.searchQuery != null && homeState.searchQuery!.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Kleine Verzögerung um sicherzustellen, dass die Karte vollständig aufgebaut ist
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  _zoomToSearchResults(mcdonaldsData);
                }
              });
            });
          }
        } else if (homeState is HomeStateNoLocation) {
          mcdonaldsData = homeState.mcdonalds_data;
          
          // Bei einer Suche automatisch zu den Ergebnissen zoomen
          if (homeState.searchQuery != null && homeState.searchQuery!.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Kleine Verzögerung um sicherzustellen, dass die Karte vollständig aufgebaut ist
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  _zoomToSearchResults(mcdonaldsData);
                }
              });
            });
          }
        } else if (homeState is HomeStateOffline) {
          currentPosition = homeState.position;
          mcdonaldsData = homeState.locations;
        }
        
        // Marker erstellen und validieren
        final markers = _buildMarkers(mcdonaldsData, size);
        
        // Marker nach Status filtern
        final List<Marker> workingMarkers =
            markers.where((marker) {
              if (marker is FacilityMarker) {
                return marker.dot == 'working';
              }
              return false;
            }).toList();
            
        final List<Marker> notWorkingMarkers =
            markers.where((marker) {
              if (marker is FacilityMarker) {
                return marker.dot == 'broken';
              }
              return false;
            }).toList();
        
        return PopupScope(
          popupController: _popupController,
          child: BlocBuilder<SettingsCubit, SettingsState>(
            buildWhen: (previous, current) => previous != current,
            builder: (context, settingsState) {
              // Marker basierend auf Einstellungen filtern
              List<Marker> selectedMarkers = settingsState.showOnlyWorking
                  ? workingMarkers
                  : (settingsState.showOnlyDefect ? notWorkingMarkers : markers);
              
              // Initiale Position festlegen
              LatLng initialCenter = _defaultPosition;
              if (settingsState.showOwnPosition && currentPosition != null) {
                initialCenter = LatLng(
                  currentPosition.latitude,
                  currentPosition.longitude
                );
              }
              
              return Stack(
                children: [
                  // Hauptkarte
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: initialCenter,
                      initialZoom: 6.0, // Niedrigerer Zoom-Wert, um mehr Standorte zu sehen
                      minZoom: settingsState.allowZoom ? 3.0 : 6.0,
                      maxZoom: settingsState.allowZoom ? 18.0 : 15.0,
                      onTap: (_, __) => _popupController.hideAllPopups(),
                    ),
                    children: [
                      // Kartenkachel-Layer mit optimierter Konfiguration für besseres Tile-Loading
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'dev.kahle.mcbroken',
                        tileProvider: NetworkTileProvider(),
                        maxZoom: 19,
                        // Erweiterte Konfiguration für besseres Tile-Loading
                        keepBuffer: 3, // Mehr Tiles im Speicher behalten
                        panBuffer: 2, // Größerer Puffer beim Schwenken
                        tileDimension: 256,
                        // Sofortiges Tile-Loading aktivieren
                        retinaMode: false,
                        // Tile-Display-Optionen für bessere Performance
                        tileDisplay: const TileDisplay.fadeIn(
                          duration: Duration(milliseconds: 150),
                        ),
                        // Keine spezielle Tile-Builder um Standard-Verhalten zu nutzen
                      ),
                      
                      // *** WICHTIG: Der MarkerClusterLayer muss VOR einem normalen MarkerLayer kommen ***
                      // Da der MarkerClusterLayer sonst keine Klicks auf die Marker erhält
                      
                      // Marker-Cluster-Layer für McDonald's-Standorte mit optimierten Parametern
                      MarkerClusterLayerWidget(
                        options: MarkerClusterLayerOptions(
                          markers: selectedMarkers,
                          // Kleiner Clusterradius für bessere Verteilung
                          maxClusterRadius: 45,
                          // Größe des Cluster-Widgets
                          size: const Size(40, 40),
                          // Benutzerdefinierte Darstellung des Clusters
                          builder: (context, markers) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.8),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  markers.length.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          },
                          // Popup-Konfiguration
                          popupOptions: PopupOptions(
                            popupController: _popupController,
                            popupBuilder: (_, marker) {
                              if (marker is FacilityMarker) {
                                return InfoPopup(
                                  size: size,
                                  locale: localizations,
                                  facilityMarker: marker,
                                  popupController: _popupController,
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      
                      // Aktuelle Position des Benutzers
                      if (currentPosition != null) 
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(currentPosition.latitude, currentPosition.longitude),
                              width: 40,
                              height: 40,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.my_location,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  
                  // Attribution für OpenStreetMap
                  _buildAttribution(),
                  
                  // Suchleiste am oberen Rand der Karte mit modernem Design
                  Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: _buildSearchBar(context, localizations),
                  ),
                  
                  // Button zum Zurückkehren zur aktuellen Position
                  Positioned(
                    right: 16.0,
                    bottom: 16.0,
                    child: FloatingActionButton(
                      heroTag: "locationButton",
                      onPressed: () {
                        if (currentPosition != null) {
                          _mapController.move(
                            LatLng(currentPosition.latitude, currentPosition.longitude),
                            15.0
                          );
                        }
                      },
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
