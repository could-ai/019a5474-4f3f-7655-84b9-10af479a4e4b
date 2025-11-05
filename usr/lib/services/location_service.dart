import 'dart:math';
import '../models/location_point.dart';

class LocationService {
  // Default starting position: San Francisco
  static const double _defaultStartLat = 37.7749;
  static const double _defaultStartLon = -122.4194;

  LocationPoint _currentPosition = LocationPoint(
    latitude: _defaultStartLat,
    longitude: _defaultStartLon,
    timestamp: DateTime.now(),
  );

  final List<LocationPoint> _path = [];
  double _totalDistance = 0.0;

  LocationPoint get currentPosition => _currentPosition;
  List<LocationPoint> get path => List.unmodifiable(_path);
  double get totalDistance => _totalDistance;

  void initialize() {
    _path.add(_currentPosition);
  }

  void reset() {
    _currentPosition = LocationPoint(
      latitude: _defaultStartLat,
      longitude: _defaultStartLon,
      timestamp: DateTime.now(),
    );
    _path.clear();
    _path.add(_currentPosition);
    _totalDistance = 0.0;
  }

  LocationPoint simulateGpsUpdate() {
    final random = Random();

    // Simulate random movement (in degrees; ~0.01° ≈ 1km)
    final latDelta = (random.nextDouble() * 2 - 1) * 0.01; // Range: -0.01 to 0.01
    final lonDelta = (random.nextDouble() * 2 - 1) * 0.01;

    final newLat = _currentPosition.latitude + latDelta;
    final newLon = _currentPosition.longitude + lonDelta;

    final newPosition = LocationPoint(
      latitude: newLat,
      longitude: newLon,
      timestamp: DateTime.now(),
    );

    // Calculate distance from previous point using Haversine formula
    final distance = _calculateDistance(
      _currentPosition.latitude,
      _currentPosition.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );

    _totalDistance += distance;
    _path.add(newPosition);
    _currentPosition = newPosition;

    print('New position: (${newLat.toStringAsFixed(6)}, ${newLon.toStringAsFixed(6)}), '
        'Distance: ${distance.toStringAsFixed(2)} km');

    return newPosition;
  }

  // Haversine formula to calculate distance between two GPS coordinates
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}
