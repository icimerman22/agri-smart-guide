/// The user's primary location, stored in `users/{uid}.primaryLocation`.
///
/// Coordinates are kept so the weather forecast (Open-Meteo) can be fetched
/// for this location without an extra geocoding step.
class FarmLocation {
  const FarmLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final double latitude;
  final double longitude;

  /// County seats of Croatia, sorted alphabetically.
  static const List<FarmLocation> croatianCities = [
    FarmLocation(name: 'Bjelovar', latitude: 45.8986, longitude: 16.8423),
    FarmLocation(name: 'Čakovec', latitude: 46.3844, longitude: 16.4339),
    FarmLocation(name: 'Dubrovnik', latitude: 42.6507, longitude: 18.0944),
    FarmLocation(name: 'Gospić', latitude: 44.5461, longitude: 15.3747),
    FarmLocation(name: 'Karlovac', latitude: 45.4929, longitude: 15.5553),
    FarmLocation(name: 'Koprivnica', latitude: 46.1628, longitude: 16.8275),
    FarmLocation(name: 'Krapina', latitude: 46.1608, longitude: 15.8789),
    FarmLocation(name: 'Osijek', latitude: 45.5550, longitude: 18.6955),
    FarmLocation(name: 'Pazin', latitude: 45.2403, longitude: 13.9367),
    FarmLocation(name: 'Požega', latitude: 45.3403, longitude: 17.6853),
    FarmLocation(name: 'Rijeka', latitude: 45.3271, longitude: 14.4422),
    FarmLocation(name: 'Sisak', latitude: 45.4851, longitude: 16.3731),
    FarmLocation(name: 'Slavonski Brod', latitude: 45.1603, longitude: 18.0156),
    FarmLocation(name: 'Split', latitude: 43.5081, longitude: 16.4402),
    FarmLocation(name: 'Šibenik', latitude: 43.7350, longitude: 15.8952),
    FarmLocation(name: 'Varaždin', latitude: 46.3057, longitude: 16.3366),
    FarmLocation(name: 'Virovitica', latitude: 45.8319, longitude: 17.3839),
    FarmLocation(name: 'Vukovar', latitude: 45.3511, longitude: 19.0028),
    FarmLocation(name: 'Zadar', latitude: 44.1194, longitude: 15.2314),
    FarmLocation(name: 'Zagreb', latitude: 45.8150, longitude: 15.9819),
  ];

  /// Reads a stored location. Returns `null` when no location has been chosen
  /// yet (empty map) or when the stored data is incomplete.
  static FarmLocation? fromMap(Map<String, dynamic> data) {
    final name = data['name'];
    final latitude = data['latitude'];
    final longitude = data['longitude'];
    if (name is! String || latitude is! num || longitude is! num) {
      return null;
    }
    return FarmLocation(
      name: name,
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
  };

  @override
  bool operator ==(Object other) =>
      other is FarmLocation &&
      other.name == name &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(name, latitude, longitude);
}
