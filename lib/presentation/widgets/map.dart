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
              icon: const Icon(Icons.location_on),
              onPressed: () {
                print('Marker tapped');
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
}
