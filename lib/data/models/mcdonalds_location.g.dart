// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcdonalds_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

McDonaldsLocation _$McDonaldsLocationFromJson(Map<String, dynamic> json) =>
    McDonaldsLocation(
      geometry: json['geometry'] == null
          ? Geometry(coordinates: <double>[0.0, 0.0], type: 'Point')
          : Geometry.fromJson(json['geometry'] as Map<String, dynamic>),
      properties: json['properties'] == null
          ? McProperties()
          : McProperties.fromJson(json['properties'] as Map<String, dynamic>),
      type: json['type'] as String? ?? 'Feature',
    );

Map<String, dynamic> _$McDonaldsLocationToJson(McDonaldsLocation instance) =>
    <String, dynamic>{
      'geometry': instance.geometry,
      'properties': instance.properties,
      'type': instance.type,
    };

Geometry _$GeometryFromJson(Map<String, dynamic> json) => Geometry(
      coordinates: json['coordinates'] == null
          ? <double>[0.0, 0.0]
          : (json['coordinates'] as List<dynamic>)
              .map((e) => e == null ? 0.0 : (e is num ? e.toDouble() : double.tryParse(e.toString()) ?? 0.0))
              .toList(),
      type: json['type'] as String? ?? 'Point',
    );

Map<String, dynamic> _$GeometryToJson(Geometry instance) => <String, dynamic>{
      'coordinates': instance.coordinates,
      'type': instance.type,
    };

McProperties _$McPropertiesFromJson(Map<String, dynamic> json) => McProperties(
      isBroken: json['is_broken'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      dot: json['dot'] as String? ?? 'unknown',
      state: json['state'] as String? ?? '',
      city: json['city'] as String? ?? '',
      street: json['street'] as String? ?? '',
      country: json['country'] as String? ?? '',
      lastChecked: json['last_checked'] as String? ?? '',
    );

Map<String, dynamic> _$McPropertiesToJson(McProperties instance) =>
    <String, dynamic>{
      'is_broken': instance.isBroken,
      'is_active': instance.isActive,
      'dot': instance.dot,
      'state': instance.state,
      'city': instance.city,
      'street': instance.street,
      'country': instance.country,
      'last_checked': instance.lastChecked,
    };
