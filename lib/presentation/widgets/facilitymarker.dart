import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FacilityMarker extends Marker {
  //final String name;
  final String street;
  final String dot;
  final String city;

  const FacilityMarker({
    required LatLng point,
    double width = 80.0,
    double height = 80.0,
    //required this.name,
    required this.street,
    required this.dot,
    required this.city,
    required super.child,
  }) : super(
          point: point,
          width: width,
          height: height,
        );
}
