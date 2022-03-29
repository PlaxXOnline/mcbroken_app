import 'dart:convert';
import 'package:collection/collection.dart';

class Mcdonalds_model {
  final Geometry geometry;
  final Properties properties;
  final String type;
  Mcdonalds_model({
    required this.geometry,
    required this.properties,
    required this.type,
  });

  Mcdonalds_model copyWith({
    Geometry? geometry,
    Properties? properties,
    String? type,
  }) {
    return Mcdonalds_model(
      geometry: geometry ?? this.geometry,
      properties: properties ?? this.properties,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'geometry': geometry.toMap()});
    result.addAll({'properties': properties.toMap()});
    result.addAll({'type': type});

    return result;
  }

  factory Mcdonalds_model.fromMap(Map<String, dynamic> map) {
    return Mcdonalds_model(
      geometry: Geometry.fromMap(map['geometry']),
      properties: Properties.fromMap(map['properties']),
      type: map['type'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Mcdonalds_model.fromJson(String source) =>
      Mcdonalds_model.fromMap(json.decode(source));

  @override
  String toString() =>
      'Mcdonalds_model(geometry: $geometry, properties: $properties, type: $type)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Mcdonalds_model &&
        other.geometry == geometry &&
        other.properties == properties &&
        other.type == type;
  }

  @override
  int get hashCode => geometry.hashCode ^ properties.hashCode ^ type.hashCode;
}

class Geometry {
  final List<String> coordinates;
  final String type;
  Geometry({
    required this.coordinates,
    required this.type,
  });

  Geometry copyWith({
    List<String>? coordinates,
    String? type,
  }) {
    return Geometry(
      coordinates: coordinates ?? this.coordinates,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'coordinates': coordinates});
    result.addAll({'type': type});

    return result;
  }

  factory Geometry.fromMap(Map<String, dynamic> map) {
    return Geometry(
      coordinates: List<String>.from(map['coordinates']),
      type: map['type'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Geometry.fromJson(String source) =>
      Geometry.fromMap(json.decode(source));

  @override
  String toString() => 'Geometry(coordinates: $coordinates, type: $type)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is Geometry &&
        listEquals(other.coordinates, coordinates) &&
        other.type == type;
  }

  @override
  int get hashCode => coordinates.hashCode ^ type.hashCode;
}

class Properties {
  final bool is_broken;
  final bool is_active;
  final String dot;
  final String state;
  final String city;
  final String street;
  final String country;
  final String last_checked;
  Properties({
    required this.is_broken,
    required this.is_active,
    required this.dot,
    required this.state,
    required this.city,
    required this.street,
    required this.country,
    required this.last_checked,
  });

  Properties copyWith({
    bool? is_broken,
    bool? is_active,
    String? dot,
    String? state,
    String? city,
    String? street,
    String? country,
    String? last_checked,
  }) {
    return Properties(
      is_broken: is_broken ?? this.is_broken,
      is_active: is_active ?? this.is_active,
      dot: dot ?? this.dot,
      state: state ?? this.state,
      city: city ?? this.city,
      street: street ?? this.street,
      country: country ?? this.country,
      last_checked: last_checked ?? this.last_checked,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'is_broken': is_broken});
    result.addAll({'is_active': is_active});
    result.addAll({'dot': dot});
    result.addAll({'state': state});
    result.addAll({'city': city});
    result.addAll({'street': street});
    result.addAll({'country': country});
    result.addAll({'last_checked': last_checked});

    return result;
  }

  factory Properties.fromMap(Map<String, dynamic> map) {
    return Properties(
      is_broken: map['is_broken'] ?? false,
      is_active: map['is_active'] ?? false,
      dot: map['dot'] ?? '',
      state: map['state'] ?? '',
      city: map['city'] ?? '',
      street: map['street'] ?? '',
      country: map['country'] ?? '',
      last_checked: map['last_checked'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Properties.fromJson(String source) =>
      Properties.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Properties(is_broken: $is_broken, is_active: $is_active, dot: $dot, state: $state, city: $city, street: $street, country: $country, last_checked: $last_checked)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Properties &&
        other.is_broken == is_broken &&
        other.is_active == is_active &&
        other.dot == dot &&
        other.state == state &&
        other.city == city &&
        other.street == street &&
        other.country == country &&
        other.last_checked == last_checked;
  }

  @override
  int get hashCode {
    return is_broken.hashCode ^
        is_active.hashCode ^
        dot.hashCode ^
        state.hashCode ^
        city.hashCode ^
        street.hashCode ^
        country.hashCode ^
        last_checked.hashCode;
  }
}
