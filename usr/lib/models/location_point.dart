class LocationPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'LocationPoint(lat: ${latitude.toStringAsFixed(6)}, lon: ${longitude.toStringAsFixed(6)}, time: $timestamp)';
  }

  // Convert to a tuple format (lat, lon)
  List<double> toLatLng() {
    return [latitude, longitude];
  }
}
