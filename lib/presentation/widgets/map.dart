import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:mcbroken/data/models/mcdonalds_model.dart';
import 'package:mcbroken/logic/homebloc/home_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mcbroken/presentation/widgets/widgets.dart';

class McDonaldsMap extends StatefulWidget {
  const McDonaldsMap({Key? key}) : super(key: key);

  @override
  _McDonaldsMapState createState() => _McDonaldsMapState();
}

class _McDonaldsMapState extends State<McDonaldsMap> {
  List<Mcdonalds_model> mcdonalds_data = <Mcdonalds_model>[];
  final PopupController popupController = PopupController();
  late FollowOnLocationUpdate _followOnLocationUpdate;
  late StreamController<double?> _followCurrentLocationStreamController;
  late final Mcdonalds_model data;

  @override
  void initState() {
    super.initState();
    _followOnLocationUpdate = FollowOnLocationUpdate.always;
    _followCurrentLocationStreamController = StreamController<double?>();
  }

  @override
  void dispose() {
    _followCurrentLocationStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations locale = AppLocalizations.of(context)!;
    final Size size = MediaQuery.sizeOf(context);
    final homeBloc = BlocProvider.of<HomeBloc>(context);
    mcdonalds_data = BlocProvider.of<HomeBloc>(context).mcDonaldsData;
    var markers = <FacilityMarker>[
      for (int i = 0, len = mcdonalds_data.length; i < len; i++)
        FacilityMarker(
          width: size.height * 0.2,
          height: size.width * 0.2,
          point: LatLng(
            double.parse(mcdonalds_data[i].geometry.coordinates[1]),
            double.parse(mcdonalds_data[i].geometry.coordinates[0]),
          ),
          city: mcdonalds_data[i].properties.city,
          street: mcdonalds_data[i].properties.street,
          dot: mcdonalds_data[i].properties.dot,
          child: SizedBox(
            height: size.height * 0.02,
            width: size.width * 0.02,
            child: FittedBox(
              child: Icon(
                Icons.location_on,
                color: mcdonalds_data[i].properties.dot == 'working'
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ),
        ),
    ];

    return PopupScope(
      popupController: popupController,
      child: FlutterMap(
        options: MapOptions(
          initialCenter:
              LatLng(homeBloc.position.latitude, homeBloc.position.longitude),
          initialZoom: 15.0,
          minZoom: 5.0,
          maxZoom: 25.0,
          onTap: (_, __) => popupController.hideAllPopups(),
          onPositionChanged: (MapPosition position, bool hasGesture) {
            if (hasGesture &&
                _followOnLocationUpdate != FollowOnLocationUpdate.never) {
              setState(
                () => _followOnLocationUpdate = FollowOnLocationUpdate.never,
              );
            }
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'dev.kahle.mcbroken',
            subdomains: const ['a', 'b', 'c'],
            tileProvider: NetworkTileProvider(),
          ),
          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              maxClusterRadius: 120,
              size: const Size(40, 40),
              padding: const EdgeInsets.all(50),
              markers: markers,
              polygonOptions: const PolygonOptions(
                  borderColor: Colors.blueAccent,
                  color: Colors.black12,
                  borderStrokeWidth: 3),
              popupOptions: PopupOptions(
                  popupSnap: PopupSnap.markerTop,
                  popupController: popupController,
                  popupBuilder: (_, marker) {
                    final facilityMarker = marker as FacilityMarker;
                    return InfoPopup(
                        size: size,
                        locale: locale,
                        facilityMarker: facilityMarker);
                  }),
              builder: (context, markers) {
                return Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: Colors.blue),
                  child: Center(
                    child: Text(
                      markers.length.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          CurrentLocationLayer(
            followCurrentLocationStream:
                _followCurrentLocationStreamController.stream,
            followOnLocationUpdate: _followOnLocationUpdate,
            turnOnHeadingUpdate: TurnOnHeadingUpdate.never,
            style: const LocationMarkerStyle(
              marker: DefaultLocationMarker(
                child: Icon(
                  Icons.navigation,
                  color: Colors.white,
                ),
              ),
              markerSize: Size(40, 40),
              markerDirection: MarkerDirection.heading,
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: FloatingActionButton(
                onPressed: () {
                  // Follow the location marker on the map when location updated until user interact with the map.
                  setState(
                    () =>
                        _followOnLocationUpdate = FollowOnLocationUpdate.always,
                  );
                  // Follow the location marker on the map and zoom the map to level 18.
                  _followCurrentLocationStreamController.add(18);
                },
                child: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
