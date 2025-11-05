import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../models/location_point.dart';
import '../services/location_service.dart';
import '../widgets/map_view.dart';
import '../widgets/stats_card.dart';

class LocationTrackerScreen extends StatefulWidget {
  const LocationTrackerScreen({super.key});

  @override
  State<LocationTrackerScreen> createState() => _LocationTrackerScreenState();
}

class _LocationTrackerScreenState extends State<LocationTrackerScreen> {
  final LocationService _locationService = LocationService();
  Timer? _trackingTimer;
  bool _isTracking = false;
  int _trackingDuration = 2; // minutes
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    // Initialize with starting position
    _locationService.initialize();
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }

  void _startTracking() {
    setState(() {
      _isTracking = true;
      _startTime = DateTime.now();
    });

    _locationService.reset();

    // Update location every 5 seconds
    _trackingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_startTime != null &&
          DateTime.now().difference(_startTime!).inMinutes >= _trackingDuration) {
        _stopTracking();
      } else {
        setState(() {
          _locationService.simulateGpsUpdate();
        });
      }
    });
  }

  void _stopTracking() {
    _trackingTimer?.cancel();
    setState(() {
      _isTracking = false;
    });

    // Show completion dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tracking Complete'),
        content: Text(
          'Total distance: ${_locationService.totalDistance.toStringAsFixed(2)} km\n'
          'Total points: ${_locationService.path.length}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _resetTracking() {
    _trackingTimer?.cancel();
    setState(() {
      _isTracking = false;
      _startTime = null;
      _locationService.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_locationService.path.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isTracking ? null : _resetTracking,
              tooltip: 'Reset',
            ),
        ],
      ),
      body: Column(
        children: [
          // Stats Cards
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: StatsCard(
                    icon: Icons.speed,
                    label: 'Distance',
                    value: '${_locationService.totalDistance.toStringAsFixed(2)} km',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatsCard(
                    icon: Icons.location_on,
                    label: 'Points',
                    value: '${_locationService.path.length}',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatsCard(
                    icon: Icons.timer,
                    label: 'Interval',
                    value: '5s',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // Map View
          Expanded(
            child: MapView(
              path: _locationService.path,
              currentPosition: _locationService.currentPosition,
            ),
          ),

          // Control Panel
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Duration:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 12),
                    ...List.generate(5, (index) {
                      final minutes = index + 1;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text('${minutes}m'),
                          selected: _trackingDuration == minutes,
                          onSelected: _isTracking
                              ? null
                              : (selected) {
                                  if (selected) {
                                    setState(() {
                                      _trackingDuration = minutes;
                                    });
                                  }
                                },
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isTracking ? _stopTracking : _startTracking,
                        icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                        label: Text(_isTracking ? 'Stop Tracking' : 'Start Tracking'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: _isTracking ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isTracking && _startTime != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Tracking in progress...',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
