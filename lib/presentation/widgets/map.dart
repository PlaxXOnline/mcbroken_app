import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mcbroken/data/models/mcdonalds_model.dart';

class McDonaldsMap extends StatelessWidget {
  final List<Mcdonalds_model> mcdonalds_data;
  const McDonaldsMap({Key? key, required this.mcdonalds_data})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var markers = <Marker>[
      for (int i = 0, len = mcdonalds_data.length; i < len; i++)
        Marker(
          width: 80.0,
          height: 80.0,
          point: LatLng(
            double.parse(mcdonalds_data[i].geometry.coordinates[1]),
            double.parse(mcdonalds_data[i].geometry.coordinates[0]),
          ),
          builder: (ctx) => Container(
            child: IconButton(
              iconSize: 75.0,
              color: mcdonalds_data[i].properties.dot == 'working'
                  ? Colors.green
                  : Colors.red,
              icon: const Icon(Icons.location_on),
              onPressed: () {
                //print('Marker tapped');
                mcDonaldsDetailSheet(context, i);
              },
            ),
          ),
        ),
    ];

    return FlutterMap(
      options: MapOptions(
        center: LatLng(48.7783, 9.1796),
        zoom: 15.0,
      ),
      layers: [
        TileLayerOptions(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
          // For example purposes. It is recommended to use
          // TileProvider with a caching and retry strategy, like
          // NetworkTileProvider or CachedNetworkTileProvider
          tileProvider: NetworkTileProvider(),
        ),
        MarkerLayerOptions(markers: markers)
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
