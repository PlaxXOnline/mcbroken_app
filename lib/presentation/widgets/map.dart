import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:mcbroken/data/models/mcdonalds_model.dart';
import 'package:mcbroken/logic/bloc/home_bloc.dart';

class McDonaldsMap extends StatefulWidget {
  @override
  _McDonaldsMapState createState() => _McDonaldsMapState();
}

class _McDonaldsMapState extends State<McDonaldsMap> {
  List<Mcdonalds_model> mcdonalds_data = <Mcdonalds_model>[];
  final PopupController popupController = PopupController();
  late final Mcdonalds_model data;

  @override
  void initState() {
    super.initState();
  }

/* class McDonaldsMap extends StatelessWidget {
  final List<Mcdonalds_model> mcdonalds_data;
  const McDonaldsMap({Key? key, required this.mcdonalds_data})
      : super(key: key); */

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    mcdonalds_data = BlocProvider.of<HomeBloc>(context).mcDonaldsData;
    var markers = <FacilityMarker>[
      for (int i = 0, len = mcdonalds_data.length; i < len; i++)
        FacilityMarker(
          width: 80.0,
          height: 80.0,
          point: LatLng(
            double.parse(mcdonalds_data[i].geometry.coordinates[1]),
            double.parse(mcdonalds_data[i].geometry.coordinates[0]),
          ),
          city: mcdonalds_data[i].properties.city,
          street: mcdonalds_data[i].properties.street,
          dot: mcdonalds_data[i].properties.dot,
          builder: (ctx) => SizedBox(
            height: 75,
            width: 75,
            child: FittedBox(
              child: Icon(
                Icons.location_on,
                color: mcdonalds_data[i].properties.dot == 'working'
                    ? Colors.green
                    : Colors.red,
              ),
            ), /* IconButton(
              iconSize: 75.0,
              color: mcdonalds_data[i].properties.dot == 'working'
                  ? Colors.green
                  : Colors.red,
              icon: const Icon(Icons.location_on),
              onPressed: () {
                mcDonaldsDetailSheet(context, i);
              },
            ), */
          ),
        ),
    ];

    return FlutterMap(
      options: MapOptions(
        center: LatLng(48.7783, 9.1796),
        zoom: 15.0,
        minZoom: 5.0,
        maxZoom: 25.0,
        plugins: [
          MarkerClusterPlugin(),
        ],
        onTap: (_, __) => popupController.hideAllPopups(),
      ),
      children: [
        TileLayerWidget(
          options: TileLayerOptions(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
            // For example purposes. It is recommended to use
            // TileProvider with a caching and retry strategy, like
            // NetworkTileProvider or CachedNetworkTileProvider
            tileProvider: NetworkTileProvider(),
          ),
        ),
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            maxClusterRadius: 120,
            size: const Size(40, 40),
            fitBoundsOptions: const FitBoundsOptions(
              padding: EdgeInsets.all(50),
            ),
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
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: size.width * 0.6,
                      height: size.height * 0.3,
                      color: Colors.white,
                      child: GestureDetector(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 10.0, left: 10.0, right: 10.0),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 100,
                                width: 100,
                                child: Image.asset(
                                    'assets/flurry_big_transparent.png'),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'McDonalds ',
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    facilityMarker.city,
                                    style: const TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                facilityMarker.street,
                                style: const TextStyle(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Eismaschine: ',
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    facilityMarker.dot == 'working'
                                        ? 'Funktioniert'
                                        : 'Defekt',
                                    style: const TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Icon(
                                    facilityMarker.dot == 'working'
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: facilityMarker.dot == 'working'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
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
              ); /* FloatingActionButton(
                  child: Text(markers.length.toString()), onPressed: () {}); */
            },
          ),
        ),
      ],
    );
  }

  Future<dynamic> mcDonaldsDetailSheet(BuildContext context, int index) {
    return showModalBottomSheet(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return FractionallySizedBox(
              heightFactor: 0.5,
              child: Padding(
                padding:
                    const EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
                child: Column(
                  children: [
                    Image.asset('assets/flurry_big_transparent.png'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'McDonalds ',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          mcdonalds_data[index].properties.city,
                          style: const TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      mcdonalds_data[index].properties.street,
                      style: const TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 70,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Eismaschine: ',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          mcdonalds_data[index].properties.dot == 'working'
                              ? 'Funktioniert'
                              : 'Defekt',
                          style: const TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          mcdonalds_data[index].properties.dot == 'working'
                              ? Icons.check_circle
                              : Icons.cancel,
                          color:
                              mcdonalds_data[index].properties.dot == 'working'
                                  ? Colors.green
                                  : Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class FacilityMarker extends Marker {
  //final String name;
  final String street;
  final String dot;
  final String city;

  FacilityMarker({
    required LatLng point,
    required WidgetBuilder builder,
    double width = 80.0,
    double height = 80.0,
    //required this.name,
    required this.street,
    required this.dot,
    required this.city,
  }) : super(
          point: point,
          builder: builder,
          width: width,
          height: height,
        );
}
