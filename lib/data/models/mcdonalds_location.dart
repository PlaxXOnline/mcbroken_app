// filepath: /Users/janikkahle/Documents/Development/Projekte/Mobile/mcbroken_app/lib/data/models/mcdonalds_location.dart
import 'package:json_annotation/json_annotation.dart';

part 'mcdonalds_location.g.dart';

/// Ein Modell zur Darstellung eines McDonald's-Standorts mit allen relevanten Daten.
///
/// Diese Klasse verwendet json_serializable für automatisierte JSON-Serialisierung
/// und -Deserialisierung, was die Wartbarkeit und Lesbarkeit des Codes verbessert.
/// Die Implementierung ist robust gegenüber null-Werten und inkonsistenten API-Antworten.
@JsonSerializable()
class McDonaldsLocation {
  /// Die geometrischen Daten des Standorts (Koordinaten)
  final Geometry geometry;

  /// Die Eigenschaften des Standorts (Betriebsstatus, Adresse usw.)
  final McProperties properties;

  /// Der Typ des geografischen Objekts (immer "Feature")
  @JsonKey(defaultValue: 'Feature')
  final String type;

  /// Erstellt eine neue [McDonaldsLocation] Instanz mit den angegebenen Werten.
  ///
  /// [geometry] enthält die Koordinaten des Standorts.
  /// [properties] enthält die Details des Standorts wie Adresse und Status.
  /// [type] beschreibt den Typ des geografischen Objekts.
  const McDonaldsLocation({
    required this.geometry,
    required this.properties,
    this.type = 'Feature',
  });

  /// Erstellt eine Kopie dieser [McDonaldsLocation] mit möglicherweise aktualisierten Werten.
  ///
  /// Alle nicht angegebenen Parameter behalten ihre ursprünglichen Werte.
  McDonaldsLocation copyWith({
    Geometry? geometry,
    McProperties? properties,
    String? type,
  }) {
    return McDonaldsLocation(
      geometry: geometry ?? this.geometry,
      properties: properties ?? this.properties,
      type: type ?? this.type,
    );
  }

  /// Konvertiert eine JSON-Map in eine [McDonaldsLocation] Instanz.
  factory McDonaldsLocation.fromJson(Map<String, dynamic> json) => 
      _$McDonaldsLocationFromJson(json);

  /// Konvertiert diese [McDonaldsLocation] Instanz in eine JSON-Map.
  Map<String, dynamic> toJson() => _$McDonaldsLocationToJson(this);

  @override
  String toString() => 
      'McDonaldsLocation(geometry: $geometry, properties: $properties, type: $type)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is McDonaldsLocation &&
        other.geometry == geometry &&
        other.properties == properties &&
        other.type == type;
  }

  @override
  int get hashCode => geometry.hashCode ^ properties.hashCode ^ type.hashCode;
}

/// Modellklasse für die geografischen Koordinaten eines McDonald's-Standorts.
@JsonSerializable()
class Geometry {
  /// Die Koordinaten des Standorts als Liste [Längengrad, Breitengrad]
  @JsonKey(defaultValue: <double>[0.0, 0.0])
  final List<double> coordinates;

  /// Der Typ der Geometrie (immer "Point")
  @JsonKey(defaultValue: 'Point')
  final String type;

  /// Erstellt eine neue [Geometry] Instanz mit den angegebenen Koordinaten und Typ.
  const Geometry({
    this.coordinates = const [0.0, 0.0],
    this.type = 'Point',
  });

  /// Erstellt eine Kopie dieser [Geometry] mit möglicherweise aktualisierten Werten.
  ///
  /// Alle nicht angegebenen Parameter behalten ihre ursprünglichen Werte.
  Geometry copyWith({
    List<double>? coordinates,
    String? type,
  }) {
    return Geometry(
      coordinates: coordinates ?? this.coordinates,
      type: type ?? this.type,
    );
  }

  /// Konvertiert eine JSON-Map in eine [Geometry] Instanz.
  factory Geometry.fromJson(Map<String, dynamic> json) => 
      _$GeometryFromJson(json);

  /// Konvertiert diese [Geometry] Instanz in eine JSON-Map.
  Map<String, dynamic> toJson() => _$GeometryToJson(this);

  @override
  String toString() => 'Geometry(coordinates: $coordinates, type: $type)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Geometry &&
        _listEquals(other.coordinates, coordinates) &&
        other.type == type;
  }

  @override
  int get hashCode => coordinates.hashCode ^ type.hashCode;
  
  /// Hilfsmethode zum Vergleich von Listen
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Eigenschaften eines McDonald's-Standorts.
@JsonSerializable()
class McProperties {
  /// Ob der Eisautomat defekt ist
  @JsonKey(name: 'is_broken', defaultValue: false)
  final bool isBroken;

  /// Ob der Standort aktiv ist
  @JsonKey(name: 'is_active', defaultValue: true)
  final bool isActive;

  /// Die Farbe des Markierungspunkts auf der Karte
  @JsonKey(defaultValue: 'unknown')
  final String dot;

  /// Der Bundesstaat des Standorts
  @JsonKey(defaultValue: '')
  final String state;

  /// Die Stadt des Standorts
  @JsonKey(defaultValue: '')
  final String city;

  /// Die Straße des Standorts
  @JsonKey(defaultValue: '')
  final String street;

  /// Das Land des Standorts
  @JsonKey(defaultValue: '')
  final String country;

  /// Der Zeitpunkt der letzten Überprüfung des Eisautomaten
  @JsonKey(name: 'last_checked', defaultValue: '')
  final String lastChecked;

  /// Erstellt eine neue [McProperties] Instanz mit den angegebenen Werten.
  const McProperties({
    this.isBroken = false,
    this.isActive = true,
    this.dot = 'unknown',
    this.state = '',
    this.city = '',
    this.street = '',
    this.country = '',
    this.lastChecked = '',
  });

  /// Erstellt eine Kopie dieser [McProperties] mit möglicherweise aktualisierten Werten.
  ///
  /// Alle nicht angegebenen Parameter behalten ihre ursprünglichen Werte.
  McProperties copyWith({
    bool? isBroken,
    bool? isActive,
    String? dot,
    String? state,
    String? city,
    String? street,
    String? country,
    String? lastChecked,
  }) {
    return McProperties(
      isBroken: isBroken ?? this.isBroken,
      isActive: isActive ?? this.isActive,
      dot: dot ?? this.dot,
      state: state ?? this.state,
      city: city ?? this.city,
      street: street ?? this.street,
      country: country ?? this.country,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }

  /// Konvertiert eine JSON-Map in eine [McProperties] Instanz.
  factory McProperties.fromJson(Map<String, dynamic> json) => 
      _$McPropertiesFromJson(json);

  /// Konvertiert diese [McProperties] Instanz in eine JSON-Map.
  Map<String, dynamic> toJson() => _$McPropertiesToJson(this);

  @override
  String toString() {
    return 'McProperties(isBroken: $isBroken, isActive: $isActive, dot: $dot, state: $state, '
        'city: $city, street: $street, country: $country, lastChecked: $lastChecked)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is McProperties &&
        other.isBroken == isBroken &&
        other.isActive == isActive &&
        other.dot == dot &&
        other.state == state &&
        other.city == city &&
        other.street == street &&
        other.country == country &&
        other.lastChecked == lastChecked;
  }

  @override
  int get hashCode {
    return isBroken.hashCode ^
        isActive.hashCode ^
        dot.hashCode ^
        state.hashCode ^
        city.hashCode ^
        street.hashCode ^
        country.hashCode ^
        lastChecked.hashCode;
  }
}
