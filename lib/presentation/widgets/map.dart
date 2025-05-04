// filepath: /Users/janikkahle/Documents/Development/Projekte/Mobile/mcbroken_app/lib/presentation/widgets/map.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster_plus/flutter_map_marker_cluster_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mcbroken/data/models/mcdonalds_model.dart';
import 'package:mcbroken/logic/blocs/home/home_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mcbroken/logic/cubits/settings/settings_cubit.dart';
import 'package:mcbroken/presentation/widgets/widgets.dart';

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
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Konvertiert eine Liste von McDonald's-Modellen in eine Liste von Kartenmarkern.
  ///
  /// Diese Methode transformiert die Rohdaten in Marker für die Kartenansicht und
  /// setzt die Farbe basierend auf dem Status der Eismaschine (grün/rot).
  ///
  /// @param data Liste der McDonald's-Standortdaten als Modellobjekte.
  /// @param size Bildschirmgröße für responsive Darstellung.
  /// @return Liste von Markern zur Darstellung auf der Karte.
  List<Marker> _buildMarkers(List<Mcdonalds_model> data, Size size) {
    // Sicherstellen, dass wir nur valide Daten verarbeiten
    if (data.isEmpty) {
      return [];
    }
    
    final List<Marker> resultMarkers = [];
    
    // Tracking für Debug-Zwecke
    int skippedCount = 0;
    int germanCount = 0;
    
    for (final location in data) {
      // Koordinaten aus dem Datensatz extrahieren und konvertieren
      double? latitude;
      double? longitude;
      
      try {
        // Breitengrad (latitude) ist normalerweise die zweite Koordinate [1]
        latitude = location.geometry.coordinates[1] is String 
            ? double.parse(location.geometry.coordinates[1] as String)
            : location.geometry.coordinates[1] as double;
            
        // Längengrad (longitude) ist normalerweise die erste Koordinate [0]
        longitude = location.geometry.coordinates[0] is String
            ? double.parse(location.geometry.coordinates[0] as String)
            : location.geometry.coordinates[0] as double;
            
        // Koordinaten-Vertauschung erkennen und korrigieren
        // (manchmal werden Koordinaten in umgekehrter Reihenfolge gespeichert)
        if (latitude > 90 || latitude < -90) {
          // Wenn der Breitengrad außerhalb des gültigen Bereichs liegt, könnten die Werte vertauscht sein
          final temp = latitude;
          latitude = longitude;
          longitude = temp;
        }
      } catch (e) {
        // Bei Konvertierungsfehlern diesen Marker überspringen
        debugPrint('Fehler beim Parsen der Koordinaten: $e');
        skippedCount++;
        continue;
      }
      
      // Nur gültige Koordinaten verwenden (keine null-Werte oder extreme Werte)
      if (latitude == null || longitude == null) {
        skippedCount++;
        continue;
      }
      
      // Prüfen, ob es sich um einen deutschen Standort handelt (grobe Abschätzung)
      // Deutschland liegt etwa zwischen 47° und 55° Nord, 6° und 15° Ost
      bool isGermany = (latitude >= 47.0 && latitude <= 55.0 && 
                        longitude >= 6.0 && longitude <= 15.0);
                        
      if (isGermany) {
        germanCount++;
      }
      
      // Gültigen Marker erstellen
      final marker = FacilityMarker(
        width: 30, // Feste Werte für stabile Darstellung
        height: 30,
        point: LatLng(latitude, longitude),
        city: location.properties.city,
        street: location.properties.street,
        dot: location.properties.dot,
        child: Icon(
          Icons.location_on,
          color: location.properties.dot == 'working' ? Colors.green : Colors.red,
          size: 30.0,
        ),
      );
      
      resultMarkers.add(marker);
    }
    
    debugPrint('Übersprungene Marker: $skippedCount');
    debugPrint('Deutsche Standorte erkannt: $germanCount');
    
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
        current is HomeStateLoaded || current is HomeStateError || current is HomeStateInitial,
      builder: (context, homeState) {
        // Position und Markerdaten basierend auf dem HomeState definieren
        Position? currentPosition;
        List<Mcdonalds_model> mcdonaldsData = [];
        
        // Je nach Zustand die entsprechenden Daten extrahieren
        if (homeState is HomeStateLoaded) {
          currentPosition = homeState.position;
          
          // Zugriff auf die vollständige Liste der McDonald's-Daten (KORRIGIERT)
          // Entscheidend ist hier die korrekte Feldreferenz
          mcdonaldsData = homeState.mcdonalds_data; 
          
          // Debug-Information zur Anzahl der geladenen Standorte
          debugPrint('Geladene McDonaldsData: ${mcdonaldsData.length}');
        }
        
        // Marker erstellen und validieren
        final markers = _buildMarkers(mcdonaldsData, size);
        debugPrint('Erstellte Marker: ${markers.length}');
        
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
        
        debugPrint('Funktionierende Marker: ${workingMarkers.length}');
        debugPrint('Defekte Marker: ${notWorkingMarkers.length}');
        
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
                      // Kartenkachel-Layer
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'dev.kahle.mcbroken',
                        tileProvider: NetworkTileProvider(),
                        maxZoom: 19,
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
